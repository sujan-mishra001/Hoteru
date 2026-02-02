import React, { createContext, useContext, useState, useEffect } from 'react';
import { useAuth } from './AuthProvider';
import { branchAPI } from '../../services/api';

interface Branch {
    id: number;
    name: string;
    code: string;
    location?: string;
    address?: string;
    phone?: string;
    email?: string;
}

interface BranchContextType {
    currentBranch: Branch | null;
    accessibleBranches: Branch[];
    selectBranch: (branchId: number) => Promise<void>;
    loading: boolean;
    refreshBranches: () => Promise<void>;
}

const BranchContext = createContext<BranchContextType | undefined>(undefined);

export const BranchProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const { token } = useAuth();
    const [currentBranch, setCurrentBranch] = useState<Branch | null>(null);
    const [accessibleBranches, setAccessibleBranches] = useState<Branch[]>([]);
    const [loading, setLoading] = useState(true);

    const fetchBranches = async () => {
        if (!token) return;
        try {
            setLoading(true);
            const response = await branchAPI.getAll();
            setAccessibleBranches(response.data);

            const storedBranchId = localStorage.getItem('currentBranchId');
            if (storedBranchId) {
                const branch = response.data.find((b: Branch) => b.id === parseInt(storedBranchId));
                if (branch) setCurrentBranch(branch);
            }
        } catch (error) {
            console.error('Error fetching branches:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (token) {
            fetchBranches();
        }
    }, [token]);

    const selectBranch = async (branchId: number) => {
        try {
            const response = await branchAPI.select(branchId);
            const { current_branch_id } = response.data;
            localStorage.setItem('currentBranchId', current_branch_id.toString());

            const branch = accessibleBranches.find(b => b.id === current_branch_id);
            if (branch) setCurrentBranch(branch);

            // Removed window.location.reload() to allow react-router navigation to work properly after selection
        } catch (error) {
            console.error('Error selecting branch:', error);
            throw error;
        }
    };

    return (
        <BranchContext.Provider
            value={{
                currentBranch,
                accessibleBranches,
                selectBranch,
                loading,
                refreshBranches: fetchBranches
            }}
        >
            {children}
        </BranchContext.Provider>
    );
};

export const useBranch = () => {
    const context = useContext(BranchContext);
    if (context === undefined) {
        throw new Error('useBranch must be used within a BranchProvider');
    }
    return context;
};
