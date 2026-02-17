"""
Order management routes
"""
from fastapi import APIRouter, Depends, Body, HTTPException, BackgroundTasks, Header
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload
from typing import Optional, List
import random
from datetime import datetime, timezone
from app.services.printing_service import PrintingService

from app.db.database import get_db
from app.core.dependencies import get_current_user, get_branch_id
from app.models import Order, OrderItem, KOT, KOTItem, Table, Customer, POSSession, CompanySettings, MenuItem, Branch

from app.schemas import OrderResponse
from app.services.inventory_service import InventoryService

router = APIRouter()


@router.get("", response_model=List[OrderResponse])
async def get_orders(
    order_type: Optional[str] = None,
    status: Optional[str] = None,
    customer_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all orders, optionally filtered by order_type, status, and customer_id"""
    # branch_id is now provided by dependency
    
    query = db.query(Order).options(
        joinedload(Order.table),
        joinedload(Order.customer), joinedload(Order.delivery_partner),
        joinedload(Order.items).joinedload(OrderItem.menu_item),
        joinedload(Order.kots).joinedload(KOT.items).joinedload(KOTItem.menu_item)
    )
    
    # Filter by branch_id for data isolation
    query = query.filter(Order.branch_id == branch_id)
    
    if order_type:
        query = query.filter(Order.order_type == order_type)
    if status:
        # Handle comma-separated status values
        status_list = [s.strip() for s in status.split(',')]
        query = query.filter(Order.status.in_(status_list))
    if customer_id:
        query = query.filter(Order.customer_id == customer_id)
    
    orders = query.order_by(Order.created_at.desc()).all()
    return orders


@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get order by ID with items"""
    # branch_id is now provided by dependency
    
    query = db.query(Order).options(
        joinedload(Order.table),
        joinedload(Order.customer), joinedload(Order.delivery_partner),
        joinedload(Order.items).joinedload(OrderItem.menu_item),
        joinedload(Order.kots).joinedload(KOT.items).joinedload(KOTItem.menu_item)
    ).filter(Order.id == order_id)
    
    # Filter by branch_id for data isolation
    if branch_id:
        query = query.filter(Order.branch_id == branch_id)
    
    order = query.first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Recalculate totals if gross_amount doesn't match sum of items
    # This handles cases where items were added incrementally through multiple KOTs
    if order.items:
        calculated_gross = sum(item.subtotal for item in order.items)
        
        # If there's a mismatch, recalculate all amounts
        if abs(calculated_gross - (order.gross_amount or 0)) > 0.01:
            settings = db.query(CompanySettings).first()
            branch = db.query(Branch).filter(Branch.id == order.branch_id).first()
            
            sc_rate = branch.service_charge_rate if branch and branch.service_charge_rate is not None else (settings.service_charge_rate if settings else 10.0)
            tax_rate = branch.tax_rate if branch and branch.tax_rate is not None else (settings.tax_rate if settings else 13.0)
            
            discount = order.discount or 0
            delivery = order.delivery_charge or 0
            
            # Consistent with Frontend: SC and Tax on Net of Discount
            base_amount = max(0, calculated_gross - discount)
            sc_amount = round(base_amount * (sc_rate / 100), 2)
            tax_amount = round((base_amount + sc_amount) * (tax_rate / 100), 2)
            
            order.gross_amount = calculated_gross
            order.service_charge_amount = sc_amount
            order.tax_amount = tax_amount
            order.net_amount = round(base_amount + sc_amount + tax_amount + delivery, 2)
            order.total_amount = order.net_amount
            
            db.commit()
            db.refresh(order)
    
    return order


@router.post("", response_model=OrderResponse)
async def create_order(
    order_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id),
    x_branch_code: str = Header(..., alias="X-Branch-Code")
):
    """Create a new order"""
    items_data = order_data.pop('items', [])
    
    if 'order_number' not in order_data:
        # Generate branch-specific order number (format: BRANCH-ORD-YYYYMMDD-SEQ)
        today_str = datetime.now().strftime('%Y%m%d')
        prefix = f"{x_branch_code}-ORD-{today_str}-"
        
        while True:
            last_order = db.query(Order).filter(
                Order.branch_id == branch_id,
                Order.order_number.like(f"{prefix}%")
            ).order_by(Order.order_number.desc()).first()
            
            if last_order:
                try:
                    parts = last_order.order_number.split('-')
                    if len(parts) >= 3:
                        last_seq = int(parts[-1])
                        seq = last_seq + 1
                    else:
                        seq = 1
                except (ValueError, IndexError):
                    seq = 1
            else:
                seq = 1
                
            order_number = f"{prefix}{seq:04d}"
            # Double check uniqueness within branch
            if not db.query(Order).filter(Order.order_number == order_number, Order.branch_id == branch_id).first():
                order_data['order_number'] = order_number
                break
            # If exists, loop will run again and last_order will find the one we just detected
    order_data['created_by'] = current_user.id
    order_data['branch_id'] = branch_id
    
    # Tie to active POS Session
    active_session = db.query(POSSession).filter(
        POSSession.user_id == current_user.id,
        POSSession.branch_id == branch_id,
        POSSession.status == "Open"
    ).first()
    if active_session:
        order_data['pos_session_id'] = active_session.id
    
    # Handle customer lookup/creation by name if customer_id is missing
    customer_name = order_data.pop('customer_name', None)
    if not order_data.get('customer_id') and customer_name:
        # Try to find existing customer by name in this branch
        customer = db.query(Customer).filter(
            Customer.name == customer_name,
            Customer.branch_id == branch_id
        ).first()

        if not customer:
            # Create a basic customer profile
            customer = Customer(
                name=customer_name,
                branch_id=branch_id,
                customer_type="Regular"
            )
            db.add(customer)
            db.flush()

        order_data['customer_id'] = customer.id

    # Calculate accurate amounts based on business rules
    # 1. Gross - sum of items
    gross = 0
    for item in items_data:
        price = item.get('price')
        if price is None or price == 0:
            mi = db.query(MenuItem).filter(MenuItem.id == item.get('menu_item_id')).first()
            price = mi.price if mi else 0
        gross += (item.get('quantity', 0) * price)
    
    # 2. Charges from settings (Branch specific first)
    settings = db.query(CompanySettings).first()
    branch = db.query(Branch).filter(Branch.id == branch_id).first()
    
    sc_rate = branch.service_charge_rate if branch and branch.service_charge_rate is not None else (settings.service_charge_rate if settings else 10.0)
    tax_rate = branch.tax_rate if branch and branch.tax_rate is not None else (settings.tax_rate if settings else 13.0)
    
    discount = order_data.get('discount', 0)
    delivery_charge = order_data.get('delivery_charge', 0)
    
    # Consistent with Frontend: SC and Tax on Net of Discount
    base_amount = max(0, gross - discount)
    sc_amount = round(base_amount * (sc_rate / 100), 2)
    tax_amount = round((base_amount + sc_amount) * (tax_rate / 100), 2)
    
    order_data['gross_amount'] = gross
    order_data['service_charge_amount'] = sc_amount
    order_data['tax_amount'] = tax_amount
    order_data['net_amount'] = round(base_amount + sc_amount + tax_amount + delivery_charge, 2)
    order_data['total_amount'] = order_data['net_amount']
    
    # Set branch_id for data isolation
    order_data['branch_id'] = branch_id
    
    # Remove fields not in Order model but potentially in input
    order_data.pop('tax', None)
    order_data.pop('service_charge', None)
    
    new_order = Order(**order_data)
    db.add(new_order)
    db.flush() # Get ID before adding items
    
    # Add items
    for item in items_data:
        order_item = OrderItem(
            order_id=new_order.id,
            menu_item_id=item['menu_item_id'],
            quantity=item['quantity'],
            price=item.get('price', 0),
            subtotal=item.get('subtotal', item.get('price', 0) * item['quantity']),
            notes=item.get('notes', '')
        )
        db.add(order_item)
    
    # --- Generate KOT/BOT logic ---
    if new_order.status != 'Draft':
        item_ids = [item['menu_item_id'] for item in items_data]
        menu_items = db.query(MenuItem).options(joinedload(MenuItem.category)).filter(MenuItem.id.in_(item_ids)).all()
        # Map item ID -> MenuItem object
        menu_items_map = {m.id: m for m in menu_items}
        
        kot_items = []
        bot_items = []
        
        for item in items_data:
            m_item = menu_items_map.get(item['menu_item_id'])
            if m_item:
                # Prioritize Category type, fallback to MenuItem.kot_bot
                category_type = m_item.category.type if m_item.category else m_item.kot_bot
                if category_type == 'BOT':
                    bot_items.append(item)
                else:
                    kot_items.append(item)

        today_str = datetime.now().strftime('%Y%m%d')

        # Create KOT
        if kot_items:
            kot_prefix = f"KOT-{today_str}-"
            
            while True:
                # Check globally across all branches for uniqueness if we've removed branch code
                last_kot = db.query(KOT).filter(
                    KOT.kot_number.like(f"{kot_prefix}%")
                ).order_by(KOT.kot_number.desc()).first()
                
                kot_seq = 1
                if last_kot:
                    try:
                        parts = last_kot.kot_number.split('-')
                        if len(parts) >= 3:
                            kot_seq = int(parts[-1]) + 1
                    except (ValueError, IndexError):
                        pass
                
                new_kot_num = f"{kot_prefix}{kot_seq:04d}"
                if not db.query(KOT).filter(KOT.kot_number == new_kot_num).first():
                    break
            
            kot = KOT(
                kot_number=new_kot_num,
                order_id=new_order.id,
                branch_id=branch_id,
                kot_type='KOT',
                status='Pending',
                created_by=current_user.id
            )
            db.add(kot)
            db.flush()
            
            for item in kot_items:
                k_item = KOTItem(
                    kot_id=kot.id,
                    menu_item_id=item['menu_item_id'],
                    quantity=item['quantity'],
                    notes=item.get('notes', '')
                )
                db.add(k_item)
                
        # Create BOT
        if bot_items:
            bot_prefix = f"BOT-{today_str}-"
            
            while True:
                # Check globally across all branches for uniqueness
                last_bot = db.query(KOT).filter(
                    KOT.kot_number.like(f"{bot_prefix}%")
                ).order_by(KOT.kot_number.desc()).first()
                
                bot_seq = 1
                if last_bot:
                    try:
                        parts = last_bot.kot_number.split('-')
                        if len(parts) >= 3:
                            bot_seq = int(parts[-1]) + 1
                    except (ValueError, IndexError):
                        pass
                
                new_bot_num = f"{bot_prefix}{bot_seq:04d}"
                if not db.query(KOT).filter(KOT.kot_number == new_bot_num).first():
                    break
            
            bot = KOT(
                kot_number=new_bot_num,
                order_id=new_order.id,
                branch_id=branch_id,
                kot_type='BOT',
                status='Pending',
                created_by=current_user.id
            )
            db.add(bot)
            db.flush()
            
            for item in bot_items:
                b_item = KOTItem(
                    kot_id=bot.id,
                    menu_item_id=item['menu_item_id'],
                    quantity=item['quantity'],
                    notes=item.get('notes', '')
                )
                db.add(b_item)
    
    # Update table status to Occupied if table order
    if new_order.table_id and new_order.order_type in ['Table', 'Dine-in']:
        table = db.query(Table).filter(Table.id == new_order.table_id).first()
        if table:
            # Determine target status
            target_status = "Occupied"
            if new_order.status in ['Paid', 'Completed']:
                target_status = "Available"
            
            if table.merge_group_id and str(table.merge_group_id).strip():
                # Update all tables in merge group
                db.query(Table).filter(
                    Table.merge_group_id == table.merge_group_id,
                    Table.branch_id == new_order.branch_id
                ).update({"status": target_status})
            else:
                table.status = target_status
    
    # Update customer stats if Paid
    if new_order.status in ['Paid', 'Completed'] and new_order.customer_id:
        customer = db.query(Customer).filter(Customer.id == new_order.customer_id).first()
        if customer:
            customer.total_visits += 1
            customer.total_spent += (new_order.net_amount or 0)
            customer.due_amount += (new_order.credit_amount or 0)
            customer.updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(new_order)
    
    # Reload with relationships
    order = db.query(Order).options(
        joinedload(Order.table),
        joinedload(Order.customer),
        joinedload(Order.items).joinedload(OrderItem.menu_item),
        joinedload(Order.kots).joinedload(KOT.items).joinedload(KOTItem.menu_item)
    ).filter(Order.id == new_order.id).first()
    
    return order


@router.put("/{order_id}", response_model=OrderResponse)
@router.patch("/{order_id}", response_model=OrderResponse)
async def update_order(
    order_id: int,
    order_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Update an order"""
    order = db.query(Order).filter(
        Order.id == order_id,
        Order.branch_id == branch_id
    ).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    old_status = order.status
    
    # Separate items if they exist
    items_data = order_data.pop('items', None)
    
    for key, value in order_data.items():
        if hasattr(order, key):
            setattr(order, key, value)
    
    # Update items if provided
    if items_data is not None:
        # Simple approach: clear and re-add
        # For a more robust system, we would diff them.
        db.query(OrderItem).filter(OrderItem.order_id == order.id).delete()
        for item_data in items_data:
            new_order_item = OrderItem(
                order_id=order.id,
                menu_item_id=item_data['menu_item_id'],
                quantity=item_data['quantity'],
                price=item_data.get('price', 0),
                subtotal=item_data.get('subtotal', item_data.get('price', 0) * item_data['quantity']),
                notes=item_data.get('notes', '')
            )
            db.add(new_order_item)
    
    # Recalculate amounts if items were updated or specific amounts provided
    if items_data is not None or 'gross_amount' in order_data or 'discount' in order_data or 'delivery_charge' in order_data:
        # Calculate gross - if items_data is provided, use it (it's the source of truth for the update)
        if items_data is not None:
             gross = 0
             for item in items_data:
                 price = item.get('price')
                 if price is None or price == 0:
                     # Fallback to current menu price if missing
                     mi = db.query(MenuItem).filter(MenuItem.id == item['menu_item_id']).first()
                     price = mi.price if mi else 0
                 gross += (item['quantity'] * price)
        else:
            # Use existing items if none provided in this update
            gross = sum(item.quantity * item.price for item in order.items)
        
        settings = db.query(CompanySettings).first()
        branch = db.query(Branch).filter(Branch.id == order.branch_id).first()
        
        sc_rate = branch.service_charge_rate if branch and branch.service_charge_rate is not None else (settings.service_charge_rate if settings else 10.0)
        tax_rate = branch.tax_rate if branch and branch.tax_rate is not None else (settings.tax_rate if settings else 13.0)
        
        discount = order.discount or 0
        delivery = order.delivery_charge or 0
        
        # Consistent with Frontend: SC and Tax on Net of Discount
        base_amount = max(0, gross - discount)
        sc_amount = round(base_amount * (sc_rate / 100), 2)
        tax_amount = round((base_amount + sc_amount) * (tax_rate / 100), 2)
        
        order.gross_amount = gross
        order.service_charge_amount = sc_amount
        order.tax_amount = tax_amount
        order.net_amount = round(base_amount + sc_amount + tax_amount + delivery, 2)
        order.total_amount = order.net_amount
    
    # Handle KOT status when order status changes
    if 'status' in order_data:
        new_status = order_data['status']
        if new_status in ['Paid', 'Completed'] and old_status not in ['Paid', 'Completed']:
            # Inventory is already deducted when KOT/BOT is marked as Served
            # No need to deduct again here
            
            # Mark all associated KOTs as Served when payment is done
            db.query(KOT).filter(KOT.order_id == order.id).update({"status": "Served"})
            
            # Update table status if applicable
            if order.table_id and order.order_type in ['Table', 'Dine-in']:
                table = db.query(Table).filter(Table.id == order.table_id).first()
                if table:
                    if table.merge_group_id and str(table.merge_group_id).strip():
                        # Update all tables in merge group
                        db.query(Table).filter(
                            Table.merge_group_id == table.merge_group_id,
                            Table.branch_id == order.branch_id
                        ).update({"status": "Available"})
                    else:
                        table.status = "Available"
            
            # Update customer stats if applicable
            if order.customer_id:
                customer = db.query(Customer).filter(Customer.id == order.customer_id).first()
                if customer:
                    customer.total_visits += 1
                    customer.total_spent += (order.net_amount or 0)
                    customer.due_amount += (order.credit_amount or 0)
                    customer.updated_at = datetime.now(timezone.utc)
            
            # Update active POS Session for the current user (Real-time tracking)
            if current_user:
                active_session = db.query(POSSession).filter(
                    POSSession.user_id == current_user.id,
                    POSSession.status == "Open"
                ).first()
                
                if active_session:
                    # Update session stats
                    active_session.total_sales += (order.net_amount or 0)
                    active_session.total_orders += 1
                    active_session.updated_at = datetime.now(timezone.utc)
                    
        elif new_status == 'Cancelled':
            if order.table_id and order.order_type in ['Table', 'Dine-in']:
                table = db.query(Table).filter(Table.id == order.table_id).first()
                if table:
                    if table.merge_group_id and str(table.merge_group_id).strip():
                        db.query(Table).filter(
                            Table.merge_group_id == table.merge_group_id,
                            Table.branch_id == order.branch_id
                        ).update({"status": "Available"})
                    else:
                        table.status = "Available"
            
            # If the order was previously Paid/Completed, subtract from customer stats
            if old_status in ['Paid', 'Completed'] and order.customer_id:
                customer = db.query(Customer).filter(Customer.id == order.customer_id).first()
                if customer:
                    customer.total_spent -= (order.net_amount or 0)
                    customer.due_amount -= (order.credit_amount or 0)
                    if customer.total_visits > 0:
                        customer.total_visits -= 1
        elif new_status == 'BillRequested' and order.table_id and order.order_type in ['Table', 'Dine-in']:
            table = db.query(Table).filter(Table.id == order.table_id).first()
            if table:
                if table.merge_group_id and str(table.merge_group_id).strip():
                    db.query(Table).filter(
                        Table.merge_group_id == table.merge_group_id,
                        Table.branch_id == order.branch_id
                    ).update({"status": "BillRequested"})
                else:
                    table.status = "BillRequested"
        elif new_status in ['Pending', 'In Progress'] and order.table_id and order.order_type in ['Table', 'Dine-in']:
            table = db.query(Table).filter(Table.id == order.table_id).first()
            if table:
                if table.merge_group_id and str(table.merge_group_id).strip():
                    db.query(Table).filter(
                        Table.merge_group_id == table.merge_group_id,
                        Table.branch_id == order.branch_id
                    ).update({"status": "Occupied"})
                else:
                    table.status = "Occupied"
    
    db.commit()
    
    # Reload with relationships
    updated_order = db.query(Order).options(
        joinedload(Order.table),
        joinedload(Order.customer),
        joinedload(Order.items).joinedload(OrderItem.menu_item)
    ).filter(Order.id == order_id).first()
    
    return updated_order


@router.delete("/{order_id}")
async def delete_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Delete an order"""
    order = db.query(Order).filter(
        Order.id == order_id,
        Order.branch_id == branch_id
    ).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Reset table status if this was a table order
    if order.table_id and order.order_type in ['Table', 'Dine-in']:
        table = db.query(Table).filter(Table.id == order.table_id).first()
        if table:
            if table.merge_group_id and str(table.merge_group_id).strip():
                db.query(Table).filter(
                    Table.merge_group_id == table.merge_group_id,
                    Table.branch_id == order.branch_id
                ).update({"status": "Available"})
            else:
                table.status = "Available"
    
    db.delete(order)
    db.commit()
    return {"message": "Order deleted successfully"}

@router.post("/{order_id}/print")
async def print_bill(
    order_id: int,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Trigger bill printing for an order"""
    # branch_id is now provided by dependency
    
    order = db.query(Order).options(
        joinedload(Order.table),
        joinedload(Order.customer),
        joinedload(Order.items).joinedload(OrderItem.menu_item)
    ).filter(Order.id == order_id).first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    if branch_id and order.branch_id != branch_id:
         raise HTTPException(status_code=403, detail="Not authorized to print this order")

    printing_service = PrintingService(db)
    background_tasks.add_task(printing_service.print_bill, order)
    
    return {"message": "Bill print job queued"}
    
@router.post("/{order_id}/change-table")
async def change_order_table(
    order_id: int,
    new_table_id: int = Body(..., embed=True),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Change order's table and update statuses"""
    order = db.query(Order).filter(
        Order.id == order_id,
        Order.branch_id == branch_id
    ).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
        
    old_table_id = order.table_id
    if old_table_id == new_table_id:
        return {"message": "Table is the same"}
        
    # 1. Handle Old Table(s)
    if old_table_id and order.order_type in ['Table', 'Dine-in']:
        old_table = db.query(Table).filter(Table.id == old_table_id).first()
        if old_table:
            if old_table.merge_group_id and str(old_table.merge_group_id).strip():
                # Make all tables in the old group available
                db.query(Table).filter(
                    Table.merge_group_id == old_table.merge_group_id,
                    Table.branch_id == order.branch_id
                ).update({"status": "Available"})
            else:
                old_table.status = "Available"
                
    # 2. Handle New Table(s)
    new_table = db.query(Table).filter(Table.id == new_table_id).first()
    if not new_table:
        raise HTTPException(status_code=404, detail="New table not found")
        
    # Update order
    order.table_id = new_table_id
    
    # 3. Update New table status
    if order.order_type in ['Table', 'Dine-in']:
        if new_table.merge_group_id and str(new_table.merge_group_id).strip():
            # Update all tables in new merge group
            db.query(Table).filter(
                Table.merge_group_id == new_table.merge_group_id,
                Table.branch_id == order.branch_id
            ).update({"status": "Occupied"})
        else:
            new_table.status = "Occupied"
        
    db.commit()
    return {"message": "Table changed successfully", "new_table_id": new_table_id}


@router.post("/{order_id}/items", response_model=OrderResponse)
async def add_order_items(
    order_id: int,
    payload: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id),
    x_branch_code: str = Header(..., alias="X-Branch-Code")
):
    """Add items to an existing order and generate KOTs"""
    order = db.query(Order).options(
        joinedload(Order.items)
    ).filter(
        Order.id == order_id,
        Order.branch_id == branch_id
    ).first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
        
    items_data = payload.get('items', [])
    if not items_data:
        raise HTTPException(status_code=400, detail="No items provided")
    
    # 1. Add Items
    for item in items_data:
        order_item = OrderItem(
            order_id=order.id,
            menu_item_id=item['menu_item_id'],
            quantity=item['quantity'],
            price=item.get('price', 0),
            subtotal=item.get('subtotal', item.get('price', 0) * item['quantity']),
            notes=item.get('notes', '')
        )
        db.add(order_item)
        
    # 2. Recalculate Totals
    # Get current items + new items for calculation
    current_gross = order.gross_amount or 0
    new_items_gross = 0
    for item in items_data:
        price = item.get('price')
        if price is None or price == 0:
            mi = db.query(MenuItem).filter(MenuItem.id == item.get('menu_item_id')).first()
            price = mi.price if mi else 0
        new_items_gross += (item.get('quantity', 0) * price)
    
    total_gross = current_gross + new_items_gross
    
    settings = db.query(CompanySettings).first()
    branch = db.query(Branch).filter(Branch.id == order.branch_id).first()
    
    sc_rate = branch.service_charge_rate if branch and branch.service_charge_rate is not None else (settings.service_charge_rate if settings else 10.0)
    tax_rate = branch.tax_rate if branch and branch.tax_rate is not None else (settings.tax_rate if settings else 13.0)
    
    discount = order.discount or 0
    delivery = order.delivery_charge or 0
    
    # Consistent with Frontend: SC and Tax on Net of Discount
    base_amount = max(0, total_gross - discount)
    sc_amount = round(base_amount * (sc_rate / 100), 2)
    tax_amount = round((base_amount + sc_amount) * (tax_rate / 100), 2)
    
    order.gross_amount = total_gross
    order.service_charge_amount = sc_amount
    order.tax_amount = tax_amount
    order.net_amount = round(base_amount + sc_amount + tax_amount + delivery, 2)
    order.total_amount = order.net_amount
    
    # 3. Generate KOT/BOT (Copy logic from create_order)
    if order.status != 'Draft':
        item_ids = [item['menu_item_id'] for item in items_data]
        menu_items = db.query(MenuItem).options(joinedload(MenuItem.category)).filter(MenuItem.id.in_(item_ids)).all()
        menu_items_map = {m.id: m for m in menu_items}
        
        kot_items = []
        bot_items = []
        
        for item in items_data:
            m_item = menu_items_map.get(item['menu_item_id'])
            if m_item:
                # Prioritize Category type
                category_type = m_item.category.type if m_item.category else m_item.kot_bot
                if category_type == 'BOT':
                    bot_items.append(item)
                else:
                    kot_items.append(item)

        today_str = datetime.now().strftime('%Y%m%d')

        # Create KOT
        if kot_items:
            kot_prefix = f"KOT-{today_str}-"
            
            while True:
                # Check globally for uniqueness
                last_kot = db.query(KOT).filter(
                    KOT.kot_number.like(f"{kot_prefix}%")
                ).order_by(KOT.kot_number.desc()).first()
                
                kot_seq = 1
                if last_kot:
                    try:
                        parts = last_kot.kot_number.split('-')
                        if len(parts) >= 3:
                            kot_seq = int(parts[-1]) + 1
                    except (ValueError, IndexError):
                        pass
                
                new_kot_num = f"{kot_prefix}{kot_seq:04d}"
                if not db.query(KOT).filter(KOT.kot_number == new_kot_num).first():
                    break
            
            kot = KOT(
                kot_number=new_kot_num,
                order_id=order.id,
                branch_id=branch_id,
                kot_type='KOT',
                status='Pending',
                created_by=current_user.id
            )
            db.add(kot)
            db.flush()
            
            for item in kot_items:
                k_item = KOTItem(
                    kot_id=kot.id,
                    menu_item_id=item['menu_item_id'],
                    quantity=item['quantity'],
                    notes=item.get('notes', '')
                )
                db.add(k_item)
                
        # Create BOT
        if bot_items:
            bot_prefix = f"BOT-{today_str}-"
            
            while True:
                # Check globally for uniqueness
                last_bot = db.query(KOT).filter(
                    KOT.kot_number.like(f"{bot_prefix}%")
                ).order_by(KOT.kot_number.desc()).first()
                
                bot_seq = 1
                if last_bot:
                    try:
                        parts = last_bot.kot_number.split('-')
                        if len(parts) >= 3:
                            bot_seq = int(parts[-1]) + 1
                    except (ValueError, IndexError):
                        pass
                
                new_bot_num = f"{bot_prefix}{bot_seq:04d}"
                if not db.query(KOT).filter(KOT.kot_number == new_bot_num).first():
                    break
            
            bot = KOT(
                kot_number=new_bot_num,
                order_id=order.id,
                branch_id=branch_id,
                kot_type='BOT',
                status='Pending',
                created_by=current_user.id
            )
            db.add(bot)
            db.flush()
            
            for item in bot_items:
                b_item = KOTItem(
                    kot_id=bot.id,
                    menu_item_id=item['menu_item_id'],
                    quantity=item['quantity'],
                    notes=item.get('notes', '')
                )
                db.add(b_item)
            
    db.commit()
    db.refresh(order)
    
    # Return updated order
    updated_order = db.query(Order).options(
        joinedload(Order.table),
        joinedload(Order.customer),
        joinedload(Order.items).joinedload(OrderItem.menu_item),
        joinedload(Order.kots).joinedload(KOT.items).joinedload(KOTItem.menu_item)
    ).filter(Order.id == order.id).first()
    
    return updated_order
