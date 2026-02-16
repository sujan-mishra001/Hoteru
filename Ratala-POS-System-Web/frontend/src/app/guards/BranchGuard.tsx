import React from 'react';
import { Navigate, Outlet, useParams } from 'react-router-dom';
import { useBranch } from '../providers/BranchProvider';

const BranchGuard: React.FC = () => {
    const { branchSlug } = useParams<{ branchSlug: string }>();
    const { currentBranch, loading, selectBranchBySlug } = useBranch();

    React.useEffect(() => {
        if (branchSlug && (!currentBranch || (currentBranch.slug !== branchSlug && currentBranch.code !== branchSlug))) {
            selectBranchBySlug(branchSlug);
        }
    }, [branchSlug, currentBranch, selectBranchBySlug]);

    if (loading) {
        return <div className="flex items-center justify-center min-h-screen">Loading branch context...</div>;
    }

    if (!branchSlug) {
        return <Navigate to="/select-branch" replace />;
    }

    if (!currentBranch && !loading) {
        // If we have a branchCode but no currentBranch after loading completion, 
        // it means the branch doesn't exist or isn't accessible.
        return <Navigate to="/select-branch" replace />;
    }

    return <Outlet />;
};

export default BranchGuard;

