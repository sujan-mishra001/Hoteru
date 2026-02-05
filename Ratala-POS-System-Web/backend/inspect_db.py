from app.db.database import get_engine
from sqlalchemy import inspect
from app.models import Order

def inspect_table():
    engine = get_engine()
    inspector = inspect(engine)
    for table_name in ['orders', 'tables', 'kots', 'order_items']:
        columns = inspector.get_columns(table_name)
        print(f"Columns in '{table_name}' table:")
        for column in columns:
            print(f" - {column['name']} ({column['type']})")
        print("-" * 20)

if __name__ == "__main__":
    inspect_table()
