"""
Branch service for managing organization branches
"""
from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.branch import Branch
from app.models.user_branch import UserBranchAssignment
from app.schemas import BranchCreate, BranchUpdate
from datetime import datetime
import re


def slugify(text: str) -> str:
    """Create a URL-friendly slug from text"""
    if not text:
        return ""
    text = text.lower()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[-\s]+', '-', text).strip('-')
    return text


def get_branch(db: Session, branch_id: int) -> Optional[Branch]:
    """Get branch by ID"""
    return db.query(Branch).filter(Branch.id == branch_id).first()


def get_branch_by_code(db: Session, code: str) -> Optional[Branch]:
    """Get branch by code"""
    return db.query(Branch).filter(Branch.code == code).first()


def get_branches_by_organization(
    db: Session, 
    organization_id: int,
    skip: int = 0,
    limit: int = 100,
    active_only: bool = False
) -> List[Branch]:
    """Get all branches for an organization"""
    query = db.query(Branch).filter(Branch.organization_id == organization_id)
    
    if active_only:
        query = query.filter(Branch.is_active == True)
    
    return query.offset(skip).limit(limit).all()


def get_branches_by_user(db: Session, user_id: int) -> List[Branch]:
    """Get all branches accessible by a user"""
    # Join UserBranchAssignment with Branch
    branches = db.query(Branch).join(
        UserBranchAssignment,
        UserBranchAssignment.branch_id == Branch.id
    ).filter(
        UserBranchAssignment.user_id == user_id,
        Branch.is_active == True
    ).all()
    
    return branches


def get_primary_branch(db: Session, user_id: int) -> Optional[Branch]:
    """Get user's primary branch"""
    assignment = db.query(UserBranchAssignment).filter(
        UserBranchAssignment.user_id == user_id,
        UserBranchAssignment.is_primary == True
    ).first()
    
    if assignment:
        return get_branch(db, assignment.branch_id)
    
    # If no primary branch set, return first assigned branch
    branches = get_branches_by_user(db, user_id)
    return branches[0] if branches else None


def create_branch(
    db: Session,
    organization_id: int,
    branch_data: BranchCreate
) -> Branch:
    """Create a new branch"""
    db_branch = Branch(
        organization_id=organization_id,
        name=branch_data.name,
        slug=slugify(branch_data.name),
        code=branch_data.code,
        location=branch_data.location,
        address=branch_data.address,
        phone=branch_data.phone,
        email=branch_data.email,
        facebook_url=getattr(branch_data, 'facebook_url', None),
        instagram_url=getattr(branch_data, 'instagram_url', None),
        slogan=getattr(branch_data, 'slogan', None),
        is_active=True
    )
    
    db.add(db_branch)
    db.commit()
    db.refresh(db_branch)
    
    return db_branch


def update_branch(
    db: Session,
    branch_id: int,
    branch_data: BranchUpdate
) -> Optional[Branch]:
    """Update branch details"""
    db_branch = get_branch(db, branch_id)
    
    if not db_branch:
        return None
    
    update_data = branch_data.model_dump(exclude_unset=True)
    
    if 'name' in update_data:
        db_branch.slug = slugify(update_data['name'])
        
    for key, value in update_data.items():
        setattr(db_branch, key, value)
    
    db_branch.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_branch)
    
    return db_branch


def delete_branch(db: Session, branch_id: int) -> bool:
    """Delete/deactivate branch"""
    db_branch = get_branch(db, branch_id)
    
    if not db_branch:
        return False
    
    # Deactivate instead of deleting to preserve data integrity
    db_branch.is_active = False
    db.commit()
    
    return True


def assign_user_to_branch(
    db: Session,
    user_id: int,
    branch_id: int,
    organization_id: int,
    is_primary: bool = False
) -> UserBranchAssignment:
    """Assign a user to a branch"""
    
    # Check if assignment already exists
    existing = db.query(UserBranchAssignment).filter(
        UserBranchAssignment.user_id == user_id,
        UserBranchAssignment.branch_id == branch_id
    ).first()
    
    if existing:
        # Update primary status if needed
        if is_primary and not existing.is_primary:
            # Unset other primary branches for this user
            db.query(UserBranchAssignment).filter(
                UserBranchAssignment.user_id == user_id,
                UserBranchAssignment.is_primary == True
            ).update({"is_primary": False})
            
            existing.is_primary = True
            db.commit()
            db.refresh(existing)
        return existing
    
    # If this is the user's first branch, make it primary
    user_branches = db.query(UserBranchAssignment).filter(
        UserBranchAssignment.user_id == user_id
    ).count()
    
    if user_branches == 0:
        is_primary = True
    
    # If setting as primary, unset other primary branches
    if is_primary:
        db.query(UserBranchAssignment).filter(
            UserBranchAssignment.user_id == user_id,
            UserBranchAssignment.is_primary == True
        ).update({"is_primary": False})
    
    db_assignment = UserBranchAssignment(
        user_id=user_id,
        branch_id=branch_id,
        organization_id=organization_id,
        is_primary=is_primary
    )
    
    db.add(db_assignment)
    db.commit()
    db.refresh(db_assignment)
    
    return db_assignment


def remove_user_from_branch(
    db: Session,
    user_id: int,
    branch_id: int
) -> bool:
    """Remove user's access to a branch"""
    db_assignment = db.query(UserBranchAssignment).filter(
        UserBranchAssignment.user_id == user_id,
        UserBranchAssignment.branch_id == branch_id
    ).first()
    
    if not db_assignment:
        return False
    
    was_primary = db_assignment.is_primary
    db.delete(db_assignment)
    db.commit()
    
    # If this was the primary branch, set another branch as primary
    if was_primary:
        remaining_assignment = db.query(UserBranchAssignment).filter(
            UserBranchAssignment.user_id == user_id
        ).first()
        
        if remaining_assignment:
            remaining_assignment.is_primary = True
            db.commit()
    
    return True


def get_user_branch_assignments(db: Session, user_id: int) -> List[UserBranchAssignment]:
    """Get all branch assignments for a user"""
    return db.query(UserBranchAssignment).filter(
        UserBranchAssignment.user_id == user_id
    ).all()
