"""
Order management service
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime
import random
from app.models.orders import Order, OrderItem, KOT, KOTItem, Table
from app.models.menu import MenuItem
from app.services.printing_service import PrintingService
from sqlalchemy.orm import joinedload


class OrderService:
    """Service for order operations"""
    
    @staticmethod
    def generate_order_number() -> str:
        """Generate a unique order number"""
        return f"ORD-{datetime.now().strftime('%Y%m%d')}-{random.randint(1000, 9999)}"
    
    @staticmethod
    def get_all_orders(db: Session) -> List[Order]:
        """Get all orders"""
        return db.query(Order).all()
    
    @staticmethod
    def get_order_by_id(db: Session, order_id: int) -> Optional[Order]:
        """Get order by ID"""
        return db.query(Order).filter(Order.id == order_id).first()
    
    @staticmethod
    def create_order(db: Session, order_data: dict) -> Order:
        """Create a new order"""
        if 'order_number' not in order_data:
            order_data['order_number'] = OrderService.generate_order_number()
        
        new_order = Order(**order_data)
        db.add(new_order)
        db.commit()
        db.refresh(new_order)
        return new_order
    
    @staticmethod
    def update_order_status(db: Session, order_id: int, status: str) -> Optional[Order]:
        """Update order status"""
        order = db.query(Order).filter(Order.id == order_id).first()
        if not order:
            return None
        
        order.status = status
        db.commit()
        db.refresh(order)
        return order
    
    @staticmethod
    async def create_kots_for_order(db: Session, order_id: int, user_id: int):
        """
        Identify items in the order that are not yet in a KOT/BOT and create them.
        This handles both new orders and additions to existing orders.
        """
        order = db.query(Order).options(
            joinedload(Order.items),
            joinedload(Order.kots).joinedload(KOT.items)
        ).filter(Order.id == order_id).first()
        
        if not order:
            return
            
        # 1. Map current total quantities in order
        order_items_map = {} # {menu_item_id: total_qty}
        for item in order.items:
            order_items_map[item.menu_item_id] = order_items_map.get(item.menu_item_id, 0) + item.quantity
            
        # 2. Map quantities already in KOTs
        koted_items_map = {} # {menu_item_id: total_qty}
        for kot in order.kots:
            if kot.status != 'Cancelled':
                for item in kot.items:
                    koted_items_map[item.menu_item_id] = koted_items_map.get(item.menu_item_id, 0) + item.quantity
                    
        # 3. Identify pending items
        pending_items = [] # list of (menu_item, quantity)
        for menu_item_id, total_qty in order_items_map.items():
            koted_qty = koted_items_map.get(menu_item_id, 0)
            pending_qty = total_qty - koted_qty
            
            if pending_qty > 0:
                menu_item = db.query(MenuItem).filter(MenuItem.id == menu_item_id).first()
                if menu_item:
                    pending_items.append((menu_item, pending_qty))
                    
        if not pending_items:
            return
            
        # 4. Group pending items by KOT/BOT type
        kot_groups = {} # {type: [items]}
        for menu_item, qty in pending_items:
            kot_type = (menu_item.kot_bot or 'KOT').upper()
            if kot_type not in kot_groups:
                kot_groups[kot_type] = []
            
            # Find original order item for notes (crude way, just take first one)
            notes = ""
            for item in order.items:
                if item.menu_item_id == menu_item.id:
                    notes = item.notes
                    break
                    
            kot_groups[kot_type].append({
                'menu_item_id': menu_item.id,
                'quantity': qty,
                'notes': notes
            })
            
        # 5. Create KOTs
        printing_service = PrintingService(db)
        
        for kot_type, items in kot_groups.items():
            prefix = 'KOT' if kot_type == 'KOT' else 'BOT'
            kot_number = f"{prefix}-{datetime.now().strftime('%Y%m%d%H%M')}-{random.randint(100, 999)}"
            
            new_kot = KOT(
                order_id=order.id,
                kot_number=kot_number,
                kot_type=kot_type,
                status='Pending',
                created_by=user_id
            )
            db.add(new_kot)
            db.flush()
            
            for item_data in items:
                kot_item = KOTItem(
                    kot_id=new_kot.id,
                    menu_item_id=item_data['menu_item_id'],
                    quantity=item_data['quantity'],
                    notes=item_data['notes']
                )
                db.add(kot_item)
            
            db.commit()
            
            # Print KOT/BOT
            kot_to_print = db.query(KOT).options(
                joinedload(KOT.order).joinedload(Order.table),
                joinedload(KOT.items).joinedload(KOTItem.menu_item),
                joinedload(KOT.user)
            ).filter(KOT.id == new_kot.id).first()
            
            if kot_type == 'KOT':
                await printing_service.print_kot(kot_to_print)
            else:
                await printing_service.print_bot(kot_to_print)
