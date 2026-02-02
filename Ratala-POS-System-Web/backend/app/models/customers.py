"""
Customer models
"""
from sqlalchemy import Column, Integer, String, DateTime, Float
from datetime import datetime
from app.database import Base


class Customer(Base):
    """Customer model"""
    __tablename__ = "customers"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    phone = Column(String, nullable=True)
    email = Column(String, nullable=True)
    address = Column(String, nullable=True)
    customer_type = Column(String, default="Regular")  # VIP, Regular, New, Corporate
    total_spent = Column(Float, default=0.0)
    total_visits = Column(Integer, default=0)
    due_amount = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
