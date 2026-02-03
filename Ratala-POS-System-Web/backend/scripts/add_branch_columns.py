"""
Direct SQL migration to add branch_id columns

This script adds branch_id columns directly to the database without using Alembic.
Run this script to enable branch isolation.
"""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import get_engine
from sqlalchemy import text


def add_branch_columns():
    """Add branch_id columns to all relevant tables"""
    engine = get_engine()
    
    migrations = [
        # Orders table
        """
        ALTER TABLE orders 
        ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
        
        CREATE INDEX IF NOT EXISTS ix_orders_branch_id ON orders(branch_id);
        """,
        
        # Tables table
        """
        ALTER TABLE tables 
        ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
        
        CREATE INDEX IF NOT EXISTS ix_tables_branch_id ON tables(branch_id);
        """,
        
        # Floors table
        """
        ALTER TABLE floors 
        ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
        
        CREATE INDEX IF NOT EXISTS ix_floors_branch_id ON floors(branch_id);
        """,
        
        # Menu items table
        """
        ALTER TABLE menu_items 
        ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
        
        CREATE INDEX IF NOT EXISTS ix_menu_items_branch_id ON menu_items(branch_id);
        """,
        
        # Categories table
        """
        ALTER TABLE categories 
        ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
        
        CREATE INDEX IF NOT EXISTS ix_categories_branch_id ON categories(branch_id);
        """,
        
        # Menu groups table
        """
        ALTER TABLE menu_groups 
        ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
        
        CREATE INDEX IF NOT EXISTS ix_menu_groups_branch_id ON menu_groups(branch_id);
        """,
        
        # Customers table
        """
        ALTER TABLE customers 
        ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
        
        CREATE INDEX IF NOT EXISTS ix_customers_branch_id ON customers(branch_id);
        """,
        
        # Products table
        """
        ALTER TABLE products 
        ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
        
        CREATE INDEX IF NOT EXISTS ix_products_branch_id ON products(branch_id);
        """,
        
        # Inventory transactions table
        """
        ALTER TABLE inventory_transactions 
        ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
        
        CREATE INDEX IF NOT EXISTS ix_inventory_transactions_branch_id ON inventory_transactions(branch_id);
        """,
        
        # Purchase bills table
        """
        ALTER TABLE purchase_bills 
        ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
        
        CREATE INDEX IF NOT EXISTS ix_purchase_bills_branch_id ON purchase_bills(branch_id);
        """,
        
        # Sessions table
        """
        ALTER TABLE sessions 
        ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
        
        CREATE INDEX IF NOT EXISTS ix_sessions_branch_id ON sessions(branch_id);
        """,
    ]
    
    print("🔄 Adding branch_id columns to database...")
    print("=" * 60)
    
    with engine.connect() as conn:
        for i, migration in enumerate(migrations, 1):
            try:
                conn.execute(text(migration))
                conn.commit()
                table_name = migration.split("ALTER TABLE")[1].split()[0] if "ALTER TABLE" in migration else "unknown"
                print(f"✅ {i}. Added branch_id to {table_name}")
            except Exception as e:
                print(f"⚠️  {i}. Error (may already exist): {str(e)[:100]}")
    
    print("=" * 60)
    print("✅ Migration complete!")
    print("\nNext steps:")
    print("1. Restart your backend server")
    print("2. Run: python scripts/migrate_branch_data.py 1")
    print("3. Test creating floors in both branches")


if __name__ == "__main__":
    print("""
╔════════════════════════════════════════════════════════════╗
║        Add Branch Isolation Columns to Database           ║
╚════════════════════════════════════════════════════════════╝

This will add branch_id columns to all tables.

⚠️  Make sure you have a database backup before proceeding!

Press Enter to continue or Ctrl+C to cancel...
    """)
    
    input()
    add_branch_columns()
