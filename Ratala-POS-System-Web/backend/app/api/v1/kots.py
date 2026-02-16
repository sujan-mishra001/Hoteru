"""
KOT (Kitchen Order Ticket) and BOT (Bar Order Ticket) management routes with branch isolation
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload
from typing import Optional, List
from datetime import datetime, timezone
import random

from app.db.database import get_db
from app.core.dependencies import get_current_user, get_branch_id
from app.models import KOT, Order, KOTItem, MenuItem
from sqlalchemy.orm import joinedload
from fastapi import BackgroundTasks
from app.services.printing_service import PrintingService

from app.schemas.orders_customers import KOTResponse

router = APIRouter()


@router.get("", response_model=List[KOTResponse])
async def get_kots(
    kot_type: Optional[str] = None,  # KOT or BOT
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get all KOTs/BOTs for the branch, optionally filtered by type and status"""
    # branch_id is now provided by dependency
    
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


@router.get("/{kot_id}", response_model=KOTResponse)
async def get_kot(
    kot_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get KOT by ID, filtered by branch"""
    # branch_id is now provided by dependency
    
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


@router.post("", response_model=KOTResponse)
async def create_kot(
    background_tasks: BackgroundTasks,
    kot_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Create a new KOT or BOT"""
    items_data = kot_data.pop('items', [])
    
    # Generate KOT number if not provided
    if 'kot_number' not in kot_data:
        kot_type = kot_data.get('kot_type', 'KOT')
        prefix = 'KOT' if kot_type == 'KOT' else 'BOT'
        
        # Get today's start
        today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        today_str = datetime.now().strftime('%Y%m%d')
        kot_prefix = f"{prefix}-{today_str}-"
        
        while True:
            # Check globally across all branches for uniqueness if we've removed branch code
            last_kot = db.query(KOT).filter(
                KOT.kot_number.like(f"{kot_prefix}%")
            ).order_by(KOT.kot_number.desc()).first()
            
            seq = 1
            if last_kot:
                try:
                    parts = last_kot.kot_number.split('-')
                    if len(parts) >= 3:
                        seq = int(parts[-1]) + 1
                except (ValueError, IndexError):
                    pass
            
            kot_number = f"{kot_prefix}{seq:04d}"
            
            # Check if this number already exists
            existing = db.query(KOT).filter(KOT.kot_number == kot_number).first()
            if not existing:
                kot_data['kot_number'] = kot_number
                break
            
            # If exists, we continue loop which will find the new last_kot
    
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
    
    # Reload with relationships for printing
    kot = db.query(KOT).options(
        joinedload(KOT.order).joinedload(Order.table),
        joinedload(KOT.items).joinedload(KOTItem.menu_item).joinedload(MenuItem.bom),
        joinedload(KOT.user)
    ).filter(KOT.id == new_kot.id).first()

    # Background printing
    printing_service = PrintingService(db)
    if kot.kot_type == 'KOT':
        background_tasks.add_task(printing_service.print_kot, kot)
    else:
        background_tasks.add_task(printing_service.print_bot, kot)

    return kot


@router.put("/{kot_id}", response_model=KOTResponse)
async def update_kot(
    kot_id: int,
    kot_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Update a KOT/BOT in the branch"""
    # branch_id is now provided by dependency
    
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


@router.put("/{kot_id}/status", response_model=KOTResponse)
async def update_kot_status(
    kot_id: int,
    status: str = Body(..., embed=True),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Update KOT/BOT status in the branch"""
    # branch_id is now provided by dependency
    
    query = db.query(KOT).options(
        joinedload(KOT.items).joinedload(KOTItem.menu_item)
    ).filter(KOT.id == kot_id)
    if branch_id:
        query = query.join(Order).filter(Order.branch_id == branch_id)
    kot = query.first()
    
    if not kot:
        raise HTTPException(status_code=404, detail="KOT not found or access denied")
    
    old_status = kot.status
    kot.status = status
    
    # Deduct inventory when KOT is marked as Served
    if status == "Served" and old_status != "Served":
        from app.services.inventory_service import InventoryService
        # Get the order to pass to inventory service
        order = db.query(Order).filter(Order.id == kot.order_id).first()
        if order:
            InventoryService.deduct_inventory_for_order(db, order, current_user.id)
    
    db.commit()
    db.refresh(kot)
    return kot

@router.post("/{kot_id}/print")
async def print_kot(
    kot_id: int,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Manually trigger KOT/BOT printing"""
    # branch_id is now provided by dependency
    
    query = db.query(KOT).options(
        joinedload(KOT.order).joinedload(Order.table),
        joinedload(KOT.items).joinedload(KOTItem.menu_item),
        joinedload(KOT.user)
    ).filter(KOT.id == kot_id)
    
    if branch_id:
        query = query.join(Order).filter(Order.branch_id == branch_id)
    
    kot = query.first()
    if not kot:
        raise HTTPException(status_code=404, detail="KOT not found")
    
    printing_service = PrintingService(db)
    if kot.kot_type == 'KOT':
        background_tasks.add_task(printing_service.print_kot, kot)
    else:
        background_tasks.add_task(printing_service.print_bot, kot)
        
    return {"message": "Print job queued"}
