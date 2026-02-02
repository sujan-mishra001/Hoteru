"""
Organization service for managing multi-tenant organizations
"""
from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.organization import Organization, SubscriptionPlan, SubscriptionStatus
from app.models.auth import User
from app.schemas import OrganizationCreate, OrganizationUpdate
from datetime import datetime


def get_organization(db: Session, organization_id: int) -> Optional[Organization]:
    """Get organization by ID"""
    return db.query(Organization).filter(Organization.id == organization_id).first()


def get_organization_by_slug(db: Session, slug: str) -> Optional[Organization]:
    """Get organization by slug"""
    return db.query(Organization).filter(Organization.slug == slug).first()


def get_organizations(db: Session, skip: int = 0, limit: int = 100) -> List[Organization]:
    """Get all organizations (for super admin)"""
    return db.query(Organization).offset(skip).limit(limit).all()


def create_organization(
    db: Session,
    org_data: OrganizationCreate,
    owner_id: int
) -> Organization:
    """Create a new organization"""
    
    # Set max limits based on subscription plan
    max_branches = 1
    max_users = 5
    
    if org_data.subscription_plan == SubscriptionPlan.BASIC:
        max_branches = 3
        max_users = 20
    elif org_data.subscription_plan == SubscriptionPlan.PREMIUM:
        max_branches = 10
        max_users = 100
    elif org_data.subscription_plan == SubscriptionPlan.ENTERPRISE:
        max_branches = 999
        max_users = 9999
    
    db_organization = Organization(
        name=org_data.name,
        slug=org_data.slug,
        subscription_plan=org_data.subscription_plan,
        subscription_status=SubscriptionStatus.TRIAL,
        subscription_start_date=datetime.utcnow(),
        max_branches=max_branches,
        max_users=max_users,
        company_address=org_data.company_address,
        company_phone=org_data.company_phone,
        company_email=org_data.company_email,
        owner_id=owner_id
    )
    
    db.add(db_organization)
    db.commit()
    db.refresh(db_organization)
    
    # Update user to link to this organization
    user = db.query(User).filter(User.id == owner_id).first()
    if user:
        user.organization_id = db_organization.id
        user.is_organization_owner = True
        db.commit()
    
    return db_organization


def update_organization(
    db: Session,
    organization_id: int,
    org_data: OrganizationUpdate
) -> Optional[Organization]:
    """Update organization details"""
    db_organization = get_organization(db, organization_id)
    
    if not db_organization:
        return None
    
    update_data = org_data.model_dump(exclude_unset=True)
    
    # Update max limits if subscription plan changed
    if "subscription_plan" in update_data:
        plan = update_data["subscription_plan"]
        if plan == SubscriptionPlan.FREE:
            update_data["max_branches"] = 1
            update_data["max_users"] = 5
        elif plan == SubscriptionPlan.BASIC:
            update_data["max_branches"] = 3
            update_data["max_users"] = 20
        elif plan == SubscriptionPlan.PREMIUM:
            update_data["max_branches"] = 10
            update_data["max_users"] = 100
        elif plan == SubscriptionPlan.ENTERPRISE:
            update_data["max_branches"] = 999
            update_data["max_users"] = 9999
    
    for key, value in update_data.items():
        setattr(db_organization, key, value)
    
    db_organization.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_organization)
    
    return db_organization


def delete_organization(db: Session, organization_id: int) -> bool:
    """Delete/deactivate organization"""
    db_organization = get_organization(db, organization_id)
    
    if not db_organization:
        return False
    
    # Set subscription to inactive instead of deleting
    db_organization.subscription_status = SubscriptionStatus.INACTIVE
    db.commit()
    
    return True


def validate_subscription(organization: Organization) -> dict:
    """Validate organization subscription status and limits"""
    result = {
        "is_valid": False,
        "can_create_branch": False,
        "can_create_user": False,
        "message": ""
    }
    
    # Check subscription status
    if organization.subscription_status != SubscriptionStatus.ACTIVE:
        if organization.subscription_status == SubscriptionStatus.TRIAL:
            result["is_valid"] = True
            result["message"] = "Trial subscription"
        else:
            result["message"] = f"Subscription is {organization.subscription_status}"
            return result
    else:
        result["is_valid"] = True
    
    # Check branch limit
    current_branches = len(organization.branches) if organization.branches else 0
    result["can_create_branch"] = current_branches < organization.max_branches
    
    # Check user limit
    current_users = len(organization.users) if organization.users else 0
    result["can_create_user"] = current_users < organization.max_users
    
    if not result["can_create_branch"]:
        result["message"] = f"Branch limit reached ({current_branches}/{organization.max_branches})"
    
    if not result["can_create_user"]:
        result["message"] = f"User limit reached ({current_users}/{organization.max_users})"
    
    return result
