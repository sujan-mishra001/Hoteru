from sqlalchemy.orm import Session
from app.models.orders import Order, OrderItem
from app.models.inventory import Product, InventoryTransaction, BillOfMaterials, BOMItem
from datetime import datetime

class InventoryService:
    @staticmethod
    def deduct_inventory_for_order(db: Session, order: Order, user_id: int):
        """
        Deduct inventory based on BOM for all items in the order.
        Only runs for orders that have BOMs defined.
        """
        for item in order.items:
            # Find BOM for this menu item
            bom = db.query(BillOfMaterials).filter(
                BillOfMaterials.menu_item_id == item.menu_item_id,
                BillOfMaterials.is_active == 1
            ).first()
            
            if not bom:
                continue # No BOM defined for this item, skip deduction
            
            # For each component in BOM, create a transaction
            for component in bom.components:
                # Total quantity to deduct = BOM component quantity * Order item quantity
                deduct_qty = component.quantity * item.quantity
                
                txn = InventoryTransaction(
                    product_id=component.product_id,
                    transaction_type="OUT",
                    quantity=deduct_qty,
                    reference_number=order.order_number,
                    reference_id=order.id,
                    pos_session_id=order.pos_session_id,
                    notes=f"Auto-deducted for Order {order.order_number}",
                    created_by=user_id,
                    created_at=datetime.utcnow()
                )
                db.add(txn)
        
        db.flush() # Ensure transactions are ready to be committed with the order
