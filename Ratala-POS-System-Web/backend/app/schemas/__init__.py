"""
Pydantic schemas for request/response validation
"""
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime
from .pos_session import *


# ============ Auth Schemas ============
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
    permissions: List[str] = []

    class Config:
        from_attributes = True


# ============ Organization Schemas ============
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


# ============ Branch Schemas ============
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
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class BranchBasicResponse(BaseModel):
    """Simplified branch response for lists"""
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


# ============ User-Branch Assignment Schemas ============
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


class BranchSelectionRequest(BaseModel):
    """Request to select a branch for current session"""
    branch_id: int


# ============ Customer Schemas ============
class CustomerCreate(BaseModel):
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    customer_type: str = "Regular"


class CustomerUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    customer_type: Optional[str] = None


class CustomerResponse(BaseModel):
    id: int
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    customer_type: str
    total_spent: float
    total_visits: int
    due_amount: float
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============ Menu Schemas ============
class CategoryCreate(BaseModel):
    name: str
    type: str = "KOT"  # Default to KOT
    image: Optional[str] = None
    description: Optional[str] = None
    is_active: bool = True


class CategoryResponse(BaseModel):
    id: int
    name: str
    type: str
    image: Optional[str] = None
    description: Optional[str] = None
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class MenuGroupCreate(BaseModel):
    name: str
    category_id: int
    image: Optional[str] = None
    description: Optional[str] = None
    is_active: bool = True


class MenuGroupResponse(BaseModel):
    id: int
    name: str
    category_id: int
    image: Optional[str] = None
    description: Optional[str] = None
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class MenuItemCreate(BaseModel):
    name: str
    category_id: int
    group_id: Optional[int] = None
    price: float
    image: Optional[str] = None
    description: Optional[str] = None
    inventory_tracking: bool = False
    kot_bot: str = "KOT"
    is_active: bool = True


class MenuItemResponse(BaseModel):
    id: int
    name: str
    category_id: int
    group_id: Optional[int] = None
    price: float
    image: Optional[str] = None
    description: Optional[str] = None
    inventory_tracking: bool
    kot_bot: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============ Inventory Schemas ============
class UnitCreate(BaseModel):
    name: str
    abbreviation: Optional[str] = None


class ProductCreate(BaseModel):
    name: str
    category: Optional[str] = None
    unit_id: int
    current_stock: float = 0
    min_stock: float = 0


class InventoryTransactionCreate(BaseModel):
    product_id: int
    transaction_type: str
    quantity: float
    notes: Optional[str] = None


# ============ Purchase Schemas ============
class SupplierCreate(BaseModel):
    name: str
    contact_person: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None


class PurchaseBillCreate(BaseModel):
    supplier_id: int
    total_amount: float
    status: str = "Pending"


class PurchaseReturnCreate(BaseModel):
    purchase_bill_id: int
    total_amount: float
    reason: Optional[str] = None


# ============ Order Schemas ============
class TableResponse(BaseModel):
    id: int
    table_id: str
    floor: str
    status: str
    
    class Config:
        from_attributes = True


class CustomerBasicResponse(BaseModel):
    id: int
    name: str
    phone: Optional[str] = None
    
    class Config:
        from_attributes = True


class MenuItemBasicResponse(BaseModel):
    id: int
    name: str
    price: float
    
    class Config:
        from_attributes = True


class OrderItemResponse(BaseModel):
    id: int
    menu_item_id: int
    quantity: int
    price: float
    subtotal: float
    notes: Optional[str] = None
    menu_item: Optional[MenuItemBasicResponse] = None
    
    class Config:
        from_attributes = True


class KOTItemResponse(BaseModel):
    id: int
    menu_item_id: int
    quantity: int
    notes: Optional[str] = None
    menu_item: Optional[MenuItemBasicResponse] = None
    
    class Config:
        from_attributes = True


class KOTResponse(BaseModel):
    id: int
    kot_number: str
    kot_type: str
    status: str
    created_at: datetime
    items: List[KOTItemResponse] = []
    
    class Config:
        from_attributes = True


class OrderResponse(BaseModel):
    id: int
    order_number: str
    table_id: Optional[int] = None
    customer_id: Optional[int] = None
    order_type: str
    status: str
    total_amount: float
    gross_amount: float
    discount: float
    net_amount: float
    paid_amount: float
    credit_amount: float
    payment_type: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    table: Optional[TableResponse] = None
    customer: Optional[CustomerBasicResponse] = None
    items: List[OrderItemResponse] = []
    kots: List[KOTResponse] = []
    
    class Config:
        from_attributes = True


class OrderCreate(BaseModel):
    table_id: Optional[int] = None
    customer_id: Optional[int] = None
    order_type: str  # Table, Takeaway, Self Delivery, Delivery Partner, Pay First
    status: str = "Pending"
    session_id: Optional[int] = None
    gross_amount: Optional[float] = 0
    discount: Optional[float] = 0
    net_amount: Optional[float] = 0
    paid_amount: Optional[float] = 0
    credit_amount: Optional[float] = 0
    payment_type: Optional[str] = None


# ============ User Management Schemas ============
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


# ============ Role & Permission Schemas ============
class RoleBase(BaseModel):
    name: str
    description: Optional[str] = None
    permissions: List[str] = []


class RoleCreate(RoleBase):
    pass


class RoleUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    permissions: Optional[List[str]] = None


class RoleResponse(RoleBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
