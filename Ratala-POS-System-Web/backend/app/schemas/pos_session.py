from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class POSSessionBase(BaseModel):
    opening_cash: float = 0.0
    notes: Optional[str] = None
    branch_id: Optional[int] = None

class POSSessionCreate(POSSessionBase):
    pass

class POSSessionUpdate(BaseModel):
    actual_cash: Optional[float] = None
    status: Optional[str] = None
    notes: Optional[str] = None
    
    # These might be updated by the system on close
    total_sales: Optional[float] = None
    cash_sales: Optional[float] = None
    online_sales: Optional[float] = None
    credit_sales: Optional[float] = None
    expected_cash: Optional[float] = None
    end_time: Optional[datetime] = None
    total_orders: Optional[int] = None

class POSSessionUser(BaseModel):
    id: int
    full_name: str
    role: str
    
    class Config:
        from_attributes = True

class POSSession(POSSessionBase):
    id: int
    user_id: int
    start_time: datetime
    end_time: Optional[datetime]
    status: str
    actual_cash: float
    expected_cash: float
    total_sales: float
    cash_sales: float
    online_sales: float
    credit_sales: float
    total_orders: int
    report_path: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime]
    user: Optional[POSSessionUser]

    class Config:
        from_attributes = True
