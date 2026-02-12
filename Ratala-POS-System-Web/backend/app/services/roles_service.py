"""
Role service for managing dynamic roles and permissions
"""
from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.role import Role
from app.schemas import RoleCreate, RoleUpdate


def get_roles(db: Session, skip: int = 0, limit: int = 100) -> List[Role]:
    """Get all roles"""
    return db.query(Role).offset(skip).limit(limit).all()


def get_role(db: Session, role_id: int) -> Optional[Role]:
    """Get a single role by ID"""
    return db.query(Role).filter(Role.id == role_id).first()


def get_role_by_name(db: Session, name: str) -> Optional[Role]:
    """Get a single role by name"""
    return db.query(Role).filter(Role.name == name).first()


def create_role(db: Session, role_data: RoleCreate) -> Role:
    """Create a new role"""
    db_role = Role(
        name=role_data.name,
        description=role_data.description,
        permissions=role_data.permissions
    )
    db.add(db_role)
    db.commit()
    db.refresh(db_role)
    return db_role


def update_role(db: Session, role_id: int, role_data: RoleUpdate) -> Optional[Role]:
    """Update an existing role"""
    db_role = get_role(db, role_id)
    if not db_role:
        return None
    
    update_data = role_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_role, key, value)
    
    db.commit()
    db.refresh(db_role)
    return db_role


def delete_role(db: Session, role_id: int) -> bool:
    """Delete a role"""
    db_role = get_role(db, role_id)
    if not db_role:
        return False
    
    db.delete(db_role)
    db.commit()
    return True


def get_available_permissions() -> List[str]:
    """
    Get all available granular permissions in the system.
    This can be expanded as more features are added.
    """
    return [
        "dashboard.view",
        "pos.access"
    ]
