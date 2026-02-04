import psycopg2
from app.core.config import settings

def migrate():
    # Parse DATABASE_URL
    # postgresql://postgres:password@localhost:5432/digibi
    db_url = "postgresql://postgres:password@localhost:5432/digibi"
    
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()
    
    tables_to_update = [
        "suppliers",
        "purchase_bills",
        "purchase_returns",
        "delivery_partners",
        "customers"
    ]
    
    for table in tables_to_update:
        print(f"Adding branch_id to {table}...")
        try:
            # Check if column exists
            cur.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name='{table}' AND column_name='branch_id'")
            if not cur.fetchone():
                cur.execute(f"ALTER TABLE {table} ADD COLUMN branch_id INTEGER REFERENCES branches(id)")
                # Default existing to branch 1
                cur.execute(f"UPDATE {table} SET branch_id = 1 WHERE branch_id IS NULL")
                print(f"Successfully added and initialized branch_id for {table}")
            else:
                print(f"branch_id already exists in {table}")
        except Exception as e:
            print(f"Error updating {table}: {e}")
            conn.rollback()
        else:
            conn.commit()
            
    cur.close()
    conn.close()
    print("Migration complete!")

if __name__ == "__main__":
    migrate()
