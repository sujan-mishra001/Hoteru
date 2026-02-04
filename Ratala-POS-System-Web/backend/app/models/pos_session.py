from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base

class POSSession(Base):
    """
    POS Session (Staff Shift / Business Run) model.
    The core of the operational flow. All transactions are tied here.
    """
    __tablename__ = "pos_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True) # If multi-branch
    
    start_time = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    end_time = Column(DateTime(timezone=True), nullable=True)
    
    status = Column(String, default="Open")  # Open, Closed
    
    opening_cash = Column(Float, default=0.0)
    actual_cash = Column(Float, default=0.0) # Ground truth entered by staff on close
    expected_cash = Column(Float, default=0.0) # Calculated system expectation
    
    # Sales Summaries (calculated/snapshot on close)
    total_sales = Column(Float, default=0.0)
    cash_sales = Column(Float, default=0.0)
    online_sales = Column(Float, default=0.0) # Card, Esewa, etc.
    credit_sales = Column(Float, default=0.0)
    
    discount_total = Column(Float, default=0.0)
    net_total = Column(Float, default=0.0)
    
    total_orders = Column(Integer, default=0)
    
    notes = Column(Text, nullable=True)
    report_path = Column(String, nullable=True) # PDF report location
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="pos_sessions")
    # orders = relationship("Order", back_populates="pos_session")
    # transactions = relationship("InventoryTransaction", back_populates="pos_session")
