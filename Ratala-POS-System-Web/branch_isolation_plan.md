# Implementation Plan - Robust Branch Isolation

This plan outlines the transition from session-based branch tracking to **URL-based branch identifiers**, ensuring strict data isolation across multiple branches.

## 1. Frontend: URL-Driven Context
The branch identity will be moved into the browser path. For example: `http://localhost:5173/OMEGA/inventory`.

### Tasks:
- [ ] **Route Refactoring**: Wrap all branch-specific routes in `AppRoutes.tsx` under a `/:branchCode` path.
- [ ] **Navigation Update**: Update `BranchSelection.tsx` to redirect users to `/${branch.code}/dashboard` upon selection.
- [ ] **Branch Guard Update**: The `BranchGuard.tsx` will now extract the branch code from the URL and verify access.
- [ ] **API Interceptor**: Update `api.ts` to automatically inject an `X-Branch-Code` header into every request, derived from the current URL.

## 2. Backend: Strict Context Filtering
The backend will strictly enforce that data is only visible for the branch specified in the request header.

### Tasks:
- [ ] **Branch Context Dependency**: Create `get_branch_id` dependency in `app/core/dependencies.py` to resolve the `branch_code` header to a database `branch_id`.
- [ ] **Endpoint Hardening**: Update all list and create endpoints to filter/insert using the resolved `branch_id`.
- [ ] **User-Branch Verification**: Ensure that the `current_user` has a valid assignment for the requested branch before processing ANY data.

## 3. Data Integrity & Uniqueness
Ensure that data created in different branches remains distinct even in shared tables.

### Tasks:
- [ ] **Order Number Prefixing**: Update `Order` model/schema logic to prefix order numbers with the branch code (e.g., `OMEGA-ORD-001`).
- [ ] **Schema Audit**: Verify that all operational tables (Orders, Transactions, KOTs, Sessions) have a non-nullable `branch_id` column.

## 4. Migration Path
- [ ] Backfill any existing data that might be missing `branch_id`.
- [ ] Update frontend components (Breadcrumbs, Sidebar) to maintain the branch prefix in navigation.
