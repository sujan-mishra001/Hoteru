"""
Settings API endpoints with branch isolation
"""
from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.models import User, CompanySettings, PaymentMode, StorageArea, DiscountRule
from pydantic import BaseModel
from datetime import datetime
import os
import uuid

router = APIRouter(prefix="/settings", tags=["settings"])


def apply_branch_filter_settings(query, model, branch_id):
    """Apply branch_id filter to settings-related queries"""
    if branch_id is not None and hasattr(model, 'branch_id'):
        query = query.filter(model.branch_id == branch_id)
    return query


@router.get("/public-company")
async def get_public_company_settings(
    branch_id: int | None = None,
    db: Session = Depends(get_db)
):
    """Publicly accessible company/branch settings"""
    # If branch_id is provided, try to get branch-specific info
    branch = None
    if branch_id:
        from app.models.branch import Branch
        branch = db.query(Branch).filter(Branch.id == branch_id).first()
    
    settings = db.query(CompanySettings).first()
    
    # Merge data: branch info takes priority if it exists
    return {
        "company_name": (branch.name if branch else (settings.company_name if settings and settings.company_name else "")),
        "phone": (branch.phone if branch and branch.phone else (settings.phone if settings else "")),
        "address": (branch.address if branch and branch.address else (settings.address if settings else "")),
        "logo_url": settings.logo_url if settings else None,
        "slogan": (branch.slogan if branch and branch.slogan else getattr(settings, 'slogan', "Savor the authentic taste of tradition") if settings else "Savor the authentic taste of tradition"),
        "facebook_url": branch.facebook_url if branch else None,
        "instagram_url": branch.instagram_url if branch else None
    }


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
    tax_rate: float = 13.0
    service_charge_rate: float = 10.0
    discount_rate: float = 0.0
    notifications_enabled: bool = True
    sound_enabled: bool = True
    vibration_enabled: bool = True
    auto_print: bool = False
    dark_mode: bool = False


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
        # Create default empty settings if none exist
        settings = CompanySettings(
            company_name="",
            email="",
            phone="",
            address="",
            vat_pan_no="",
            registration_no="",
            start_date=""
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


@router.post("/company/logo")
async def update_company_logo(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Upload and update company logo"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can update company logo"
        )
        
    # Create directory if it doesn't exist
    upload_dir = "uploads/company"
    os.makedirs(upload_dir, exist_ok=True)
    
    # Validate file type
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    # Generate unique filename
    file_extension = os.path.splitext(file.filename)[1]
    filename = f"logo_{uuid.uuid4().hex}{file_extension}"
    file_path = os.path.join(upload_dir, filename)
    
    # Save file
    try:
        with open(file_path, "wb") as buffer:
            content = await file.read()
            buffer.write(content)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not save file: {str(e)}")
        
    # Update settings
    settings = db.query(CompanySettings).first()
    if not settings:
         settings = CompanySettings(company_name="")
         db.add(settings)
         db.flush()
         
    # Delete old logo if exists
    if settings.logo_url:
        old_path = settings.logo_url.lstrip("/")
        if os.path.exists(old_path):
            try:
                os.remove(old_path)
            except:
                pass
                
    settings.logo_url = f"/{upload_dir}/{filename}"
    db.commit()
    
    return {"logo_url": settings.logo_url}


# General Settings Endpoints (aliases/shorthands for mobile app)
@router.get("", response_model=CompanySettingsBase)
async def get_all_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all settings (aliased to company settings for now)"""
    settings = db.query(CompanySettings).first()
    if not settings:
        return {
            "company_name": "",
            "currency": "NPR",
            "tax_rate": 13.0,
            "service_charge_rate": 10.0,
            "discount_rate": 0.0,
            "notifications_enabled": True,
            "sound_enabled": True,
            "vibration_enabled": True,
            "auto_print": False,
            "dark_mode": False
        }
    return settings


@router.put("", response_model=CompanySettingsResponse)
async def update_all_settings(
    settings_data: CompanySettingsBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update all settings"""
    return await update_company_settings(settings_data, db, current_user)


@router.get("/currency")
async def get_currency_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get currency settings"""
    settings = db.query(CompanySettings).first()
    return {"currency": settings.currency if settings else "NPR"}


@router.put("/currency")
async def update_currency_settings(
    data: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update currency settings"""
    settings = db.query(CompanySettings).first()
    if settings:
        settings.currency = data.get("currency", settings.currency)
        db.commit()
    return {"success": True}


@router.get("/taxes")
async def get_tax_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get tax settings"""
    settings = db.query(CompanySettings).first()
    return {"tax_rate": settings.tax_rate if settings else 13.0}


@router.put("/taxes")
async def update_tax_settings(
    data: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update tax settings"""
    settings = db.query(CompanySettings).first()
    if settings:
        settings.tax_rate = data.get("tax_rate", settings.tax_rate)
        db.commit()
    return {"success": True}


@router.get("/printer")
async def get_printer_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get printer settings"""
    settings = db.query(CompanySettings).first()
    return {"auto_print": settings.auto_print if settings else False}


@router.put("/printer")
async def update_printer_settings(
    data: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update printer settings"""
    settings = db.query(CompanySettings).first()
    if settings:
        settings.auto_print = data.get("auto_print", settings.auto_print)
        db.commit()
    return {"success": True}


@router.get("/notifications")
async def get_notification_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get notification settings"""
    settings = db.query(CompanySettings).first()
    if not settings:
        return {"notifications_enabled": True, "sound_enabled": True, "vibration_enabled": True}
    return {
        "notifications_enabled": settings.notifications_enabled,
        "sound_enabled": settings.sound_enabled,
        "vibration_enabled": settings.vibration_enabled
    }


@router.put("/notifications")
async def update_notification_settings(
    data: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update notification settings"""
    settings = db.query(CompanySettings).first()
    if settings:
        settings.notifications_enabled = data.get("notifications_enabled", settings.notifications_enabled)
        settings.sound_enabled = data.get("sound_enabled", settings.sound_enabled)
        settings.vibration_enabled = data.get("vibration_enabled", settings.vibration_enabled)
        db.commit()
    return {"success": True}


@router.get("/receipt")
async def get_receipt_settings():
    """Get receipt settings (placeholder)"""
    return {"header_text": "Welcome to Ratala Hospitality", "footer_text": "Thank you for visiting!"}


@router.put("/receipt")
async def update_receipt_settings():
    """Update receipt settings (placeholder)"""
    return {"success": True}


# Payment Modes Endpoints
@router.get("/payment-modes", response_model=List[PaymentModeResponse])
async def get_payment_modes(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all payment modes for the current user's branch"""
    branch_id = current_user.current_branch_id
    query = db.query(PaymentMode)
    query = apply_branch_filter_settings(query, PaymentMode, branch_id)
    modes = query.order_by(PaymentMode.display_order).all()
    
    if not modes:
        # Seed default modes if none exist
        defaults = [
            PaymentMode(name="Cash", display_order=1),
            PaymentMode(name="QR Pay", display_order=2),
            PaymentMode(name="Credit Card", display_order=3)
        ]
        if branch_id:
            for d in defaults:
                d.branch_id = branch_id
        
        for d in defaults:
            db.add(d)
        db.commit()
        modes = query.order_by(PaymentMode.display_order).all()
        
    return modes


@router.post("/payment-modes", response_model=PaymentModeResponse)
async def create_payment_mode(
    payment_mode: PaymentModeBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new payment mode in the current user's branch"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can create payment modes"
        )
    
    branch_id = current_user.current_branch_id
    
    # Check if payment mode already exists in the branch (or globally)
    query = db.query(PaymentMode).filter(PaymentMode.name == payment_mode.name)
    query = apply_branch_filter_settings(query, PaymentMode, branch_id)
    existing = query.first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment mode already exists in this branch"
        )
    
    payment_dict = payment_mode.model_dump()
    # Set branch_id if the column exists
    if branch_id is not None and hasattr(PaymentMode, 'branch_id'):
        payment_dict['branch_id'] = branch_id
    
    new_payment_mode = PaymentMode(**payment_dict)
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
    """Update a payment mode in the current user's branch"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can update payment modes"
        )
    
    branch_id = current_user.current_branch_id
    
    query = db.query(PaymentMode).filter(PaymentMode.id == payment_mode_id)
    query = apply_branch_filter_settings(query, PaymentMode, branch_id)
    payment_mode = query.first()
    
    if not payment_mode:
        raise HTTPException(status_code=404, detail="Payment mode not found or access denied")
    
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
    """Delete a payment mode in the current user's branch"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can delete payment modes"
        )
    
    branch_id = current_user.current_branch_id
    
    query = db.query(PaymentMode).filter(PaymentMode.id == payment_mode_id)
    query = apply_branch_filter_settings(query, PaymentMode, branch_id)
    payment_mode = query.first()
    
    if not payment_mode:
        raise HTTPException(status_code=404, detail="Payment mode not found or access denied")
    
    db.delete(payment_mode)
    db.commit()
    return {"message": "Payment mode deleted successfully"}


# Storage Areas Endpoints
@router.get("/storage-areas", response_model=List[StorageAreaResponse])
async def get_storage_areas(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all storage areas for the current user's branch"""
    branch_id = current_user.current_branch_id
    query = db.query(StorageArea)
    query = apply_branch_filter_settings(query, StorageArea, branch_id)
    return query.all()


@router.post("/storage-areas", response_model=StorageAreaResponse)
async def create_storage_area(
    storage_area: StorageAreaBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new storage area in the current user's branch"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can create storage areas"
        )
    
    branch_id = current_user.current_branch_id
    area_dict = storage_area.model_dump()
    
    # Set branch_id if the column exists
    if branch_id is not None and hasattr(StorageArea, 'branch_id'):
        area_dict['branch_id'] = branch_id
    
    new_storage_area = StorageArea(**area_dict)
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
    """Update a storage area in the current user's branch"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can update storage areas"
        )
    
    branch_id = current_user.current_branch_id
    
    query = db.query(StorageArea).filter(StorageArea.id == storage_area_id)
    query = apply_branch_filter_settings(query, StorageArea, branch_id)
    storage_area = query.first()
    
    if not storage_area:
        raise HTTPException(status_code=404, detail="Storage area not found or access denied")
    
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
    """Delete a storage area in the current user's branch"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can delete storage areas"
        )
    
    branch_id = current_user.current_branch_id
    
    query = db.query(StorageArea).filter(StorageArea.id == storage_area_id)
    query = apply_branch_filter_settings(query, StorageArea, branch_id)
    storage_area = query.first()
    
    if not storage_area:
        raise HTTPException(status_code=404, detail="Storage area not found or access denied")
    
    db.delete(storage_area)
    db.commit()
    return {"message": "Storage area deleted successfully"}


# Discount Rules Endpoints
@router.get("/discounts", response_model=List[DiscountRuleResponse])
async def get_discount_rules(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all discount rules for the current user's branch"""
    branch_id = current_user.current_branch_id
    query = db.query(DiscountRule)
    query = apply_branch_filter_settings(query, DiscountRule, branch_id)
    return query.all()


@router.post("/discounts", response_model=DiscountRuleResponse)
async def create_discount_rule(
    discount: DiscountRuleBase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new discount rule in the current user's branch"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can create discount rules"
        )
    
    branch_id = current_user.current_branch_id
    discount_dict = discount.model_dump()
    
    # Set branch_id if the column exists
    if branch_id is not None and hasattr(DiscountRule, 'branch_id'):
        discount_dict['branch_id'] = branch_id
    
    new_discount = DiscountRule(**discount_dict)
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
    """Update a discount rule in the current user's branch"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can update discount rules"
        )
    
    branch_id = current_user.current_branch_id
    
    query = db.query(DiscountRule).filter(DiscountRule.id == discount_id)
    query = apply_branch_filter_settings(query, DiscountRule, branch_id)
    discount = query.first()
    
    if not discount:
        raise HTTPException(status_code=404, detail="Discount rule not found or access denied")
    
    for key, value in discount_data.model_dump().items():
        if hasattr(discount, key) and key != 'branch_id':
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
    """Delete a discount rule in the current user's branch"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can delete discount rules"
        )
    
    branch_id = current_user.current_branch_id
    
    query = db.query(DiscountRule).filter(DiscountRule.id == discount_id)
    query = apply_branch_filter_settings(query, DiscountRule, branch_id)
    discount = query.first()
    
    if not discount:
        raise HTTPException(status_code=404, detail="Discount rule not found or access denied")
    
    db.delete(discount)
    db.commit()
    return {"message": "Discount rule deleted successfully"}
