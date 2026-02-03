"""
KOT (Kitchen Order Ticket) and BOT (Bar Order Ticket) management routes with branch isolation
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
import random

from app.database import get_db
from app.dependencies import get_current_user
from app.models import KOT, Order, KOTItem
from sqlalchemy.orm import joinedload

router = APIRouter()


@router.get("")
async def get_kots(
    kot_type: Optional[str] = None,  # KOT or BOT
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all KOTs/BOTs for the current user's branch, optionally filtered by type and status"""
    branch_id = current_user.current_branch_id
    
    query = db.query(KOT).options(
        joinedload(KOT.order).joinedload(Order.table),
        joinedload(KOT.items).joinedload(KOTItem.menu_item),
        joinedload(KOT.user)
    ).join(Order)
    
    # Filter by branch_id for data isolation
    if branch_id:
        query = query.filter(Order.branch_id == branch_id)
    
    if kot_type:
        query = query.filter(KOT.kot_type == kot_type)
    if status:
        query = query.filter(KOT.status == status)
    
    kots = query.order_by(KOT.created_at.desc()).all()
    return kots


@router.get("/{kot_id}")
async def get_kot(
    kot_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get KOT by ID, filtered by user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(KOT).options(
        joinedload(KOT.order).joinedload(Order.table),
        joinedload(KOT.items).joinedload(KOTItem.menu_item),
        joinedload(KOT.user)
    ).filter(KOT.id == kot_id)
    
    # Filter by branch_id for data isolation
    if branch_id:
        query = query.join(Order).filter(Order.branch_id == branch_id)
    
    kot = query.first()
    
    if not kot:
        raise HTTPException(status_code=404, detail="KOT not found or access denied")
    return kot


@router.post("")
async def create_kot(
    kot_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new KOT or BOT"""
    items_data = kot_data.pop('items', [])
    
    # Generate KOT number if not provided
    if 'kot_number' not in kot_data:
        kot_type = kot_data.get('kot_type', 'KOT')
        prefix = 'KOT' if kot_type == 'KOT' else 'BOT'
        kot_data['kot_number'] = f"{prefix}-{datetime.now().strftime('%Y%m%d')}-{random.randint(1000, 9999)}"
    
    kot_data['created_by'] = current_user.id
    
    new_kot = KOT(**kot_data)
    db.add(new_kot)
    db.flush()
    
    # Add items
    for item in items_data:
        kot_item = KOTItem(
            kot_id=new_kot.id,
            menu_item_id=item['menu_item_id'],
            quantity=item['quantity'],
            notes=item.get('notes', '')
        )
        db.add(kot_item)
        
    db.commit()
    db.refresh(new_kot)
    return new_kot


@router.put("/{kot_id}")
async def update_kot(
    kot_id: int,
    kot_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a KOT/BOT in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(KOT).filter(KOT.id == kot_id)
    if branch_id:
        query = query.join(Order).filter(Order.branch_id == branch_id)
    kot = query.first()
    
    if not kot:
        raise HTTPException(status_code=404, detail="KOT not found or access denied")
    
    for key, value in kot_data.items():
        setattr(kot, key, value)
    
    db.commit()
    db.refresh(kot)
    return kot


@router.put("/{kot_id}/status")
async def update_kot_status(
    kot_id: int,
    status: str = Body(..., embed=True),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update KOT/BOT status in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(KOT).filter(KOT.id == kot_id)
    if branch_id:
        query = query.join(Order).filter(Order.branch_id == branch_id)
    kot = query.first()
    
    if not kot:
        raise HTTPException(status_code=404, detail="KOT not found or access denied")
    
    kot.status = status
    db.commit()
    db.refresh(kot)
    return kot
