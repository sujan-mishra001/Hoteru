"""
Inventory management routes - Transaction-based system
Core Principle: Stock is NEVER updated directly, only through transactions
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func
from datetime import datetime
import random

from app.database import get_db
from app.dependencies import get_current_user
from app.models import (
    Product, UnitOfMeasurement, InventoryTransaction,
    BillOfMaterials, BOMItem, BatchProduction, POSSession
)

router = APIRouter()


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def calculate_product_stock(db: Session, product_id: int) -> float:
    """
    Calculate current stock from transactions
    This is the SINGLE SOURCE OF TRUTH for stock levels
    """
    # Sum of all IN types
    in_sum = db.query(func.sum(InventoryTransaction.quantity)).filter(
        InventoryTransaction.product_id == product_id,
        InventoryTransaction.transaction_type.in_(['IN', 'Add', 'Production_IN'])
    ).scalar() or 0.0
    
    # Sum of all OUT types
    out_sum = db.query(func.sum(InventoryTransaction.quantity)).filter(
        InventoryTransaction.product_id == product_id,
        InventoryTransaction.transaction_type.in_(['OUT', 'Remove', 'Production_OUT'])
    ).scalar() or 0.0
    
    # Sum of Adjustments and Counts (which are stored with signed quantity)
    adj_sum = db.query(func.sum(InventoryTransaction.quantity)).filter(
        InventoryTransaction.product_id == product_id,
        InventoryTransaction.transaction_type.in_(['Adjustment', 'Count'])
    ).scalar() or 0.0
    
    return in_sum - out_sum + adj_sum


def get_product_status(stock: float, min_stock: float) -> str:
    """Calculate product status based on stock levels"""
    if stock <= 0:
        return 'Out of Stock'
    elif stock <= min_stock:
        return 'Low Stock'
    else:
        return 'In Stock'


# ============================================================================
# 1. PRODUCTS - CRUD
# ============================================================================

@router.get("/products")
async def get_products(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all products with DERIVED stock"""
    products = db.query(Product).options(joinedload(Product.unit)).all()
    
    result = []
    for product in products:
        stock = calculate_product_stock(db, product.id)
        result.append({
            "id": product.id,
            "name": product.name,
            "category": product.category,
            "unit_id": product.unit_id,
            "unit": {"id": product.unit.id, "name": product.unit.name, "abbreviation": product.unit.abbreviation} if product.unit else None,
            "current_stock": stock,
            "min_stock": product.min_stock,
            "status": get_product_status(stock, product.min_stock),
            "created_at": product.created_at,
            "updated_at": product.updated_at
        })
    
    return result


@router.post("/products")
async def create_product(
    product_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new product"""
    # Strip non-model fields
    allowed_fields = ['name', 'category', 'unit_id', 'min_stock']
    data = {k: v for k, v in product_data.items() if k in allowed_fields}
    
    new_product = Product(**data)
    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    
    return {
        "id": new_product.id,
        "name": new_product.name,
        "category": new_product.category,
        "unit_id": new_product.unit_id,
        "current_stock": 0.0,
        "min_stock": new_product.min_stock,
        "status": "Out of Stock"
    }


@router.put("/products/{product_id}")
async def update_product(
    product_id: int,
    product_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a product"""
    db_product = db.query(Product).filter(Product.id == product_id).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    allowed_fields = ['name', 'category', 'unit_id', 'min_stock']
    for key, value in product_data.items():
        if key in allowed_fields:
            setattr(db_product, key, value)
    
    db.commit()
    db.refresh(db_product)
    
    stock = calculate_product_stock(db, product_id)
    return {
        "id": db_product.id,
        "name": db_product.name,
        "category": db_product.category,
        "unit_id": db_product.unit_id,
        "current_stock": stock,
        "min_stock": db_product.min_stock,
        "status": get_product_status(stock, db_product.min_stock)
    }


@router.delete("/products/{product_id}")
async def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Delete a product - ONLY if no transactions exist"""
    db_product = db.query(Product).filter(Product.id == product_id).first()
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    txn_count = db.query(InventoryTransaction).filter(
        InventoryTransaction.product_id == product_id
    ).count()
    
    if txn_count > 0:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot delete product with {txn_count} existing transactions. Please archive it instead."
        )
    
    db.delete(db_product)
    db.commit()
    return {"message": "Product deleted successfully"}


# ============================================================================
# 2. UNITS - Simple CRUD
# ============================================================================

@router.get("/units")
async def get_units(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all units"""
    units = db.query(UnitOfMeasurement).all()
    return units


@router.post("/units")
async def create_unit(
    unit_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    new_unit = UnitOfMeasurement(**unit_data)
    db.add(new_unit)
    db.commit()
    db.refresh(new_unit)
    return new_unit


@router.put("/units/{unit_id}")
async def update_unit(
    unit_id: int,
    unit_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    db_unit = db.query(UnitOfMeasurement).filter(UnitOfMeasurement.id == unit_id).first()
    if not db_unit:
        raise HTTPException(status_code=404, detail="Unit not found")
    
    for key, value in unit_data.items():
        if key != 'id':
            setattr(db_unit, key, value)
    
    db.commit()
    db.refresh(db_unit)
    return db_unit


@router.delete("/units/{unit_id}")
async def delete_unit(
    unit_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    db_unit = db.query(UnitOfMeasurement).filter(UnitOfMeasurement.id == unit_id).first()
    if not db_unit:
        raise HTTPException(status_code=404, detail="Unit not found")
    
    products_count = db.query(Product).filter(Product.unit_id == unit_id).count()
    if products_count > 0:
        raise HTTPException(status_code=400, detail="Cannot delete unit used by products")
    
    db.delete(db_unit)
    db.commit()
    return {"message": "Unit deleted successfully"}


# ============================================================================
# 3. ADD INVENTORY
# ============================================================================

@router.post("/transactions")
async def create_transaction(
    txn_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create IN transaction for adding stock"""
    txn_data['created_by'] = current_user.id
    txn_data['transaction_type'] = 'IN'
    
    # Tie to active POS Session
    active_session = db.query(POSSession).filter(
        POSSession.user_id == current_user.id,
        POSSession.status == "Open"
    ).first()
    if active_session:
        txn_data['pos_session_id'] = active_session.id
    
    if txn_data.get('quantity', 0) <= 0:
        raise HTTPException(status_code=400, detail="Quantity must be positive for adding stock")
    
    new_txn = InventoryTransaction(**txn_data)
    db.add(new_txn)
    db.commit()
    db.refresh(new_txn)
    return new_txn


@router.get("/transactions")
async def get_transactions(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return db.query(InventoryTransaction).options(
        joinedload(InventoryTransaction.product).joinedload(Product.unit)
    ).order_by(InventoryTransaction.created_at.desc()).all()


# ============================================================================
# 4. ADJUSTMENTS
# ============================================================================

@router.post("/adjustments")
async def create_adjustment(
    adj_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create Adjustment transaction (signed quantity)"""
    if not adj_data.get('notes'):
        raise HTTPException(status_code=400, detail="Reason is required for adjustments")
        
    adj_data['created_by'] = current_user.id
    adj_data['transaction_type'] = 'Adjustment'
    
    # Tie to active POS Session
    active_session = db.query(POSSession).filter(
        POSSession.user_id == current_user.id,
        POSSession.status == "Open"
    ).first()
    if active_session:
        adj_data['pos_session_id'] = active_session.id
    
    new_adj = InventoryTransaction(**adj_data)
    db.add(new_adj)
    db.commit()
    db.refresh(new_adj)
    return new_adj


@router.get("/adjustments")
async def get_adjustments(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all adjustments"""
    return db.query(InventoryTransaction).filter(
        InventoryTransaction.transaction_type == 'Adjustment'
    ).options(
        joinedload(InventoryTransaction.product).joinedload(Product.unit)
    ).order_by(InventoryTransaction.created_at.desc()).all()


# ============================================================================
# 5. COUNTS
# ============================================================================

@router.post("/counts")
async def create_count(
    count_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Compares system stock vs physical count and creates adjustment"""
    product_id = count_data.get('product_id')
    counted_qty = count_data.get('counted_quantity', 0)
    
    if not product_id:
        raise HTTPException(status_code=400, detail="Product ID required")
        
    current_stock = calculate_product_stock(db, product_id)
    difference = counted_qty - current_stock
    
    # Find active session
    active_session = db.query(POSSession).filter(
        POSSession.user_id == current_user.id,
        POSSession.status == "Open"
    ).first()
    
    # Create Count transaction with the difference
    txn = InventoryTransaction(
        product_id=product_id,
        transaction_type='Count',
        quantity=difference,
        pos_session_id=active_session.id if active_session else None,
        notes=f"Physical count: {counted_qty} (System: {current_stock}, Diff: {difference}). " + count_data.get('notes', ''),
        created_by=current_user.id
    )
    db.add(txn)
    db.commit()
    db.refresh(txn)
    return txn


@router.get("/counts")
async def get_counts(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all inventory counts"""
    return db.query(InventoryTransaction).filter(
        InventoryTransaction.transaction_type == 'Count'
    ).options(
        joinedload(InventoryTransaction.product).joinedload(Product.unit)
    ).order_by(InventoryTransaction.created_at.desc()).all()


# ============================================================================
# 6. BOM
# ============================================================================

@router.get("/boms")
async def get_boms(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return db.query(BillOfMaterials).options(
        joinedload(BillOfMaterials.components).joinedload(BOMItem.product),
        joinedload(BillOfMaterials.finished_product)
    ).all()


@router.post("/boms")
async def create_bom(
    bom_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    components = bom_data.pop('components', [])
    
    # Clean up empty string IDs
    if bom_data.get('menu_item_id') == '':
        bom_data['menu_item_id'] = None
    if bom_data.get('finished_product_id') == '':
        bom_data['finished_product_id'] = None
        
    new_bom = BillOfMaterials(**bom_data)
    db.add(new_bom)
    db.flush()
    
    for comp in components:
        # Clean up component product_id if empty
        if not comp.get('product_id'):
            continue
        db.add(BOMItem(bom_id=new_bom.id, **comp))
        
    db.commit()
    db.refresh(new_bom)
    return new_bom


@router.put("/boms/{bom_id}")
async def update_bom(
    bom_id: int,
    bom_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    db_bom = db.query(BillOfMaterials).filter(BillOfMaterials.id == bom_id).first()
    if not db_bom:
        raise HTTPException(status_code=404, detail="BOM not found")
        
    components = bom_data.pop('components', None)
    
    # Clean up empty string IDs
    if bom_data.get('menu_item_id') == '':
        bom_data['menu_item_id'] = None
    if bom_data.get('finished_product_id') == '':
        bom_data['finished_product_id'] = None
        
    for key, value in bom_data.items():
        if key != 'id':
            setattr(db_bom, key, value)
            
    if components is not None:
        db.query(BOMItem).filter(BOMItem.bom_id == bom_id).delete()
        for comp in components:
            if not comp.get('product_id'):
                continue
            db.add(BOMItem(bom_id=bom_id, **comp))
            
    db.commit()
    db.refresh(db_bom)
    return db_bom


# ============================================================================
# 7. PRODUCTION
# ============================================================================

@router.post("/productions")
async def create_production(
    prod_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Atomic Production operation"""
    bom_id = prod_data.get('bom_id')
    quantity = prod_data.get('quantity', 1)
    
    bom = db.query(BillOfMaterials).options(
        joinedload(BillOfMaterials.components)
    ).filter(BillOfMaterials.id == bom_id).first()
    
    if not bom or not bom.is_active:
        raise HTTPException(status_code=400, detail="Active BOM required")
        
    # Check availability
    insufficient = []
    for comp in bom.components:
        required = comp.quantity * quantity
        available = calculate_product_stock(db, comp.product_id)
        if available < required:
            insufficient.append({"item": comp.product.name, "req": required, "avail": available})
            
    if insufficient:
        raise HTTPException(status_code=400, detail={"msg": "Insufficient materials", "items": insufficient})
        
    prod_num = f"PROD-{datetime.now().strftime('%Y%m%d%H%M')}-{random.randint(100, 999)}"
    
    # Find active session
    active_session = db.query(POSSession).filter(
        POSSession.user_id == current_user.id,
        POSSession.status == "Open"
    ).first()
    
    production = BatchProduction(
        production_number=prod_num,
        bom_id=bom_id,
        quantity=quantity,
        status="Completed",
        pos_session_id=active_session.id if active_session else None,
        created_by=current_user.id,
        completed_at=datetime.utcnow(),
        notes=prod_data.get('notes')
    )
    db.add(production)
    db.flush()
    
    # 1. OUT Transactions for components (Consumption)
    for component in bom.components:
        consumed_qty = component.quantity * quantity
        out_txn = InventoryTransaction(
            product_id=component.product_id,
            transaction_type='Production_OUT',
            quantity=consumed_qty,
            reference_number=prod_num,
            reference_id=production.id,
            pos_session_id=active_session.id if active_session else None,
            notes=f"Consumed for production: {bom.name} ({prod_num})",
            created_by=current_user.id
        )
        db.add(out_txn)
        
    # 2. IN Transaction for finished product (Output)
    if bom.finished_product_id:
        produced_qty = bom.output_quantity * quantity
        in_txn = InventoryTransaction(
            product_id=bom.finished_product_id,
            transaction_type='Production_IN',
            quantity=produced_qty,
            reference_number=prod_num,
            reference_id=production.id,
            pos_session_id=active_session.id if active_session else None,
            notes=f"Produced from BOM: {bom.name} ({prod_num})",
            created_by=current_user.id
        )
        db.add(in_txn)
        
    db.commit()
    db.refresh(production)
    return production


@router.get("/productions")
async def get_productions(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return db.query(BatchProduction).options(
        joinedload(BatchProduction.bom).joinedload(BillOfMaterials.finished_product)
    ).order_by(BatchProduction.created_at.desc()).all()
