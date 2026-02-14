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
            "merge_group_id": table.merge_group_id,
            "merged_to_id": table.merged_to_id,
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
        elif table.status in ["Occupied", "BillRequested"] and not table.merge_group_id:
            # Self-healing: Table is marked occupied but has no active order -> Reset to Available
            table.status = "Available"
            table_dict["status"] = "Available"
            db.add(table)
            db.commit()
        
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
                "merge_group_id": table.merge_group_id,
                "merged_to_id": table.merged_to_id,
                "kot_count": 0,
                "bot_count": 0,
                "total_amount": 0,
                "active_order_id": None
            }
            
            # Get active order
            active_order = db.query(Order).filter(
                Order.table_id == table.id,
                # Include Draft orders too
                Order.status.in_(["Pending", "In Progress", "BillRequested", "Draft"])
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
            elif table.status in ["Occupied", "BillRequested"] and not table.merge_group_id:
                # Self-healing
                table.status = "Available"
                table_data["status"] = "Available"
                db.add(table)
                db.commit()
            
            floor_data["tables"].append(table_data)
        
        result.append(floor_data)
    
    return result


@router.post("/merge")
async def merge_tables_bulk(
    payload: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Merge multiple tables"""
    branch_id = current_user.current_branch_id
    primary_table_id = payload.get("primary_table_id")
    table_ids = payload.get("table_ids", [])
    
    if not primary_table_id or not table_ids:
        raise HTTPException(status_code=400, detail="primary_table_id and table_ids are required")
    
    # Simple integer merge group ID generation
    # Find max existing merge_group_id (assuming it can be cast to int, or is int)
    # To be safe against string values, we will use a timestamp-based int
    import time
    merge_group_id = int(time.time())
    
    # Check if primary table already has a group
    primary = db.query(Table).filter(Table.id == primary_table_id, Table.branch_id == branch_id).first()
    if not primary:
        raise HTTPException(status_code=404, detail="Primary table not found")
        
    if primary.merge_group_id:
        # Try to use existing group ID if it looks like an int, else generate new?
        # If we use mixed types it might be messy.
        # Let's trust proper ID usage.
        # If existing logic uses strings, we might have an issue.
        # For now, let's just overwrite with our new int ID or use existing if compatible.
        try:
             # Check if we can parse it to match our frontend expectation
             int(primary.merge_group_id)
             merge_group_id = primary.merge_group_id
        except:
             # If existing is string, and our frontend expects int, we might need to change frontend model to String/dynamic
             # Or force new ID.
             pass

    # Update all participating tables
    all_ids = [primary_table_id] + table_ids
    for tid in all_ids:
        t = db.query(Table).filter(Table.id == tid, Table.branch_id == branch_id).first()
        if t:
            t.merge_group_id = str(merge_group_id)
            t.merged_to_id = primary_table_id if tid != primary_table_id else None
            # Do NOT force Occupied status if you want to allow merging empty tables
            # But usually merge happens for active orders. 
            # If primary has order, others should join.
            # For now, keep as is or just let status be.
            t.status = "Occupied"
            
    db.commit()
    print(f"DEBUG: Tables {all_ids} merged into group {merge_group_id} for branch {branch_id}")
    return {"message": "Merged", "merge_group_id": str(merge_group_id)}


@router.post("/unmerge")
async def unmerge_tables_bulk(
    payload: dict = Body(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Unmerge tables by Group ID with branch isolation"""
    branch_id = current_user.current_branch_id
    merge_group_id = payload.get("merge_group_id")
    
    if not merge_group_id:
        raise HTTPException(status_code=400, detail="merge_group_id is required")

    # Stringify in case it comes as int from frontend
    mg_id = str(merge_group_id)
    
    tables = db.query(Table).filter(
        Table.merge_group_id == mg_id, 
        Table.branch_id == branch_id
    ).all()
    
    for t in tables:
        t.merge_group_id = None
        t.merged_to_id = None
        
        # Check if table has active order
        active_order = db.query(Order).filter(
            Order.table_id == t.id,
            Order.status.in_(["Pending", "In Progress", "BillRequested", "Draft"])
        ).first()
        
        if not active_order:
            t.status = "Available"
        
    db.commit()
    print(f"DEBUG: Merge group {mg_id} unmerged for branch {branch_id}")
    return {"message": "Unmerged"}


@router.post("/{table_id}/merge")
async def merge_tables(
    table_id: int,
    target_table_id: int = Body(..., embed=True),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Merge two tables into a merge group"""
    branch_id = current_user.current_branch_id
    
    # Get source table
    source_query = db.query(Table).filter(Table.id == table_id)
    source_query = apply_branch_filter_table(db, source_query, branch_id)
    source_table = source_query.first()
    if not source_table:
        raise HTTPException(status_code=404, detail="Source table not found or access denied")
    
    # Get target table
    target_query = db.query(Table).filter(Table.id == target_table_id)
    target_query = apply_branch_filter_table(db, target_query, branch_id)
    target_table = target_query.first()
    if not target_table:
        raise HTTPException(status_code=404, detail="Target table not found or access denied")
    
    # Check if either table is already in a merge group
    if source_table.merge_group_id or target_table.merge_group_id:
        # If one has a group, add the other to that group
        merge_group_id = source_table.merge_group_id or target_table.merge_group_id
    else:
        # Create new merge group - find next available number
        existing_groups = db.query(Table).filter(
            Table.merge_group_id.isnot(None)
        )
        existing_groups = apply_branch_filter_table(db, existing_groups, branch_id)
        existing_groups = existing_groups.all()
        
        group_numbers = []
        for t in existing_groups:
            if t.merge_group_id and t.merge_group_id.startswith("Merge_Table_"):
                try:
                    num = int(t.merge_group_id.split("_")[-1])
                    group_numbers.append(num)
                except:
                    pass
        
        next_number = max(group_numbers) + 1 if group_numbers else 1
        merge_group_id = f"Merge_Table_{next_number}"
    
    # Assign both tables to the merge group
    source_table.merge_group_id = merge_group_id
    source_table.merged_to_id = target_table_id
    target_table.merge_group_id = merge_group_id
    
    db.commit()
    db.refresh(source_table)
    db.refresh(target_table)
    
    return {
        "message": f"Tables merged successfully into {merge_group_id}",
        "merge_group_id": merge_group_id,
        "source_table": source_table,
        "target_table": target_table
    }


@router.post("/{table_id}/unmerge")
async def unmerge_table(
    table_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Remove a table from its merge group"""
    branch_id = current_user.current_branch_id
    
    # Get table
    query = db.query(Table).filter(Table.id == table_id)
    query = apply_branch_filter_table(db, query, branch_id)
    table = query.first()
    if not table:
        raise HTTPException(status_code=404, detail="Table not found or access denied")
    
    if not table.merge_group_id:
        raise HTTPException(status_code=400, detail="Table is not in a merge group")
    
    merge_group_id = table.merge_group_id
    
    # Remove from merge group
    table.merge_group_id = None
    table.merged_to_id = None
    
    # Check if table has active order
    active_order = db.query(Order).filter(
        Order.table_id == table.id,
        Order.status.in_(["Pending", "In Progress", "BillRequested", "Draft"])
    ).first()
    
    if not active_order:
        table.status = "Available"
    
    # Check if any other tables are still in this group
    remaining_query = db.query(Table).filter(Table.merge_group_id == merge_group_id)
    remaining_query = apply_branch_filter_table(db, remaining_query, branch_id)
    remaining_tables = remaining_query.all()
    
    # If only one table left, remove it from the group too
    if len(remaining_tables) == 1:
        rem_t = remaining_tables[0]
        rem_t.merge_group_id = None
        rem_t.merged_to_id = None
        
        # Check if remaining table has active order
        rem_order = db.query(Order).filter(
            Order.table_id == rem_t.id,
            Order.status.in_(["Pending", "In Progress", "BillRequested", "Draft"])
        ).first()
        if not rem_order:
            rem_t.status = "Available"
    
    db.commit()
    db.refresh(table)
    
    return {"message": "Table unmerged successfully", "table": table}


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
    current_user = Depends(get_current_user)  # Allow managers too
):
    """Create a new table in the user's current branch"""
    branch_id = current_user.current_branch_id
    
    # Check if table_id already exists in the branch
    query = db.query(Table).filter(Table.table_id == table_data.get('table_id'))
    query = apply_branch_filter_table(db, query, branch_id)
    existing = query.first()
    if existing:
        raise HTTPException(status_code=400, detail="Table ID already exists in this branch")
    
    # 1. Handle Display Order
    floor_id = table_data.get('floor_id')
    max_order_query = db.query(Table).filter(Table.floor_id == floor_id)
    max_order_query = apply_branch_filter_table(db, max_order_query, branch_id)
    max_order = max_order_query.order_by(Table.display_order.desc()).first()
    
    table_data['display_order'] = (max_order.display_order + 1) if max_order else 0
    
    # 2. Set Floor Name if missing but ID provided
    if floor_id and 'floor' not in table_data:
        floor_obj = db.query(Floor).filter(Floor.id == floor_id).first()
        if floor_obj:
            table_data['floor'] = floor_obj.name
            
    # 3. Explicitly set branch_id
    if branch_id:
        table_data['branch_id'] = branch_id

    # 4. Create and add
    try:
        new_table = Table(
            table_id=table_data.get('table_id'),
            floor_id=table_data.get('floor_id'),
            floor=table_data.get('floor'),
            table_type=table_data.get('table_type', 'Regular'),
            capacity=table_data.get('capacity', 4),
            branch_id=table_data.get('branch_id'),
            display_order=table_data.get('display_order', 0),
            status="Available",
            is_active=True
        )
        db.add(new_table)
        db.commit()
        db.refresh(new_table)
        return new_table
    except Exception as e:
        db.rollback()
        print(f"Error creating table: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create table: {str(e)}")


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
        if hasattr(table, key):
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
    
    # Hard Delete Logic
    
    # 1. Check for active orders
    active_orders = db.query(Order).filter(
        Order.table_id == table.id,
        Order.status.in_(["Pending", "In Progress", "BillRequested", "Draft"])
    ).count()
    
    if active_orders > 0:
        raise HTTPException(status_code=400, detail="Cannot delete table with active orders. Please complete or cancel them first.")
        
    # 2. Nullify table_id for past orders (preserve history)
    db.query(Order).filter(Order.table_id == table.id).update({Order.table_id: None}, synchronize_session=False)
    
    # 3. Delete table
    db.delete(table)
    db.commit()
    return {"message": "Table deleted permanently"}



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
