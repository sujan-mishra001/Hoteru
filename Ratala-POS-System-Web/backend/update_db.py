from app.db.database import get_engine
from sqlalchemy import text

def update_schema():
    engine = get_engine()
    with engine.connect() as conn:
        print("Adding missing columns to 'orders' table...")
        try:
            conn.execute(text("ALTER TABLE orders ADD COLUMN IF NOT EXISTS service_charge DOUBLE PRECISION DEFAULT 0"))
            conn.execute(text("ALTER TABLE orders ADD COLUMN IF NOT EXISTS tax DOUBLE PRECISION DEFAULT 0"))
            conn.execute(text("UPDATE orders SET service_charge = 0 WHERE service_charge IS NULL"))
            conn.execute(text("UPDATE orders SET tax = 0 WHERE tax IS NULL"))
            conn.commit()
            print("Successfully added and initialized service_charge and tax columns.")
        except Exception as e:
            print(f"Error adding columns: {e}")
            conn.rollback()

if __name__ == "__main__":
    update_schema()
