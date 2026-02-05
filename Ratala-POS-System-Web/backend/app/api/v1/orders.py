"""
Order management routes
"""
from fastapi import APIRouter, Depends, Body, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session, joinedload
from typing import Optional, List
import random
from datetime import datetime
from app.services.printing_service import PrintingService

from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.models import Order, OrderItem, KOT, KOTItem, Table, Customer, POSSession
from app.schemas import OrderResponse
from app.services.inventory_service import InventoryService

router = APIRouter()


@router.get("", response_model=List[OrderResponse])
async def get_orders(
    order_type: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all orders, optionally filtered by order_type and status"""
    # Get user's current branch for filtering
    branch_id = current_user.current_branch_id
    
    query = db.query(Order).options(
        joinedload(Order.table),
        joinedload(Order.customer), joinedload(Order.delivery_partner),
        joinedload(Order.items).joinedload(OrderItem.menu_item),
        joinedload(Order.kots).joinedload(KOT.items).joinedload(KOTItem.menu_item)
    )
    
    # Filter by branch_id for data isolation
    if branch_id:
        query = query.filter(Order.branch_id == branch_id)
    
    if order_type:
        query = query.filter(Order.order_type == order_type)
    if status:
        query = query.filter(Order.status == status)
    
    orders = query.order_by(Order.created_at.desc()).all()
    return orders


@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get order by ID with items"""
    # Get user's current branch for filtering
    branch_id = current_user.current_branch_id
    
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
    
    return order


@router.post("", response_model=OrderResponse)
async def create_order(
    order_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new order"""
    items_data = order_data.pop('items', [])
    
    if 'order_number' not in order_data:
        order_data['order_number'] = f"ORD-{datetime.now().strftime('%Y%m%d')}-{random.randint(1000, 9999)}"
    order_data['created_by'] = current_user.id
    
    # Tie to active POS Session
    active_session = db.query(POSSession).filter(
        POSSession.user_id == current_user.id,
        POSSession.status == "Open"
    ).first()
    if active_session:
        order_data['pos_session_id'] = active_session.id
    
    # Calculate amounts if not provided
    if 'gross_amount' not in order_data:
        order_data['gross_amount'] = order_data.get('total_amount', 0)
    if 'net_amount' not in order_data:
        discount = order_data.get('discount', 0)
        order_data['net_amount'] = order_data['gross_amount'] - discount
    
    # Sync total_amount with net_amount for consistency
    if 'total_amount' not in order_data or order_data.get('total_amount') == 0:
        order_data['total_amount'] = order_data.get('net_amount', 0)
    
    # Set branch_id for data isolation
    if current_user.current_branch_id:
        order_data['branch_id'] = current_user.current_branch_id
    
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
    
    # Update table status to Occupied if table order
    if new_order.table_id:
        table = db.query(Table).filter(Table.id == new_order.table_id).first()
        if table:
            # If creating a Paid order (direct payment), keep it Available
            if new_order.status in ['Paid', 'Completed']:
                table.status = "Available"
            elif new_order.status == 'Draft':
                # Optional: Decide if Draft should mark table as Occupied. 
                # Usually Pending marks it.
                table.status = "Occupied" 
            else:
                table.status = "Occupied"
    
    # Update customer stats if Paid
    if new_order.status in ['Paid', 'Completed'] and new_order.customer_id:
        customer = db.query(Customer).filter(Customer.id == new_order.customer_id).first()
        if customer:
            customer.total_visits += 1
            customer.total_spent += new_order.net_amount
            customer.due_amount += new_order.credit_amount
            customer.updated_at = datetime.now()

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
    current_user = Depends(get_current_user)
):
    """Update an order"""
    order = db.query(Order).filter(Order.id == order_id).first()
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
    if items_data is not None:
        total = sum(item['price'] * item['quantity'] for item in items_data)
        order.gross_amount = total
        order.net_amount = total - order.discount
        order.total_amount = order.net_amount
    elif 'gross_amount' in order_data or 'discount' in order_data:
        order.net_amount = order.gross_amount - order.discount
        order.total_amount = order.net_amount
    
    # Handle KOT status when order status changes
    if 'status' in order_data:
        new_status = order_data['status']
        if new_status in ['Paid', 'Completed'] and old_status not in ['Paid', 'Completed']:
            # DEDUCT INVENTORY BASED ON BOM
            InventoryService.deduct_inventory_for_order(db, order, current_user.id)
            
            # Mark all associated KOTs as Served when payment is done
            db.query(KOT).filter(KOT.order_id == order.id).update({"status": "Served"})
            
            # Update table status if applicable
            if order.table_id:
                table = db.query(Table).filter(Table.id == order.table_id).first()
                if table:
                    table.status = "Available"
            
            # Update customer stats if applicable
            if order.customer_id:
                customer = db.query(Customer).filter(Customer.id == order.customer_id).first()
                if customer:
                    customer.total_visits += 1
                    customer.total_spent += order.net_amount
                    customer.due_amount += order.credit_amount
                    customer.updated_at = datetime.now()
            
            # Update active POS Session for the current user (Real-time tracking)
            if current_user:
                active_session = db.query(POSSession).filter(
                    POSSession.user_id == current_user.id,
                    POSSession.status == "Open"
                ).first()
                
                if active_session:
                    # Update session stats
                    active_session.total_sales += order.net_amount
                    active_session.total_orders += 1
                    active_session.updated_at = datetime.now()
                    
        elif new_status == 'Cancelled':
            # Optionally mark KOTs as Cancelled too? The user didn't ask, but it makes sense.
            # However, I'll stick to 'Served' for payment as requested.
            if order.table_id:
                table = db.query(Table).filter(Table.id == order.table_id).first()
                if table:
                    table.status = "Available"
        elif new_status == 'BillRequested' and order.table_id:
            table = db.query(Table).filter(Table.id == order.table_id).first()
            if table:
                table.status = "BillRequested"
        elif new_status in ['Pending', 'In Progress'] and order.table_id:
            table = db.query(Table).filter(Table.id == order.table_id).first()
            if table:
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
    current_user = Depends(get_current_user)
):
    """Delete an order"""
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Reset table status if this was a table order
    if order.table_id:
        table = db.query(Table).filter(Table.id == order.table_id).first()
        if table:
            table.status = "Available"
    
    db.delete(order)
    db.commit()
    return {"message": "Order deleted successfully"}

@router.post("/{order_id}/print")
async def print_bill(
    order_id: int,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Trigger bill printing for an order"""
    branch_id = current_user.current_branch_id
    
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
