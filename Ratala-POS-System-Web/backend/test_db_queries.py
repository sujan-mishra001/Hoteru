from app.db.database import get_db, init_db
from app.models import Order, Table, KOT, Floor
from sqlalchemy import text

def test_queries():
    # Force initialization if needed
    db_gen = get_db()
    db = next(db_gen)
    try:
        print("Testing Table query...")
        tables = db.query(Table).all()
        print(f"Found {len(tables)} tables")
        
        print("Testing Order query...")
        orders = db.query(Order).all()
        print(f"Found {len(orders)} orders")
        
        print("Testing Floor query...")
        floors = db.query(Floor).all()
        print(f"Found {len(floors)} floors")
        
        print("Testing KOT query...")
        kots = db.query(KOT).all()
        print(f"Found {len(kots)} kots")
        
        print("Testing POSSession query...")
        from app.models.pos_session import POSSession
        active_sessions = db.query(POSSession).filter(POSSession.status == "Open").all()
        print(f"Found {len(active_sessions)} active sessions")
        for s in active_sessions:
            print(f" - Session ID: {s.id}, User ID: {s.user_id}, Start: {s.start_time}")
        
        print("Testing specific failing query from pos.py...")
        # Simulating part of get_pos_sync
        active_order = db.query(Order).filter(
            Order.status.in_(["Pending", "In Progress", "BillRequested", "Draft"])
        ).first()
        print(f"Active order check: {active_order}")
        
    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    test_queries()
