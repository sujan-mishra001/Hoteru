import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { usePermission } from '../providers/PermissionProvider';
import { useAuth } from '../providers/AuthProvider';

interface PermissionGuardProps {
    requiredPermissions?: string[];
    allowedRoles?: string[];
}

const PermissionGuard: React.FC<PermissionGuardProps> = ({ requiredPermissions, allowedRoles }) => {
    const { hasAnyPermission, loading } = usePermission();
    const { user } = useAuth();

    if (loading) {
        return <div>Loading...</div>;
    }

    const hasRoleAccess = !allowedRoles || (user && allowedRoles.includes(user.role.toLowerCase()));
    const hasPermissionAccess = !requiredPermissions || hasAnyPermission(requiredPermissions);

    if (!hasRoleAccess || !hasPermissionAccess) {
        return <Navigate to="/unauthorized" replace />;
    }

    return <Outlet />;
};

export default PermissionGuard;
