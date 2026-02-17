import React, { createContext, useContext, useState, useEffect } from 'react';
import { useAuth } from './AuthProvider';
import { branchAPI } from '../../services/api';

interface Branch {
    id: number;
    name: string;
    code: string;
    slug?: string;
    location?: string;
    address?: string;
    phone?: string;
    email?: string;
    tax_rate?: number;
    service_charge_rate?: number;
    discount_rate?: number;
}

interface BranchContextType {
    currentBranch: Branch | null;
    accessibleBranches: Branch[];
    selectBranch: (branchId: number) => Promise<void>;
    selectBranchBySlug: (slug: string) => Promise<void>;
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
            const branches = response.data;
            setAccessibleBranches(branches);

            // Try to match current branch from URL or localStorage
            const storedBranchSlug = localStorage.getItem('currentBranchSlug');
            const pathParts = window.location.pathname.split('/');
            const urlBranchSlug = pathParts.length > 1 ? pathParts[1] : null;

            const slugToMatch = urlBranchSlug || storedBranchSlug;

            if (slugToMatch) {
                // Try matching by slug (new) then by code (legacy)
                const branch = branches.find((b: Branch) =>
                    (b.slug === slugToMatch) || (b.code === slugToMatch)
                );

                if (branch) {
                    setCurrentBranch(branch);
                    localStorage.setItem('currentBranchId', branch.id.toString());
                    localStorage.setItem('currentBranchCode', branch.code);
                    localStorage.setItem('currentBranchSlug', branch.slug || '');
                    return;
                }
            }

            const storedBranchId = localStorage.getItem('currentBranchId');
            if (storedBranchId) {
                const branch = branches.find((b: Branch) => b.id === parseInt(storedBranchId));
                if (branch) {
                    setCurrentBranch(branch);
                    localStorage.setItem('currentBranchCode', branch.code);
                    localStorage.setItem('currentBranchSlug', branch.slug || '');
                }
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
        } else {
            setCurrentBranch(null);
            setAccessibleBranches([]);
            setLoading(false);
        }
    }, [token]);

    const selectBranch = async (branchId: number) => {
        try {
            const response = await branchAPI.select(branchId);
            const { current_branch_id } = response.data;

            const branch = accessibleBranches.find(b => b.id === current_branch_id);
            if (branch) {
                setCurrentBranch(branch);
                localStorage.setItem('currentBranchId', current_branch_id.toString());
                localStorage.setItem('currentBranchCode', branch.code);
                localStorage.setItem('currentBranchSlug', branch.slug || '');

                // Update token if returned (contains the new branch_id claim)
                if (response.data.access_token) {
                    localStorage.setItem('token', response.data.access_token);
                }
            }
        } catch (error) {
            console.error('Error selecting branch:', error);
            throw error;
        }
    };

    const selectBranchBySlug = async (slug: string) => {
        let branches = accessibleBranches;
        if (branches.length === 0) {
            const response = await branchAPI.getAll();
            branches = response.data;
            setAccessibleBranches(branches);
        }

        if (branches.length > 0) {
            const branch = branches.find(b => (b.slug === slug) || (b.code === slug));
            if (branch) {
                setCurrentBranch(branch);
                localStorage.setItem('currentBranchId', branch.id.toString());
                localStorage.setItem('currentBranchCode', branch.code);
                localStorage.setItem('currentBranchSlug', branch.slug || '');
            }
        }
    };

    return (
        <BranchContext.Provider
            value={{
                currentBranch,
                accessibleBranches,
                selectBranch,
                selectBranchBySlug,
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

