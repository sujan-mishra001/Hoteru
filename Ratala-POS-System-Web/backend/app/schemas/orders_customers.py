from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

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
    due_amount: Optional[float] = None

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

class UserBasicResponse(BaseModel):
    id: int
    full_name: Optional[str] = None
    email: str
    class Config:
        from_attributes = True

class TableResponse(BaseModel):
    id: int
    table_id: str
    floor: Optional[str] = None
    status: str
    class Config:
        from_attributes = True

class OrderMinimalResponse(BaseModel):
    id: int
    order_number: str
    order_type: str
    status: str
    table_id: Optional[int] = None
    table: Optional[TableResponse] = None
    class Config:
        from_attributes = True

class CustomerBasicResponse(BaseModel):
    id: int
    name: str
    phone: Optional[str] = None
    class Config:
        from_attributes = True

class DeliveryPartnerBasicResponse(BaseModel):
    id: int
    name: str
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
    order_id: Optional[int] = None
    order: Optional[OrderMinimalResponse] = None
    user: Optional[UserBasicResponse] = None
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
    service_charge_amount: float = 0
    tax_amount: float = 0
    delivery_charge: float = 0
    created_at: datetime
    updated_at: datetime
    table: Optional[TableResponse] = None
    customer: Optional[CustomerBasicResponse] = None
    delivery_partner: Optional[DeliveryPartnerBasicResponse] = None
    items: List[OrderItemResponse] = []
    kots: List[KOTResponse] = []
    class Config:
        from_attributes = True

class OrderCreate(BaseModel):
    table_id: Optional[int] = None
    customer_id: Optional[int] = None
    order_type: str
    status: str = "Pending"
    session_id: Optional[int] = None
    gross_amount: Optional[float] = 0
    discount: Optional[float] = 0
    net_amount: Optional[float] = 0
    paid_amount: Optional[float] = 0
    credit_amount: Optional[float] = 0
    payment_type: Optional[str] = None
    delivery_partner_id: Optional[int] = None
    service_charge_amount: Optional[float] = 0
    tax_amount: Optional[float] = 0
    delivery_charge: Optional[float] = 0

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
