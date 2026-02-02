"""
Delivery partner management routes
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import DeliveryPartner

router = APIRouter()


@router.get("")
async def get_delivery_partners(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all delivery partners"""
    partners = db.query(DeliveryPartner).all()
    return partners


@router.post("")
async def create_delivery_partner(
    partner_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new delivery partner"""
    new_partner = DeliveryPartner(**partner_data)
    db.add(new_partner)
    db.commit()
    db.refresh(new_partner)
    return new_partner
