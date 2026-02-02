"""
User management routes (Admin only)
"""
from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user, check_admin_role, get_password_hash
from app.models import User as DBUser, Role, UserBranchAssignment
from app.schemas import UserResponse, UserCreateByAdmin, UserUpdate
from app.config import settings

router = APIRouter()


@router.get("", response_model=list[UserResponse])
async def get_users(
    db: Session = Depends(get_db),
    current_user: DBUser = Depends(check_admin_role)
):
    """Get all users (Admin only)"""
    users = db.query(DBUser).all()
    return users


@router.post("", response_model=UserResponse)
async def create_user(
    user_data: UserCreateByAdmin = Body(...),
    db: Session = Depends(get_db),
    current_user: DBUser = Depends(check_admin_role)
):
    """Create a new user (Admin only)"""
    # Validate role
    is_valid_role = user_data.role == "admin" or db.query(Role).filter(Role.name == user_data.role).first() is not None
    if not is_valid_role:
        raise HTTPException(
            status_code=400,
            detail="Invalid role. Please select a role created in Roles & Permissions."
        )
    
    # Use email as username if username not provided
    username = user_data.username or user_data.email
    
    # Check if user already exists
    existing_user = db.query(DBUser).filter(
        (DBUser.email == user_data.email) | (DBUser.username == username)
    ).first()
    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="User with this email or username already exists"
        )
    
    new_user = DBUser(
        username=username,
        email=user_data.email,
        full_name=user_data.full_name,
        hashed_password=get_password_hash(user_data.password),
        role=user_data.role,
        organization_id=current_user.organization_id,
        current_branch_id=user_data.branch_id,
        disabled=False
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # If a branch was assigned, create the permission linkage (UserBranchAssignment)
    if user_data.branch_id:
        assignment = UserBranchAssignment(
            user_id=new_user.id,
            branch_id=user_data.branch_id,
            organization_id=current_user.organization_id,
            is_primary=True
        )
        db.add(assignment)
        db.commit()
        
    return new_user


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: DBUser = Depends(check_admin_role)
):
    """Get user by ID (Admin only)"""
    user = db.query(DBUser).filter(DBUser.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.put("/{user_id}", response_model=UserResponse)
@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user_data: UserUpdate = Body(...),
    db: Session = Depends(get_db),
    current_user: DBUser = Depends(check_admin_role)
):
    """Update user (Admin only)"""
    user = db.query(DBUser).filter(DBUser.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Prevent changing admin role or deleting admin
    if user.role == 'admin' and user_data.role and user_data.role != 'admin':
        raise HTTPException(status_code=403, detail="Cannot change admin role")
    
    # Validate role if provided
    if user_data.role:
        is_valid_role = user_data.role == "admin" or db.query(Role).filter(Role.name == user_data.role).first() is not None
        if not is_valid_role:
            raise HTTPException(
                status_code=400,
                detail="Invalid role. Please select a role created in Roles & Permissions."
            )
    
    # Update fields
    update_data = user_data.dict(exclude_unset=True)
    if 'password' in update_data and update_data['password']:
        update_data['hashed_password'] = get_password_hash(update_data['password'])
        del update_data['password']
    
    for key, value in update_data.items():
        setattr(user, key, value)
    
    db.commit()
    db.refresh(user)
    return user


@router.delete("/{user_id}")
async def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: DBUser = Depends(check_admin_role)
):
    """Delete user (Admin only)"""
    user = db.query(DBUser).filter(DBUser.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Prevent deleting admin users
    if user.role == 'admin':
        raise HTTPException(status_code=403, detail="Cannot delete admin user")
    
    db.delete(user)
    db.commit()
    return {"message": "User deleted successfully"}
