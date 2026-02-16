"""
User management routes (Admin only)
"""
from fastapi import APIRouter, Depends, HTTPException, status, Body, File, UploadFile
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.core.dependencies import get_current_user, check_admin_role, get_password_hash, check_platform_admin, get_branch_id
from app.models import User as DBUser, Role, UserBranchAssignment
from app.schemas import UserResponse, UserCreateByAdmin, UserUpdate
from app.core.config import settings

router = APIRouter()


@router.get("", response_model=list[UserResponse])
async def get_users(
    db: Session = Depends(get_db),
    current_user: DBUser = Depends(get_current_user),
    branch_id: int = Depends(get_branch_id)
):
    """Get users for the current branch (Branch visibility)"""
    # Fix: Fetch only users assigned to the current branch
    if not current_user.organization_id:
        return []
    
    # If admin, they might want to see all users, but the user management page 
    # requirement says "only users associated with the current branch"
    # UserBranchAssignment links users to branches.
    users = db.query(DBUser).join(
        UserBranchAssignment, DBUser.id == UserBranchAssignment.user_id
    ).filter(
        UserBranchAssignment.branch_id == branch_id,
        DBUser.organization_id == current_user.organization_id
    ).all()
    
    return users


@router.get("/all", response_model=list[UserResponse])
async def get_all_organization_users(
    db: Session = Depends(get_db),
    current_user: DBUser = Depends(check_admin_role)
):
    """Get all users in the organization (Admin only)"""
    if current_user.role == "platform_admin":
        return db.query(DBUser).all()
        
    if not current_user.organization_id:
        return []
        
    users = db.query(DBUser).filter(
        DBUser.organization_id == current_user.organization_id
    ).all()
    return users


@router.post("", response_model=UserResponse)
async def create_user(
    user_data: UserCreateByAdmin = Body(...),
    db: Session = Depends(get_db),
    current_user: DBUser = Depends(check_admin_role)
):
    """Create a new user (Admin only)"""
    # Validate role - must exist in the target branch or be 'admin'
    target_branch_id = user_data.branch_id or current_user.current_branch_id
    is_valid_role = user_data.role == "admin" or db.query(Role).filter(
        Role.name == user_data.role,
        Role.branch_id == target_branch_id
    ).first() is not None
    if not is_valid_role:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid role. The role '{user_data.role}' does not exist in the target branch."
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
    
    # Prevent changing admin role or deleting admin (except for platform_admin)
    if user.role == 'admin' and user_data.role and user_data.role != 'admin' and current_user.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="Cannot change admin role")
    
    # Validate role if provided
    if user_data.role:
        # Check against user's current branch or organization default
        target_branch_id = user.current_branch_id or current_user.current_branch_id
        is_valid_role = user_data.role == "admin" or db.query(Role).filter(
            Role.name == user_data.role,
            Role.branch_id == target_branch_id
        ).first() is not None
        
        if not is_valid_role:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid role. The role '{user_data.role}' does not exist in the user's branch."
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
    
    # Prevent deleting admin users (except for platform_admin)
    if user.role == 'admin' and current_user.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="Cannot delete admin user")
    
    # If user is an organization owner, delete the entire organization
    if user.is_organization_owner and user.owned_organization:
        org = user.owned_organization
        all_members = db.query(DBUser).filter(DBUser.organization_id == org.id).all()
        member_ids = [m.id for m in all_members]
        
        # 1. Get branch IDs for manual cleanup of operational data
        from app.models.branch import Branch
        branches = db.query(Branch).filter(Branch.organization_id == org.id).all()
        branch_ids = [b.id for b in branches]
        
        if branch_ids:
            # 2. Delete all operational data linked to these branches
            from app.models.orders import Order, KOT, OrderItem, KOTItem
            from app.models.pos_session import POSSession
            from app.models.inventory import InventoryTransaction, BatchProduction
            
            # Orders cascade to OrderItems and KOTs, but let's be safe
            db.query(OrderItem).filter(OrderItem.order_id.in_(
                db.query(Order.id).filter(Order.branch_id.in_(branch_ids))
            )).delete(synchronize_session=False)
            
            db.query(KOTItem).filter(KOTItem.kot_id.in_(
                db.query(KOT.id).filter(KOT.order_id.in_(
                    db.query(Order.id).filter(Order.branch_id.in_(branch_ids))
                ))
            )).delete(synchronize_session=False)
            
            db.query(KOT).filter(KOT.order_id.in_(
                db.query(Order.id).filter(Order.branch_id.in_(branch_ids))
            )).delete(synchronize_session=False)
            
            db.query(Order).filter(Order.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            
            # POS Sessions and Transactions
            db.query(InventoryTransaction).filter(InventoryTransaction.pos_session_id.in_(
                db.query(POSSession.id).filter(POSSession.branch_id.in_(branch_ids))
            )).delete(synchronize_session=False)
            
            db.query(BatchProduction).filter(BatchProduction.pos_session_id.in_(
                db.query(POSSession.id).filter(POSSession.branch_id.in_(branch_ids))
            )).delete(synchronize_session=False)
            
            db.query(POSSession).filter(POSSession.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            
            # 3. Clean up any remaining sessions/orders for these specific users (even if branch_id was null)
            db.query(POSSession).filter(POSSession.user_id.in_(member_ids)).delete(synchronize_session=False)
            db.query(Order).filter(Order.created_by.in_(member_ids)).delete(synchronize_session=False)
            
            # 4. Finally delete the branches
            db.query(Branch).filter(Branch.organization_id == org.id).delete(synchronize_session=False)
        
        db.flush()
        
        # 5. Detach users from Org to allow Org deletion (Owner NOT NULL constraint)
        for member in all_members:
            member.organization_id = None
            member.current_branch_id = None
        db.flush()
        
        # 6. Delete Organization
        db.delete(org)
        db.flush()
        
        # 7. Delete Users
        for member in all_members:
            db.delete(member)
    else:
        # For standard staff deletion
        from app.models.orders import Order, KOT
        from app.models.pos_session import POSSession
        from app.models.inventory import InventoryTransaction, BatchProduction
        
        # Nullify creator fields where possible
        db.query(Order).filter(Order.created_by == user_id).update({Order.created_by: None})
        db.query(KOT).filter(KOT.created_by == user_id).update({KOT.created_by: None})
        db.query(InventoryTransaction).filter(InventoryTransaction.created_by == user_id).update({InventoryTransaction.created_by: None})
        db.query(BatchProduction).filter(BatchProduction.created_by == user_id).update({BatchProduction.created_by: None})
        
        # Delete non-nullable dependencies (sessions MUST have a user)
        db.query(POSSession).filter(POSSession.user_id == user_id).delete(synchronize_session=False)
        
        db.delete(user)
        
    db.commit()
    return {"message": "User deleted successfully"}


@router.post("/{user_id}/image")
async def upload_user_profile_image(
    user_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: DBUser = Depends(check_admin_role)
):
    """Upload and update profile image for a user (Admin only)"""
    user = db.query(DBUser).filter(DBUser.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
        
    try:
        content = await file.read()
        user.profile_image_data = content
        user.profile_image_url = f"/api/v1/images/users/{user_id}/profile"
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not read file: {str(e)}")
        
    db.commit()
    db.refresh(user)
    return user
