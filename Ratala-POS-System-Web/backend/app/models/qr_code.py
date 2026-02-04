"""
QR Code Management Model
"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base


class QRCode(Base):
    """QR Code model for payment methods"""
    __tablename__ = "qr_codes"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)  # e.g., "Fonepay", "eSewa", "Khalti"
    image_url = Column(String, nullable=False)  # URL to the uploaded QR code image
    is_active = Column(Boolean, default=True)
    display_order = Column(Integer, default=0)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True)  # Optional: QR per branch
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship
    branch = relationship("Branch", back_populates="qr_codes")
