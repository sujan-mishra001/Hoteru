"""
Delivery partner management routes with branch isolation
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.models import DeliveryPartner

router = APIRouter()


def apply_branch_filter_delivery(query, branch_id):
    """Apply branch_id filter to DeliveryPartner queries"""
    if branch_id is not None and hasattr(DeliveryPartner, 'branch_id'):
        query = query.filter(DeliveryPartner.branch_id == branch_id)
    return query


@router.get("")
async def get_delivery_partners(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all delivery partners for the current user's branch"""
    branch_id = current_user.current_branch_id
    query = db.query(DeliveryPartner)
    query = apply_branch_filter_delivery(query, branch_id)
    partners = query.all()
    return partners


@router.post("")
async def create_delivery_partner(
    partner_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new delivery partner in the current user's branch"""
    branch_id = current_user.current_branch_id
    
    # Set branch_id if the column exists
    if branch_id is not None and hasattr(DeliveryPartner, 'branch_id'):
        partner_data['branch_id'] = branch_id
    
    new_partner = DeliveryPartner(**partner_data)
    db.add(new_partner)
    db.commit()
    db.refresh(new_partner)
    return new_partner


@router.put("/{partner_id}")
async def update_delivery_partner(
    partner_id: int,
    partner_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a delivery partner in the current user's branch"""
    branch_id = current_user.current_branch_id
    query = db.query(DeliveryPartner).filter(DeliveryPartner.id == partner_id)
    query = apply_branch_filter_delivery(query, branch_id)
    partner = query.first()
    
    if not partner:
        raise HTTPException(status_code=404, detail="Partner not found or access denied")
    
    for key, value in partner_data.items():
        if hasattr(partner, key) and key != 'id' and key != 'branch_id':
             setattr(partner, key, value)
             
    db.commit()
    db.refresh(partner)
    return partner


@router.delete("/{partner_id}")
async def delete_delivery_partner(
    partner_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Delete a delivery partner in the current user's branch"""
    branch_id = current_user.current_branch_id
    query = db.query(DeliveryPartner).filter(DeliveryPartner.id == partner_id)
    query = apply_branch_filter_delivery(query, branch_id)
    partner = query.first()
    
    if not partner:
        raise HTTPException(status_code=404, detail="Partner not found or access denied")
    
    db.delete(partner)
    db.commit()
    return {"message": "Delivery partner deleted successfully"}
