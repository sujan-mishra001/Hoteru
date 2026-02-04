"""
Settings-related models (Company Settings, Payment Modes, etc.)
"""
from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, Text
from datetime import datetime
from app.db.database import Base


class CompanySettings(Base):
    """Company/Restaurant settings model"""
    __tablename__ = "company_settings"
    
    id = Column(Integer, primary_key=True, index=True)
    company_name = Column(String, nullable=False)
    email = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    address = Column(String, nullable=True)
    vat_pan_no = Column(String, nullable=True)
    registration_no = Column(String, nullable=True)
    start_date = Column(String, nullable=True)
    logo_url = Column(String, nullable=True)
    
    # Invoice settings
    invoice_prefix = Column(String, default="INV")
    invoice_footer_text = Column(Text, nullable=True)
    show_vat_on_invoice = Column(Boolean, default=True)
    
    # Other settings
    currency = Column(String, default="NPR")
    timezone = Column(String, default="Asia/Kathmandu")
    tax_rate = Column(Float, default=13.0)
    service_charge_rate = Column(Float, default=10.0)
    discount_rate = Column(Float, default=0.0)
    
    # User Preferences (synchronized with backend for multi-device consistency)
    notifications_enabled = Column(Boolean, default=True)
    sound_enabled = Column(Boolean, default=True)
    vibration_enabled = Column(Boolean, default=True)
    auto_print = Column(Boolean, default=False)
    dark_mode = Column(Boolean, default=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class PaymentMode(Base):
    """Payment modes available in the restaurant"""
    __tablename__ = "payment_modes"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)  # Cash, Fonepay, Credit Card, etc.
    is_active = Column(Boolean, default=True)
    display_order = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class StorageArea(Base):
    """Storage areas for inventory"""
    __tablename__ = "storage_areas"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, unique=True)
    description = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class DiscountRule(Base):
    """Discount rules configuration"""
    __tablename__ = "discount_rules"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    discount_type = Column(String, nullable=False)  # Percentage, Fixed Amount
    discount_value = Column(Float, nullable=False)
    is_active = Column(Boolean, default=True)
    min_order_amount = Column(Float, default=0)
    max_discount_amount = Column(Float, nullable=True)
    applicable_on = Column(String, default="All")  # All, Dine-In, Takeaway, Delivery
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
