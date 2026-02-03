"""
Add branch_id to remaining models for comprehensive branch isolation

Revision ID: add_branch_remaining
Revises: add_branch_isolation
Create Date: 2026-02-03
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = 'add_branch_remaining'
down_revision = 'add_branch_isolation'
branch_labels = None
depends_on = None


def upgrade():
    # Add branch_id to Customer model
    op.add_column('customers', sa.Column('branch_id', sa.Integer(), nullable=True))
    op.create_index('ix_customers_branch_id', 'customers', ['branch_id'], unique=False)
    
    # Add branch_id to delivery_partners table
    op.add_column('delivery_partners', sa.Column('branch_id', sa.Integer(), nullable=True))
    op.create_index('ix_delivery_partners_branch_id', 'delivery_partners', ['branch_id'], unique=False)
    
    # Add branch_id to suppliers table
    op.add_column('suppliers', sa.Column('branch_id', sa.Integer(), nullable=True))
    op.create_index('ix_suppliers_branch_id', 'suppliers', ['branch_id'], unique=False)
    
    # Add branch_id to purchase_bills table
    op.add_column('purchase_bills', sa.Column('branch_id', sa.Integer(), nullable=True))
    op.create_index('ix_purchase_bills_branch_id', 'purchase_bills', ['branch_id'], unique=False)
    
    # Add branch_id to purchase_returns table
    op.add_column('purchase_returns', sa.Column('branch_id', sa.Integer(), nullable=True))
    op.create_index('ix_purchase_returns_branch_id', 'purchase_returns', ['branch_id'], unique=False)
    
    # Add branch_id to products table
    op.add_column('products', sa.Column('branch_id', sa.Integer(), nullable=True))
    op.create_index('ix_products_branch_id', 'products', ['branch_id'], unique=False)
    
    # Add branch_id to inventory_transactions table
    op.add_column('inventory_transactions', sa.Column('branch_id', sa.Integer(), nullable=True))
    op.create_index('ix_inventory_transactions_branch_id', 'inventory_transactions', ['branch_id'], unique=False)
    
    # Add branch_id to bills_of_materials table
    op.add_column('bills_of_materials', sa.Column('branch_id', sa.Integer(), nullable=True))
    op.create_index('ix_bills_of_materials_branch_id', 'bills_of_materials', ['branch_id'], unique=False)
    
    # Add branch_id to batch_productions table
    op.add_column('batch_productions', sa.Column('branch_id', sa.Integer(), nullable=True))
    op.create_index('ix_batch_productions_branch_id', 'batch_productions', ['branch_id'], unique=False)
    
    # Add branch_id to payment_modes table
    op.add_column('payment_modes', sa.Column('branch_id', sa.Integer(), nullable=True))
    op.create_index('ix_payment_modes_branch_id', 'payment_modes', ['branch_id'], unique=False)
    
    # Add branch_id to storage_areas table
    op.add_column('storage_areas', sa.Column('branch_id', sa.Integer(), nullable=True))
    op.create_index('ix_storage_areas_branch_id', 'storage_areas', ['branch_id'], unique=False)
    
    # Add branch_id to discount_rules table
    op.add_column('discount_rules', sa.Column('branch_id', sa.Integer(), nullable=True))
    op.create_index('ix_discount_rules_branch_id', 'discount_rules', ['branch_id'], unique=False)
    
    # Add foreign key constraints for branch_id
    op.create_foreign_key('fk_customers_branch_id', 'customers', 'branches', ['branch_id'], ['id'])
    op.create_foreign_key('fk_delivery_partners_branch_id', 'delivery_partners', 'branches', ['branch_id'], ['id'])
    op.create_foreign_key('fk_suppliers_branch_id', 'suppliers', 'branches', ['branch_id'], ['id'])
    op.create_foreign_key('fk_purchase_bills_branch_id', 'purchase_bills', 'branches', ['branch_id'], ['id'])
    op.create_foreign_key('fk_purchase_returns_branch_id', 'purchase_returns', 'branches', ['branch_id'], ['id'])
    op.create_foreign_key('fk_products_branch_id', 'products', 'branches', ['branch_id'], ['id'])
    op.create_foreign_key('fk_inventory_transactions_branch_id', 'inventory_transactions', 'branches', ['branch_id'], ['id'])
    op.create_foreign_key('fk_bills_of_materials_branch_id', 'bills_of_materials', 'branches', ['branch_id'], ['id'])
    op.create_foreign_key('fk_batch_productions_branch_id', 'batch_productions', 'branches', ['branch_id'], ['id'])
    op.create_foreign_key('fk_payment_modes_branch_id', 'payment_modes', 'branches', ['branch_id'], ['id'])
    op.create_foreign_key('fk_storage_areas_branch_id', 'storage_areas', 'branches', ['branch_id'], ['id'])
    op.create_foreign_key('fk_discount_rules_branch_id', 'discount_rules', 'branches', ['branch_id'], ['id'])


def downgrade():
    # Drop foreign key constraints first
    op.drop_constraint('fk_discount_rules_branch_id', 'discount_rules', type_='foreignkey')
    op.drop_constraint('fk_storage_areas_branch_id', 'storage_areas', type_='foreignkey')
    op.drop_constraint('fk_payment_modes_branch_id', 'payment_modes', type_='foreignkey')
    op.drop_constraint('fk_batch_productions_branch_id', 'batch_productions', type_='foreignkey')
    op.drop_constraint('fk_bills_of_materials_branch_id', 'bills_of_materials', type_='foreignkey')
    op.drop_constraint('fk_inventory_transactions_branch_id', 'inventory_transactions', type_='foreignkey')
    op.drop_constraint('fk_products_branch_id', 'products', type_='foreignkey')
    op.drop_constraint('fk_purchase_returns_branch_id', 'purchase_returns', type_='foreignkey')
    op.drop_constraint('fk_purchase_bills_branch_id', 'purchase_bills', type_='foreignkey')
    op.drop_constraint('fk_suppliers_branch_id', 'suppliers', type_='foreignkey')
    op.drop_constraint('fk_delivery_partners_branch_id', 'delivery_partners', type_='foreignkey')
    op.drop_constraint('fk_customers_branch_id', 'customers', type_='foreignkey')
    
    # Drop indexes and columns
    op.drop_index('ix_discount_rules_branch_id', 'discount_rules')
    op.drop_column('discount_rules', 'branch_id')
    
    op.drop_index('ix_storage_areas_branch_id', 'storage_areas')
    op.drop_column('storage_areas', 'branch_id')
    
    op.drop_index('ix_payment_modes_branch_id', 'payment_modes')
    op.drop_column('payment_modes', 'branch_id')
    
    op.drop_index('ix_batch_productions_branch_id', 'batch_productions')
    op.drop_column('batch_productions', 'branch_id')
    
    op.drop_index('ix_bills_of_materials_branch_id', 'bills_of_materials')
    op.drop_column('bills_of_materials', 'branch_id')
    
    op.drop_index('ix_inventory_transactions_branch_id', 'inventory_transactions')
    op.drop_column('inventory_transactions', 'branch_id')
    
    op.drop_index('ix_products_branch_id', 'products')
    op.drop_column('products', 'branch_id')
    
    op.drop_index('ix_purchase_returns_branch_id', 'purchase_returns')
    op.drop_column('purchase_returns', 'branch_id')
    
    op.drop_index('ix_purchase_bills_branch_id', 'purchase_bills')
    op.drop_column('purchase_bills', 'branch_id')
    
    op.drop_index('ix_suppliers_branch_id', 'suppliers')
    op.drop_column('suppliers', 'branch_id')
    
    op.drop_index('ix_delivery_partners_branch_id', 'delivery_partners')
    op.drop_column('delivery_partners', 'branch_id')
    
    op.drop_index('ix_customers_branch_id', 'customers')
    op.drop_column('customers', 'branch_id')
