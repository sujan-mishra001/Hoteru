"""
Organization model for multi-tenant SaaS
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from app.database import Base


class SubscriptionPlan(str, enum.Enum):
    """Subscription plan types"""
    FREE = "free"
    BASIC = "basic"
    PREMIUM = "premium"
    ENTERPRISE = "enterprise"
    LEGACY = "legacy"  # For existing data during migration


class SubscriptionStatus(str, enum.Enum):
    """Subscription status"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    TRIAL = "trial"
    EXPIRED = "expired"
    SUSPENDED = "suspended"


class Organization(Base):
    """Organization/Company model for multi-tenant architecture"""
    __tablename__ = "organizations"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    slug = Column(String, unique=True, nullable=False, index=True)
    
    # Subscription details
    subscription_plan = Column(
        SQLEnum(SubscriptionPlan), 
        default=SubscriptionPlan.FREE, 
        nullable=False
    )
    subscription_status = Column(
        SQLEnum(SubscriptionStatus), 
        default=SubscriptionStatus.TRIAL, 
        nullable=False
    )
    subscription_start_date = Column(DateTime, default=datetime.utcnow)
    subscription_end_date = Column(DateTime, nullable=True)
    
    # Plan limits
    max_branches = Column(Integer, default=1)  # Based on subscription plan
    max_users = Column(Integer, default=5)  # Based on subscription plan
    
    # Contact & company info
    company_address = Column(String, nullable=True)
    company_phone = Column(String, nullable=True)
    company_email = Column(String, nullable=True)
    
    # Ownership
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    owner = relationship("User", back_populates="owned_organization", foreign_keys=[owner_id])
    branches = relationship("Branch", back_populates="organization", cascade="all, delete-orphan")
    users = relationship("User", back_populates="organization", foreign_keys="User.organization_id")

    def __repr__(self):
        return f"<Organization(id={self.id}, name='{self.name}', plan={self.subscription_plan})>"
    
    @property
    def is_active(self):
        """Check if organization subscription is active"""
        return self.subscription_status == SubscriptionStatus.ACTIVE
    
    @property
    def can_create_branch(self):
        """Check if organization can create more branches"""
        current_branches = len(self.branches) if self.branches else 0
        return current_branches < self.max_branches
    
    @property
    def can_create_user(self):
        """Check if organization can create more users"""
        current_users = len(self.users) if self.users else 0
        return current_users < self.max_users
