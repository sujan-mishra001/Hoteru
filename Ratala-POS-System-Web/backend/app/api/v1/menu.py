"""
Menu management routes with branch isolation
"""
from fastapi import APIRouter, Depends, HTTPException, Body, File, UploadFile
from sqlalchemy.orm import Session
import os
import uuid
import shutil

from app.db.database import get_db
from app.core.dependencies import get_current_user, get_branch_id
from app.models import MenuItem, Category, MenuGroup, Branch
from typing import List
from app.schemas import (
    MenuItemCreate, MenuItemResponse, 
    CategoryResponse, MenuGroupResponse,
    BulkMenuItemUpdateResponse
)

router = APIRouter()


def apply_branch_filter_menu(query, model, branch_id):
    """Apply branch_id filter if branch_id is set and model has branch_id column"""
    if branch_id is not None and hasattr(model, 'branch_id'):
        query = query.filter(model.branch_id == branch_id)
    return query


@router.get("/public-items", response_model=List[MenuItemResponse])
async def get_public_menu_items(
    branch_id: int | None = None,
    db: Session = Depends(get_db)
):
    """Publicly accessible menu items - strictly branch-based"""
    if not branch_id:
        return []
    
    query = db.query(MenuItem).filter(MenuItem.is_active == True)
    query = query.filter(MenuItem.branch_id == branch_id)
    return query.all()


@router.get("/public-categories", response_model=List[CategoryResponse])
async def get_public_categories(
    branch_id: int | None = None,
    db: Session = Depends(get_db)
):
    """Publicly accessible categories - strictly branch-based"""
    if not branch_id:
        return []
        
    query = db.query(Category).filter(Category.is_active == True)
    query = query.filter(Category.branch_id == branch_id)
    return query.all()


@router.get("/items", response_model=List[MenuItemResponse])
async def get_menu_items(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all menu items for the branch"""
    query = db.query(MenuItem).filter(MenuItem.is_active == True, MenuItem.branch_id == branch_id)
    menu_items = query.all()
    # Explicit mapping not needed due to Pydantic from_attributes=True, but safer
    return menu_items


@router.post("/items")
async def create_menu_item(
    item_data: MenuItemCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Create a new menu item in the branch"""
    item_dict = item_data.dict()
    item_dict['branch_id'] = branch_id
    
    new_item = MenuItem(**item_dict)
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    return new_item


@router.get("/categories")
async def get_categories(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all categories for the branch"""
    query = db.query(Category).filter(Category.is_active == True, Category.branch_id == branch_id)
    categories = query.all()
    return categories


@router.post("/categories")
async def create_category(
    category_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Create a new category in the branch"""
    category_data['branch_id'] = branch_id
    
    new_category = Category(**category_data)
    db.add(new_category)
    db.commit()
    db.refresh(new_category)
    return new_category


@router.get("/groups")
async def get_groups(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all menu groups for the branch"""
    query = db.query(MenuGroup).filter(MenuGroup.is_active == True, MenuGroup.branch_id == branch_id)
    groups = query.all()
    return groups


@router.post("/groups")
async def create_group(
    group_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Create a new menu group in the branch"""
    group_data['branch_id'] = branch_id
    
    new_group = MenuGroup(**group_data)
    db.add(new_group)
    db.commit()
    db.refresh(new_group)
    return new_group


@router.put("/items/bulk-update", response_model=BulkMenuItemUpdateResponse)
async def bulk_update_menu_items(
    updates: list[dict] = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
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
        
        item = db.query(MenuItem).filter(MenuItem.id == item_id, MenuItem.branch_id == branch_id).first()
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


@router.put("/items/{item_id}", response_model=MenuItemResponse)
@router.patch("/items/{item_id}", response_model=MenuItemResponse)
async def update_menu_item(
    item_id: int,
    item_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Update a menu item in the branch"""
    query = db.query(MenuItem).filter(MenuItem.id == item_id, MenuItem.branch_id == branch_id)
    item = query.first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found or access denied")
    
    for key, value in item_data.items():
        if hasattr(item, key) and key != 'branch_id':
            setattr(item, key, value)
    
    db.commit()
    db.refresh(item)
    return item


@router.delete("/items/{item_id}")
async def delete_menu_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Soft delete a menu item (mark as inactive)"""
    query = db.query(MenuItem).filter(MenuItem.id == item_id, MenuItem.branch_id == branch_id)
    item = query.first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found or access denied")
    
    item.is_active = False
    db.commit()
    return {"message": "Menu item deleted"}


@router.post("/items/{item_id}/image", response_model=MenuItemResponse)
async def upload_menu_item_image(
    item_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Upload and update image for a menu item"""
    query = db.query(MenuItem).filter(MenuItem.id == item_id, MenuItem.branch_id == branch_id)
    item = query.first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found or access denied")
        
    # Save to database (Binary)
    try:
        content = await file.read()
        item.image_data = content
        item.image = f"/api/v1/images/menu-items/{item_id}"
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not read file: {str(e)}")
        
    db.commit()
    db.refresh(item)
    
    return item


@router.post("/categories/{category_id}/image", response_model=CategoryResponse)
async def upload_category_image(
    category_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Upload and update image for a category"""
    query = db.query(Category).filter(Category.id == category_id, Category.branch_id == branch_id)
    category = query.first()
    
    if not category:
        raise HTTPException(status_code=404, detail="Category not found or access denied")
        
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
        
    try:
        content = await file.read()
        category.image_data = content
        category.image = f"/api/v1/images/categories/{category_id}"
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not read file: {str(e)}")
        
    db.commit()
    db.refresh(category)
    return category


@router.post("/groups/{group_id}/image", response_model=MenuGroupResponse)
async def upload_group_image(
    group_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Upload and update image for a menu group"""
    # branch_id is now provided by dependency
    
    query = db.query(MenuGroup).filter(MenuGroup.id == group_id, MenuGroup.branch_id == branch_id)
    group = query.first()
    
    if not group:
        raise HTTPException(status_code=404, detail="Menu group not found or access denied")
        
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
        
    try:
        content = await file.read()
        group.image_data = content
        group.image = f"/api/v1/images/groups/{group_id}"
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not read file: {str(e)}")
        
    db.commit()
    db.refresh(group)
    return group


@router.put("/categories/{category_id}", response_model=CategoryResponse)
@router.patch("/categories/{category_id}", response_model=CategoryResponse)
async def update_category(
    category_id: int,
    category_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Update a category in the branch"""
    query = db.query(Category).filter(Category.id == category_id, Category.branch_id == branch_id)
    category = query.first()
    
    if not category:
        raise HTTPException(status_code=404, detail="Category not found or access denied")
    
    for key, value in category_data.items():
        if hasattr(category, key) and key != 'branch_id':
            setattr(category, key, value)
    
    db.commit()
    db.refresh(category)
    return category


@router.delete("/categories/{category_id}")
async def delete_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Soft delete a category and its items/groups"""
    query = db.query(Category).filter(Category.id == category_id, Category.branch_id == branch_id)
    category = query.first()
    
    if not category:
        raise HTTPException(status_code=404, detail="Category not found or access denied")
    
    category.is_active = False
    
    # Also soft delete groups and items in this category
    db.query(MenuGroup).filter(MenuGroup.category_id == category_id).update({"is_active": False})
    db.query(MenuItem).filter(MenuItem.category_id == category_id).update({"is_active": False})
    
    db.commit()
    return {"message": "Category and associated items deleted"}


@router.put("/groups/{group_id}", response_model=MenuGroupResponse)
@router.patch("/groups/{group_id}", response_model=MenuGroupResponse)
async def update_group(
    group_id: int,
    group_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Update a menu group in the branch"""
    query = db.query(MenuGroup).filter(MenuGroup.id == group_id, MenuGroup.branch_id == branch_id)
    group = query.first()
    
    if not group:
        raise HTTPException(status_code=404, detail="Menu group not found or access denied")
    
    for key, value in group_data.items():
        if hasattr(group, key) and key != 'branch_id':
            setattr(group, key, value)
    
    db.commit()
    db.refresh(group)
    return group


@router.delete("/groups/{group_id}")
async def delete_group(
    group_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Soft delete a menu group and its items"""
    query = db.query(MenuGroup).filter(MenuGroup.id == group_id, MenuGroup.branch_id == branch_id)
    group = query.first()
    
    if not group:
        raise HTTPException(status_code=404, detail="Menu group not found or access denied")
    
    group.is_active = False
    
    # Also soft delete items in this group
    db.query(MenuItem).filter(MenuItem.group_id == group_id).update({"is_active": False})
    
    db.commit()
    return {"message": "Menu group and associated items deleted"}

