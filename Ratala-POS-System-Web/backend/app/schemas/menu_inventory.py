from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class CategoryCreate(BaseModel):
    name: str
    type: str = "KOT"
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
