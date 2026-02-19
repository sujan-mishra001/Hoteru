"""
Inventory management routes - Transaction-based system with branch isolation
Core Principle: Stock is NEVER updated directly, only through transactions
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, or_
from datetime import datetime, timezone
import random

from app.db.database import get_db
from app.core.dependencies import get_current_user, get_branch_id
from app.models import (
    Product, UnitOfMeasurement, InventoryTransaction,
    BillOfMaterials, BOMItem, BatchProduction, POSSession, Branch, MenuItem
)
from app.services.inventory_service import InventoryService

router = APIRouter()


def apply_branch_filter_inventory(query, model, branch_id):
    """Apply strict branch_id filter for data isolation"""
    if branch_id is not None and hasattr(model, 'branch_id'):
        query = query.filter(model.branch_id == branch_id)
    return query


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
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all products with DERIVED stock for the branch"""
    query = db.query(Product).options(joinedload(Product.unit))
    query = apply_branch_filter_inventory(query, Product, branch_id)
    products = query.all()
    
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
            "product_type": product.product_type,
            "status": get_product_status(stock, product.min_stock),
            "created_at": product.created_at,
            "updated_at": product.updated_at
        })
    
    return result


@router.post("/products")
async def create_product(
    product_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Create a new product in the branch"""
    # Check if a product with the same name already exists in this branch
    existing = db.query(Product).filter(
        Product.name == product_data.get('name'),
        Product.branch_id == branch_id
    ).first()
    if existing:
        raise HTTPException(
            status_code=400,
            detail=f"A product named '{product_data.get('name')}' already exists in this branch."
        )

    # Strip non-model fields
    allowed_fields = ['name', 'category', 'unit_id', 'min_stock', 'product_type']
    data = {k: v for k, v in product_data.items() if k in allowed_fields}
    data['branch_id'] = branch_id
    
    new_product = Product(**data)
    db.add(new_product)
    db.flush() # Get ID
    
    # Handle initial stock if provided
    initial_stock = 0.0
    if 'current_stock' in product_data:
        try:
            qty = float(product_data['current_stock'])
            if qty > 0:
                txn = InventoryTransaction(
                    product_id=new_product.id,
                    transaction_type='IN',
                    quantity=qty,
                    notes="Opening Stock",
                    created_by=current_user.id
                )
                db.add(txn)
                initial_stock = qty
        except (ValueError, TypeError):
            pass

    db.commit()
    db.refresh(new_product)
    
    return {
        "id": new_product.id,
        "name": new_product.name,
        "category": new_product.category,
        "unit_id": new_product.unit_id,
        "current_stock": initial_stock,
        "min_stock": new_product.min_stock,
        "product_type": new_product.product_type,
        "status": get_product_status(initial_stock, new_product.min_stock)
    }


@router.put("/products/{product_id}")
@router.patch("/products/{product_id}")
async def update_product(
    product_id: int,
    product_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Update a product in the branch"""
    query = db.query(Product).filter(Product.id == product_id)
    query = apply_branch_filter_inventory(query, Product, branch_id)
    db_product = query.first()
    
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found or access denied")
    
    allowed_fields = ['name', 'category', 'unit_id', 'min_stock']
    
    # Check for name collision if renaming
    if 'name' in product_data and product_data['name'] != db_product.name:
        existing = db.query(Product).filter(
            Product.name == product_data['name'],
            Product.branch_id == branch_id,
            Product.id != product_id
        ).first()
        if existing:
            raise HTTPException(
                status_code=400,
                detail=f"A product named '{product_data['name']}' already exists in this branch."
            )

    for key, value in product_data.items():
        if key in allowed_fields:
            setattr(db_product, key, value)
    
    # Handle direct stock update
    if 'current_stock' in product_data:
        try:
            new_stock = float(product_data['current_stock'])
            current_stock = calculate_product_stock(db, product_id)
            diff = new_stock - current_stock
            
            if abs(diff) > 0.001: # Avoid floating point issues
                txn = InventoryTransaction(
                    product_id=product_id,
                    transaction_type='Adjustment',
                    quantity=diff, # Adjustment takes signed value
                    notes="Manual update from product form",
                    created_by=current_user.id
                )
                db.add(txn)
        except (ValueError, TypeError):
            pass

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
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Delete a product in the branch - ONLY if no transactions exist"""
    query = db.query(Product).filter(Product.id == product_id)
    query = apply_branch_filter_inventory(query, Product, branch_id)
    db_product = query.first()
    
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found or access denied")
    
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
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all units for the branch with branch details"""
    query = db.query(UnitOfMeasurement).options(joinedload(UnitOfMeasurement.branch))
    query = apply_branch_filter_inventory(query, UnitOfMeasurement, branch_id)
    units = query.all()
    
    result = []
    for unit in units:
        result.append({
            "id": unit.id,
            "name": unit.name,
            "abbreviation": unit.abbreviation,
            "conversion_factor": unit.conversion_factor,
            "base_unit_id": unit.base_unit_id,
            "branch_id": unit.branch_id,
            "branch_slug": unit.branch.code if unit.branch else None,
            "created_at": unit.created_at
        })
    return result


@router.post("/units")
async def create_unit(
    unit_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Create a new unit of measurement for the branch"""
    # Check if unit with same name already exists in this branch
    existing_unit = db.query(UnitOfMeasurement).filter(
        UnitOfMeasurement.name == unit_data.get('name'),
        UnitOfMeasurement.branch_id == branch_id
    ).first()
    
    if existing_unit:
        raise HTTPException(
            status_code=400, 
            detail=f"Unit '{unit_data.get('name')}' already exists in this branch"
        )
    
    unit_data['branch_id'] = branch_id
    new_unit = UnitOfMeasurement(**unit_data)
    db.add(new_unit)
    
    try:
        db.commit()
        db.refresh(new_unit)
        return new_unit
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Error creating unit: {str(e)}")


@router.put("/units/{unit_id}")
@router.patch("/units/{unit_id}")
async def update_unit(
    unit_id: int,
    unit_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    query = db.query(UnitOfMeasurement).filter(UnitOfMeasurement.id == unit_id)
    query = apply_branch_filter_inventory(query, UnitOfMeasurement, branch_id)
    db_unit = query.first()
    if not db_unit:
        raise HTTPException(status_code=404, detail="Unit not found or access denied")
    
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
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    query = db.query(UnitOfMeasurement).filter(UnitOfMeasurement.id == unit_id)
    query = apply_branch_filter_inventory(query, UnitOfMeasurement, branch_id)
    db_unit = query.first()
    if not db_unit:
        raise HTTPException(status_code=404, detail="Unit not found or access denied")
    
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
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Create IN transaction for adding stock"""
    txn_data['created_by'] = current_user.id
    txn_data['branch_id'] = branch_id
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
    
    # Trigger auto-production if this is an 'IN' transaction
    InventoryService.trigger_auto_production(
        db, 
        new_txn.product_id, 
        new_txn.quantity, 
        branch_id, 
        current_user.id
    )
    db.commit()
    
    return new_txn


@router.get("/transactions")
async def get_transactions(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all inventory transactions for the branch"""
    query = db.query(InventoryTransaction).options(
        joinedload(InventoryTransaction.product).joinedload(Product.unit)
    )
    query = apply_branch_filter_inventory(query, InventoryTransaction, branch_id)
    return query.order_by(InventoryTransaction.created_at.desc()).all()


# ============================================================================
# 4. ADJUSTMENTS
# ============================================================================

@router.post("/adjustments")
async def create_adjustment(
    adj_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Create Adjustment transaction (signed quantity) in the branch"""
    # branch_id is now provided by dependency
    
    if not adj_data.get('notes'):
        raise HTTPException(status_code=400, detail="Reason is required for adjustments")
        
    adj_data['created_by'] = current_user.id
    adj_data['transaction_type'] = 'Adjustment'
    
    # Set branch_id if the column exists
    if branch_id is not None and hasattr(InventoryTransaction, 'branch_id'):
        adj_data['branch_id'] = branch_id
    
    # Tie to active POS Session
    active_session = db.query(POSSession).filter(
        POSSession.user_id == current_user.id,
        POSSession.status == "Open"
    ).first()
    if active_session:
        adj_data['pos_session_id'] = active_session.id
    
    # Convert quantity to product's base unit if necessary using InventoryService
    from app.services.inventory_service import InventoryService
    
    # Get product's base unit_id
    product_id = adj_data.get('product_id')
    product = db.query(Product).filter(Product.id == product_id).first()
    to_unit_id = product.unit_id if product else None
    
    # Get incoming quantity and unit
    incoming_qty = adj_data.get('quantity', 0)
    from_unit_id = adj_data.get('unit_id')
    
    # Convert quantity
    conversion_qty = InventoryService.convert_quantity(
        db, 
        incoming_qty, 
        from_unit_id, 
        to_unit_id
    )

    adj_data['quantity'] = conversion_qty
    # Remove unit_id from adj_data if it's not a model field (InventoryTransaction doesn't have it)
    if 'unit_id' in adj_data:
        del adj_data['unit_id']

    new_adj = InventoryTransaction(**adj_data)
    db.add(new_adj)
    db.commit()
    db.refresh(new_adj)
    
    # Trigger auto-production for positive adjustments (stock add)
    if new_adj.quantity > 0:
        InventoryService.trigger_auto_production(
            db,
            new_adj.product_id,
            new_adj.quantity,
            branch_id,
            current_user.id
        )
        db.commit()
        
    return new_adj


@router.get("/adjustments")
async def get_adjustments(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all adjustments for the branch"""
    # branch_id is now provided by dependency
    
    query = db.query(InventoryTransaction).filter(
        InventoryTransaction.transaction_type == 'Adjustment'
    )
    query = apply_branch_filter_inventory(query, InventoryTransaction, branch_id)
    return query.options(
        joinedload(InventoryTransaction.product).joinedload(Product.unit)
    ).order_by(InventoryTransaction.created_at.desc()).all()


# ============================================================================
# 6. BOM
# ============================================================================

@router.get("/boms")
async def get_boms(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all BOMs with real-time component stock for the branch"""
    # branch_id is now provided by dependency
    
    query = db.query(BillOfMaterials).options(
        joinedload(BillOfMaterials.components).joinedload(BOMItem.product).joinedload(Product.unit),
        joinedload(BillOfMaterials.components).joinedload(BOMItem.unit),
        joinedload(BillOfMaterials.menu_items)
    )
    query = apply_branch_filter_inventory(query, BillOfMaterials, branch_id)
    boms = query.all()
    
    result = []
    for bom in boms:
        components = []
        for comp in bom.components:
            stock = calculate_product_stock(db, comp.product_id)
            components.append({
                "id": comp.id,
                "product_id": comp.product_id,
                "unit_id": comp.unit_id,
                "quantity": comp.quantity,
                "item_type": comp.item_type,
                "product": {
                    "id": comp.product.id,
                    "name": comp.product.name,
                    "current_stock": stock,
                    "unit": {
                        "id": comp.product.unit.id,
                        "name": comp.product.unit.name,
                        "abbreviation": comp.product.unit.abbreviation,
                        "conversion_factor": comp.product.unit.conversion_factor
                    } if comp.product.unit else None
                },
                "unit": {
                    "id": comp.unit.id,
                    "name": comp.unit.name,
                    "abbreviation": comp.unit.abbreviation,
                    "conversion_factor": comp.unit.conversion_factor
                } if comp.unit else None
            })
            
        result.append({
            "id": bom.id,
            "name": bom.name,
            "output_quantity": bom.output_quantity,
            "is_active": bom.is_active,
            "created_at": bom.created_at,
            "bom_type": bom.bom_type,
            "production_mode": bom.production_mode,
            "finished_product_id": bom.finished_product_id,
            "finished_product": {
                "id": bom.finished_product.id,
                "name": bom.finished_product.name,
                "unit": {
                    "id": bom.finished_product.unit.id,
                    "abbreviation": bom.finished_product.unit.abbreviation
                } if bom.finished_product.unit else None
            } if bom.finished_product else None,
            "components": components,
            "menu_items": [
                {"id": mi.id, "name": mi.name} for mi in bom.menu_items
            ]
        })
        
    return result


@router.post("/boms")
async def create_bom(
    bom_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Create a new BOM in the branch"""
    # branch_id is now provided by dependency
    components = bom_data.pop('components', [])
    
    # Set branch_id if the column exists
    if branch_id is not None:
        bom_data['branch_id'] = branch_id
        
    # Handle menu item linking
    menu_item_ids = bom_data.pop('menu_item_ids', [])
    
    # Handle empty finished_product_id
    if bom_data.get('finished_product_id') == '':
        bom_data['finished_product_id'] = None
        
    # Create the BOM
    new_bom = BillOfMaterials(**bom_data)
    db.add(new_bom)
    db.flush()
    
    if menu_item_ids:
        db.query(MenuItem).filter(MenuItem.id.in_(menu_item_ids)).update(
            {"bom_id": new_bom.id}, synchronize_session=False
        )
    
    for comp in components:
        if not comp.get('product_id'):
            continue
            
        if comp.get('unit_id') == '':
            comp['unit_id'] = None
            
        db.add(BOMItem(bom_id=new_bom.id, **comp))
        
    db.commit()
    db.refresh(new_bom)
    return new_bom


@router.put("/boms/{bom_id}")
@router.patch("/boms/{bom_id}")
async def update_bom(
    bom_id: int,
    bom_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    query = db.query(BillOfMaterials).filter(BillOfMaterials.id == bom_id)
    query = apply_branch_filter_inventory(query, BillOfMaterials, branch_id)
    db_bom = query.first()
    if not db_bom:
        raise HTTPException(status_code=404, detail="BOM not found")
        
    components = bom_data.pop('components', None)
    menu_item_ids = bom_data.pop('menu_item_ids', None)
        
    for key, value in bom_data.items():
        if key != 'id':
            # Handle empty finished_product_id
            if key == 'finished_product_id' and value == '':
                value = None
            setattr(db_bom, key, value)
            
    if components is not None:
        db.query(BOMItem).filter(BOMItem.bom_id == bom_id).delete()
        for comp in components:
            if not comp.get('product_id'):
                continue
                
            # Convert empty string unit_id to None
            if comp.get('unit_id') == '':
                comp['unit_id'] = None
                
            db.add(BOMItem(bom_id=bom_id, **comp))
            
            
    # Handle menu item linking
    if menu_item_ids is not None:
        # Clear existing links for this BOM
        db.query(MenuItem).filter(MenuItem.bom_id == bom_id).update({"bom_id": None}, synchronize_session=False)
        # Set new links
        if menu_item_ids:
            db.query(MenuItem).filter(MenuItem.id.in_(menu_item_ids)).update(
                {"bom_id": bom_id}, synchronize_session=False
            )
            
    db.commit()
    db.refresh(db_bom)
    return db_bom


@router.delete("/boms/{bom_id}")
async def delete_bom(
    bom_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Delete a BOM and clear references in MenuItems"""
    query = db.query(BillOfMaterials).filter(BillOfMaterials.id == bom_id)
    query = apply_branch_filter_inventory(query, BillOfMaterials, branch_id)
    db_bom = query.first()
    
    if not db_bom:
        raise HTTPException(status_code=404, detail="Recipe not found")
        
    # Check if this BOM has production history (cannot delete for audit reasons)
    has_history = db.query(BatchProduction).filter(BatchProduction.bom_id == bom_id).first()
    if has_history:
        raise HTTPException(
            status_code=400, 
            detail="Cannot delete recipe with production record history. Please deactivate it instead for auditing purposes."
        )
        
    # Clear references in MenuItems (for Menu BOMs)
    db.query(MenuItem).filter(MenuItem.bom_id == bom_id).update({"bom_id": None}, synchronize_session=False)
    
    # Delete BOMItem components
    db.query(BOMItem).filter(BOMItem.bom_id == bom_id).delete()
    
    db.delete(db_bom)
    db.commit()
    return {"message": "Recipe deleted successfully"}


# ============================================================================
# 7. PRODUCTION
# ============================================================================

@router.post("/productions")
async def create_production(
    prod_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Atomic Production operation"""
    bom_id = prod_data.get('bom_id')
    # Batch produced MUST be a whole number for easier counting and stock integrity
    try:
        quantity = int(float(prod_data.get('quantity', 1)))
    except (ValueError, TypeError):
        quantity = 1
    
    if quantity <= 0:
        raise HTTPException(status_code=400, detail="Production quantity must be at least 1")
    
    query = db.query(BillOfMaterials).options(
        joinedload(BillOfMaterials.components)
    ).filter(BillOfMaterials.id == bom_id)
    
    query = apply_branch_filter_inventory(query, BillOfMaterials, branch_id)
    bom = query.first()
    
    if not bom or not bom.is_active:
        raise HTTPException(status_code=400, detail="Active BOM required")
        
    # Check availability
    insufficient = []
    for comp in bom.components:
        # Total component quantity required = component.quantity * quantity (batches)
        raw_req = comp.quantity * quantity
        
        # Convert required quantity to product's base unit for accurate comparison
        required_in_base = InventoryService.convert_quantity(
            db, raw_req, comp.unit_id, comp.product.unit_id
        )
        
        available = calculate_product_stock(db, comp.product_id)
        if available < required_in_base:
            insufficient.append({
                "item": comp.product.name, 
                "req": raw_req, 
                "req_base": required_in_base,
                "avail": available,
                "unit": comp.unit.abbreviation if comp.unit else comp.product.unit.abbreviation
            })
            
    if insufficient:
        raise HTTPException(status_code=400, detail={"msg": "Insufficient materials", "items": insufficient})
        
    today_date = datetime.now(timezone.utc).strftime('%Y%m%d')
    while True:
        # Count productions for today for daily sequence
        daily_count = db.query(BatchProduction).filter(
            func.date(BatchProduction.created_at) == datetime.utcnow().date()
        ).count()
        prod_num = f"PROD-{today_date}-{str(daily_count + 1).zfill(4)}"
        
        # Double check uniqueness (in case of race conditions)
        if not db.query(BatchProduction).filter(BatchProduction.production_number == prod_num).first():
            break
        # If exists (race condition), the loop will try count+1 again but count might have updated
        # However, .count() won't update in the same transaction unless refreshed
        # For simplicity in this context:
        daily_count += 1 
    
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
        notes=prod_data.get('notes'),
        finished_product_id=bom.finished_product_id,
        branch_id=branch_id
    )
    db.add(production)
    db.flush()
    
    # 1. IN Transactions for Outputs (Stock Addition)
    outputs = [c for c in bom.components if c.item_type == "output"]
    for output in outputs:
        out_raw_qty = output.quantity * quantity
        
        # Convert to product's base unit
        added_qty = InventoryService.convert_quantity(
            db, out_raw_qty, output.unit_id, output.product.unit_id
        )
        
        in_txn = InventoryTransaction(
            product_id=output.product_id,
            transaction_type='Production_IN',
            quantity=added_qty,
            reference_number=prod_num,
            reference_id=production.id,
            pos_session_id=active_session.id if active_session else None,
            notes=f"Produced from BOM: {bom.name} ({prod_num})",
            created_by=current_user.id,
            branch_id=branch_id
        )
        db.add(in_txn)

    # Simple backward compatibility for legacy single-output BOMs
    if not outputs and bom.finished_product_id:
        in_txn = InventoryTransaction(
            product_id=bom.finished_product_id,
            transaction_type='Production_IN',
            quantity=bom.output_quantity * quantity,
            reference_number=prod_num,
            reference_id=production.id,
            pos_session_id=active_session.id if active_session else None,
            notes=f"Produced from BOM (Legacy): {bom.name} ({prod_num})",
            created_by=current_user.id,
            branch_id=branch_id
        )
        db.add(in_txn)
    
    # 2. OUT Transactions for Inputs (Consumption)
    inputs = [c for c in bom.components if c.item_type == "input"]
    for component in inputs:
        raw_qty = component.quantity * quantity
        
        consumed_qty = InventoryService.convert_quantity(
            db, raw_qty, component.unit_id, component.product.unit_id
        )
        
        out_txn = InventoryTransaction(
            product_id=component.product_id,
            transaction_type='Production_OUT',
            quantity=consumed_qty,
            reference_number=prod_num,
            reference_id=production.id,
            pos_session_id=active_session.id if active_session else None,
            notes=f"Consumed for production: {bom.name} ({prod_num})",
            created_by=current_user.id,
            branch_id=branch_id
        )
        db.add(out_txn)
        
    db.commit()
    db.refresh(production)
    return production


@router.get("/productions")
async def get_productions(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all productions for the branch with detailed info"""
    # branch_id is now provided by dependency
    query = db.query(BatchProduction).options(
        joinedload(BatchProduction.bom).joinedload(BillOfMaterials.menu_items),
        joinedload(BatchProduction.bom).joinedload(BillOfMaterials.components).joinedload(BOMItem.product).joinedload(Product.unit)
    )
    query = apply_branch_filter_inventory(query, BatchProduction, branch_id)
    productions = query.order_by(BatchProduction.created_at.asc()).all()
    
    # Accurate FIFO distribution of sales across batches
    from app.models import OrderItem, Order
    
    # 1. Group productions by BOM
    bom_productions = {}
    for p in productions:
        if p.bom_id not in bom_productions:
            bom_productions[p.bom_id] = []
        bom_productions[p.bom_id].append(p)
        
    result_map = {} # Store final objects by ID
    
    for bom_id, prods in bom_productions.items():
        if not prods or not prods[0].bom:
            continue

        # Get all sales for this BOM
        menu_item_ids = [mi.id for mi in prods[0].bom.menu_items] if prods[0].bom.menu_items else []
        total_sold = 0
        if menu_item_ids:
            sold = db.query(func.sum(OrderItem.quantity)).join(Order).filter(
                OrderItem.menu_item_id.in_(menu_item_ids),
                Order.status != 'Cancelled'
            ).scalar()
            total_sold = float(sold) if sold else 0.0
            
        remaining_sold = total_sold
        
        # Distribute total_sold across prods in FIFO order (they are already sorted asc)
        for p in prods:
            if not p.bom:
                continue
            total_produced = p.bom.output_quantity * p.quantity
            consumed = min(total_produced, remaining_sold)
            remaining_sold -= consumed
            
            result_map[p.id] = {
                "id": p.id,
                "production_number": p.production_number,
                "bom_id": p.bom_id,
                "quantity": p.quantity,
                "total_produced": total_produced,
                "consumed_quantity": consumed,
                "remaining_quantity": total_produced - consumed,
                "status": p.status,
                "created_at": p.created_at,
                "bom": {
                    "id": p.bom.id,
                    "name": p.bom.name,
                    "output_quantity": p.bom.output_quantity,
                    "bom_type": p.bom.bom_type,
                    "menu_items": [{"id": mi.id, "name": mi.name} for mi in p.bom.menu_items],
                    "outputs": [
                        {
                            "product_name": comp.product.name,
                            "quantity": comp.quantity * p.quantity,
                            "unit": comp.unit.abbreviation if comp.unit else comp.product.unit.abbreviation
                        } for comp in p.bom.components if comp.item_type == 'output'
                    ]
                }
            }
            
    # Sort back to descending order for the UI
    final_result = [result_map[p.id] for p in productions]
    final_result.reverse()
    return final_result

@router.get("/productions/counts")
async def get_productions_counts(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get production summary grouped by Menu Item name"""
    from sqlalchemy import func
    from app.models.menu import MenuItem
    
    # Query to group by Menu Item name and sum quantities
    # Join BillOfMaterials and BatchProduction
    query = db.query(
        MenuItem.name.label('menu_item_name'),
        func.sum(BatchProduction.quantity).label('total_batches'),
        # Assuming output_quantity is per batch
        func.sum(BatchProduction.quantity * BillOfMaterials.output_quantity).label('total_quantity'),
        func.max(BatchProduction.completed_at).label('last_produced')
    ).join(BillOfMaterials, MenuItem.bom_id == BillOfMaterials.id)\
     .join(BatchProduction, BatchProduction.bom_id == BillOfMaterials.id)\
     .filter(
        BatchProduction.branch_id == branch_id,
        BatchProduction.status == 'Completed'
    ).group_by(MenuItem.id, MenuItem.name)
    
    counts = query.all()
    
    return [
        {
            "menu_item_name": c.menu_item_name,
            "batches": float(c.total_batches) if c.total_batches else 0,
            "total_produced": float(c.total_quantity) if c.total_quantity else 0,
            "last_produced": c.last_produced
        } for c in counts
    ]
