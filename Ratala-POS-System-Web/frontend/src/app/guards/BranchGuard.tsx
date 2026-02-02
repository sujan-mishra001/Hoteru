import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useBranch } from '../providers/BranchProvider';

const BranchGuard: React.FC = () => {
    const { currentBranch, loading } = useBranch();

    if (loading) {
        return <div>Loading...</div>;
    }

    if (!currentBranch) {
        return <Navigate to="/select-branch" replace />;
    }

    return <Outlet />;
};

export default BranchGuard;
