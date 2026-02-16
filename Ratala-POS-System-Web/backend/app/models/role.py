"""
Role model for dynamic role and permission management
"""
from sqlalchemy import Column, Integer, String, Text, JSON, DateTime, ForeignKey, UniqueConstraint
from datetime import datetime
from app.db.database import Base


class Role(Base):
    """Role model with dynamic permissions stored as JSON"""
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    description = Column(Text, nullable=True)
    permissions = Column(JSON, default=list)  # List of permission strings
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True, index=True)
    
    __table_args__ = (
        UniqueConstraint('name', 'branch_id', name='uq_role_name_branch'),
    )
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
