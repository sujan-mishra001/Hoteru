"""
Update existing floors, menu items, and orders with branch_id

This script intelligently assigns branch_id to existing data.
For now, it will prompt you to assign data to specific branches.
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import get_engine
from sqlalchemy import text

def update_data_with_branches():
    engine = get_engine()
    conn = engine.connect()
    
    # Get branches
    result = conn.execute(text("SELECT id, name FROM branches ORDER BY id"))
    branches = result.fetchall()
    
    print("\n📋 Available Branches:")
    for branch in branches:
        print(f"  {branch[0]}. {branch[1]}")
    
    print("\n" + "=" * 60)
    print("OPTION 1: Assign ALL existing data to ONE branch")
    print("OPTION 2: Keep data shared (don't assign branch_id yet)")
    print("=" * 60)
    
    choice = input("\nEnter 1 or 2: ").strip()
    
    if choice == "1":
        branch_id = input(f"\nWhich branch ID? (1-{len(branches)}): ").strip()
        
        try:
            branch_id = int(branch_id)
            
            # Update all tables
            tables_to_update = [
                'floors', 'tables', 'orders', 'menu_items', 
                'categories', 'menu_groups', 'customers',
                'products', 'inventory_transactions', 'purchase_bills', 'sessions'
            ]
            
            print(f"\n🔄 Assigning all data to Branch {branch_id}...")
            
            for table in tables_to_update:
                try:
                    result = conn.execute(text(f"""
                        UPDATE {table} 
                        SET branch_id = :branch_id 
                        WHERE branch_id IS NULL
                    """), {"branch_id": branch_id})
                    conn.commit()
                    print(f"  ✅ Updated {table}")
                except Exception as e:
                    print(f"  ⚠️  {table}: {str(e)[:50]}")
            
            print(f"\n✅ All existing data assigned to Branch {branch_id}")
            print("\n🔄 Now restart your backend server:")
            print("   1. Stop the current server (Ctrl+C)")
            print("   2. Run: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload")
            
        except ValueError:
            print("❌ Invalid branch ID")
    
    else:
        print("\n✅ Data will remain shared (no branch_id assigned)")
        print("   You can manually assign branch_id later in the database")
    
    conn.close()

if __name__ == "__main__":
    update_data_with_branches()
