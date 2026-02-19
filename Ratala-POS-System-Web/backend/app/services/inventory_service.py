from sqlalchemy.orm import Session
from sqlalchemy import func
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
        Deduct inventory based on BOM mappings.
        Supports recursive production: if an ingredient is low, triggers its production BOM if available.
        """
        for item in order.items:
            menu_item = item.menu_item
            if not menu_item or not menu_item.bom_id:
                continue
                
            bom = menu_item.bom
            if not bom or not bom.is_active:
                continue

            # Process ingredients for this menu item
            # Ingredients are BOMItem with item_type='input' (or all for legacy BOMs)
            ingredients = [c for c in bom.components if getattr(c, 'item_type', 'input') == 'input']
            
            for component in ingredients:
                # 1. Calculate required quantity for item * order quantity
                # For legacy BOMs, yield was output_quantity. For Menu BOMs, yield is usually 1.0 but we handle both.
                raw_req = (component.quantity * item.quantity) / (bom.output_quantity or 1.0)
                
                # Convert to base unit of the product
                required_qty = InventoryService.convert_quantity(
                    db, raw_req, component.unit_id, component.product.unit_id
                )
                
                # 2. Check stock and trigger production if needed
                InventoryService.ensure_stock_availability(db, component.product_id, required_qty, order.branch_id, user_id)
                
                # 3. Create OUT Transaction
                txn = InventoryTransaction(
                    product_id=component.product_id,
                    transaction_type="OUT",
                    quantity=required_qty,
                    reference_number=order.order_number,
                    reference_id=order.id,
                    pos_session_id=order.pos_session_id,
                    notes=f"Sold via {menu_item.name} (Order {order.order_number})",
                    created_by=user_id,
                    branch_id=order.branch_id,
                    created_at=datetime.utcnow()
                )
                db.add(txn)
        
        db.flush()

    @staticmethod
    def ensure_stock_availability(db: Session, product_id: int, required_qty: float, branch_id: int, user_id: int):
        """
        Checks if stock is available for a product. 
        If not, attempts to trigger production BOM if one exists for this product.
        Recursive function to support parent-child BOM chaining.
        """
        from app.api.v1.inventory import calculate_product_stock
        
        current_stock = calculate_product_stock(db, product_id)
        if current_stock >= required_qty:
            return True
            
        deficit = required_qty - current_stock
        
        # Look for a production BOM that outputs this product
        # 1. Check legacy BOM where finished_product_id matches
        # 2. Check new multi-output BOM where product is an 'output' component
        
        # For simplicity, we prioritize 'automatic' production mode BOMs
        production_bom = db.query(BillOfMaterials).join(BOMItem).filter(
            BillOfMaterials.branch_id == branch_id,
            BillOfMaterials.is_active == True,
            BillOfMaterials.production_mode == 'automatic',
            BOMItem.product_id == product_id,
            BOMItem.item_type == 'output'
        ).first() or db.query(BillOfMaterials).filter(
            BillOfMaterials.branch_id == branch_id,
            BillOfMaterials.is_active == True,
            BillOfMaterials.production_mode == 'automatic',
            BillOfMaterials.finished_product_id == product_id
        ).first()

        if not production_bom:
            return False # No way to produce this automatically
            
        # Calculate how many batches needed
        # Yield refers to how much of the target product is produced per batch
        yield_per_batch = 1.0
        if production_bom.finished_product_id == product_id:
            yield_per_batch = production_bom.output_quantity or 1.0
        else:
            # Multi-output BOM: find the output component's quantity
            output_comp = next((c for c in production_bom.components if c.product_id == product_id and c.item_type == 'output'), None)
            if output_comp:
                yield_per_batch = output_comp.quantity
                
        if yield_per_batch <= 0:
            return False
            
        batches_needed = deficit / yield_per_batch
        
        # Check if we can produce these batches (recursive check for ingredients!)
        # We need to ensure ALL ingredients for this production BOM are available or can be produced
        can_produce = True
        inputs = [c for c in production_bom.components if c.item_type == 'input']
        for in_comp in inputs:
            req_in_qty = in_comp.quantity * batches_needed
            req_in_base = InventoryService.convert_quantity(db, req_in_qty, in_comp.unit_id, in_comp.product.unit_id)
            
            if not InventoryService.ensure_stock_availability(db, in_comp.product_id, req_in_base, branch_id, user_id):
                can_produce = False
                break
                
        if can_produce:
            # Trigger Atomic Production
            from app.api.v1.inventory import create_production
            try:
                # We mock a request body for the existing API logic
                # Actually, better to call a simplified internal production trigger
                InventoryService.internal_trigger_production(db, production_bom, batches_needed, branch_id, user_id)
                return True
            except Exception as e:
                print(f"Failed to auto-produce: {str(e)}")
                return False
        
        return False

    @staticmethod
    def internal_trigger_production(db: Session, bom: BillOfMaterials, quantity: float, branch_id: int, user_id: int):
        """Internal atomic production without dependency on API router"""
        import random
        from app.models.inventory import BatchProduction
        
        today_date = datetime.utcnow().strftime('%Y%m%d')
        
        while True:
            # Count productions for today for daily sequence
            daily_count = db.query(BatchProduction).filter(
                func.date(BatchProduction.created_at) == datetime.utcnow().date()
            ).count()
            prod_num = f"AUTO-{today_date}-{str(daily_count + 1).zfill(4)}"
            
            # Uniqueness check
            if not db.query(BatchProduction).filter(BatchProduction.production_number == prod_num).first():
                break
            daily_count += 1
        
        production = BatchProduction(
            production_number=prod_num,
            bom_id=bom.id,
            quantity=quantity,
            status="Completed",
            branch_id=branch_id,
            created_by=user_id,
            completed_at=datetime.utcnow(),
            notes=f"Auto-triggered recursive production",
            finished_product_id=bom.finished_product_id
        )
        db.add(production)
        db.flush()
        
        # 1. IN Transactions for Outputs
        outputs = [c for c in bom.components if c.item_type == "output"]
        if not outputs and bom.finished_product_id:
            # Legacy support
            added_qty = bom.output_quantity * quantity
            db.add(InventoryTransaction(
                product_id=bom.finished_product_id,
                transaction_type='Production_IN',
                quantity=added_qty,
                reference_number=prod_num,
                reference_id=production.id,
                notes="Auto-produced (Legacy)",
                created_by=user_id,
                branch_id=branch_id
            ))
        else:
            for out in outputs:
                added_qty = InventoryService.convert_quantity(db, out.quantity * quantity, out.unit_id, out.product.unit_id)
                db.add(InventoryTransaction(
                    product_id=out.product_id,
                    transaction_type='Production_IN',
                    quantity=added_qty,
                    reference_number=prod_num,
                    reference_id=production.id,
                    notes=f"Auto-produced via recursive BOM",
                    created_by=user_id,
                    branch_id=branch_id
                ))
                # Trigger auto-production for the output product (recursive step)
                InventoryService.trigger_auto_production(db, out.product_id, added_qty, branch_id, user_id)
        
        # 2. OUT Transactions for Inputs
        inputs = [c for c in bom.components if c.item_type == 'input']
        for inp in inputs:
            consumed_qty = InventoryService.convert_quantity(db, inp.quantity * quantity, inp.unit_id, inp.product.unit_id)
            db.add(InventoryTransaction(
                product_id=inp.product_id,
                transaction_type='Production_OUT',
                quantity=consumed_qty,
                reference_number=prod_num,
                reference_id=production.id,
                notes=f"Auto-consumed for recursive production",
                created_by=user_id,
                branch_id=branch_id
            ))
        
        db.flush()

    @staticmethod
    def trigger_auto_production(db: Session, product_id: int, quantity: float, branch_id: int, user_id: int):
        """
        Trigger automatic production for BOMs that depend on the given product.
        Called when stock is added. (Kept for compatibility, but ensure_stock_availability is the new primary recursive driver)
        """
        # Find BOMs where this product is an INPUT and mode is automatic
        auto_boms = db.query(BillOfMaterials).join(BOMItem).filter(
            BillOfMaterials.production_mode == 'automatic',
            BillOfMaterials.is_active == True,
            BillOfMaterials.branch_id == branch_id,
            BOMItem.product_id == product_id,
            BOMItem.item_type == 'input'
        ).all()
        
        for bom in auto_boms:
            component = next((c for c in bom.components if c.product_id == product_id and c.item_type == 'input'), None)
            if not component or component.quantity <= 0: continue
            
            # Calculate how many batches this incoming quantity can produce
            from_factor = component.unit.conversion_factor if component.unit else 1.0
            to_factor = component.product.unit.conversion_factor if component.product.unit else 1.0
            req_in_base_per_batch = (component.quantity * from_factor) / to_factor
            
            if req_in_base_per_batch > 0:
                import math
                # ERP Rule: Number of batches MUST be a whole number for easier counting
                num_batches = math.floor(quantity / req_in_base_per_batch)
                
                if num_batches > 0:
                    InventoryService.internal_trigger_production(db, bom, num_batches, branch_id, user_id)
        
        db.flush()
