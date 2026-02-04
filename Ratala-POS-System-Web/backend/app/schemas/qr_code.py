"""
QR Code Management API Schemas
"""
from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class QRCodeBase(BaseModel):
    name: str
    is_active: Optional[bool] = True
    display_order: Optional[int] = 0
    branch_id: Optional[int] = None


class QRCodeCreate(QRCodeBase):
    pass


class QRCodeUpdate(BaseModel):
    name: Optional[str] = None
    is_active: Optional[bool] = None
    display_order: Optional[int] = None
    branch_id: Optional[int] = None


class QRCodeResponse(QRCodeBase):
    id: int
    image_url: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
