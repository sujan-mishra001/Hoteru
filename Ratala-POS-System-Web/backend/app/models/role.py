"""
Role model for dynamic role and permission management
"""
from sqlalchemy import Column, Integer, String, Text, JSON, DateTime
from datetime import datetime
from app.db.database import Base


class Role(Base):
    """Role model with dynamic permissions stored as JSON"""
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True, nullable=False)
    description = Column(Text, nullable=True)
    permissions = Column(JSON, default=list)  # List of permission strings
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
