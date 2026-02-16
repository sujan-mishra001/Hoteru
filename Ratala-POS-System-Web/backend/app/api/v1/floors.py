"""
Floor management routes with branch isolation
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.core.dependencies import get_current_user, check_admin_role, get_branch_id
from app.models import Floor, Branch

router = APIRouter()


def apply_branch_filter(db: Session, query, branch_id):
    """Apply branch_id filter if branch_id is set and model has branch_id column"""
    if branch_id is not None:
        query = query.filter(Floor.branch_id == branch_id)
    return query


@router.get("")
async def get_floors(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all floors for the branch, ordered by display_order"""
    floors = db.query(Floor).filter(
        Floor.is_active == True,
        Floor.branch_id == branch_id
    ).order_by(Floor.display_order).all()
    return floors


@router.get("/{floor_id}")
async def get_floor(
    floor_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get floor by ID, filtered by branch"""
    floor = db.query(Floor).filter(
        Floor.id == floor_id,
        Floor.branch_id == branch_id
    ).first()
    if not floor:
        raise HTTPException(status_code=404, detail="Floor not found")
    return floor


@router.post("")
async def create_floor(
    floor_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(check_admin_role),
    branch_id: int = Depends(get_branch_id)
):
    """Create a new floor in the branch (Admin only)"""
    # Check if floor name already exists in the branch
    existing = db.query(Floor).filter(
        Floor.name == floor_data.get('name'),
        Floor.branch_id == branch_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Floor name already exists in this branch")
    
    # Get max display_order for the branch
    max_order = db.query(Floor).filter(
        Floor.branch_id == branch_id
    ).order_by(Floor.display_order.desc()).first()
    
    floor_data['display_order'] = (max_order.display_order + 1) if max_order else 0
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
    current_user = Depends(check_admin_role),
    branch_id: int = Depends(get_branch_id)
):
    """Update a floor in the branch (Admin only)"""
    # Get floor filtered by branch
    floor = db.query(Floor).filter(
        Floor.id == floor_id,
        Floor.branch_id == branch_id
    ).first()
    if not floor:
        raise HTTPException(status_code=404, detail="Floor not found or access denied")
    
    # Check if new name conflicts with existing in the branch
    if 'name' in floor_data and floor_data['name'] != floor.name:
        existing = db.query(Floor).filter(
            Floor.name == floor_data['name'],
            Floor.branch_id == branch_id
        ).first()
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
    current_user = Depends(check_admin_role),
    branch_id: int = Depends(get_branch_id)
):
    """Delete a floor in the branch (Admin only) - sets is_active to False"""
    # Get floor filtered by branch
    floor = db.query(Floor).filter(
        Floor.id == floor_id,
        Floor.branch_id == branch_id
    ).first()
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
    current_user = Depends(check_admin_role),
    branch_id: int = Depends(get_branch_id)
):
    """Reorder a floor in the branch (Admin only)"""
    # Get floor filtered by branch
    floor = db.query(Floor).filter(
        Floor.id == floor_id,
        Floor.branch_id == branch_id
    ).first()
    if not floor:
        raise HTTPException(status_code=404, detail="Floor not found or access denied")
    
    floor.display_order = new_order
    db.commit()
    db.refresh(floor)
    return floor
