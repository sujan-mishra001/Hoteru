import React from 'react';
import { useLocation, Outlet } from 'react-router-dom';
import Supplier from './purchase_sub/Supplier';
import PurchaseBill from './purchase_sub/PurchaseBill';
import PurchaseReturn from './purchase_sub/PurchaseReturn';

const Purchase: React.FC = () => {
    const location = useLocation();

    // Handle sub-routes manually if they are not defined in AppRoutes yet
    // But ideally we use Outlet
    if (location.pathname === '/purchase/supplier') return <Supplier />;
    if (location.pathname === '/purchase/bill') return <PurchaseBill />;
    if (location.pathname === '/purchase/return') return <PurchaseReturn />;

    // Default view
    if (location.pathname === '/purchase') return <PurchaseBill />;

    return <Outlet />;
};

export default Purchase;

