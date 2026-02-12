"""
Order management service
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime
import random
from app.models.orders import Order, OrderItem, KOT, Table, Session


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
    def create_kot(db: Session, order_id: int) -> KOT:
        """Create a KOT for an order"""
        kot_number = f"KOT-{datetime.now().strftime('%Y%m%d')}-{random.randint(1000, 9999)}"
        new_kot = KOT(
            kot_number=kot_number,
            order_id=order_id,
            status="Pending"
        )
        db.add(new_kot)
        db.commit()
        db.refresh(new_kot)
        return new_kot
