from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class OrganizationCreate(BaseModel):
    name: str
    slug: str
    subscription_plan: str = "free"
    company_address: Optional[str] = None
    company_phone: Optional[str] = None
    company_email: Optional[str] = None

class OrganizationUpdate(BaseModel):
    name: Optional[str] = None
    subscription_plan: Optional[str] = None
    subscription_status: Optional[str] = None
    max_branches: Optional[int] = None
    max_users: Optional[int] = None
    company_address: Optional[str] = None
    company_phone: Optional[str] = None
    company_email: Optional[str] = None

class OrganizationResponse(BaseModel):
    id: int
    name: str
    slug: str
    subscription_plan: str
    subscription_status: str
    subscription_start_date: Optional[datetime] = None
    subscription_end_date: Optional[datetime] = None
    max_branches: int
    max_users: int
    company_address: Optional[str] = None
    company_phone: Optional[str] = None
    company_email: Optional[str] = None
    owner_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class BranchCreate(BaseModel):
    name: str
    code: str
    location: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None

class BranchUpdate(BaseModel):
    name: Optional[str] = None
    location: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    facebook_url: Optional[str] = None
    instagram_url: Optional[str] = None
    slogan: Optional[str] = None
    is_active: Optional[bool] = None

class BranchResponse(BaseModel):
    id: int
    organization_id: int
    name: str
    code: str
    location: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    facebook_url: Optional[str] = None
    instagram_url: Optional[str] = None
    slogan: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class BranchBasicResponse(BaseModel):
    id: int
    name: str
    code: str
    location: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    is_active: bool

    class Config:
        from_attributes = True

class BranchSelectionRequest(BaseModel):
    branch_id: int

class UserBranchAssignmentCreate(BaseModel):
    user_id: int
    branch_id: int
    is_primary: bool = False

class UserBranchAssignmentResponse(BaseModel):
    id: int
    user_id: int
    branch_id: int
    organization_id: int
    is_primary: bool
    created_at: datetime

    class Config:
        from_attributes = True
