"""
Session tracking model for enhanced security
"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.sql import func
from app.database import Base


class UserSession(Base):
    """Track active user sessions"""
    __tablename__ = "user_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    token_jti = Column(String, unique=True, nullable=False, index=True)  # JWT ID
    ip_address = Column(String, nullable=True)
    user_agent = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=False)
    last_activity = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    is_active = Column(Boolean, default=True)
    revoked_at = Column(DateTime(timezone=True), nullable=True)


class TokenBlacklist(Base):
    """Blacklist for revoked tokens"""
    __tablename__ = "token_blacklist"

    id = Column(Integer, primary_key=True, index=True)
    token_jti = Column(String, unique=True, nullable=False, index=True)
    user_id = Column(Integer, nullable=False)
    revoked_at = Column(DateTime(timezone=True), server_default=func.now())
    reason = Column(String, nullable=True)  # logout, expired, security, etc.
