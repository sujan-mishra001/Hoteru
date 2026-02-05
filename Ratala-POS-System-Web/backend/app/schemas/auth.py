from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

class Token(BaseModel):
    access_token: str
    token_type: str
    role: str
    organization_id: Optional[int] = None
    current_branch_id: Optional[int] = None
    accessible_branches: Optional[List[dict]] = []

class TokenData(BaseModel):
    username: Optional[str] = None
    role: Optional[str] = None
    organization_id: Optional[int] = None
    branch_id: Optional[int] = None

class UserCreate(BaseModel):
    email: str
    full_name: str
    password: str
    role: str = "worker"

class UserResponse(BaseModel):
    id: int
    username: str
    email: Optional[str] = None
    full_name: Optional[str] = None
    role: str
    company_name: Optional[str] = None
    company_location: Optional[str] = None
    disabled: Optional[bool] = None
    organization_id: Optional[int] = None
    current_branch_id: Optional[int] = None
    is_organization_owner: bool = False
    profile_image_url: Optional[str] = None
    permissions: List[str] = []

    class Config:
        from_attributes = True

class UserCreateByAdmin(BaseModel):
    username: Optional[str] = None
    email: str
    full_name: str
    password: str
    role: str
    branch_id: Optional[int] = None

class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    full_name: Optional[str] = None
    password: Optional[str] = None
    role: Optional[str] = None
    disabled: Optional[bool] = None
class UserProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    password: Optional[str] = None
