"""
Delivery-related models
"""
from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from app.database import Base


class DeliveryPartner(Base):
    """Delivery partner model"""
    __tablename__ = "delivery_partners"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    phone = Column(String, nullable=True)
    vehicle_number = Column(String, nullable=True)
    status = Column(String, default="Active")
    created_at = Column(DateTime, default=datetime.utcnow)
