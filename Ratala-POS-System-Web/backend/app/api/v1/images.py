from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models import MenuItem, Category, MenuGroup, CompanySettings, User
from typing import Optional

router = APIRouter(prefix="/images", tags=["images"])

@router.get("/menu-items/{item_id}")
async def get_menu_item_image(item_id: int, db: Session = Depends(get_db)):
    item = db.query(MenuItem).filter(MenuItem.id == item_id).first()
    if not item or not item.image_data:
        raise HTTPException(status_code=404, detail="Image not found")
    return Response(content=item.image_data, media_type="image/jpeg")

@router.get("/categories/{category_id}")
async def get_category_image(category_id: int, db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category or not category.image_data:
        raise HTTPException(status_code=404, detail="Image not found")
    return Response(content=category.image_data, media_type="image/jpeg")

@router.get("/groups/{group_id}")
async def get_group_image(group_id: int, db: Session = Depends(get_db)):
    group = db.query(MenuGroup).filter(MenuGroup.id == group_id).first()
    if not group or not group.image_data:
        raise HTTPException(status_code=404, detail="Image not found")
    return Response(content=group.image_data, media_type="image/jpeg")

@router.get("/company/logo")
async def get_company_logo(db: Session = Depends(get_db)):
    settings = db.query(CompanySettings).first()
    if not settings or not settings.logo_data:
        raise HTTPException(status_code=404, detail="Logo not found")
    return Response(content=settings.logo_data, media_type="image/jpeg")

@router.get("/users/{user_id}/profile")
async def get_user_profile_image(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.profile_image_data:
        raise HTTPException(status_code=404, detail="Image not found")
    return Response(content=user.profile_image_data, media_type="image/jpeg")
