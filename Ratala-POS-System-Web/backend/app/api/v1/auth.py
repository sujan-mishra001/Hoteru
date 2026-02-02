"""
Authentication routes
"""
from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import (
    verify_password, get_password_hash, create_access_token, get_current_user
)
from app.models import User as DBUser
from app.schemas import Token, UserCreate, UserResponse, BranchSelectionRequest
from app.config import settings

router = APIRouter()


@router.post("/signup", response_model=dict)
async def signup(user_data: UserCreate, db: Session = Depends(get_db)):
    """
    User registration endpoint - creates user and organization
    First user signup becomes the organization owner
    """
    from app.models import Organization
    from app.models.organization import SubscriptionPlan, SubscriptionStatus
    from datetime import datetime
    import re
    
    # Validate role - only admin can signup (workers are created by admin)
    if user_data.role not in ["admin"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only admin accounts can be created via signup. Contact your admin to create worker accounts."
        )
    
    # Check if user already exists
    existing_user = db.query(DBUser).filter(DBUser.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Create user
    new_user = DBUser(
        username=user_data.email,  # Use email as username
        email=user_data.email,
        full_name=user_data.full_name,
        hashed_password=get_password_hash(user_data.password),
        role=user_data.role,
        disabled=False
    )
    db.add(new_user)
    db.flush()  # Get the user ID
    
    # Create organization for this user
    # Generate slug from user's name or email
    company_name = user_data.full_name.split()[0] if user_data.full_name else "Company"
    slug_base = re.sub(r'[^a-z0-9]+', '-', company_name.lower())
    slug = f"{slug_base}-{new_user.id}"
    
    organization = Organization(
        name=f"{company_name}'s Restaurant",
        slug=slug,
        subscription_plan=SubscriptionPlan.FREE,
        subscription_status=SubscriptionStatus.TRIAL,
        subscription_start_date=datetime.utcnow(),
        max_branches=1,  # Free plan: 1 branch
        max_users=5,  # Free plan: 5 users
        company_email=user_data.email,
        owner_id=new_user.id
    )
    db.add(organization)
    db.flush()
    
    # Update user with organization
    new_user.organization_id = organization.id
    new_user.is_organization_owner = True
    
    db.commit()
    db.refresh(new_user)
    db.refresh(organization)
    
    print(f"👤 New signup attempt for email: {user_data.email}")
    
    return {
        "success": True,
        "message": "Account created successfully! Please log in to create your first branch.",
        "user": {
            "id": new_user.id,
            "email": new_user.email,
            "full_name": new_user.full_name,
            "role": new_user.role
        },
        "organization": {
            "id": organization.id,
            "name": organization.name,
            "subscription_plan": organization.subscription_plan
        },
        "next_steps": [
            "1. Log in with your credentials",
            "2. Create your first branch",
            "3. Start managing your restaurant"
        ]
    }


@router.post("/token", response_model=Token)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """Login endpoint - returns JWT token with organization and branch info"""
    from app.services import branch_service
    
    user = db.query(DBUser).filter(
        (DBUser.username == form_data.username) | (DBUser.email == form_data.username)
    ).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Get user's accessible branches
    accessible_branches = []
    current_branch_id = user.current_branch_id
    
    if user.organization_id:
        # Get all branches the user can access
        branches = branch_service.get_branches_by_user(db, user.id)
        accessible_branches = [
            {
                "id": branch.id,
                "name": branch.name,
                "code": branch.code,
                "location": branch.location
            }
            for branch in branches
        ]
        
        # If user doesn't have a current branch set, use primary branch
        if not current_branch_id and branches:
            primary_branch = branch_service.get_primary_branch(db, user.id)
            if primary_branch:
                current_branch_id = primary_branch.id
                user.current_branch_id = current_branch_id
                db.commit()
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={
            "sub": user.username,
            "role": user.role,
            "organization_id": user.organization_id,
            "branch_id": current_branch_id
        },
        expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role,
        "organization_id": user.organization_id,
        "current_branch_id": current_branch_id,
        "accessible_branches": accessible_branches
    }


@router.get("/users/me", response_model=UserResponse)
async def read_users_me(
    current_user: DBUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current authenticated user with permissions and robust fallbacks"""
    from app.models.role import Role
    from sqlalchemy import func
    
    user_role_name = current_user.role.lower()
    permissions = []
    
    if user_role_name == 'admin':
        permissions = ["*"]
    else:
        # 1. Try to fetch dynamic permissions from roles table
        role = db.query(Role).filter(func.lower(Role.name) == user_role_name).first()
        if role and role.permissions:
            permissions = role.permissions
            
        # 2. Fallback to standard permissions for legacy or default roles if no dynamic perms found
        if not permissions:
            if user_role_name == 'manager':
                permissions = ['dashboard.view', 'pos.access', 'inventory.view', 'orders.view', 'customers.manage', 'sessions.manage']
            elif user_role_name in ['waiter', 'bartender']:
                permissions = ['pos.access', 'orders.view', 'customers.manage']
            elif user_role_name == 'store keeper':
                permissions = ['inventory.manage', 'inventory.view']
            elif user_role_name == 'cashier':
                permissions = ['pos.access', 'orders.view', 'cashier.view', 'sessions.manage']
            elif user_role_name == 'worker':
                permissions = ['pos.access', 'orders.view', 'sessions.manage']
            else:
                permissions = ['pos.access'] # Minimal access default

    # Ensure sessions.manage is included if the role is a worker and it's missing but expected
    # (Safety net for the user's specific request)
    if user_role_name == 'worker' and 'sessions.manage' not in permissions:
        permissions.append('sessions.manage')

    current_user.permissions = permissions
    return current_user


@router.post("/select-branch", response_model=Token)
async def select_branch(
    branch_selection: BranchSelectionRequest,
    db: Session = Depends(get_db),
    current_user: DBUser = Depends(get_current_user)
):
    """Select a branch for the current session"""
    from app.services import branch_service
    
    # Verify user has access to this branch
    user_branches = branch_service.get_branches_by_user(db, current_user.id)
    branch_ids = [b.id for b in user_branches]
    
    if branch_selection.branch_id not in branch_ids:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this branch"
        )
    
    # Update user's current branch
    current_user.current_branch_id = branch_selection.branch_id
    db.commit()
    
    # Generate new token with updated branch ID
    accessible_branches = [
        {
            "id": branch.id,
            "name": branch.name,
            "code": branch.code,
            "location": branch.location
        }
        for branch in user_branches
    ]
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={
            "sub": current_user.username,
            "role": current_user.role,
            "organization_id": current_user.organization_id,
            "branch_id": branch_selection.branch_id
        },
        expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": current_user.role,
        "organization_id": current_user.organization_id,
        "current_branch_id": branch_selection.branch_id,
        "accessible_branches": accessible_branches
    }

