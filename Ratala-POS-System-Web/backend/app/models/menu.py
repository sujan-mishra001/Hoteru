"""
Menu-related models (Categories, Menu Groups, Menu Items)
"""
from sqlalchemy import Column, Integer, String, Boolean, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base


class Category(Base):
    """Menu category model"""
    __tablename__ = "categories"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    type = Column(String, nullable=False)  # KOT or BOT
    image = Column(String, nullable=True)
    description = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.now)


class MenuGroup(Base):
    """Menu group model"""
    __tablename__ = "menu_groups"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"))
    image = Column(String, nullable=True)
    description = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.now)
    
    category = relationship("Category")


class MenuItem(Base):
    """Menu item model"""
    __tablename__ = "menu_items"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"))
    group_id = Column(Integer, ForeignKey("menu_groups.id"), nullable=True)
    price = Column(Float, nullable=False)
    image = Column(String, nullable=True)
    description = Column(String, nullable=True)
    inventory_tracking = Column(Boolean, default=False)
    kot_bot = Column(String, nullable=False)  # KOT or BOT
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    category = relationship("Category")
    group = relationship("MenuGroup")
