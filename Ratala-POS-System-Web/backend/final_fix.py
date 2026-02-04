
import psycopg2
from urllib.parse import urlparse

DATABASE_URL = "postgresql://postgres:password@localhost:5432/digibi"

def fix():
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

    print("Checking for branches...")
    cursor.execute("SELECT id FROM branches;")
    branches = cursor.fetchall()
    if not branches:
        print("No branches found.")
        return
    
    bid = branches[0][0]
    print(f"Using default branch ID: {bid}")

    print("Updating floors where branch_id is null...")
    cursor.execute("UPDATE floors SET branch_id = %s WHERE branch_id IS NULL;", (bid,))
    print(f"Updated {cursor.rowcount} floors.")

    print("Updating tables where branch_id is null...")
    cursor.execute("UPDATE tables SET branch_id = %s WHERE branch_id IS NULL;", (bid,))
    print(f"Updated {cursor.rowcount} tables.")

    cursor.close()
    conn.close()

if __name__ == "__main__":
    fix()
