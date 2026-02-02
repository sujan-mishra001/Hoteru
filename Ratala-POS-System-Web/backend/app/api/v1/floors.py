"""
Floor management routes
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.dependencies import get_current_user, check_admin_role
from app.models import Floor

router = APIRouter()


@router.get("")
async def get_floors(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all floors ordered by display_order"""
    floors = db.query(Floor).filter(Floor.is_active == True).order_by(Floor.display_order).all()
    return floors


@router.get("/{floor_id}")
async def get_floor(
    floor_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get floor by ID"""
    floor = db.query(Floor).filter(Floor.id == floor_id).first()
    if not floor:
        raise HTTPException(status_code=404, detail="Floor not found")
    return floor


@router.post("")
async def create_floor(
    floor_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(check_admin_role)
):
    """Create a new floor (Admin only)"""
    # Check if floor name already exists
    existing = db.query(Floor).filter(Floor.name == floor_data.get('name')).first()
    if existing:
        raise HTTPException(status_code=400, detail="Floor name already exists")
    
    # Get max display_order
    max_order = db.query(Floor).order_by(Floor.display_order.desc()).first()
    floor_data['display_order'] = (max_order.display_order + 1) if max_order else 0
    
    new_floor = Floor(**floor_data)
    db.add(new_floor)
    db.commit()
    db.refresh(new_floor)
    return new_floor


@router.put("/{floor_id}")
async def update_floor(
    floor_id: int,
    floor_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(check_admin_role)
):
    """Update a floor (Admin only)"""
    floor = db.query(Floor).filter(Floor.id == floor_id).first()
    if not floor:
        raise HTTPException(status_code=404, detail="Floor not found")
    
    # Check if new name conflicts with existing
    if 'name' in floor_data and floor_data['name'] != floor.name:
        existing = db.query(Floor).filter(Floor.name == floor_data['name']).first()
        if existing:
            raise HTTPException(status_code=400, detail="Floor name already exists")
    
    for key, value in floor_data.items():
        setattr(floor, key, value)
    
    db.commit()
    db.refresh(floor)
    return floor


@router.delete("/{floor_id}")
async def delete_floor(
    floor_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(check_admin_role)
):
    """Delete a floor (Admin only) - sets is_active to False"""
    floor = db.query(Floor).filter(Floor.id == floor_id).first()
    if not floor:
        raise HTTPException(status_code=404, detail="Floor not found")
    
    # Soft delete - set is_active to False
    floor.is_active = False
    db.commit()
    return {"message": "Floor deleted successfully"}


@router.put("/{floor_id}/reorder")
async def reorder_floor(
    floor_id: int,
    new_order: int = Body(..., embed=True),
    db: Session = Depends(get_db),
    current_user = Depends(check_admin_role)
):
    """Reorder a floor (Admin only)"""
    floor = db.query(Floor).filter(Floor.id == floor_id).first()
    if not floor:
        raise HTTPException(status_code=404, detail="Floor not found")
    
    floor.display_order = new_order
    db.commit()
    db.refresh(floor)
    return floor
