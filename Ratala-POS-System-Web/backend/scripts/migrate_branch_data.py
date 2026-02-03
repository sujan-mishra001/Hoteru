"""
Script to update existing data with branch_id values

This script helps migrate existing data to include branch_id references.
Run this after the database migration has been applied.
"""
from sqlalchemy.orm import Session
from app.database import SessionLocal, init_db
from app.models import (
    Order, Table, Floor, MenuItem, Category, MenuGroup,
    Customer, Product, InventoryTransaction, PurchaseBill, Session as MealSession
)


def update_existing_data_with_branch_id(default_branch_id: int = 1):
    """
    Update all existing records to have a branch_id.
    
    Args:
        default_branch_id: The branch ID to assign to existing records (default: 1)
    """
    db = SessionLocal()
    
    try:
        print(f"🔄 Updating existing data with branch_id = {default_branch_id}")
        
        # Update Orders
        orders_updated = db.query(Order).filter(Order.branch_id == None).update(
            {Order.branch_id: default_branch_id},
            synchronize_session=False
        )
        print(f"   ✅ Updated {orders_updated} orders")
        
        # Update Tables
        tables_updated = db.query(Table).filter(Table.branch_id == None).update(
            {Table.branch_id: default_branch_id},
            synchronize_session=False
        )
        print(f"   ✅ Updated {tables_updated} tables")
        
        # Update Floors
        floors_updated = db.query(Floor).filter(Floor.branch_id == None).update(
            {Floor.branch_id: default_branch_id},
            synchronize_session=False
        )
        print(f"   ✅ Updated {floors_updated} floors")
        
        # Update Menu Items
        items_updated = db.query(MenuItem).filter(MenuItem.branch_id == None).update(
            {MenuItem.branch_id: default_branch_id},
            synchronize_session=False
        )
        print(f"   ✅ Updated {items_updated} menu items")
        
        # Update Categories
        categories_updated = db.query(Category).filter(Category.branch_id == None).update(
            {Category.branch_id: default_branch_id},
            synchronize_session=False
        )
        print(f"   ✅ Updated {categories_updated} categories")
        
        # Update Menu Groups
        groups_updated = db.query(MenuGroup).filter(MenuGroup.branch_id == None).update(
            {MenuGroup.branch_id: default_branch_id},
            synchronize_session=False
        )
        print(f"   ✅ Updated {groups_updated} menu groups")
        
        # Update Customers
        customers_updated = db.query(Customer).filter(Customer.branch_id == None).update(
            {Customer.branch_id: default_branch_id},
            synchronize_session=False
        )
        print(f"   ✅ Updated {customers_updated} customers")
        
        # Update Products
        products_updated = db.query(Product).filter(Product.branch_id == None).update(
            {Product.branch_id: default_branch_id},
            synchronize_session=False
        )
        print(f"   ✅ Updated {products_updated} products")
        
        # Update Inventory Transactions
        transactions_updated = db.query(InventoryTransaction).filter(
            InventoryTransaction.branch_id == None
        ).update(
            {InventoryTransaction.branch_id: default_branch_id},
            synchronize_session=False
        )
        print(f"   ✅ Updated {transactions_updated} inventory transactions")
        
        # Update Purchase Bills
        bills_updated = db.query(PurchaseBill).filter(PurchaseBill.branch_id == None).update(
            {PurchaseBill.branch_id: default_branch_id},
            synchronize_session=False
        )
        print(f"   ✅ Updated {bills_updated} purchase bills")
        
        # Update Meal Sessions
        sessions_updated = db.query(MealSession).filter(MealSession.branch_id == None).update(
            {MealSession.branch_id: default_branch_id},
            synchronize_session=False
        )
        print(f"   ✅ Updated {sessions_updated} meal sessions")
        
        db.commit()
        print(f"\n✅ Successfully updated all existing data with branch_id = {default_branch_id}")
        
    except Exception as e:
        db.rollback()
        print(f"\n❌ Error updating data: {e}")
        raise
    finally:
        db.close()


def verify_branch_isolation():
    """Verify that branch isolation is working correctly"""
    db = SessionLocal()
    
    try:
        print("\n🔍 Verifying branch isolation...")
        
        # Check orders by branch
        from sqlalchemy import func
        branch_stats = db.query(
            Order.branch_id,
            func.count(Order.id).label('order_count')
        ).group_by(Order.branch_id).all()
        
        print("\n📊 Orders by Branch:")
        for branch_id, count in branch_stats:
            print(f"   Branch {branch_id}: {count} orders")
        
        # Check if any records are missing branch_id
        missing_branch = db.query(Order).filter(Order.branch_id == None).count()
        if missing_branch > 0:
            print(f"\n⚠️  Warning: {missing_branch} orders are missing branch_id")
        else:
            print(f"\n✅ All orders have branch_id assigned")
        
    finally:
        db.close()


if __name__ == "__main__":
    import sys
    
    # Initialize database
    init_db()
    
    # Get branch_id from command line or use default
    branch_id = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    
    print(f"""
╔════════════════════════════════════════════════════════════╗
║        Branch Isolation Data Migration Script             ║
╚════════════════════════════════════════════════════════════╝

This script will update all existing records to include
branch_id = {branch_id}

⚠️  IMPORTANT: Make sure you have a database backup before proceeding!

Press Enter to continue or Ctrl+C to cancel...
    """)
    
    input()
    
    # Update data
    update_existing_data_with_branch_id(branch_id)
    
    # Verify
    verify_branch_isolation()
    
    print(f"""
╔════════════════════════════════════════════════════════════╗
║                  Migration Complete!                       ║
╚════════════════════════════════════════════════════════════╝

Next steps:
1. Verify the data in your database
2. Test the mobile and web apps
3. Ensure both apps show the same data for the same branch

For more information, see BRANCH_ISOLATION.md
    """)
