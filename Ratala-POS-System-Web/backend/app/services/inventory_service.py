from sqlalchemy.orm import Session
from app.models.orders import Order, OrderItem
from app.models.inventory import Product, InventoryTransaction, BillOfMaterials, BOMItem, UnitOfMeasurement
from datetime import datetime

class InventoryService:
    @staticmethod
    def convert_quantity(db: Session, quantity: float, from_unit_id: int, to_unit_id: int) -> float:
        """Helper to convert quantity between units if they are compatible"""
        if not from_unit_id or from_unit_id == to_unit_id:
            return quantity
            
        from_unit = db.query(UnitOfMeasurement).filter(UnitOfMeasurement.id == from_unit_id).first()
        to_unit = db.query(UnitOfMeasurement).filter(UnitOfMeasurement.id == to_unit_id).first()
        
        if not from_unit or not to_unit:
            return quantity
            
        # Conversion logic: (qty * from_factor) / to_factor
        return (quantity * from_unit.conversion_factor) / to_unit.conversion_factor

    @staticmethod
    def deduct_inventory_for_order(db: Session, order: Order, user_id: int):
        """
        Deduct inventory based on BOM for all items in the order.
        Now uses the relationship from MenuItem.bom_id
        """
        for item in order.items:
            # Get the menu item to check for a linked BOM
            menu_item = item.menu_item
            if not menu_item or not menu_item.bom_id:
                continue
                
            bom = menu_item.bom
            if not bom or not bom.is_active:
                continue
            
            # 1. If BOM has a finished_product linked, deduct from that instead of components
            if bom.finished_product_id:
                # Deduction quantity = item.quantity (since 1 menu_item = 1 produced unit usually, or based on yield)
                deduct_qty = item.quantity
                
                txn = InventoryTransaction(
                    product_id=bom.finished_product_id,
                    transaction_type="Production_OUT",
                    quantity=deduct_qty,
                    reference_number=order.order_number,
                    reference_id=order.id,
                    pos_session_id=order.pos_session_id,
                    notes=f"Sold from produced stock (Order {order.order_number})",
                    created_by=user_id,
                    created_at=datetime.utcnow()
                )
                db.add(txn)
                continue

            # 2. Production-Aware JIT Deduction:
            # Check how much of this item was already "produced" (ingredients already deducted)
            # vs how much needs to be deducted now.
            
            from app.models import BatchProduction, OrderItem as OI, Order as O
            from sqlalchemy import func
            
            # Get all menu items linked to this BOM
            menu_item_ids = [mi.id for mi in bom.menu_items]
            
            # Total produced for this BOM until NOW
            total_produced = db.query(func.sum(BatchProduction.quantity * BillOfMaterials.output_quantity))\
                .filter(BatchProduction.bom_id == bom.id, BatchProduction.created_at <= datetime.utcnow())\
                .scalar() or 0.0
                
            # Total sold (served) until NOW (excluding this specific order)
            total_sold = db.query(func.sum(OI.quantity)).join(O)\
                .filter(OI.menu_item_id.in_(menu_item_ids), O.id != order.id, O.status != 'Cancelled')\
                .scalar() or 0.0
                
            available_produced_balance = max(0, total_produced - total_sold)
            
            # Calculate how many units exceed the production pool
            # (If available_produced_balance is 10 and we sell 12, we need to deduct ingredients for 2 units JIT)
            jit_deduct_qty = max(0, item.quantity - available_produced_balance)

            if jit_deduct_qty > 0:
                for component in bom.components:
                    # Total quantity to deduct = (BOM qty per batch * Surplus qty) / BOM Yield (output_quantity)
                    raw_qty = (component.quantity * jit_deduct_qty) / (bom.output_quantity or 1.0)
                    
                    # Convert to product's base unit if necessary
                    deduct_qty = InventoryService.convert_quantity(
                        db, raw_qty, component.unit_id, component.product.unit_id
                    )
                    
                    txn = InventoryTransaction(
                        product_id=component.product_id,
                        transaction_type="OUT",
                        quantity=deduct_qty,
                        reference_number=order.order_number,
                        reference_id=order.id,
                        pos_session_id=order.pos_session_id,
                        notes=f"Auto-deducted JIT for Order {order.order_number} (Excl. produced pool: {jit_deduct_qty}/{item.quantity})",
                        created_by=user_id,
                        created_at=datetime.utcnow()
                    )
                    db.add(txn)
        
        db.flush() 
