# Multi-Branch Data Isolation Architecture

## Overview

This system uses a **single shared database** with **branch-based data isolation** to support multiple restaurant branches. This is the industry-standard approach for multi-tenant SaaS applications.

## Architecture Design

### Single Database with Branch Isolation ✅

```
┌─────────────────────────────────────────┐
│         PostgreSQL Database             │
│                                         │
│  ┌─────────────┐  ┌─────────────┐     │
│  │  Branch 1   │  │  Branch 2   │     │
│  │   Data      │  │   Data      │     │
│  │ (branch_id=1)│  │(branch_id=2)│     │
│  └─────────────┘  └─────────────┘     │
│                                         │
│  All data filtered by branch_id        │
└─────────────────────────────────────────┘
```

### Why This Approach?

1. **Data Integrity**: Foreign key constraints work across all branches
2. **Easier Maintenance**: Single schema to manage and migrate
3. **Better Performance**: No database connection switching overhead
4. **Centralized Reporting**: Admins can generate cross-branch analytics
5. **Simpler Backups**: One database to backup and restore
6. **Cost Effective**: Single database instance for all branches
7. **Scalability**: Can handle hundreds of branches efficiently

## Models with Branch Isolation

The following models have `branch_id` foreign keys:

### Core Business Models
- ✅ **Orders** - Each order belongs to a specific branch
- ✅ **Tables** - Each branch has its own tables
- ✅ **Floors** - Floor layouts are branch-specific
- ✅ **Menu Items** - Branches can have different menus/pricing
- ✅ **Categories** - Menu categories per branch
- ✅ **Menu Groups** - Menu organization per branch

### Customer & Inventory
- ✅ **Customers** - Track which branch they frequent
- ✅ **Products** - Inventory is branch-specific
- ✅ **Inventory Transactions** - Stock movements per branch
- ✅ **Purchase Bills** - Purchases are branch-specific

### Sessions
- ✅ **Sessions** - Meal sessions (Breakfast/Lunch/Dinner) per branch
- ✅ **POS Sessions** - Staff shift sessions per branch

## How Data Sync Works

### Mobile App ↔ Backend ↔ Web App

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│  Mobile App  │         │   Backend    │         │   Web App    │
│              │         │              │         │              │
│ Branch: XYZ  │◄───────►│  Filters by  │◄───────►│ Branch: XYZ  │
│              │   API   │  branch_id   │   API   │              │
└──────────────┘         └──────────────┘         └──────────────┘
                                │
                                ▼
                         ┌──────────────┐
                         │  PostgreSQL  │
                         │   Database   │
                         └──────────────┘
```

### Authentication Flow

1. **User Login**
   ```
   POST /auth/login
   → Returns: { user_id, token, branches: [...] }
   ```

2. **Branch Selection**
   ```
   POST /auth/select-branch
   Body: { branch_id: 1 }
   → Updates: user.current_branch_id = 1
   ```

3. **All Subsequent Requests**
   ```
   GET /orders
   → Backend automatically filters: WHERE branch_id = user.current_branch_id
   ```

## Implementation Guide

### 1. Database Migration

Run the migration to add branch_id columns:

```bash
cd backend
alembic upgrade head
```

This will add `branch_id` to all critical models.

### 2. API Endpoints - Automatic Filtering

All API endpoints automatically filter by the user's current branch:

```python
from app.utils.branch_isolation import apply_branch_filter

@router.get("/orders")
def get_orders(db: Session, current_user = Depends(get_current_user)):
    branch_id = current_user.current_branch_id
    
    # Query with automatic branch filtering
    query = db.query(Order)
    query = apply_branch_filter(query, Order, branch_id)
    
    return query.all()
```

### 3. Creating New Records

When creating new records, automatically set the branch_id:

```python
from app.utils.branch_isolation import set_branch_id_on_create

@router.post("/orders")
def create_order(order_data: OrderCreate, db: Session, current_user = Depends(get_current_user)):
    branch_id = current_user.current_branch_id
    
    # Create order
    order = Order(**order_data.dict())
    
    # Automatically set branch_id
    set_branch_id_on_create(order, branch_id)
    
    db.add(order)
    db.commit()
    return order
```

### 4. Mobile App Integration

The mobile app already handles branch selection:

```dart
// In branch_selection_screen.dart
await _authService.selectBranch(branch.id);

// All subsequent API calls include the user's token
// Backend automatically filters by current_branch_id
```

## Data Synchronization

### Real-time Sync

Both mobile and web apps see the same data because:

1. **Same Database**: Both apps query the same PostgreSQL database
2. **Same Branch Filter**: Both apps send the user's auth token
3. **Backend Filtering**: Backend extracts `current_branch_id` from token
4. **Automatic Isolation**: All queries filtered by `branch_id`

### Example: Order Creation Flow

```
Mobile App (Branch A)                Backend                    Web App (Branch A)
      │                                 │                              │
      │  POST /orders                   │                              │
      │  (token: user_branch_A)         │                              │
      ├────────────────────────────────►│                              │
      │                                 │ Create order                 │
      │                                 │ SET branch_id = A            │
      │                                 │ Save to database             │
      │                                 │                              │
      │  ◄─────────────────────────────┤                              │
      │  { order_id: 123 }              │                              │
      │                                 │                              │
      │                                 │  ◄───────────────────────────┤
      │                                 │  GET /orders                 │
      │                                 │  (token: user_branch_A)      │
      │                                 │                              │
      │                                 │  WHERE branch_id = A         │
      │                                 │  Returns: [order_123, ...]   │
      │                                 ├─────────────────────────────►│
      │                                 │                              │
      │                                 │  ✅ Same data on both apps   │
```

## Security Considerations

### 1. Branch Access Control

Users can only access branches they're assigned to:

```python
from app.utils.branch_isolation import ensure_branch_access

@router.get("/orders")
def get_orders(branch_id: int, db: Session, current_user = Depends(get_current_user)):
    # Verify user has access to this branch
    ensure_branch_access(current_user, branch_id, db)
    
    # Proceed with query...
```

### 2. Automatic Filtering

All queries are automatically filtered by branch_id to prevent data leakage:

```python
# ❌ WRONG - No branch filtering
orders = db.query(Order).all()  # Returns ALL branches' data!

# ✅ CORRECT - With branch filtering
branch_id = current_user.current_branch_id
orders = db.query(Order).filter(Order.branch_id == branch_id).all()
```

## Testing Branch Isolation

### Test Scenario

1. Create two branches: "Branch A" and "Branch B"
2. Create a user assigned to "Branch A"
3. Create orders in both branches
4. Login as the user and select "Branch A"
5. Verify: User only sees orders from "Branch A"
6. Switch to "Branch B" (if user has access)
7. Verify: User only sees orders from "Branch B"

### SQL Verification

```sql
-- Check branch isolation is working
SELECT branch_id, COUNT(*) as order_count
FROM orders
GROUP BY branch_id;

-- Verify a specific order belongs to correct branch
SELECT id, order_number, branch_id, created_at
FROM orders
WHERE order_number = 'ORD-001';
```

## Migration Checklist

- [x] Add `branch_id` columns to all models
- [x] Create database migration script
- [x] Add branch isolation utilities
- [ ] Update all API endpoints to use branch filtering
- [ ] Test mobile app with multiple branches
- [ ] Test web app with multiple branches
- [ ] Verify data isolation between branches
- [ ] Update existing data with branch_id values

## Next Steps

1. **Run Migration**: Execute the Alembic migration to add branch_id columns
2. **Update Existing Data**: Set branch_id for existing records
3. **Update API Endpoints**: Add branch filtering to all endpoints
4. **Test Thoroughly**: Verify isolation works correctly
5. **Deploy**: Roll out to production with proper backups

## Support

For questions or issues with branch isolation:
- Check the `app/utils/branch_isolation.py` module
- Review API endpoint implementations
- Verify user's `current_branch_id` is set correctly
- Check database foreign key constraints
