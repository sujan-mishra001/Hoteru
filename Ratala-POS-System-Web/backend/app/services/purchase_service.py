"""
Purchase management service
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime
import random
from app.models.purchase import Supplier, PurchaseBill, PurchaseReturn


class PurchaseService:
    """Service for purchase operations"""
    
    @staticmethod
    def generate_bill_number() -> str:
        """Generate a unique purchase bill number"""
        return f"PO-{datetime.now().strftime('%Y%m%d')}-{random.randint(1000, 9999)}"
    
    @staticmethod
    def generate_return_number() -> str:
        """Generate a unique return number"""
        return f"RET-{datetime.now().strftime('%Y%m%d')}-{random.randint(1000, 9999)}"
    
    @staticmethod
    def get_all_suppliers(db: Session) -> List[Supplier]:
        """Get all suppliers"""
        return db.query(Supplier).all()
    
    @staticmethod
    def create_supplier(db: Session, supplier_data: dict) -> Supplier:
        """Create a new supplier"""
        new_supplier = Supplier(**supplier_data)
        db.add(new_supplier)
        db.commit()
        db.refresh(new_supplier)
        return new_supplier
    
    @staticmethod
    def create_purchase_bill(db: Session, bill_data: dict) -> PurchaseBill:
        """Create a new purchase bill"""
        if 'bill_number' not in bill_data:
            bill_data['bill_number'] = PurchaseService.generate_bill_number()
        
        new_bill = PurchaseBill(**bill_data)
        db.add(new_bill)
        db.commit()
        db.refresh(new_bill)
        return new_bill
    
    @staticmethod
    def create_purchase_return(db: Session, return_data: dict) -> PurchaseReturn:
        """Create a new purchase return"""
        if 'return_number' not in return_data:
            return_data['return_number'] = PurchaseService.generate_return_number()
        
        new_return = PurchaseReturn(**return_data)
        db.add(new_return)
        db.commit()
        db.refresh(new_return)
        return new_return
