"""
Table management routes with branch isolation
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session, joinedload
from typing import Optional, List

from app.db.database import get_db
from app.core.dependencies import get_current_user, check_admin_role
from app.models import Table, Floor, Order, KOT

router = APIRouter()


def apply_branch_filter_table(db: Session, query, branch_id):
    """Apply branch_id filter if branch_id is set and model has branch_id column"""
    if branch_id is not None:
        query = query.filter(Table.branch_id == branch_id)
    return query


def apply_branch_filter_floor(db: Session, query, branch_id):
    """Apply branch_id filter to floor queries"""
    if branch_id is not None:
        query = query.filter(Floor.branch_id == branch_id)
    return query


@router.get("")
async def get_tables(
    floor: Optional[str] = None,
    floor_id: Optional[int] = None,
    include_inactive: bool = False,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all tables for the current user's branch with KOT/BOT counts, optionally filtered by floor"""
    branch_id = current_user.current_branch_id
    query = db.query(Table)
    
    # Apply branch filter
    query = apply_branch_filter_table(db, query, branch_id)
    
    if not include_inactive:
        query = query.filter(Table.is_active == True)
    
    if floor_id:
        query = query.filter(Table.floor_id == floor_id)
    elif floor:
        query = query.filter(Table.floor == floor)
    
    tables = query.order_by(Table.display_order).all()
    
    # Get KOT/BOT counts for each table
    result = []
    for table in tables:
        table_dict = {
            "id": table.id,
            "table_id": table.table_id,
            "floor": table.floor,
            "floor_id": table.floor_id,
            "table_type": table.table_type,
            "capacity": table.capacity,
            "status": table.status,
            "is_active": table.is_active,
            "display_order": table.display_order,
            "is_hold_table": table.is_hold_table,
            "hold_table_name": table.hold_table_name,
            "kot_count": 0,
            "bot_count": 0,
            "active_order_id": None,
            "total_amount": 0
        }
        
        # Get active order for this table
        active_order = db.query(Order).filter(
            Order.table_id == table.id,
            Order.status.in_(["Pending", "In Progress", "BillRequested", "Draft"])
        ).first()
        
        if active_order:
            table_dict["active_order_id"] = active_order.id
            table_dict["total_amount"] = active_order.net_amount
            table_dict["order_start_time"] = active_order.created_at

            
            # Count KOTs and BOTs
            kots = db.query(KOT).filter(KOT.order_id == active_order.id).all()
            for kot in kots:
                if kot.kot_type == "KOT":
                    table_dict["kot_count"] += 1
                else:
                    table_dict["bot_count"] += 1
        
        result.append(table_dict)
    
    return result


@router.get("/with-stats")
async def get_tables_with_stats(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get tables with order statistics grouped by floor for the current user's branch"""
    branch_id = current_user.current_branch_id
    
    # Get floors filtered by branch
    floor_query = db.query(Floor).filter(Floor.is_active == True)
    floor_query = apply_branch_filter_floor(db, floor_query, branch_id)
    floors = floor_query.order_by(Floor.display_order).all()
    
    result = []
    for floor in floors:
        tables = db.query(Table).filter(
            Table.floor_id == floor.id,
            Table.is_active == True
        ).order_by(Table.display_order).all()
        
        floor_data = {
            "floor_id": floor.id,
            "floor_name": floor.name,
            "tables": []
        }
        
        for table in tables:
            table_data = {
                "id": table.id,
                "table_id": table.table_id,
                "table_type": table.table_type,
                "status": table.status,
                "capacity": table.capacity,
                "kot_count": 0,
                "bot_count": 0,
                "total_amount": 0,
                "active_order_id": None
            }
            
            # Get active order
            active_order = db.query(Order).filter(
                Order.table_id == table.id,
                Order.status.in_(["Pending", "In Progress", "BillRequested"])
            ).first()
            
            if active_order:
                table_data["active_order_id"] = active_order.id
                table_data["total_amount"] = active_order.net_amount
                
                kots = db.query(KOT).filter(KOT.order_id == active_order.id).all()
                for kot in kots:
                    if kot.kot_type == "KOT":
                        table_data["kot_count"] += 1
                    else:
                        table_data["bot_count"] += 1
            
            floor_data["tables"].append(table_data)
        
        result.append(floor_data)
    
    return result


@router.get("/{table_id}")
async def get_table(
    table_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get table by ID with active order info, filtered by user's branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(Table).filter(Table.id == table_id)
    query = apply_branch_filter_table(db, query, branch_id)
    table = query.first()
    if not table:
        raise HTTPException(status_code=404, detail="Table not found or access denied")
    
    result = {
        "id": table.id,
        "table_id": table.table_id,
        "floor": table.floor,
        "floor_id": table.floor_id,
        "table_type": table.table_type,
        "capacity": table.capacity,
        "status": table.status,
        "is_active": table.is_active,
        "display_order": table.display_order,
        "is_hold_table": table.is_hold_table,
        "hold_table_name": table.hold_table_name,
        "active_order": None
    }
    
    # Get active order
    active_order = db.query(Order).filter(
        Order.table_id == table.id,
        Order.status.in_(["Pending", "In Progress", "BillRequested"])
    ).first()
    
    if active_order:
        result["active_order"] = {
            "id": active_order.id,
            "order_number": active_order.order_number,
            "status": active_order.status,
            "net_amount": active_order.net_amount
        }
    
    return result


@router.post("")
async def create_table(
    table_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(check_admin_role)
):
    """Create a new table in the user's current branch (Admin only)"""
    branch_id = current_user.current_branch_id
    
    # Check if table_id already exists in the branch (or globally if branch_id is None)
    query = db.query(Table).filter(Table.table_id == table_data.get('table_id'))
    query = apply_branch_filter_table(db, query, branch_id)
    existing = query.first()
    if existing:
        raise HTTPException(status_code=400, detail="Table ID already exists in this branch")
    
    # Set floor name from floor_id if provided
    if 'floor_id' in table_data and table_data['floor_id']:
        floor_query = db.query(Floor).filter(Floor.id == table_data['floor_id'])
        floor_query = apply_branch_filter_floor(db, floor_query, branch_id)
        floor = floor_query.first()
        if floor:
            table_data['floor'] = floor.name
    
    # Get max display_order for this floor, filtered by branch
    query = db.query(Table).filter(Table.floor_id == table_data.get('floor_id'))
    query = apply_branch_filter_table(db, query, branch_id)
    max_order = query.order_by(Table.display_order.desc()).first()
    table_data['display_order'] = (max_order.display_order + 1) if max_order else 0
    
    # Set branch_id for the new table
    if branch_id is not None:
        table_data['branch_id'] = branch_id
    
    new_table = Table(**table_data)
    db.add(new_table)
    db.commit()
    db.refresh(new_table)
    return new_table


@router.put("/{table_id}")
@router.patch("/{table_id}")
async def update_table(
    table_id: int,
    table_data: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a table in the user's current branch"""
    branch_id = current_user.current_branch_id
    
    # Get table filtered by branch
    query = db.query(Table).filter(Table.id == table_id)
    query = apply_branch_filter_table(db, query, branch_id)
    table = query.first()
    if not table:
        raise HTTPException(status_code=404, detail="Table not found or access denied")
    
    # Check if new table_id conflicts with existing in the branch
    if 'table_id' in table_data and table_data['table_id'] != table.table_id:
        query = db.query(Table).filter(Table.table_id == table_data['table_id'])
        query = apply_branch_filter_table(db, query, branch_id)
        existing = query.first()
        if existing:
            raise HTTPException(status_code=400, detail="Table ID already exists in this branch")
    
    # Update floor name if floor_id changed
    if 'floor_id' in table_data and table_data['floor_id'] != table.floor_id:
        floor_query = db.query(Floor).filter(Floor.id == table_data['floor_id'])
        floor_query = apply_branch_filter_floor(db, floor_query, branch_id)
        floor = floor_query.first()
        if floor:
            table_data['floor'] = floor.name
    
    for key, value in table_data.items():
        setattr(table, key, value)
    
    db.commit()
    db.refresh(table)
    return table


@router.put("/{table_id}/status")
@router.patch("/{table_id}/status")
async def update_table_status(
    table_id: int,
    status: str = Body(..., embed=True),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update table status in the user's current branch"""
    branch_id = current_user.current_branch_id
    
    query = db.query(Table).filter(Table.id == table_id)
    query = apply_branch_filter_table(db, query, branch_id)
    table = query.first()
    if not table:
        raise HTTPException(status_code=404, detail="Table not found or access denied")
    
    valid_statuses = ["Available", "Occupied", "Reserved", "BillRequested"]
    if status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of: {valid_statuses}")
    
    table.status = status
    db.commit()
    db.refresh(table)
    return table


@router.delete("/{table_id}")
async def delete_table(
    table_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(check_admin_role)
):
    """Delete a table in the user's current branch (Admin only) - sets is_active to False"""
    branch_id = current_user.current_branch_id
    
    query = db.query(Table).filter(Table.id == table_id)
    query = apply_branch_filter_table(db, query, branch_id)
    table = query.first()
    if not table:
        raise HTTPException(status_code=404, detail="Table not found or access denied")
    
    # Soft delete
    table.is_active = False
    db.commit()
    return {"message": "Table deleted successfully"}


@router.put("/{table_id}/reorder")
async def reorder_table(
    table_id: int,
    new_order: int = Body(..., embed=True),
    db: Session = Depends(get_db),
    current_user = Depends(check_admin_role)
):
    """Reorder a table in the user's current branch (Admin only)"""
    branch_id = current_user.current_branch_id
    
    query = db.query(Table).filter(Table.id == table_id)
    query = apply_branch_filter_table(db, query, branch_id)
    table = query.first()
    if not table:
        raise HTTPException(status_code=404, detail="Table not found or access denied")
    
    table.display_order = new_order
    db.commit()
    db.refresh(table)
    return table
