"""
Purchase-related models (Suppliers, Purchase Bills, Purchase Returns)
"""
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base


class Supplier(Base):
    """Supplier model"""
    __tablename__ = "suppliers"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    contact_person = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    email = Column(String, nullable=True)
    address = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class PurchaseBill(Base):
    """Purchase bill model"""
    __tablename__ = "purchase_bills"
    
    id = Column(Integer, primary_key=True, index=True)
    bill_number = Column(String, unique=True, nullable=False)
    supplier_id = Column(Integer, ForeignKey("suppliers.id"))
    total_amount = Column(Float, nullable=False)
    status = Column(String, default="Pending")  # Pending, Paid
    order_date = Column(DateTime, default=datetime.utcnow)
    paid_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    supplier = relationship("Supplier")


class PurchaseReturn(Base):
    """Purchase return model"""
    __tablename__ = "purchase_returns"
    
    id = Column(Integer, primary_key=True, index=True)
    return_number = Column(String, unique=True, nullable=False)
    purchase_bill_id = Column(Integer, ForeignKey("purchase_bills.id"))
    supplier_id = Column(Integer, ForeignKey("suppliers.id"), nullable=True) # Direct link to supplier
    total_amount = Column(Float, nullable=False)
    reason = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    purchase_bill = relationship("PurchaseBill", back_populates="returns")
    supplier = relationship("Supplier")

# Add back_populates to PurchaseBill
PurchaseBill.returns = relationship("PurchaseReturn", back_populates="purchase_bill", cascade="all, delete-orphan")
