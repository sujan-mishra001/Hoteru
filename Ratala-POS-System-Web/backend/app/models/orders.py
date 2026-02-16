"""
Order-related models (Floors, Tables, Sessions, Orders, Order Items, KOTs)
"""
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.db.database import Base


class Floor(Base):
    """Floor model for restaurant floor management"""
    __tablename__ = "floors"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)  # e.g., "Ground Floor", "Rooftop"
    display_order = Column(Integer, default=0)  # For ordering floors in UI
    is_active = Column(Boolean, default=True)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    tables = relationship("Table", back_populates="floor_rel")

    __table_args__ = (
        UniqueConstraint('name', 'branch_id', name='uq_floor_name_branch'),
    )


class Table(Base):
    """Table model for restaurant tables"""
    __tablename__ = "tables"
    
    id = Column(Integer, primary_key=True, index=True)
    table_id = Column(String, nullable=False)  # Display name: T1, VIP2, etc.
    floor_id = Column(Integer, ForeignKey("floors.id"), nullable=True)
    floor = Column(String, nullable=True)  # Legacy field - made nullable
    table_type = Column(String, default="Regular")  # Regular, VIP, Outdoor
    capacity = Column(Integer, default=4)
    status = Column(String, default="Available")  # Available, Occupied, Reserved, BillRequested
    is_active = Column(Boolean, default=True)
    display_order = Column(Integer, default=0)
    is_hold_table = Column(String, default="No")  # Yes, No - for hold tables
    hold_table_name = Column(String, nullable=True)  # Unique name for hold table
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True, index=True)
    merged_to_id = Column(Integer, ForeignKey("tables.id"), nullable=True)
    merge_group_id = Column(String, nullable=True)  # e.g., "Merge_Table_1", "Merge_Table_2"
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    floor_rel = relationship("Floor", back_populates="tables")

    __table_args__ = (
        UniqueConstraint('table_id', 'branch_id', name='uq_table_id_branch'),
    )


class Session(Base):
    """Restaurant session model (e.g., Breakfast, Lunch, Dinner)"""
    __tablename__ = "sessions"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    start_time = Column(String, nullable=False)  # e.g., "09:00"
    end_time = Column(String, nullable=False)  # e.g., "17:00"
    status = Column(String, default="Active")
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class Order(Base):
    """Order model"""
    __tablename__ = "orders"
    
    id = Column(Integer, primary_key=True, index=True)
    order_number = Column(String, unique=True, nullable=False)
    table_id = Column(Integer, ForeignKey("tables.id"), nullable=True)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)
    order_type = Column(String, nullable=False)  # Table, Takeaway, Self Delivery, Delivery Partner, Pay First
    status = Column(String, default="Pending")  # Pending, In Progress, Completed, Cancelled, Paid
    total_amount = Column(Float, default=0)
    gross_amount = Column(Float, default=0)
    discount = Column(Float, default=0)
    net_amount = Column(Float, default=0)
    paid_amount = Column(Float, default=0)
    credit_amount = Column(Float, default=0)
    payment_type = Column(String, nullable=True)  # Cash, Fonepay, Credit Card, etc.
    service_charge_amount = Column(Float, default=0)
    tax_amount = Column(Float, default=0)
    delivery_charge = Column(Float, default=0)
    
    # Branch isolation
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True, index=True)
    
    # Meal Session (Breakfast/Lunch/Dinner)
    session_id = Column(Integer, ForeignKey("sessions.id"), nullable=True)
    
    # Operational Shift Session
    pos_session_id = Column(Integer, ForeignKey("pos_sessions.id"), nullable=True)
    
    # Delivery Partner
    delivery_partner_id = Column(Integer, ForeignKey("delivery_partners.id"), nullable=True)
    
    created_by = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    table = relationship("Table")
    customer = relationship("Customer")
    delivery_partner = relationship("DeliveryPartner")
    session = relationship("Session")
    pos_session = relationship("POSSession")
    user = relationship("User", backref="created_orders")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    kots = relationship("KOT", back_populates="order", cascade="all, delete-orphan")


class OrderItem(Base):
    """Order item model"""
    __tablename__ = "order_items"
    
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    menu_item_id = Column(Integer, ForeignKey("menu_items.id"))
    quantity = Column(Integer, nullable=False)
    price = Column(Float, nullable=False)
    subtotal = Column(Float, nullable=False)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    order = relationship("Order", back_populates="items")
    menu_item = relationship("MenuItem")


class KOT(Base):
    """Kitchen Order Ticket model (also handles BOT - Bar Order Ticket)"""
    __tablename__ = "kots"
    
    id = Column(Integer, primary_key=True, index=True)
    kot_number = Column(String, unique=True, nullable=False)
    order_id = Column(Integer, ForeignKey("orders.id"))
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True, index=True)
    kot_type = Column(String, default="KOT")  # KOT or BOT
    status = Column(String, default="Pending")  # Pending, In Progress, Ready, Served
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    order = relationship("Order", back_populates="kots")
    user = relationship("User", backref="created_kots")
    items = relationship("KOTItem", back_populates="kot", cascade="all, delete-orphan")


class KOTItem(Base):
    """KOT item model"""
    __tablename__ = "kot_items"
    
    id = Column(Integer, primary_key=True, index=True)
    kot_id = Column(Integer, ForeignKey("kots.id"))
    menu_item_id = Column(Integer, ForeignKey("menu_items.id"))
    quantity = Column(Integer, nullable=False)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    kot = relationship("KOT", back_populates="items")
    menu_item = relationship("MenuItem")
