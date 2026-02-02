"""
Branch model for multi-location support
"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base


class Branch(Base):
    """Branch/Location model for multi-tenant organizations"""
    __tablename__ = "branches"

    id = Column(Integer, primary_key=True, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=False, index=True)
    
    # Branch details
    name = Column(String, nullable=False)
    code = Column(String, unique=True, nullable=False, index=True)  # e.g., "DA001", "DA002"
    location = Column(String, nullable=True)
    address = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    email = Column(String, nullable=True)
    
    # Status
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    organization = relationship("Organization", back_populates="branches")
    user_assignments = relationship("UserBranchAssignment", back_populates="branch", cascade="all, delete-orphan")
    
    # Operational data relationships (will be added to existing models)
    # tables = relationship("Table", back_populates="branch")
    # sessions = relationship("Session", back_populates="branch")
    # orders = relationship("Order", back_populates="branch")
    
    def __repr__(self):
        return f"<Branch(id={self.id}, code='{self.code}', name='{self.name}', org_id={self.organization_id})>"
    
    @property
    def full_name(self):
        """Get full branch name including location"""
        if self.location:
            return f"{self.name} - {self.location}"
        return self.name
