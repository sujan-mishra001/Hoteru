"""
Database models organized by domain
"""
from app.models.auth import User
from app.models.role import Role
from app.models.organization import Organization
from app.models.branch import Branch
from app.models.user_branch import UserBranchAssignment
from app.models.customers import Customer
from app.models.menu import Category, MenuGroup, MenuItem
from app.models.inventory import (
    UnitOfMeasurement, Product, InventoryTransaction,
    BillOfMaterials, BOMItem, BatchProduction
)
from app.models.orders import Floor, Table, Session, Order, OrderItem, KOT, KOTItem
from app.models.purchase import Supplier, PurchaseBill, PurchaseReturn
from app.models.delivery import DeliveryPartner
from app.models.settings import CompanySettings, PaymentMode, StorageArea, DiscountRule
from app.models.pos_session import POSSession
from app.models.qr_code import QRCode
from app.models.printer import Printer

__all__ = [
    # Auth
    "User",
    "Role",
    # Multi-tenant
    "Organization",
    "Branch",
    "UserBranchAssignment",
    # Customers
    "Customer",
    # Menu
    "Category",
    "MenuGroup",
    "MenuItem",
    # Inventory
    "UnitOfMeasurement",
    "Product",
    "InventoryTransaction",
    "BillOfMaterials",
    "BOMItem",
    "BatchProduction",
    # Orders
    "Floor",
    "Table",
    "Session",
    "POSSession",  # <--- Added
    "Order",
    "OrderItem",
    "KOT",
    "KOTItem",
    # Purchase
    "Supplier",
    "PurchaseBill",
    "PurchaseReturn",
    # Delivery
    "DeliveryPartner",
    # Settings
    "CompanySettings",
    "PaymentMode",
    "StorageArea",
    "DiscountRule",
    "QRCode",
    "Printer",
]
