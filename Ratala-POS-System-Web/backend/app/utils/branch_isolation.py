"""
Branch Isolation Middleware and Utilities

This module provides automatic branch_id injection for all database operations
to ensure proper data isolation between branches in a multi-tenant system.
"""
from fastapi import Request, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional


def get_current_branch_id(request: Request) -> Optional[int]:
    """
    Extract the current branch_id from the authenticated user's session.
    
    Args:
        request: FastAPI request object containing user information
        
    Returns:
        int: The current branch_id or None if not set
    """
    # Get user from request state (set by auth middleware)
    user = getattr(request.state, 'user', None)
    if user and hasattr(user, 'current_branch_id'):
        return user.current_branch_id
    return None


def ensure_branch_access(user, branch_id: int, db: Session) -> bool:
    """
    Verify that a user has access to a specific branch.
    
    Args:
        user: The authenticated user object
        branch_id: The branch ID to check access for
        db: Database session
        
    Returns:
        bool: True if user has access, raises HTTPException otherwise
    """
    from app.models.user_branch import UserBranchAssignment
    
    # Admins have access to all branches
    if user.role == 'admin':
        return True
    
    # Check if user is assigned to this branch
    assignment = db.query(UserBranchAssignment).filter(
        UserBranchAssignment.user_id == user.id,
        UserBranchAssignment.branch_id == branch_id,
        UserBranchAssignment.is_active == True
    ).first()
    
    if not assignment:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"You do not have access to branch {branch_id}"
        )
    
    return True


def apply_branch_filter(query, model, branch_id: Optional[int]):
    """
    Apply branch_id filter to a SQLAlchemy query if the model has a branch_id column.
    
    Args:
        query: SQLAlchemy query object
        model: The model class being queried
        branch_id: The branch ID to filter by
        
    Returns:
        Modified query with branch filter applied
    """
    # Check if model has branch_id attribute
    if hasattr(model, 'branch_id') and branch_id is not None:
        query = query.filter(model.branch_id == branch_id)
    
    return query


def set_branch_id_on_create(obj, branch_id: Optional[int]):
    """
    Automatically set branch_id on a new object before inserting into database.
    
    Args:
        obj: The model instance to set branch_id on
        branch_id: The branch ID to set
    """
    if hasattr(obj, 'branch_id') and branch_id is not None:
        obj.branch_id = branch_id


class BranchIsolationMixin:
    """
    Mixin class to add branch isolation helper methods to service classes.
    
    Usage:
        class OrderService(BranchIsolationMixin):
            def get_orders(self, db: Session, user):
                branch_id = self.get_user_branch_id(user)
                query = db.query(Order)
                query = self.filter_by_branch(query, Order, branch_id)
                return query.all()
    """
    
    @staticmethod
    def get_user_branch_id(user) -> Optional[int]:
        """Get the current branch_id from user object"""
        return getattr(user, 'current_branch_id', None)
    
    @staticmethod
    def filter_by_branch(query, model, branch_id: Optional[int]):
        """Apply branch filter to query"""
        return apply_branch_filter(query, model, branch_id)
    
    @staticmethod
    def set_branch(obj, branch_id: Optional[int]):
        """Set branch_id on object"""
        set_branch_id_on_create(obj, branch_id)


# Decorator for automatic branch filtering
def with_branch_isolation(func):
    """
    Decorator to automatically apply branch isolation to service methods.
    
    The decorated function must accept 'db' and 'current_user' parameters.
    """
    from functools import wraps
    
    @wraps(func)
    def wrapper(*args, **kwargs):
        # Extract db and current_user from kwargs
        db = kwargs.get('db')
        current_user = kwargs.get('current_user')
        
        if current_user and hasattr(current_user, 'current_branch_id'):
            # Store branch_id in kwargs for use in the function
            kwargs['branch_id'] = current_user.current_branch_id
        
        return func(*args, **kwargs)
    
    return wrapper
