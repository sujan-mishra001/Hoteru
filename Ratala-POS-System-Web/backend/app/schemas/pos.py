from pydantic import BaseModel
from typing import List, Optional
from .menu_inventory import CategoryResponse, MenuGroupResponse, MenuItemResponse
from .orders_customers import TableResponse

class TableSyncInfo(BaseModel):
    id: int
    table_id: str
    floor: Optional[str] = None
    floor_id: Optional[int] = None
    table_type: str
    capacity: int
    status: str
    kot_count: int
    bot_count: int
    active_order_id: Optional[int] = None
    total_amount: Optional[float] = 0.0
    is_hold_table: Optional[str] = "No"
    merge_group_id: Optional[str] = None
    merged_to_id: Optional[int] = None

class POSSyncResponse(BaseModel):
    categories: List[CategoryResponse]
    groups: List[MenuGroupResponse]
    items: List[MenuItemResponse]
    floors: List[dict] # Floors are simple
    active_session: Optional[dict] = None
    tables: List[TableSyncInfo]
