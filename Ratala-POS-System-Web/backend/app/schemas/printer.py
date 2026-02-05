from pydantic import BaseModel
from typing import Optional, List
from enum import Enum
import enum

class PrinterConnection(str, enum.Enum):
    NETWORK = "network"
    USB = "usb"
    BLUETOOTH = "bluetooth"

class PrinterBrand(str, enum.Enum):
    EPSON = "epson"
    XPRINTER = "xprinter"
    RONGTA = "rongta"
    TVS = "tvs"
    GENERIC = "generic"

class PrinterUsage(str, Enum):
    KITCHEN = "kitchen"
    BAR = "bar"
    BILLING = "billing"
    RECEPTION = "reception"

class PrinterBase(BaseModel):
    name: str
    ip_address: Optional[str] = None
    port: Optional[int] = 9100
    connection_type: PrinterConnection = PrinterConnection.NETWORK
    printer_usage: Optional[PrinterUsage] = PrinterUsage.BILLING
    is_active: Optional[bool] = True
    paper_size: Optional[int] = 80
    brand: PrinterBrand = PrinterBrand.GENERIC
    branch_id: int

class PrinterCreate(PrinterBase):
    pass

class PrinterUpdate(BaseModel):
    name: Optional[str] = None
    ip_address: Optional[str] = None
    port: Optional[int] = None
    connection_type: Optional[PrinterConnection] = None
    printer_usage: Optional[PrinterUsage] = None
    is_active: Optional[bool] = None
    paper_size: Optional[int] = None
    brand: Optional[PrinterBrand] = None

class Printer(PrinterBase):
    id: int

    class Config:
        from_attributes = True
