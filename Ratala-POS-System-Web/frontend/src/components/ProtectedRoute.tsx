import React from 'react';
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../app/providers/AuthProvider';

interface ProtectedRouteProps {
    allowedRoles?: string[];
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ allowedRoles }) => {
    const { user, loading, token } = useAuth();
    const location = useLocation();

    if (loading) {
        return (
            <div className="flex items-center justify-center min-vh-100">
                <div className="spinner">Loading...</div>
            </div>
        );
    }

    if (!token) {
        return <Navigate to="/login" replace />;
    }

    if (!user) {
        return <Navigate to="/login" replace />;
    }

    // Define worker roles (non-admin roles that should only access /pos)
    const workerRoles = ['worker', 'waiter', 'bartender'];
    const isWorkerRole = workerRoles.includes(user.role);

    // Define routes accessible by workers
    const workerAllowedRoutes = ['/pos', '/orders', '/customers', '/support'];
    const publicRoutes = ['/login', '/signup'];
    const isAllowedRoute = workerAllowedRoutes.some(route => location.pathname.startsWith(route));
    const isPublicRoute = publicRoutes.includes(location.pathname);

    // If worker/waiters/bartenders try to access a route that's not allowed for them, redirect to /pos
    if (isWorkerRole && !isAllowedRoute && !isPublicRoute) {
        return <Navigate to="/pos" replace />;
    }

    // If admin tries to access worker-only routes, allow it (admin can access everything)
    if (user.role === 'admin') {
        return <Outlet />;
    }

    // Check if user has required role for this route
    if (allowedRoles && !allowedRoles.includes(user.role)) {
        // Redirect workers to /pos, admins to dashboard
        if (isWorkerRole) {
            return <Navigate to="/pos" replace />;
        }
        return <Navigate to="/welcome-admin" replace />;
    }

    return <Outlet />;
};

export default ProtectedRoute;

