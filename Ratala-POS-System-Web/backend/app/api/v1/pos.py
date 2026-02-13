from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional

from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.models import Category, MenuGroup, MenuItem, Floor, Table, Order, KOT
from app.schemas.pos import POSSyncResponse, TableSyncInfo

router = APIRouter()

@router.get("/sync", response_model=POSSyncResponse)
async def get_pos_sync(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Consolidated sync endpoint for POS startup.
    Reduces 6-7 calls into 1.
    """
    branch_id = current_user.current_branch_id
    
    # 1. Fetch Menu Data
    categories = db.query(Category).filter(Category.is_active == True)
    if branch_id:
        categories = categories.filter(Category.branch_id == branch_id)
    categories = categories.all()
    
    groups = db.query(MenuGroup).filter(MenuGroup.is_active == True)
    if branch_id:
        groups = groups.filter(MenuGroup.branch_id == branch_id)
    groups = groups.all()
    
    items = db.query(MenuItem).filter(MenuItem.is_active == True)
    if branch_id:
        items = items.filter(MenuItem.branch_id == branch_id)
    items = items.all()
    
    # 2. Fetch Floor/Table Data
    floors = db.query(Floor).filter(Floor.is_active == True)
    if branch_id:
        floors = floors.filter(Floor.branch_id == branch_id)
    floors = floors.order_by(Floor.display_order).all()
    
    tables_query = db.query(Table).filter(Table.is_active == True)
    if branch_id:
        tables_query = tables_query.filter(Table.branch_id == branch_id)
    tables = tables_query.order_by(Table.display_order).all()
    
    # 3. Process Tables (Add status/order info)
    processed_tables = []
    for table in tables:
        table_info = {
            "id": table.id,
            "table_id": table.table_id,
            "floor": table.floor,
            "floor_id": table.floor_id,
            "table_type": table.table_type,
            "capacity": table.capacity,
            "status": table.status,
            "is_hold_table": getattr(table, 'is_hold_table', 'No') or 'No',
            "hold_table_name": getattr(table, 'hold_table_name', None),
            "merge_group_id": getattr(table, 'merge_group_id', None),
            "merged_to_id": getattr(table, 'merged_to_id', None),
            "kot_count": 0,
            "bot_count": 0,
            "active_order_id": None,
            "total_amount": 0.0
        }
        
        # Get active order for this table
        active_order = db.query(Order).filter(
            Order.table_id == table.id,
            Order.status.in_(["Pending", "In Progress", "BillRequested", "Draft"])
        ).first()
        
        if active_order:
            table_info["active_order_id"] = active_order.id
            table_info["total_amount"] = active_order.net_amount
            
            # Count KOTs/BOTs
            kots = db.query(KOT).filter(KOT.order_id == active_order.id).all()
            for kot in kots:
                if kot.kot_type == "KOT":
                    table_info["kot_count"] += 1
                else:
                    table_info["bot_count"] += 1
                    
        processed_tables.append(table_info)
    
    # 4. Get active session
    from app.models.pos_session import POSSession
    active_session_obj = db.query(POSSession).filter(
        POSSession.user_id == current_user.id,
        POSSession.status == "Open"
    ).first()
    
    active_session = None
    if active_session_obj:
        active_session = {
            "id": active_session_obj.id,
            "start_time": active_session_obj.start_time,
            "opening_cash": active_session_obj.opening_cash,
            "status": active_session_obj.status
        }
        
    return {
        "categories": categories,
        "groups": groups,
        "items": items,
        "floors": [
            {"id": f.id, "name": f.name, "display_order": f.display_order, "is_active": f.is_active} 
            for f in floors
        ],
        "active_session": active_session,
        "tables": processed_tables
    }
