"""
User-Branch assignment model for multi-branch access control
"""
from sqlalchemy import Column, Integer, Boolean, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base


class UserBranchAssignment(Base):
    """Assignment model linking users to branches they can access"""
    __tablename__ = "user_branch_assignments"
    
    __table_args__ = (
        UniqueConstraint('user_id', 'branch_id', name='unique_user_branch'),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=False, index=True)
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=False, index=True)
    
    # Primary branch flag - user's default branch
    is_primary = Column(Boolean, default=False, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="branch_assignments")
    branch = relationship("Branch", back_populates="user_assignments")
    
    def __repr__(self):
        return f"<UserBranchAssignment(user_id={self.user_id}, branch_id={self.branch_id}, primary={self.is_primary})>"
