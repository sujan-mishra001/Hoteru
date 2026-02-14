import React from 'react'; // Main App Routes

import { Routes, Route, Navigate } from 'react-router-dom';

// Layouts
import AuthLayout from '../layouts/AuthLayout';
import AdminLayout from '../layouts/AdminLayout';
import POSLayout from '../layouts/POSLayout';
import BranchSetupLayout from '../layouts/BranchSetupLayout';

// Guards
import AuthGuard from '../guards/AuthGuard';
import BranchGuard from '../guards/BranchGuard';
import PermissionGuard from '../guards/PermissionGuard';

// Pages
import Login from '../../features/auth/Login';
import Signup from '../../features/auth/Signup';
import ForgotPassword from '../../features/auth/ForgotPassword';
import OTPVerification from '../../features/auth/OTPVerification';
import ResetPassword from '../../features/auth/ResetPassword';
import BranchSelection from '../../features/branches/BranchSelection';
import BranchCreate from '../../features/branches/BranchCreate';
import Dashboard from '../../features/dashboard/Dashboard';
import POSDashboard from '../../features/pos/POSDashboard';
import Billing from '../../features/pos/billing/Billing';
import OrderTaking from '../../features/pos/OrderTaking';
import KOT from '../../features/pos/KOT';
import Cashier from '../../features/pos/Cashier';
import POSSettings from '../../features/pos/POSSettings';
import FloorTableSettings from '../../features/pos/FloorTableSettings';
import MenuManagement from '../../features/pos/MenuManagement';
import Support from '../../features/pos/Support';
import Customers from '../../features/customers/Customers';
import Orders from '../../features/orders/Orders';
import Inventory from '../../features/inventory/Inventory';
import ProductList from '../../features/inventory/inventory/Products';
import Units from '../../features/inventory/inventory/Units';
import BOM from '../../features/inventory/inventory/BOM';
import Adjustment from '../../features/inventory/inventory/Adjustment';
import InventoryCount from '../../features/inventory/inventory/InventoryCount';
import Production from '../../features/inventory/inventory/Production';
import ProductionCount from '../../features/inventory/inventory/ProductionCount';
import AddInventory from '../../features/inventory/inventory/AddInventory';

import Purchase from '../../features/inventory/Purchase';
import Supplier from '../../features/inventory/purchase_sub/Supplier';
import PurchaseBill from '../../features/inventory/purchase_sub/PurchaseBill';
import PurchaseReturn from '../../features/inventory/purchase_sub/PurchaseReturn';

import UserManagement from '../../features/users/UserManagement';
import Roles from '../../features/roles/Roles';
import Reports from '../../features/reports/Reports';
import SessionReport from '../../features/reports/SessionReport';
import DailySalesReport from '../../features/reports/DailySalesReport';
import MonthlySalesReport from '../../features/reports/MonthlySalesReport';
import DaybookReport from '../../features/reports/DaybookReport';
import PurchaseReport from '../../features/reports/PurchaseReport';
import Settings from '../../features/settings/Settings';
import DigitalMenu from '../../features/pos/DigitalMenu';

const AppRoutes: React.FC = () => {
    return (
        <Routes>
            {/* Public Routes */}
            <Route element={<AuthLayout />}>
                <Route path="/login" element={<Login />} />
                <Route path="/signup" element={<Signup />} />
                <Route path="/forgot-password" element={<ForgotPassword />} />
                <Route path="/verify-otp" element={<OTPVerification />} />
                <Route path="/reset-password" element={<ResetPassword />} />
            </Route>

            {/* View-Only Routes (Outside Layouts) */}
            <Route path="/digital-menu/:branchId" element={<DigitalMenu />} />

            {/* Private Routes */}
            <Route element={<AuthGuard />}>
                {/* Branch Selection/Setup */}
                <Route element={<BranchSetupLayout />}>
                    <Route path="/select-branch" element={<BranchSelection />} />
                    <Route path="/branches/create" element={<BranchCreate />} />
                </Route>

                {/* Branch-Specific Routes */}
                <Route element={<BranchGuard />}>
                    {/* Admin/Manager Panel */}
                    <Route element={<PermissionGuard requiredPermissions={['dashboard.view']} />}>
                        <Route element={<AdminLayout />}>
                            <Route path="/dashboard" element={<Dashboard />} />
                            <Route element={<PermissionGuard allowedRoles={['admin']} />}>
                                <Route path="/users" element={<UserManagement />} />
                                <Route path="/roles" element={<Roles />} />
                            </Route>
                            <Route path="/customers" element={<Customers />} />
                            <Route path="/orders" element={<Orders />} />
                            <Route path="/inventory" element={<Inventory />}>
                                <Route index element={<ProductList />} />
                                <Route path="products" element={<ProductList />} />
                                <Route path="units" element={<Units />} />
                                <Route path="bom" element={<BOM />} />
                                <Route path="adjustment" element={<Adjustment />} />
                                <Route path="count" element={<InventoryCount />} />
                                <Route path="production" element={<Production />} />
                                <Route path="production-count" element={<ProductionCount />} />
                                <Route path="add" element={<AddInventory />} />
                            </Route>

                            <Route path="/purchase" element={<Purchase />}>
                                <Route index element={<PurchaseBill />} />
                                <Route path="supplier" element={<Supplier />} />
                                <Route path="bill" element={<PurchaseBill />} />
                                <Route path="return" element={<PurchaseReturn />} />
                            </Route>
                            <Route path="/reports">
                                <Route index element={<Reports />} />
                                <Route path="sessions" element={<SessionReport />} />
                                <Route path="daily-sales" element={<DailySalesReport />} />
                                <Route path="monthly-sales" element={<MonthlySalesReport />} />
                                <Route path="daybook" element={<DaybookReport />} />
                                <Route path="purchase" element={<PurchaseReport />} />
                            </Route>
                            <Route path="/settings" element={<Settings />} />
                            <Route path="/menu" element={<MenuManagement />} />
                            <Route element={<PermissionGuard allowedRoles={['admin']} />}>
                                <Route path="/floor-tables" element={<FloorTableSettings />} />
                            </Route>

                            <Route path="/" element={<Navigate to="/dashboard" replace />} />
                        </Route>
                    </Route>

                    {/* POS Interface */}
                    <Route element={<PermissionGuard requiredPermissions={['pos.access']} />}>
                        <Route path="/pos" element={<POSLayout />}>
                            <Route index element={<Navigate to="/pos/tables" replace />} />
                            <Route path="tables" element={<POSDashboard />} />
                            <Route path="customers" element={<Customers />} />
                            <Route path="orders" element={<Orders />} />
                            <Route path="kot" element={<KOT />} />
                            <Route path="cashier" element={<Cashier />} />
                            <Route path="billing/:tableId" element={<Billing />} />
                            <Route path="order/:tableId" element={<OrderTaking />} />
                            <Route path="order" element={<OrderTaking />} />
                            <Route path="order-taking/:tableId" element={<OrderTaking />} />
                            <Route path="settings" element={<POSSettings />} />
                            <Route path="menu" element={<MenuManagement />} />
                            <Route path="support" element={<Support />} />
                        </Route>
                    </Route>
                </Route>
            </Route>

            {/* Unauthorized & 404 */}
            <Route path="/unauthorized" element={<div>Unauthorized Access</div>} />
            <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
    );
};

export default AppRoutes;

