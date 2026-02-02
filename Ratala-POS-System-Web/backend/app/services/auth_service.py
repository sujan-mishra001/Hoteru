"""
Authentication and authorization service
"""
from typing import Optional
from sqlalchemy.orm import Session
from app.models.auth import User
from app.dependencies import get_password_hash, verify_password


class AuthService:
    """Service for authentication operations"""
    
    @staticmethod
    def authenticate_user(db: Session, username: str, password: str) -> Optional[User]:
        """Authenticate a user by username/email and password"""
        user = db.query(User).filter(
            (User.username == username) | (User.email == username)
        ).first()
        
        if not user or not verify_password(password, user.hashed_password):
            return None
        
        return user
    
    @staticmethod
    def create_user(db: Session, email: str, full_name: str, password: str, role: str = "worker") -> User:
        """Create a new user"""
        # Check if user already exists
        existing_user = db.query(User).filter(User.email == email).first()
        if existing_user:
            raise ValueError("Email already registered")
        
        new_user = User(
            username=email,
            email=email,
            full_name=full_name,
            hashed_password=get_password_hash(password),
            role=role,
            disabled=False
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        return new_user
    
    @staticmethod
    def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
        """Get user by ID"""
        return db.query(User).filter(User.id == user_id).first()
    
    @staticmethod
    def get_user_by_email(db: Session, email: str) -> Optional[User]:
        """Get user by email"""
        return db.query(User).filter(User.email == email).first()
