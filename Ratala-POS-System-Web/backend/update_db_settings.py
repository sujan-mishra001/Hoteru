import sys
from sqlalchemy import create_engine, text
from app.core.config import settings

def update_db():
    print(f"Connecting to {settings.DATABASE_URL}...")
    engine = create_engine(settings.DATABASE_URL)
    
    with engine.connect() as conn:
        # Check if table exists
        result = conn.execute(text("SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'company_settings')"))
        if not result.scalar():
            print("Table 'company_settings' does not exist yet. It will be created on startup.")
            return

        print("Updating 'company_settings' table...")
        
        # Add service_charge_rate if missing
        try:
            conn.execute(text("ALTER TABLE company_settings ADD COLUMN service_charge_rate FLOAT DEFAULT 10.0"))
            print("Added column 'service_charge_rate'")
        except Exception as e:
            if "already exists" in str(e):
                print("Column 'service_charge_rate' already exists")
            else:
                print(f"Error adding 'service_charge_rate': {e}")
        
        # Add discount_rate if missing
        try:
            conn.execute(text("ALTER TABLE company_settings ADD COLUMN discount_rate FLOAT DEFAULT 0.0"))
            print("Added column 'discount_rate'")
        except Exception as e:
            if "already exists" in str(e):
                print("Column 'discount_rate' already exists")
            else:
                print(f"Error adding 'discount_rate': {e}")
        
        conn.commit()
    
    print("Database update complete.")

if __name__ == "__main__":
    # Ensure app is in path
    import os
    sys.path.append(os.getcwd())
    update_db()
