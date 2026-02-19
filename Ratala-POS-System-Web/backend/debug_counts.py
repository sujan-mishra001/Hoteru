from app.db.database import SessionLocal, init_db
from app.models.inventory import BatchProduction, BillOfMaterials
from app.models.menu import MenuItem
from sqlalchemy import func

def debug_counts():
    init_db()
    from app.db.database import SessionLocal # Re-import after init_db set global
    db = SessionLocal()
    try:
        print("Checking BatchProductions...")
        prods = db.query(BatchProduction).filter(BatchProduction.status == 'Completed').count()
        print(f"Total Completed BatchProductions: {prods}")
        
        print("\nChecking BOMs with MenuItems...")
        boms_with_menu = db.query(BillOfMaterials).join(MenuItem).count()
        print(f"Total BOMs linked to MenuItems: {boms_with_menu}")
        
        print("\nRunning full join query...")
        query = db.query(
            MenuItem.name,
            BatchProduction.id
        ).join(BillOfMaterials, MenuItem.bom_id == BillOfMaterials.id)\
         .join(BatchProduction, BatchProduction.bom_id == BillOfMaterials.id)\
         .filter(BatchProduction.status == 'Completed')
        
        results = query.all()
        print(f"Total results in joined query: {len(results)}")
        for r in results[:5]:
            print(f"Menu Item: {r[0]}, Production ID: {r[1]}")

    finally:
        db.close()

if __name__ == '__main__':
    debug_counts()
