"""
API v1 routes
"""
from fastapi import APIRouter

api_router = APIRouter()

# Import and include all route modules (lazy import to avoid circular dependencies)
try:
    from . import (
        auth, users, customers, menu, inventory, purchase, orders, reports, 
        delivery, tables, kots, settings, organizations, branches, roles, floors, sessions, otp, qr_codes, printers, pos
    )
    
    # Include all route modules
    api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
    api_router.include_router(otp.router, prefix="/otp", tags=["OTP"])
    # Multi-tenant routes
    api_router.include_router(organizations.router)  # prefix already set in router
    api_router.include_router(branches.router)  # prefix already set in router
    
    # User & customer routes
    api_router.include_router(users.router, prefix="/users", tags=["Users"])
    api_router.include_router(customers.router, prefix="/customers", tags=["Customers"])
    api_router.include_router(roles.router, tags=["Roles & Permissions"])
    api_router.include_router(sessions.router, prefix="/sessions", tags=["Staff Sessions"])
    
    # Menu & inventory routes
    api_router.include_router(menu.router, prefix="/menu", tags=["Menu"])
    api_router.include_router(inventory.router, prefix="/inventory", tags=["Inventory"])
    api_router.include_router(purchase.router, prefix="/purchase", tags=["Purchase"])
    
    # Order management routes
    api_router.include_router(orders.router, prefix="/orders", tags=["Orders"])
    api_router.include_router(floors.router, prefix="/floors", tags=["Floors"])
    api_router.include_router(tables.router, prefix="/tables", tags=["Tables"])
    api_router.include_router(kots.router, prefix="/kots", tags=["KOTs"])
    
    # Other routes
    api_router.include_router(reports.router, prefix="/reports", tags=["Reports"])
    api_router.include_router(delivery.router, prefix="/delivery", tags=["Delivery Partners"])
    api_router.include_router(settings.router, tags=["Settings"])
    api_router.include_router(qr_codes.router)  # prefix already set in router
    api_router.include_router(printers.router, prefix="/printers", tags=["Printers"])
    api_router.include_router(pos.router, prefix="/pos", tags=["POS Sync"])
except ImportError as e:
    print(f"Warning: Could not import some routes: {e}")
