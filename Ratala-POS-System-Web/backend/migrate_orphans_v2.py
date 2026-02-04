
import psycopg2
from urllib.parse import urlparse

DATABASE_URL = "postgresql://postgres:password@localhost:5432/digibi"

def migrate_data():
    parsed = urlparse(DATABASE_URL)
    conn = psycopg2.connect(
        host=parsed.hostname,
        port=parsed.port,
        user=parsed.username,
        password=parsed.password,
        database=parsed.path[1:]
    )
    conn.autocommit = True
    cursor = conn.cursor()

    # Get the first branch ID as a default
    cursor.execute("SELECT id FROM branches LIMIT 1;")
    branch_row = cursor.fetchone()
    if not branch_row:
        print("❌ No branches found!")
        return
    
    branch_id = branch_row[0]
    print(f"Assigning EVERYTHING to branch ID: {branch_id}")

    # Force update everything that isn't already assigned
    cursor.execute("UPDATE floors SET branch_id = %s WHERE branch_id IS NULL;", (branch_id,))
    print(f"✅ Updated {cursor.rowcount} floors (with NULL)")
    
    cursor.execute("UPDATE tables SET branch_id = %s WHERE branch_id IS NULL;", (branch_id,))
    print(f"✅ Updated {cursor.rowcount} tables (with NULL)")

    cursor.close()
    conn.close()

if __name__ == "__main__":
    migrate_data()
