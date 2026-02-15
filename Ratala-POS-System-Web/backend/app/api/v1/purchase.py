"""
Purchase management routes with branch isolation
"""
from fastapi import APIRouter, Depends, Body
from sqlalchemy.orm import Session, joinedload
import random
from datetime import datetime, timezone

from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.models import Supplier, PurchaseBill, PurchaseReturn, PurchaseBillItem, InventoryTransaction, Product

router = APIRouter()


def apply_branch_filter_purchase(query, model, branch_id):
    """Apply branch_id filter to purchase-related queries"""
    if branch_id is not None and hasattr(model, 'branch_id'):
        query = query.filter(model.branch_id == branch_id)
    return query


@router.get("/suppliers")
async def get_suppliers(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all suppliers for the current user's branch"""
    branch_id = current_user.current_branch_id
    query = db.query(Supplier)
    query = apply_branch_filter_purchase(query, Supplier, branch_id)
    suppliers = query.all()
    return suppliers


@router.get("/suppliers/{supplier_id}")
async def get_supplier(
    supplier_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get a specific supplier in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(Supplier).filter(Supplier.id == supplier_id)
    query = apply_branch_filter_purchase(query, Supplier, branch_id)
    supplier = query.first()
    
    if not supplier:
        raise HTTPException(status_code=404, detail="Supplier not found or access denied")
    return supplier


@router.post("/suppliers")
async def create_supplier(
    supplier_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new supplier in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    # Set branch_id if the column exists
    if branch_id is not None and hasattr(Supplier, 'branch_id'):
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
    current_user = Depends(get_current_user)
):
    """Update a supplier in the current user's branch"""
    branch_id = current_user.current_branch_id
    
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
    current_user = Depends(get_current_user)
):
    """Delete a supplier in the current user's branch"""
    branch_id = current_user.current_branch_id
    
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
    current_user = Depends(get_current_user)
):
    """Get all purchase bills for the current user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(PurchaseBill).options(
        joinedload(PurchaseBill.supplier),
        joinedload(PurchaseBill.items).joinedload(PurchaseBillItem.product)
    )
    query = apply_branch_filter_purchase(query, PurchaseBill, branch_id)
    bills = query.order_by(PurchaseBill.created_at.desc()).all()
    return bills


@router.get("/bills/{bill_id}")
async def get_bill(
    bill_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get a specific purchase bill in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(PurchaseBill).options(
        joinedload(PurchaseBill.supplier),
        joinedload(PurchaseBill.items).joinedload(PurchaseBillItem.product)
    ).filter(PurchaseBill.id == bill_id)
    query = apply_branch_filter_purchase(query, PurchaseBill, branch_id)
    bill = query.first()
    
    if not bill:
        raise HTTPException(status_code=404, detail="Bill not found or access denied")
    return bill


@router.post("/bills")
async def create_bill(
    bill_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new purchase bill in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    # Extract items if they exist
    items_data = bill_data.pop('items', [])
    
    # Parse dates if they are strings
    for date_field in ['order_date', 'paid_date']:
        if date_field in bill_data and isinstance(bill_data[date_field], str) and bill_data[date_field]:
            try:
                bill_data[date_field] = datetime.strptime(bill_data[date_field], '%Y-%m-%d')
            except ValueError:
                bill_data[date_field] = None
        elif date_field in bill_data and not bill_data[date_field]:
            bill_data[date_field] = None

    # Set branch_id
    if branch_id is not None and hasattr(PurchaseBill, 'branch_id'):
        bill_data['branch_id'] = branch_id
    
    # Generate sequential bill number: PO-YYYYMMDD-XXXX (Global Sequence)
    today_str = datetime.now().strftime('%Y%m%d')
    prefix = f"PO-{today_str}"
    
    while True:
        # Use total count of all bills for the sequence number
        total_bills = db.query(PurchaseBill).count()
        new_seq = total_bills + 1
        bill_number = f"{prefix}-{new_seq:04d}"
        
        # Double check uniqueness
        if not db.query(PurchaseBill).filter(PurchaseBill.bill_number == bill_number).first():
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
        # Note: We create the transaction as soon as the bill is created, 
        # or maybe we should only do it if status is 'Paid'? 
        # Usually, purchase bill means stock has arrived.
        inventory_txn = InventoryTransaction(
            product_id=item['product_id'],
            transaction_type="IN",
            quantity=item['quantity'],
            reference_number=new_bill.bill_number,
            reference_id=new_bill.id,
            notes=f"Purchase from {new_bill.supplier.name}" if new_bill.supplier else "Purchase Bill",
            created_by=current_user.id
        )
        db.add(inventory_txn)

    db.commit()
    db.refresh(new_bill)
    return new_bill


@router.put("/bills/{bill_id}")
@router.patch("/bills/{bill_id}")
async def update_bill(
    bill_id: int,
    bill_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a purchase bill"""
    db_bill = db.query(PurchaseBill).filter(PurchaseBill.id == bill_id).first()
    if not db_bill:
        from fastapi import HTTPException
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
    current_user = Depends(get_current_user)
):
    """Delete a purchase bill"""
    db_bill = db.query(PurchaseBill).filter(PurchaseBill.id == bill_id).first()
    if not db_bill:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Bill not found")
    
    # Delete associated inventory transactions
    db.query(InventoryTransaction).filter(
        InventoryTransaction.reference_number == db_bill.bill_number,
        InventoryTransaction.reference_id == db_bill.id
    ).delete(synchronize_session=False)

    db.delete(db_bill)
    db.commit()
    return {"message": "Bill and associated transactions deleted successfully"}


@router.get("/returns")
async def get_returns(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all purchase returns for the current user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(PurchaseReturn).options(
        joinedload(PurchaseReturn.purchase_bill),
        joinedload(PurchaseReturn.supplier)
    )
    query = apply_branch_filter_purchase(query, PurchaseReturn, branch_id)
    returns = query.order_by(PurchaseReturn.created_at.desc()).all()
    return returns


@router.post("/returns")
async def create_return(
    return_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new purchase return in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    # If supplier_id not provided but purchase_bill_id is, try to get supplier_id from bill
    if 'supplier_id' not in return_data and 'purchase_bill_id' in return_data:
        bill_query = db.query(PurchaseBill).filter(PurchaseBill.id == return_data['purchase_bill_id'])
        bill_query = apply_branch_filter_purchase(bill_query, PurchaseBill, branch_id)
        bill = bill_query.first()
        if bill:
            return_data['supplier_id'] = bill.supplier_id

    # Set branch_id if the column exists
    if branch_id is not None and hasattr(PurchaseReturn, 'branch_id'):
        return_data['branch_id'] = branch_id
    
    # Generate sequential return number: RET-YYYYMMDD-XXXX
    today_str = datetime.now().strftime('%Y%m%d')
    prefix = f"RET-{today_str}"
    while True:
        last_return = db.query(PurchaseReturn).filter(
            PurchaseReturn.return_number.like(f"{prefix}-%")
        ).order_by(PurchaseReturn.return_number.desc()).first()
        
        if last_return:
            try:
                last_seq = int(last_return.return_number.split('-')[-1])
                new_seq = last_seq + 1
            except (ValueError, IndexError):
                new_seq = 1
        else:
            new_seq = 1
            
        return_number = f"{prefix}-{new_seq:04d}"
        if not db.query(PurchaseReturn).filter(PurchaseReturn.return_number == return_number).first():
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
    current_user = Depends(get_current_user)
):
    """Delete a purchase return"""
    db_return = db.query(PurchaseReturn).filter(PurchaseReturn.id == return_id).first()
    if not db_return:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Return not found")
    
    db.delete(db_return)
    db.commit()
    return {"message": "Return deleted successfully"}
