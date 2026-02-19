"""
User management routes (Admin only)
"""
from fastapi import APIRouter, Depends, HTTPException, status, Body, File, UploadFile
from sqlalchemy.orm import Session, joinedload

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
    query = db.query(DBUser).options(
        joinedload(DBUser.organization),
        joinedload(DBUser.branch_assignments).joinedload(UserBranchAssignment.branch)
    )
    
    if current_user.role == "platform_admin":
        return query.all()
        
    if not current_user.organization_id:
        return []
        
    users = query.filter(
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
    target_branch_id = user_data.branch_id or (current_user.current_branch_id if current_user.role != "platform_admin" else None)
    
    if current_user.role == "platform_admin":
        is_valid_role = True
    else:
        is_valid_role = user_data.role == "admin" or db.query(Role).filter(
            Role.name == user_data.role,
            Role.branch_id == target_branch_id
        ).first() is not None
        
    if not is_valid_role:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid role. The role '{user_data.role}' does not exist in the target branch."
        )
    
    # Deriving Organization ID
    org_id = current_user.organization_id
    if current_user.role == "platform_admin" and user_data.branch_id:
        from app.models.branch import Branch
        target_branch = db.query(Branch).filter(Branch.id == user_data.branch_id).first()
        if target_branch:
            org_id = target_branch.organization_id

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
        organization_id=org_id,
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
            organization_id=org_id,
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
        # Platform Admin can assign any role
        if current_user.role == "platform_admin":
            is_valid_role = True
        else:
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
        
        # Collect IDs for manual cleanup of operational data
        from app.models.branch import Branch
        branches = db.query(Branch).filter(Branch.organization_id == org.id).all()
        branch_ids = [b.id for b in branches]
        
        if branch_ids:
            # 1. Get all related IDs for deep cleanup
            from app.models.orders import Order, KOT, OrderItem, KOTItem, Table, Floor, Session
            from app.models.pos_session import POSSession
            from app.models.inventory import InventoryTransaction, BatchProduction, UnitOfMeasurement, Product, BillOfMaterials, BOMItem
            from app.models.role import Role
            from app.models.menu import Category, MenuGroup, MenuItem
            from app.models.customers import Customer
            from app.models.printer import Printer
            from app.models.qr_code import QRCode
            from app.models.settings import PaymentMode, StorageArea, DiscountRule
            from app.models.purchase import Supplier, PurchaseBill, PurchaseReturn, PurchaseBillItem
            from app.models.delivery import DeliveryPartner
            
            product_ids = [r[0] for r in db.query(Product.id).filter(Product.branch_id.in_(branch_ids)).all()]
            order_ids = [r[0] for r in db.query(Order.id).filter(Order.branch_id.in_(branch_ids)).all()]
            # KOTs can be linked by branch_id OR pointing to orders we are deleting
            kot_ids = [r[0] for r in db.query(KOT.id).filter(
                (KOT.branch_id.in_(branch_ids)) | (KOT.order_id.in_(order_ids))
            ).all()]
            bom_ids = [r[0] for r in db.query(BillOfMaterials.id).filter(BillOfMaterials.branch_id.in_(branch_ids)).all()]
            purchase_bill_ids = [r[0] for r in db.query(PurchaseBill.id).filter(PurchaseBill.branch_id.in_(branch_ids)).all()]
            
            # 2. Delete operational items in order of dependency (Items -> Parents)
            
            # KOT items first
            if kot_ids:
                db.query(KOTItem).filter(KOTItem.kot_id.in_(kot_ids)).delete(synchronize_session=False)
                db.flush()
                # Delete KOTs before Orders
                db.query(KOT).filter(KOT.id.in_(kot_ids)).delete(synchronize_session=False)
                db.flush()

            # Order items
            if order_ids:
                db.query(OrderItem).filter(OrderItem.order_id.in_(order_ids)).delete(synchronize_session=False)
                db.flush()
                # Delete Orders before POSSessions
                db.query(Order).filter(Order.id.in_(order_ids)).delete(synchronize_session=False)
                db.flush()
            
            # Inventory dependencies
            if product_ids:
                db.query(InventoryTransaction).filter(InventoryTransaction.product_id.in_(product_ids)).delete(synchronize_session=False)
                db.query(BatchProduction).filter(BatchProduction.finished_product_id.in_(product_ids)).delete(synchronize_session=False)
                db.query(BOMItem).filter(BOMItem.product_id.in_(product_ids)).delete(synchronize_session=False)
                db.query(PurchaseBillItem).filter(PurchaseBillItem.product_id.in_(product_ids)).delete(synchronize_session=False)
                db.flush()
            
            # Remaining branch-linked operational data
            db.query(BatchProduction).filter(BatchProduction.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(POSSession).filter(POSSession.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.flush()
            
            # Menu items and Categories
            db.query(MenuItem).filter(MenuItem.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(MenuGroup).filter(MenuGroup.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(Category).filter(Category.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.flush()
            
            # Bill of Materials and Batch Production cleanup
            if bom_ids:
                # 1. Delete all production records referencing these BOMs (even if branch_id differs)
                db.query(BatchProduction).filter(BatchProduction.bom_id.in_(bom_ids)).delete(synchronize_session=False)
                # 2. Delete all items belonging to these BOMs
                db.query(BOMItem).filter(BOMItem.bom_id.in_(bom_ids)).delete(synchronize_session=False)
                db.flush()
            
            # 3. Finally delete the BOMs themselves
            db.query(BillOfMaterials).filter(BillOfMaterials.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.flush()
            
            # Products
            db.query(Product).filter(Product.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.flush()
            
            # Tables and Floors (Handle self-referencing table merges)
            db.query(Table).filter(Table.branch_id.in_(branch_ids)).update({Table.merged_to_id: None}, synchronize_session=False)
            db.query(QRCode).filter(QRCode.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(Table).filter(Table.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(Floor).filter(Floor.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(Session).filter(Session.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            
            # Purchases
            if purchase_bill_ids:
                db.query(PurchaseBillItem).filter(PurchaseBillItem.purchase_bill_id.in_(purchase_bill_ids)).delete(synchronize_session=False)
                # Delete returns referencing these bills first
                db.query(PurchaseReturn).filter(PurchaseReturn.purchase_bill_id.in_(purchase_bill_ids)).delete(synchronize_session=False)
                db.flush()
            db.query(PurchaseReturn).filter(PurchaseReturn.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(PurchaseBill).filter(PurchaseBill.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(Supplier).filter(Supplier.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            
            # Utilities and Core branch settings
            db.query(UnitOfMeasurement).filter(UnitOfMeasurement.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(Role).filter(Role.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(Customer).filter(Customer.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(Printer).filter(Printer.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(DeliveryPartner).filter(DeliveryPartner.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            
            # User Assignments
            from app.models.user_branch import UserBranchAssignment
            db.query(UserBranchAssignment).filter(UserBranchAssignment.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            
            # Settings
            db.query(PaymentMode).filter(PaymentMode.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(StorageArea).filter(StorageArea.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.query(DiscountRule).filter(DiscountRule.branch_id.in_(branch_ids)).delete(synchronize_session=False)
            db.flush()

        # 3. Detach users from Org and Branches BEFORE deleting branches (CRITICAL for FKs)
        for member in all_members:
            member.organization_id = None
            member.current_branch_id = None
        db.flush()

        # 4. Clean up any remaining sessions/orders/transactions for these specific users
        # Delete in order of dependency
        db.query(InventoryTransaction).filter(InventoryTransaction.created_by.in_(member_ids)).delete(synchronize_session=False)
        db.query(BatchProduction).filter(BatchProduction.created_by.in_(member_ids)).delete(synchronize_session=False)
        db.query(KOT).filter(KOT.created_by.in_(member_ids)).delete(synchronize_session=False)
        db.query(Order).filter(Order.created_by.in_(member_ids)).delete(synchronize_session=False)
        db.query(POSSession).filter(POSSession.user_id.in_(member_ids)).delete(synchronize_session=False)
        db.flush()

        # 5. Finally delete the branches and organization
        if branch_ids:
            db.query(Branch).filter(Branch.organization_id == org.id).delete(synchronize_session=False)
        
        db.flush()
        db.delete(org)
        db.flush()
        
        # 6. Delete Users
        for member in all_members:
            try:
                db.delete(member)
            except Exception as e:
                # If a user still has dependencies we can't clear, nullify them
                print(f"Warning: Could not delete user {member.id}: {str(e)}")
                member.disabled = True

    else:
        # For standard staff (non-owner) deletion
        from app.models.orders import Order, KOT
        from app.models.pos_session import POSSession
        from app.models.inventory import InventoryTransaction, BatchProduction
        from app.models.user_branch import UserBranchAssignment
        
        # 1. Clear branch assignments
        db.query(UserBranchAssignment).filter(UserBranchAssignment.user_id == user_id).delete(synchronize_session=False)

        # 2. Get user's sessions to handle their dependencies
        user_session_ids = [s[0] for s in db.query(POSSession.id).filter(POSSession.user_id == user_id).all()]

        # 3. Nullify references to this user and their sessions
        # First, nullify pos_session_id in related tables (Order, InventoryTransaction, BatchProduction)
        if user_session_ids:
            db.query(Order).filter(Order.pos_session_id.in_(user_session_ids)).update({Order.pos_session_id: None}, synchronize_session=False)
            db.query(InventoryTransaction).filter(InventoryTransaction.pos_session_id.in_(user_session_ids)).update({InventoryTransaction.pos_session_id: None}, synchronize_session=False)
            db.query(BatchProduction).filter(BatchProduction.pos_session_id.in_(user_session_ids)).update({BatchProduction.pos_session_id: None}, synchronize_session=False)
            db.flush()

        # 4. Nullify creator fields
        db.query(Order).filter(Order.created_by == user_id).update({Order.created_by: None}, synchronize_session=False)
        db.query(KOT).filter(KOT.created_by == user_id).update({KOT.created_by: None}, synchronize_session=False)
        db.query(InventoryTransaction).filter(InventoryTransaction.created_by == user_id).update({InventoryTransaction.created_by: None}, synchronize_session=False)
        db.query(BatchProduction).filter(BatchProduction.created_by == user_id).update({BatchProduction.created_by: None}, synchronize_session=False)
        
        # 5. Delete non-nullable dependencies (sessions MUST have a user)
        if user_session_ids:
            db.query(POSSession).filter(POSSession.id.in_(user_session_ids)).delete(synchronize_session=False)
        
        db.flush()
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
