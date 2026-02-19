"""
Purchase management routes with branch isolation
"""
from fastapi import APIRouter, Depends, Body, Header
from sqlalchemy.orm import Session, joinedload
import random
from datetime import datetime, timezone

from app.db.database import get_db
from app.core.dependencies import get_current_user, get_branch_id
from app.models import Supplier, PurchaseBill, PurchaseReturn, PurchaseBillItem, InventoryTransaction, Product, Branch

router = APIRouter()


def apply_branch_filter_purchase(query, model, branch_id):
    """Apply branch_id filter to purchase-related queries"""
    if branch_id is not None and hasattr(model, 'branch_id'):
        query = query.filter(model.branch_id == branch_id)
    return query


@router.get("/suppliers")
async def get_suppliers(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all suppliers for the branch"""
    suppliers = db.query(Supplier).filter(Supplier.branch_id == branch_id).all()
    return suppliers


@router.get("/suppliers/{supplier_id}")
async def get_supplier(
    supplier_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get a specific supplier in the branch"""
    supplier = db.query(Supplier).filter(
        Supplier.id == supplier_id,
        Supplier.branch_id == branch_id
    ).first()
    
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found or access denied")
    return supplier


@router.post("/suppliers")
async def create_supplier(
    supplier_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Create a new supplier in the branch"""
    supplier_data['branch_id'] = branch_id
    
    new_supplier = Supplier(**supplier_data)
    db.add(new_supplier)
    db.commit()
    db.refresh(new_supplier)
    return new_supplier


@router.put("/suppliers/{supplier_id}")
@router.patch("/suppliers/{supplier_id}")
async def update_supplier(
    supplier_id: int,
    supplier_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Update a supplier in the branch"""
    # branch_id is now provided by dependency
    
    query = db.query(Supplier).filter(Supplier.id == supplier_id)
    query = apply_branch_filter_purchase(query, Supplier, branch_id)
    db_supplier = query.first()
    
    if not db_supplier:
        raise HTTPException(status_code=404, detail="Supplier not found or access denied")
    
    for key, value in supplier_data.items():
        if key != "id":
            setattr(db_supplier, key, value)
            
    db.commit()
    db.refresh(db_supplier)
    return db_supplier


@router.delete("/suppliers/{supplier_id}")
async def delete_supplier(
    supplier_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Delete a supplier in the branch"""
    # branch_id is now provided by dependency
    
    query = db.query(Supplier).filter(Supplier.id == supplier_id)
    query = apply_branch_filter_purchase(query, Supplier, branch_id)
    db_supplier = query.first()
    
    if not db_supplier:
        raise HTTPException(status_code=404, detail="Supplier not found or access denied")
    
    # Check if supplier has bills
    bills_count = db.query(PurchaseBill).filter(PurchaseBill.supplier_id == supplier_id).count()
    if bills_count > 0:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="Cannot delete supplier with existing purchase bills")

    db.delete(db_supplier)
    db.commit()
    return {"message": "Supplier deleted successfully"}


@router.get("/bills")
async def get_bills(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all purchase bills for the branch"""
    bills = db.query(PurchaseBill).filter(
        PurchaseBill.branch_id == branch_id
    ).options(
        joinedload(PurchaseBill.supplier),
        joinedload(PurchaseBill.items).joinedload(PurchaseBillItem.product)
    ).order_by(PurchaseBill.created_at.desc()).all()
    return bills


@router.get("/bills/{bill_id}")
async def get_bill(
    bill_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get a specific purchase bill in the branch"""
    bill = db.query(PurchaseBill).options(
        joinedload(PurchaseBill.supplier),
        joinedload(PurchaseBill.items).joinedload(PurchaseBillItem.product)
    ).filter(
        PurchaseBill.id == bill_id,
        PurchaseBill.branch_id == branch_id
    ).first()
    
    if not bill:
        raise HTTPException(status_code=404, detail="Bill not found or access denied")
    return bill


@router.post("/bills")
async def create_bill(
    bill_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id),
    x_branch_code: str = Header(..., alias="X-Branch-Code")
):
    """Create a new purchase bill in the branch"""
    # Extract items if they exist
    items_data = bill_data.pop('items', [])
    
    # ... existing date parsing ...
    for date_field in ['order_date', 'paid_date']:
        if date_field in bill_data and isinstance(bill_data[date_field], str) and bill_data[date_field]:
            try:
                bill_data[date_field] = datetime.strptime(bill_data[date_field], '%Y-%m-%d')
            except ValueError:
                bill_data[date_field] = None
        elif date_field in bill_data and not bill_data[date_field]:
            bill_data[date_field] = None

    bill_data['branch_id'] = branch_id
    
    # Generate sequential bill number: BRANCH-PO-YYYYMMDD-XXXX
    today_str = datetime.now().strftime('%Y%m%d')
    prefix = f"{x_branch_code}-PO-{today_str}-"
    
    while True:
        last_bill = db.query(PurchaseBill).filter(
            PurchaseBill.branch_id == branch_id,
            PurchaseBill.bill_number.like(f"{prefix}%")
        ).order_by(PurchaseBill.bill_number.desc()).first()
        
        if last_bill:
            try:
                last_seq = int(last_bill.bill_number.split('-')[-1])
                new_seq = last_seq + 1
            except:
                new_seq = 1
        else:
            new_seq = 1
            
        bill_number = f"{prefix}{new_seq:04d}"
        
        # Double check uniqueness within branch
        if not db.query(PurchaseBill).filter(PurchaseBill.bill_number == bill_number, PurchaseBill.branch_id == branch_id).first():
            bill_data['bill_number'] = bill_number
            break
    
    # Create the bill
    new_bill = PurchaseBill(**bill_data)
    db.add(new_bill)
    db.flush() # Get bill ID
    
    # Add items and create inventory transactions
    for item in items_data:
        # Create bill item
        bill_item = PurchaseBillItem(
            purchase_bill_id=new_bill.id,
            product_id=item['product_id'],
            quantity=item['quantity'],
            unit_id=item.get('unit_id'),
            rate=item['rate'],
            total_amount=item['quantity'] * item['rate']
        )
        db.add(bill_item)
        
        # Create inventory transaction (IN)
        # Convert quantity to product's base unit if necessary using InventoryService
        from app.services.inventory_service import InventoryService
        
        # Get product's base unit_id
        product = db.query(Product).filter(Product.id == item['product_id']).first()
        to_unit_id = product.unit_id if product else None
        
        # Convert quantity
        conversion_qty = InventoryService.convert_quantity(
            db, 
            item['quantity'], 
            item.get('unit_id'), 
            to_unit_id
        )

        inventory_txn = InventoryTransaction(
            product_id=item['product_id'],
            transaction_type="IN",
            quantity=conversion_qty,
            reference_number=new_bill.bill_number,
            reference_id=new_bill.id,
            branch_id=branch_id,
            notes=f"Purchase from {new_bill.supplier.name} ({item['quantity']} {item.get('unit_id') if item.get('unit_id') else ''})" if new_bill.supplier else "Purchase Bill",
            created_by=current_user.id
        )
        db.add(inventory_txn)
        
        # Trigger auto-production for each purchase item
        InventoryService.trigger_auto_production(
            db,
            item['product_id'],
            conversion_qty,
            branch_id,
            current_user.id
        )

    db.commit()
    db.refresh(new_bill)
    return new_bill


@router.put("/bills/{bill_id}")
@router.patch("/bills/{bill_id}")
async def update_bill(
    bill_id: int,
    bill_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Update a purchase bill"""
    db_bill = db.query(PurchaseBill).filter(
        PurchaseBill.id == bill_id,
        PurchaseBill.branch_id == branch_id
    ).first()
    if not db_bill:
        raise HTTPException(status_code=404, detail="Bill not found")

    # Update fields
    for key, value in bill_data.items():
        if key in ['id', 'bill_number', 'supplier']:
            continue # Don't update primary keys, immutable fields or relations
        
        # Parse dates
        if key in ['order_date', 'paid_date']:
            if isinstance(value, str) and value:
                try:
                    setattr(db_bill, key, datetime.strptime(value, '%Y-%m-%d'))
                except ValueError:
                    pass 
            elif not value:
                setattr(db_bill, key, None)
        else:
             setattr(db_bill, key, value)

    db.commit()
    db.refresh(db_bill)
    return db_bill


@router.delete("/bills/{bill_id}")
async def delete_bill(
    bill_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Delete a purchase bill"""
    db_bill = db.query(PurchaseBill).filter(
        PurchaseBill.id == bill_id,
        PurchaseBill.branch_id == branch_id
    ).first()
    if not db_bill:
        raise HTTPException(status_code=404, detail="Bill not found")
    
    # Delete associated inventory transactions
    db.query(InventoryTransaction).filter(
        InventoryTransaction.reference_number == db_bill.bill_number,
        InventoryTransaction.branch_id == branch_id,
        InventoryTransaction.reference_id == db_bill.id
    ).delete(synchronize_session=False)

    db.delete(db_bill)
    db.commit()
    return {"message": "Bill and associated transactions deleted successfully"}


@router.get("/returns")
async def get_returns(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all purchase returns for the branch"""
    returns = db.query(PurchaseReturn).filter(
        PurchaseReturn.branch_id == branch_id
    ).options(
        joinedload(PurchaseReturn.purchase_bill),
        joinedload(PurchaseReturn.supplier)
    ).order_by(PurchaseReturn.created_at.desc()).all()
    return returns


@router.post("/returns")
async def create_return(
    return_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id),
    x_branch_code: str = Header(..., alias="X-Branch-Code")
):
    """Create a new purchase return in the branch"""
    # If supplier_id not provided but purchase_bill_id is, try to get supplier_id from bill
    if 'supplier_id' not in return_data and 'purchase_bill_id' in return_data:
        bill = db.query(PurchaseBill).filter(
            PurchaseBill.id == return_data['purchase_bill_id'],
            PurchaseBill.branch_id == branch_id
        ).first()
        if bill:
            return_data['supplier_id'] = bill.supplier_id

    return_data['branch_id'] = branch_id
    
    # Generate sequential return number: BRANCH-RET-YYYYMMDD-XXXX
    today_str = datetime.now().strftime('%Y%m%d')
    prefix = f"{x_branch_code}-RET-{today_str}-"
    while True:
        last_return = db.query(PurchaseReturn).filter(
            PurchaseReturn.branch_id == branch_id,
            PurchaseReturn.return_number.like(f"{prefix}%")
        ).order_by(PurchaseReturn.return_number.desc()).first()
        
        if last_return:
            try:
                last_seq = int(last_return.return_number.split('-')[-1])
                new_seq = last_seq + 1
            except:
                new_seq = 1
        else:
            new_seq = 1
            
        return_number = f"{prefix}{new_seq:04d}"
        if not db.query(PurchaseReturn).filter(PurchaseReturn.return_number == return_number, PurchaseReturn.branch_id == branch_id).first():
            return_data['return_number'] = return_number
            break
    new_return = PurchaseReturn(**return_data)
    db.add(new_return)
    db.commit()
    db.refresh(new_return)
    return new_return


@router.delete("/returns/{return_id}")
async def delete_return(
    return_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Delete a purchase return"""
    db_return = db.query(PurchaseReturn).filter(
        PurchaseReturn.id == return_id,
        PurchaseReturn.branch_id == branch_id
    ).first()
    if not db_return:
        raise HTTPException(status_code=404, detail="Return not found")
    
    db.delete(db_return)
    db.commit()
    return {"message": "Return deleted successfully"}
