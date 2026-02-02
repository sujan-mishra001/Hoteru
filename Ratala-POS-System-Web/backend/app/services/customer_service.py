"""
Customer management service
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.customers import Customer
from app.schemas import CustomerCreate, CustomerUpdate


class CustomerService:
    """Service for customer operations"""
    
    @staticmethod
    def get_all_customers(db: Session) -> List[Customer]:
        """Get all customers"""
        return db.query(Customer).all()
    
    @staticmethod
    def get_customer_by_id(db: Session, customer_id: int) -> Optional[Customer]:
        """Get customer by ID"""
        return db.query(Customer).filter(Customer.id == customer_id).first()
    
    @staticmethod
    def create_customer(db: Session, customer_data: CustomerCreate) -> Customer:
        """Create a new customer"""
        new_customer = Customer(**customer_data.dict())
        db.add(new_customer)
        db.commit()
        db.refresh(new_customer)
        return new_customer
    
    @staticmethod
    def update_customer(db: Session, customer_id: int, customer_data: CustomerUpdate) -> Optional[Customer]:
        """Update a customer"""
        customer = db.query(Customer).filter(Customer.id == customer_id).first()
        if not customer:
            return None
        
        update_data = customer_data.dict(exclude_unset=True)
        for key, value in update_data.items():
            setattr(customer, key, value)
        
        db.commit()
        db.refresh(customer)
        return customer
    
    @staticmethod
    def delete_customer(db: Session, customer_id: int) -> bool:
        """Delete a customer"""
        customer = db.query(Customer).filter(Customer.id == customer_id).first()
        if not customer:
            return False
        
        db.delete(customer)
        db.commit()
        return True
