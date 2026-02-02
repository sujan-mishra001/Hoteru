"""
Settings API endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.dependencies import get_current_user
from app.models import User, CompanySettings, PaymentMode, StorageArea, DiscountRule
from pydantic import BaseModel
from datetime import datetime

router = APIRouter(prefix="/settings", tags=["settings"])


# Pydantic schemas
class CompanySettingsBase(BaseModel):
    company_name: str
    email: str | None = None
    phone: str | None = None
    address: str | None = None
    vat_pan_no: str | None = None
    registration_no: str | None = None
    start_date: str | None = None
    logo_url: str | None = None
    invoice_prefix: str = "INV"
    invoice_footer_text: str | None = None
    show_vat_on_invoice: bool = True
    currency: str = "NPR"
    timezone: str = "Asia/Kathmandu"


class CompanySettingsResponse(CompanySettingsBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PaymentModeBase(BaseModel):
    name: str
    is_active: bool = True
    display_order: int = 0


class PaymentModeResponse(PaymentModeBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class StorageAreaBase(BaseModel):
    name: str
    description: str | None = None
    is_active: bool = True


class StorageAreaResponse(StorageAreaBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class DiscountRuleBase(BaseModel):
    name: str
    discount_type: str  # Percentage, Fixed Amount
    discount_value: float
    is_active: bool = True
    min_order_amount: float = 0
    max_discount_amount: float | None = None
    applicable_on: str = "All"


class DiscountRuleResponse(DiscountRuleBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# Company Settings Endpoints
@router.get("/company", response_model=CompanySettingsResponse)
async def get_company_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get company settings"""
    settings = db.query(CompanySettings).first()
    if not settings:
        # Create default settings if none exist
        settings = CompanySettings(
            company_name="HOTERU",
            email="fisap73734@ahanim.com",
            phone="32908409328",
            address="Kirtipur",
            vat_pan_no="39284032",
            registration_no="23432432",
            start_date="2025-08-26"
        )
        db.add(settings)
        db.commit()
        db.refresh(settings)
    return settings


@router.put("/company", response_model=CompanySettingsResponse)
async def update_company_settings(
    settings_data: CompanySettingsBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update company settings"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can update company settings"
        )
    
    settings = db.query(CompanySettings).first()
    if not settings:
        settings = CompanySettings(**settings_data.model_dump())
        db.add(settings)
    else:
        for key, value in settings_data.model_dump().items():
            setattr(settings, key, value)
    
    db.commit()
    db.refresh(settings)
    return settings


# Payment Modes Endpoints
@router.get("/payment-modes", response_model=List[PaymentModeResponse])
async def get_payment_modes(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all payment modes"""
    return db.query(PaymentMode).order_by(PaymentMode.display_order).all()


@router.post("/payment-modes", response_model=PaymentModeResponse)
async def create_payment_mode(
    payment_mode: PaymentModeBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new payment mode"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can create payment modes"
        )
    
    # Check if payment mode already exists
    existing = db.query(PaymentMode).filter(PaymentMode.name == payment_mode.name).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment mode already exists"
        )
    
    new_payment_mode = PaymentMode(**payment_mode.model_dump())
    db.add(new_payment_mode)
    db.commit()
    db.refresh(new_payment_mode)
    return new_payment_mode


@router.put("/payment-modes/{payment_mode_id}", response_model=PaymentModeResponse)
async def update_payment_mode(
    payment_mode_id: int,
    payment_mode_data: PaymentModeBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update a payment mode"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can update payment modes"
        )
    
    payment_mode = db.query(PaymentMode).filter(PaymentMode.id == payment_mode_id).first()
    if not payment_mode:
        raise HTTPException(status_code=404, detail="Payment mode not found")
    
    for key, value in payment_mode_data.model_dump().items():
        setattr(payment_mode, key, value)
    
    db.commit()
    db.refresh(payment_mode)
    return payment_mode


@router.delete("/payment-modes/{payment_mode_id}")
async def delete_payment_mode(
    payment_mode_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete a payment mode"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can delete payment modes"
        )
    
    payment_mode = db.query(PaymentMode).filter(PaymentMode.id == payment_mode_id).first()
    if not payment_mode:
        raise HTTPException(status_code=404, detail="Payment mode not found")
    
    db.delete(payment_mode)
    db.commit()
    return {"message": "Payment mode deleted successfully"}


# Storage Areas Endpoints
@router.get("/storage-areas", response_model=List[StorageAreaResponse])
async def get_storage_areas(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all storage areas"""
    return db.query(StorageArea).all()


@router.post("/storage-areas", response_model=StorageAreaResponse)
async def create_storage_area(
    storage_area: StorageAreaBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new storage area"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can create storage areas"
        )
    
    new_storage_area = StorageArea(**storage_area.model_dump())
    db.add(new_storage_area)
    db.commit()
    db.refresh(new_storage_area)
    return new_storage_area


@router.put("/storage-areas/{storage_area_id}", response_model=StorageAreaResponse)
async def update_storage_area(
    storage_area_id: int,
    storage_area_data: StorageAreaBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update a storage area"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can update storage areas"
        )
    
    storage_area = db.query(StorageArea).filter(StorageArea.id == storage_area_id).first()
    if not storage_area:
        raise HTTPException(status_code=404, detail="Storage area not found")
    
    for key, value in storage_area_data.model_dump().items():
        setattr(storage_area, key, value)
    
    db.commit()
    db.refresh(storage_area)
    return storage_area


@router.delete("/storage-areas/{storage_area_id}")
async def delete_storage_area(
    storage_area_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete a storage area"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can delete storage areas"
        )
    
    storage_area = db.query(StorageArea).filter(StorageArea.id == storage_area_id).first()
    if not storage_area:
        raise HTTPException(status_code=404, detail="Storage area not found")
    
    db.delete(storage_area)
    db.commit()
    return {"message": "Storage area deleted successfully"}


# Discount Rules Endpoints
@router.get("/discounts", response_model=List[DiscountRuleResponse])
async def get_discount_rules(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all discount rules"""
    return db.query(DiscountRule).all()


@router.post("/discounts", response_model=DiscountRuleResponse)
async def create_discount_rule(
    discount: DiscountRuleBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new discount rule"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can create discount rules"
        )
    
    new_discount = DiscountRule(**discount.model_dump())
    db.add(new_discount)
    db.commit()
    db.refresh(new_discount)
    return new_discount


@router.put("/discounts/{discount_id}", response_model=DiscountRuleResponse)
async def update_discount_rule(
    discount_id: int,
    discount_data: DiscountRuleBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update a discount rule"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can update discount rules"
        )
    
    discount = db.query(DiscountRule).filter(DiscountRule.id == discount_id).first()
    if not discount:
        raise HTTPException(status_code=404, detail="Discount rule not found")
    
    for key, value in discount_data.model_dump().items():
        setattr(discount, key, value)
    
    db.commit()
    db.refresh(discount)
    return discount


@router.delete("/discounts/{discount_id}")
async def delete_discount_rule(
    discount_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete a discount rule"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can delete discount rules"
        )
    
    discount = db.query(DiscountRule).filter(DiscountRule.id == discount_id).first()
    if not discount:
        raise HTTPException(status_code=404, detail="Discount rule not found")
    
    db.delete(discount)
    db.commit()
    return {"message": "Discount rule deleted successfully"}
