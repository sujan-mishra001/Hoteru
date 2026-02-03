"""
Floor management routes with branch isolation
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.dependencies import get_current_user, check_admin_role
from app.models import Floor

router = APIRouter()


def apply_branch_filter(db: Session, query, branch_id):
    """Apply branch_id filter if branch_id is set and model has branch_id column"""
    if branch_id is not None:
        query = query.filter(Floor.branch_id == branch_id)
    return query


@router.get("")
async def get_floors(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all floors for the current user's branch, ordered by display_order"""
    branch_id = current_user.current_branch_id
    query = db.query(Floor).filter(Floor.is_active == True)
    query = apply_branch_filter(db, query, branch_id)
    floors = query.order_by(Floor.display_order).all()
    return floors


@router.get("/{floor_id}")
async def get_floor(
    floor_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get floor by ID, filtered by user's branch"""
    branch_id = current_user.current_branch_id
    query = db.query(Floor).filter(Floor.id == floor_id)
    query = apply_branch_filter(db, query, branch_id)
    floor = query.first()
    if not floor:
        raise HTTPException(status_code=404, detail="Floor not found")
    return floor


@router.post("")
async def create_floor(
    floor_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(check_admin_role)
):
    """Create a new floor in the user's current branch (Admin only)"""
    branch_id = current_user.current_branch_id
    
    # Check if floor name already exists in the branch (or globally if branch_id is None)
    query = db.query(Floor).filter(Floor.name == floor_data.get('name'))
    query = apply_branch_filter(db, query, branch_id)
    existing = query.first()
    if existing:
        raise HTTPException(status_code=400, detail="Floor name already exists in this branch")
    
    # Get max display_order for the branch
    query = db.query(Floor)
    query = apply_branch_filter(db, query, branch_id)
    max_order = query.order_by(Floor.display_order.desc()).first()
    floor_data['display_order'] = (max_order.display_order + 1) if max_order else 0
    
    # Set branch_id for the new floor
    if branch_id is not None:
        floor_data['branch_id'] = branch_id
    
    new_floor = Floor(**floor_data)
    db.add(new_floor)
    db.commit()
    db.refresh(new_floor)
    return new_floor


@router.put("/{floor_id}")
@router.patch("/{floor_id}")
async def update_floor(
    floor_id: int,
    floor_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(check_admin_role)
):
    """Update a floor in the user's current branch (Admin only)"""
    branch_id = current_user.current_branch_id
    
    # Get floor filtered by branch
    query = db.query(Floor).filter(Floor.id == floor_id)
    query = apply_branch_filter(db, query, branch_id)
    floor = query.first()
    if not floor:
        raise HTTPException(status_code=404, detail="Floor not found or access denied")
    
    # Check if new name conflicts with existing in the branch
    if 'name' in floor_data and floor_data['name'] != floor.name:
        query = db.query(Floor).filter(Floor.name == floor_data['name'])
        query = apply_branch_filter(db, query, branch_id)
        existing = query.first()
        if existing:
            raise HTTPException(status_code=400, detail="Floor name already exists in this branch")
    
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
    """Delete a floor in the user's current branch (Admin only) - sets is_active to False"""
    branch_id = current_user.current_branch_id
    
    # Get floor filtered by branch
    query = db.query(Floor).filter(Floor.id == floor_id)
    query = apply_branch_filter(db, query, branch_id)
    floor = query.first()
    if not floor:
        raise HTTPException(status_code=404, detail="Floor not found or access denied")
    
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
    """Reorder a floor in the user's current branch (Admin only)"""
    branch_id = current_user.current_branch_id
    
    # Get floor filtered by branch
    query = db.query(Floor).filter(Floor.id == floor_id)
    query = apply_branch_filter(db, query, branch_id)
    floor = query.first()
    if not floor:
        raise HTTPException(status_code=404, detail="Floor not found or access denied")
    
    floor.display_order = new_order
    db.commit()
    db.refresh(floor)
    return floor
