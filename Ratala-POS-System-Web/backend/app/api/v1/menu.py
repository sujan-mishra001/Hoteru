"""
Menu management routes
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import MenuItem, Category, MenuGroup
from app.schemas import MenuItemCreate

router = APIRouter()


@router.get("/items")
async def get_menu_items(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all menu items"""
    items = db.query(MenuItem).all()
    return items


@router.post("/items")
async def create_menu_item(
    item_data: MenuItemCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new menu item"""
    new_item = MenuItem(**item_data.dict())
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    return new_item


@router.get("/categories")
async def get_categories(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all categories"""
    categories = db.query(Category).all()
    return categories


@router.post("/categories")
async def create_category(
    category_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new category"""
    new_category = Category(**category_data)
    db.add(new_category)
    db.commit()
    db.refresh(new_category)
    return new_category


@router.get("/groups")
async def get_groups(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all menu groups"""
    groups = db.query(MenuGroup).all()
    return groups


@router.post("/groups")
async def create_group(
    group_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new menu group"""
    new_group = MenuGroup(**group_data)
    db.add(new_group)
    db.commit()
    db.refresh(new_group)
    return new_group


@router.put("/items/{item_id}")
async def update_menu_item(
    item_id: int,
    item_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a menu item"""
    item = db.query(MenuItem).filter(MenuItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found")
    
    for key, value in item_data.items():
        if hasattr(item, key):
            setattr(item, key, value)
    
    db.commit()
    db.refresh(item)
    return item


@router.put("/items/bulk-update")
async def bulk_update_menu_items(
    updates: list[dict] = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Bulk update menu items (e.g., for price updates)
    
    Example:
    [
        {"id": 1, "price": 150},
        {"id": 2, "price": 200}
    ]
    """
    updated_items = []
    
    for update in updates:
        item_id = update.get("id")
        if not item_id:
            continue
        
        item = db.query(MenuItem).filter(MenuItem.id == item_id).first()
        if not item:
            continue
        
        for key, value in update.items():
            if key != "id" and hasattr(item, key):
                setattr(item, key, value)
        
        updated_items.append(item)
    
    db.commit()
    
    for item in updated_items:
        db.refresh(item)
    
    return {"updated_count": len(updated_items), "items": updated_items}


@router.delete("/items/{item_id}")
async def delete_menu_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Delete a menu item"""
    item = db.query(MenuItem).filter(MenuItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found")
    
    db.delete(item)
    db.commit()
    return {"message": "Menu item deleted"}


@router.put("/categories/{category_id}")
async def update_category(
    category_id: int,
    category_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a category"""
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    for key, value in category_data.items():
        if hasattr(category, key):
            setattr(category, key, value)
    
    db.commit()
    db.refresh(category)
    return category


@router.delete("/categories/{category_id}")
async def delete_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Delete a category"""
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    db.delete(category)
    db.commit()
    return {"message": "Category deleted"}


@router.put("/groups/{group_id}")
async def update_group(
    group_id: int,
    group_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a menu group"""
    group = db.query(MenuGroup).filter(MenuGroup.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Menu group not found")
    
    for key, value in group_data.items():
        if hasattr(group, key):
            setattr(group, key, value)
    
    db.commit()
    db.refresh(group)
    return group


@router.delete("/groups/{group_id}")
async def delete_group(
    group_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Delete a menu group"""
    group = db.query(MenuGroup).filter(MenuGroup.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Menu group not found")
    
    db.delete(group)
    db.commit()
    return {"message": "Menu group deleted"}

