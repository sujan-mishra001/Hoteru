from sqlalchemy import Column, Integer, String, Boolean, Enum, ForeignKey
from sqlalchemy.orm import relationship
from app.db.database import Base
import enum

class PrinterType(str, enum.Enum):
    THERMAL = "thermal"
    NETWORK = "network"
    USB = "usb"
    BLUETOOTH = "bluetooth"

class PrinterConnection(str, enum.Enum):
    NETWORK = "network"
    USB = "usb"
    BLUETOOTH = "bluetooth"

class PrinterUsage(str, enum.Enum):
    KITCHEN = "kitchen"
    BAR = "bar"
    BILLING = "billing"
    RECEPTION = "reception"

class Printer(Base):
    __tablename__ = "printers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    ip_address = Column(String, nullable=True) # For network printers
    port = Column(Integer, default=9100)
    connection_type = Column(Enum(PrinterConnection), default=PrinterConnection.NETWORK)
    printer_usage = Column(Enum(PrinterUsage), default=PrinterUsage.BILLING)
    is_active = Column(Boolean, default=True)
    paper_size = Column(Integer, default=80) # 80mm or 58mm
    
    branch_id = Column(Integer, ForeignKey("branches.id"))
    branch = relationship("Branch", back_populates="printers")

    # For organizational setup
    organization_id = Column(Integer, ForeignKey("organizations.id"), nullable=True)
