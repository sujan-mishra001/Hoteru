import sys
from pathlib import Path

# Add the current directory to sys.path so we can import app
sys.path.append(str(Path(__file__).parent))

from app.database import get_engine, Base, init_db
from sqlalchemy import text

def reset_db():
    print("🗑️  Dropping all tables...")
    engine = get_engine()
    with engine.connect() as conn:
        conn.execute(text("DROP SCHEMA public CASCADE;"))
        conn.execute(text("CREATE SCHEMA public;"))
        conn.commit()
    
    print("🏗️  Recreating all tables...")
    init_db()
    print("✅ Database reset complete!")

if __name__ == "__main__":
    confirm = input("⚠️  WARNING: This will delete ALL data in the database. Continue? (y/n): ")
    if confirm.lower() == 'y':
        reset_db()
    else:
        print("Aborted.")
