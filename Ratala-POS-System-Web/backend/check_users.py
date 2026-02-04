
import psycopg2
from urllib.parse import urlparse

DATABASE_URL = "postgresql://postgres:password@localhost:5432/digibi"

def check_users():
    parsed = urlparse(DATABASE_URL)
    conn = psycopg2.connect(
        host=parsed.hostname,
        port=parsed.port,
        user=parsed.username,
        password=parsed.password,
        database=parsed.path[1:]
    )
    cursor = conn.cursor()

    print("\n--- Users ---")
    cursor.execute("SELECT id, username, current_branch_id FROM users;")
    for row in cursor.fetchall():
        print(f"ID: {row[0]}, User: {row[1]}, CurrentBranch: {row[2]}")

    print("\n--- User Branch Assignments ---")
    cursor.execute("SELECT user_id, branch_id, is_primary FROM user_branch_assignments;")
    for row in cursor.fetchall():
        print(f"User: {row[0]}, Branch: {row[1]}, Primary: {row[2]}")

    cursor.close()
    conn.close()

if __name__ == "__main__":
    check_users()
