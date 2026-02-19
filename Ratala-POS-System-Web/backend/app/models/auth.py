"""
Authentication and user models
"""
from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, LargeBinary
from sqlalchemy.orm import relationship
from app.db.database import Base


class User(Base):
    """User model for authentication and authorization"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, nullable=False)
    company_name = Column(String, nullable=True)  # Legacy field, kept for backward compatibility
    company_location = Column(String, nullable=True)  # Legacy field
    hashed_password = Column(String, nullable=False)
    role = Column(String, nullable=False)  # admin, worker, waiter, bartender
    disabled = Column(Boolean, default=False)
    
    # Multi-tenant fields
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=True, index=True)
    current_branch_id = Column(Integer, ForeignKey("branches.id", ondelete="SET NULL"), nullable=True)  # Session management
    is_organization_owner = Column(Boolean, default=False, nullable=False)
    profile_image_url = Column(String, nullable=True)
    profile_image_data = Column(LargeBinary, nullable=True)
    
    # Relationships
    organization = relationship("Organization", back_populates="users", foreign_keys=[organization_id])
    owned_organization = relationship("Organization", back_populates="owner", foreign_keys="Organization.owner_id", uselist=False)
    branch_assignments = relationship("UserBranchAssignment", back_populates="user", cascade="all, delete-orphan")
    pos_sessions = relationship("POSSession", back_populates="user", cascade="all, delete-orphan")
    current_branch = relationship("Branch", back_populates="current_users")
