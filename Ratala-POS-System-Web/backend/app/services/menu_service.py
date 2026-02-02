"""
Menu management service
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.menu import Category, MenuGroup, MenuItem


class MenuService:
    """Service for menu operations"""
    
    # Category operations
    @staticmethod
    def get_all_categories(db: Session) -> List[Category]:
        """Get all categories"""
        return db.query(Category).all()
    
    @staticmethod
    def create_category(db: Session, category_data: dict) -> Category:
        """Create a new category"""
        new_category = Category(**category_data)
        db.add(new_category)
        db.commit()
        db.refresh(new_category)
        return new_category
    
    # Menu Group operations
    @staticmethod
    def get_all_groups(db: Session) -> List[MenuGroup]:
        """Get all menu groups"""
        return db.query(MenuGroup).all()
    
    @staticmethod
    def create_group(db: Session, group_data: dict) -> MenuGroup:
        """Create a new menu group"""
        new_group = MenuGroup(**group_data)
        db.add(new_group)
        db.commit()
        db.refresh(new_group)
        return new_group
    
    # Menu Item operations
    @staticmethod
    def get_all_menu_items(db: Session) -> List[MenuItem]:
        """Get all menu items"""
        return db.query(MenuItem).all()
    
    @staticmethod
    def get_menu_item_by_id(db: Session, item_id: int) -> Optional[MenuItem]:
        """Get menu item by ID"""
        return db.query(MenuItem).filter(MenuItem.id == item_id).first()
    
    @staticmethod
    def create_menu_item(db: Session, item_data: dict) -> MenuItem:
        """Create a new menu item"""
        new_item = MenuItem(**item_data)
        db.add(new_item)
        db.commit()
        db.refresh(new_item)
        return new_item
    
    @staticmethod
    def update_menu_item(db: Session, item_id: int, item_data: dict) -> Optional[MenuItem]:
        """Update a menu item"""
        item = db.query(MenuItem).filter(MenuItem.id == item_id).first()
        if not item:
            return None
        
        for key, value in item_data.items():
            setattr(item, key, value)
        
        db.commit()
        db.refresh(item)
        return item
