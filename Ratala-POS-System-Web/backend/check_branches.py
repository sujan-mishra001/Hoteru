
import psycopg2
from urllib.parse import urlparse

DATABASE_URL = "postgresql://postgres:password@localhost:5432/digibi"

def check_branches():
    parsed = urlparse(DATABASE_URL)
    conn = psycopg2.connect(
        host=parsed.hostname,
        port=parsed.port,
        user=parsed.username,
        password=parsed.password,
        database=parsed.path[1:]
    )
    cursor = conn.cursor()

    print("\n--- Branches in DB ---")
    cursor.execute("SELECT id, name, code FROM branches;")
    for row in cursor.fetchall():
        print(f"ID: {row[0]}, Name: {row[1]}, Code: {row[2]}")

    cursor.close()
    conn.close()

if __name__ == "__main__":
    check_branches()
