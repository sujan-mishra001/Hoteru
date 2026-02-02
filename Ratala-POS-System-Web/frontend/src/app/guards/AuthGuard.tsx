import React from 'react';
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../providers/AuthProvider';

const AuthGuard: React.FC = () => {
    const { token, loading } = useAuth();
    const location = useLocation();

    if (loading) {
        return <div>Loading...</div>; // Replace with proper loading spinner
    }

    if (!token) {
        return <Navigate to="/login" state={{ from: location }} replace />;
    }

    return <Outlet />;
};

export default AuthGuard;
