
import psycopg2
from urllib.parse import urlparse

DATABASE_URL = "postgresql://postgres:password@localhost:5432/digibi"

def check_data():
    parsed = urlparse(DATABASE_URL)
    conn = psycopg2.connect(
        host=parsed.hostname,
        port=parsed.port,
        user=parsed.username,
        password=parsed.password,
        database=parsed.path[1:]
    )
    cursor = conn.cursor()

    print("\n--- Floors in DB ---")
    cursor.execute("SELECT id, name, branch_id FROM floors;")
    rows = cursor.fetchall()
    if not rows:
        print("No floors found.")
    for row in rows:
        print(f"ID: {row[0]}, Name: '{row[1]}', BranchID: {row[2]!r}")

    print("\n--- Tables in DB ---")
    cursor.execute("SELECT id, table_id, floor_id, branch_id FROM tables;")
    rows = cursor.fetchall()
    if not rows:
        print("No tables found.")
    for row in rows:
        print(f"ID: {row[0]}, TableID: '{row[1]}', FloorID: {row[2]}, BranchID: {row[3]!r}")

    cursor.close()
    conn.close()

if __name__ == "__main__":
    check_data()
