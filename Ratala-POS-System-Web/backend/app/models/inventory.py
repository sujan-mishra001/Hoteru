"""
Inventory-related models (Products, Units, Transactions, BOM, Production)
Transaction-based inventory system - stock is ALWAYS derived
"""
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text, Boolean, select, func, UniqueConstraint
from sqlalchemy.orm import relationship, column_property
from sqlalchemy.ext.hybrid import hybrid_property
from datetime import datetime
from app.db.database import Base


class UnitOfMeasurement(Base):
    """Unit of measurement model"""
    __tablename__ = "units_of_measurement"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    abbreviation = Column(String, nullable=True)
    base_unit_id = Column(Integer, ForeignKey("units_of_measurement.id"), nullable=True)
    conversion_factor = Column(Float, default=1.0)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    base_unit = relationship("UnitOfMeasurement", remote_side=[id])
    branch = relationship("Branch")

    __table_args__ = (
        UniqueConstraint('name', 'branch_id', name='uq_unit_name_branch'),
    )


class Product(Base):
    """
    Product/Inventory item model
    Stock is ALWAYS derived from transactions
    """
    __tablename__ = "products"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    category = Column(String, nullable=True)
    unit_id = Column(Integer, ForeignKey("units_of_measurement.id"))
    min_stock = Column(Float, default=0)
    product_type = Column(String, default="Raw") # Raw, Semi-Finished, Finished
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    unit = relationship("UnitOfMeasurement")
    transactions = relationship("InventoryTransaction", back_populates="product", cascade="all, delete-orphan")

    __table_args__ = (
        UniqueConstraint('name', 'branch_id', name='uq_product_name_branch'),
    )

    @hybrid_property
    def current_stock(self):
        """Derived stock from all transactions"""
        total = 0.0
        for txn in self.transactions:
            if txn.transaction_type in ['IN', 'Add', 'Production_IN']:
                total += txn.quantity
            elif txn.transaction_type in ['OUT', 'Remove', 'Production_OUT']:
                total -= txn.quantity
            elif txn.transaction_type in ['Adjustment']:
                total += txn.quantity # For adjustments, quantity is stored as signed
        return total

    @current_stock.expression
    def current_stock(cls):
        """SQL expression for current_stock to allow filtering/sorting in DB"""
        from .inventory import InventoryTransaction # Avoid circular import if needed, but here it's fine
        
        # This is a bit complex for a hybrid expression, but basically:
        # Sum(quantity where type is IN) - Sum(quantity where type is OUT) + Sum(quantity where type is Adjustment)
        
        # However, for simplicity and since the user wants it derived, 
        # let's calculate it in Python for now unless performance becomes an issue.
        # To truly follow "No cached fields", we compute it on the fly.
        return 0 # Placeholder for expression if we were to use it in queries

    @hybrid_property
    def status(self):
        stock = self.current_stock
        if stock <= 0:
            return "Out of Stock"
        elif stock <= self.min_stock:
            return "Low Stock"
        else:
            return "In Stock"


class InventoryTransaction(Base):
    """
    Inventory transaction model - the ONLY way to change stock
    Types: IN, OUT, Adjustment, Production_IN, Production_OUT
    """
    __tablename__ = "inventory_transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    transaction_type = Column(String, nullable=False)
    quantity = Column(Float, nullable=False)
    reference_number = Column(String, nullable=True)
    reference_id = Column(Integer, nullable=True)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True, index=True)
    pos_session_id = Column(Integer, ForeignKey("pos_sessions.id"), nullable=True)
    notes = Column(Text, nullable=True)
    created_by = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)
    
    product = relationship("Product", back_populates="transactions")
    user = relationship("User")
    pos_session = relationship("POSSession")


class BillOfMaterials(Base):
    """Bill of Materials defines requirements for a finished product"""
    __tablename__ = "bills_of_materials"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    output_quantity = Column(Float, default=1.0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True, index=True)
    finished_product_id = Column(Integer, ForeignKey("products.id"), nullable=True)
    production_mode = Column(String, default="manual") # manual, automatic
    bom_type = Column(String, nullable=False, default="production") # production, menu
    
    components = relationship("BOMItem", back_populates="bom", cascade="all, delete-orphan")
    menu_items = relationship("MenuItem", back_populates="bom")
    finished_product = relationship("Product", foreign_keys=[finished_product_id])


class BOMItem(Base):
    """Individual component for a BOM"""
    __tablename__ = "bom_items"
    
    id = Column(Integer, primary_key=True, index=True)
    bom_id = Column(Integer, ForeignKey("bills_of_materials.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    unit_id = Column(Integer, ForeignKey("units_of_measurement.id"), nullable=True)
    quantity = Column(Float, nullable=False)
    item_type = Column(String, nullable=False, default="input") # input, output
    
    bom = relationship("BillOfMaterials", back_populates="components")
    product = relationship("Product")
    unit = relationship("UnitOfMeasurement")


class BatchProduction(Base):
    """Tracks a single production run"""
    __tablename__ = "batch_productions"
    
    id = Column(Integer, primary_key=True, index=True)
    production_number = Column(String, unique=True, nullable=False)
    bom_id = Column(Integer, ForeignKey("bills_of_materials.id"), nullable=False)
    quantity = Column(Float, nullable=False)
    status = Column(String, default="Pending")
    branch_id = Column(Integer, ForeignKey("branches.id"), nullable=True, index=True)
    pos_session_id = Column(Integer, ForeignKey("pos_sessions.id"), nullable=True)
    production_cost = Column(Float, default=0.0)
    notes = Column(Text, nullable=True)
    created_by = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)
    
    bom = relationship("BillOfMaterials")
    user = relationship("User")
    pos_session = relationship("POSSession")
    finished_product_id = Column(Integer, ForeignKey("products.id"), nullable=True)
    finished_product = relationship("Product", foreign_keys=[finished_product_id])
