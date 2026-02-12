from pydantic import BaseModel
from typing import Optional, List
from enum import Enum
import enum

class PrinterConnection(str, enum.Enum):
    NETWORK = "NETWORK"
    USB = "USB"
    BLUETOOTH = "BLUETOOTH"

class PrinterBrand(str, enum.Enum):
    EPSON = "EPSON"
    XPRINTER = "XPRINTER"
    RONGTA = "RONGTA"
    TVS = "TVS"
    GENERIC = "GENERIC"

class PrinterBase(BaseModel):
    name: str
    ip_address: Optional[str] = None
    port: Optional[int] = 9100
    connection_type: PrinterConnection = PrinterConnection.NETWORK
    is_active: Optional[bool] = True
    paper_size: Optional[int] = 80
    brand: PrinterBrand = PrinterBrand.GENERIC
    usb_path: Optional[str] = None

class PrinterCreate(PrinterBase):
    pass

class PrinterUpdate(BaseModel):
    name: Optional[str] = None
    ip_address: Optional[str] = None
    port: Optional[int] = None
    connection_type: Optional[PrinterConnection] = None
    is_active: Optional[bool] = None
    paper_size: Optional[int] = None
    brand: Optional[PrinterBrand] = None
    usb_path: Optional[str] = None

class Printer(PrinterBase):
    id: int
    branch_id: int

    class Config:
        from_attributes = True
