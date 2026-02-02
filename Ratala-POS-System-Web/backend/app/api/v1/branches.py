"""
API endpoints for branch management
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.dependencies import get_current_user
from app.models.auth import User
from app.schemas import (
    BranchCreate,
    BranchUpdate,
    BranchResponse,
    BranchBasicResponse,
    UserBranchAssignmentCreate,
    UserBranchAssignmentResponse
)
from app.services import branch_service, organization_service


router = APIRouter(prefix="/branches", tags=["Branches"])


@router.post("/", response_model=BranchResponse, status_code=status.HTTP_201_CREATED)
def create_branch(
    branch_data: BranchCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new branch (admin only, requires valid subscription)
    """
    # Only admins can create branches
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can create branches"
        )
    
    # Check if user has an organization
    if not current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is not associated with any organization"
        )
    
    # Get organization and validate subscription
    organization = organization_service.get_organization(db, current_user.organization_id)
    
    # DEVELOPMENT MODE: Subscription validation disabled for testing
    # TODO: Re-enable this in production
    # validation = organization_service.validate_subscription(organization)
    # if not validation["can_create_branch"]:
    #     raise HTTPException(
    #         status_code=status.HTTP_403_FORBIDDEN,
    #         detail=f"Cannot create branch: {validation['message']}"
    #     )
    
    # Check if branch code is unique
    existing_branch = branch_service.get_branch_by_code(db, branch_data.code)
    if existing_branch:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Branch code already exists"
        )
    
    branch = branch_service.create_branch(db, current_user.organization_id, branch_data)
    
    # Automatically assign the creator (admin) to this branch
    branch_service.assign_user_to_branch(
        db, 
        current_user.id, 
        branch.id, 
        current_user.organization_id,
        is_primary=False  # Don't override their existing primary branch
    )
    
    return branch


@router.get("/", response_model=List[BranchBasicResponse])
def list_branches(
    active_only: bool = True,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """List all branches in the user's organization"""
    if not current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is not associated with any organization"
        )
    
    branches = branch_service.get_branches_by_organization(
        db,
        current_user.organization_id,
        skip=skip,
        limit=limit,
        active_only=active_only
    )
    
    return branches


@router.get("/user/{user_id}", response_model=List[BranchBasicResponse])
def get_user_branches(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all branches accessible by a specific user"""
    # Only admins or the user themselves can view this
    if current_user.id != user_id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    branches = branch_service.get_branches_by_user(db, user_id)
    return branches


@router.get("/my/branches", response_model=List[BranchBasicResponse])
def get_my_branches(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all branches accessible by current user"""
    branches = branch_service.get_branches_by_user(db, current_user.id)
    return branches


@router.get("/my/primary", response_model=BranchResponse)
def get_my_primary_branch(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get current user's primary branch"""
    branch = branch_service.get_primary_branch(db, current_user.id)
    
    if not branch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No primary branch found for user"
        )
    
    return branch


@router.get("/{branch_id}", response_model=BranchResponse)
def get_branch(
    branch_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get branch details"""
    branch = branch_service.get_branch(db, branch_id)
    
    if not branch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Branch not found"
        )
    
    # Check if user has access to this branch
    if branch.organization_id != current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied to this branch"
        )
    
    return branch


@router.put("/{branch_id}", response_model=BranchResponse)
@router.patch("/{branch_id}", response_model=BranchResponse)
def update_branch(
    branch_id: int,
    branch_data: BranchUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update branch details (admin only)"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can update branches"
        )
    
    branch = branch_service.get_branch(db, branch_id)
    
    if not branch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Branch not found"
        )
    
    # Check if branch belongs to user's organization
    if branch.organization_id != current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied to this branch"
        )
    
    updated_branch = branch_service.update_branch(db, branch_id, branch_data)
    return updated_branch


@router.delete("/{branch_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_branch(
    branch_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Deactivate branch (admin only)"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can delete branches"
        )
    
    branch = branch_service.get_branch(db, branch_id)
    
    if not branch:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Branch not found"
        )
    
    # Check if branch belongs to user's organization
    if branch.organization_id != current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied to this branch"
        )
    
    branch_service.delete_branch(db, branch_id)
    return None


@router.post("/assign", response_model=UserBranchAssignmentResponse, status_code=status.HTTP_201_CREATED)
def assign_user_to_branch(
    assignment_data: UserBranchAssignmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Assign a user to a branch (admin only)"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can assign users to branches"
        )
    
    # Verify branch exists and belongs to current org
    branch = branch_service.get_branch(db, assignment_data.branch_id)
    if not branch or branch.organization_id != current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Branch not found or access denied"
        )
    
    assignment = branch_service.assign_user_to_branch(
        db,
        assignment_data.user_id,
        assignment_data.branch_id,
        current_user.organization_id,
        assignment_data.is_primary
    )
    
    return assignment


@router.delete("/assign/{user_id}/{branch_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_user_from_branch(
    user_id: int,
    branch_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Remove user's access to a branch (admin only)"""
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can remove branch assignments"
        )
    
    # Verify branch exists and belongs to current org
    branch = branch_service.get_branch(db, branch_id)
    if not branch or branch.organization_id != current_user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Branch not found or access denied"
        )
    
    success = branch_service.remove_user_from_branch(db, user_id, branch_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Assignment not found"
        )
    
    return None
