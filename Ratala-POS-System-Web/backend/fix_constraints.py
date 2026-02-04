
import psycopg2
from urllib.parse import urlparse

DATABASE_URL = "postgresql://postgres:password@localhost:5432/digibi"

def fix_db():
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

    print("Fixing Floors table...")
    try:
        # Check for unique index/constraint on 'name'
        cursor.execute("ALTER TABLE floors DROP CONSTRAINT IF EXISTS floors_name_key CASCADE;")
        cursor.execute("DROP INDEX IF EXISTS ix_floors_name;")
        # Add composite unique constraint
        cursor.execute("ALTER TABLE floors ADD CONSTRAINT uq_floor_name_branch UNIQUE (name, branch_id);")
        print("✅ Floors table fixed")
    except Exception as e:
        print(f"⚠️  Floors table fix warning: {e}")

    print("Fixing Tables table...")
    try:
        # Check for unique index/constraint on 'table_id'
        cursor.execute("ALTER TABLE tables DROP CONSTRAINT IF EXISTS tables_table_id_key CASCADE;")
        cursor.execute("DROP INDEX IF EXISTS ix_tables_table_id;")
        # Add composite unique constraint
        cursor.execute("ALTER TABLE tables ADD CONSTRAINT uq_table_id_branch UNIQUE (table_id, branch_id);")
        # Make 'floor' column nullable
        cursor.execute("ALTER TABLE tables ALTER COLUMN floor DROP NOT NULL;")
        print("✅ Tables table fixed")
    except Exception as e:
        print(f"⚠️  Tables table fix warning: {e}")

    cursor.close()
    conn.close()

if __name__ == "__main__":
    fix_db()
