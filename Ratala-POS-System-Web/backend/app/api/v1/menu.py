"""
Menu management routes with branch isolation
"""
from fastapi import APIRouter, Depends, HTTPException, Body, File, UploadFile
from sqlalchemy.orm import Session
import os
import uuid
import shutil

from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.models import MenuItem, Category, MenuGroup
from app.schemas import MenuItemCreate

router = APIRouter()


def apply_branch_filter_menu(query, model, branch_id):
    """Apply branch_id filter if branch_id is set and model has branch_id column"""
    if branch_id is not None and hasattr(model, 'branch_id'):
        query = query.filter(model.branch_id == branch_id)
    return query


@router.get("/public-items")
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


@router.get("/public-categories")
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


@router.get("/items")
async def get_menu_items(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all menu items for the current user's branch"""
    branch_id = current_user.current_branch_id
    query = db.query(MenuItem)
    query = apply_branch_filter_menu(query, MenuItem, branch_id)
    items = query.all()
    return items


@router.post("/items")
async def create_menu_item(
    item_data: MenuItemCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new menu item in the current user's branch"""
    branch_id = current_user.current_branch_id
    item_dict = item_data.dict()
    
    # Set branch_id for the new item
    if branch_id is not None:
        item_dict['branch_id'] = branch_id
    
    new_item = MenuItem(**item_dict)
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    return new_item


@router.get("/categories")
async def get_categories(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all categories for the current user's branch"""
    branch_id = current_user.current_branch_id
    query = db.query(Category)
    query = apply_branch_filter_menu(query, Category, branch_id)
    categories = query.all()
    return categories


@router.post("/categories")
async def create_category(
    category_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new category in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    # Set branch_id for the new category
    if branch_id is not None:
        category_data['branch_id'] = branch_id
    
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
    """Get all menu groups for the current user's branch"""
    branch_id = current_user.current_branch_id
    query = db.query(MenuGroup)
    query = apply_branch_filter_menu(query, MenuGroup, branch_id)
    groups = query.all()
    return groups


@router.post("/groups")
async def create_group(
    group_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new menu group in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    # Set branch_id for the new group
    if branch_id is not None:
        group_data['branch_id'] = branch_id
    
    new_group = MenuGroup(**group_data)
    db.add(new_group)
    db.commit()
    db.refresh(new_group)
    return new_group


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


@router.put("/items/{item_id}")
@router.patch("/items/{item_id}")
async def update_menu_item(
    item_id: int,
    item_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a menu item in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(MenuItem).filter(MenuItem.id == item_id)
    query = apply_branch_filter_menu(query, MenuItem, branch_id)
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
    current_user = Depends(get_current_user)
):
    """Delete a menu item in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(MenuItem).filter(MenuItem.id == item_id)
    query = apply_branch_filter_menu(query, MenuItem, branch_id)
    item = query.first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found or access denied")
    
    db.delete(item)
    db.commit()
    return {"message": "Menu item deleted"}


@router.post("/items/{item_id}/image")
async def upload_menu_item_image(
    item_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Upload and update image for a menu item"""
    branch_id = current_user.current_branch_id
    
    query = db.query(MenuItem).filter(MenuItem.id == item_id)
    query = apply_branch_filter_menu(query, MenuItem, branch_id)
    item = query.first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Menu item not found or access denied")
        
    # Create directory if it doesn't exist
    from pathlib import Path
    BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent
    upload_dir = BASE_DIR / "uploads" / "menu_items"
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    # Validate file type
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    # Generate unique filename
    extension = os.path.splitext(file.filename)[1]
    filename = f"{uuid.uuid4()}{extension}"
    file_path = upload_dir / filename
    
    # Save file
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not save file: {str(e)}")
        
    # Update menu item image path (relative to static files server)
    image_url = f"/uploads/menu_items/{filename}"
    item.image = image_url
    db.commit()
    db.refresh(item)
    
    return item


@router.put("/categories/{category_id}")
@router.patch("/categories/{category_id}")
async def update_category(
    category_id: int,
    category_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a category in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(Category).filter(Category.id == category_id)
    query = apply_branch_filter_menu(query, Category, branch_id)
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
    current_user = Depends(get_current_user)
):
    """Delete a category in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(Category).filter(Category.id == category_id)
    query = apply_branch_filter_menu(query, Category, branch_id)
    category = query.first()
    
    if not category:
        raise HTTPException(status_code=404, detail="Category not found or access denied")
    
    db.delete(category)
    db.commit()
    return {"message": "Category deleted"}


@router.put("/groups/{group_id}")
@router.patch("/groups/{group_id}")
async def update_group(
    group_id: int,
    group_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a menu group in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(MenuGroup).filter(MenuGroup.id == group_id)
    query = apply_branch_filter_menu(query, MenuGroup, branch_id)
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
    current_user = Depends(get_current_user)
):
    """Delete a menu group in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(MenuGroup).filter(MenuGroup.id == group_id)
    query = apply_branch_filter_menu(query, MenuGroup, branch_id)
    group = query.first()
    
    if not group:
        raise HTTPException(status_code=404, detail="Menu group not found or access denied")
    
    db.delete(group)
    db.commit()
    return {"message": "Menu group deleted"}

