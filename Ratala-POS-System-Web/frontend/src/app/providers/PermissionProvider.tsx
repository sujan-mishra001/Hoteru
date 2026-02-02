import React, { createContext, useContext, useState, useEffect } from 'react';
import { useAuth } from './AuthProvider';
import { useBranch } from './BranchProvider';

interface PermissionContextType {
    permissions: string[];
    hasPermission: (permission: string) => boolean;
    hasAnyPermission: (permissions: string[]) => boolean;
    loading: boolean;
}

const PermissionContext = createContext<PermissionContextType | undefined>(undefined);

export const PermissionProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const { user } = useAuth();
    const { currentBranch } = useBranch();
    const [permissions, setPermissions] = useState<string[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (user && currentBranch) {
            // Priority 1: Dynamic permissions from backend (if available)
            // We check if permissions exists as an array, even if it's empty
            if (Array.isArray(user.permissions)) {
                setPermissions(user.permissions);
                // If it's an empty list but the role is 'admin', we should still grant all if '*' is not there
                // although backend already handles this.
            }
            // Priority 2: Fallback to hardcoded roles if backend didn't provide permissions
            else {
                const userRole = user.role.toLowerCase();
                let derivedPermissions: string[] = [];

                if (userRole === 'admin') {
                    derivedPermissions = ['*'];
                } else if (userRole === 'manager') {
                    derivedPermissions = ['dashboard.view', 'pos.access', 'inventory.view', 'orders.view', 'customers.manage', 'sessions.manage'];
                } else if (userRole === 'waiter' || userRole === 'bartender') {
                    derivedPermissions = ['pos.access', 'orders.view', 'customers.manage'];
                } else if (userRole === 'store keeper') {
                    derivedPermissions = ['inventory.manage', 'inventory.view'];
                } else if (userRole === 'cashier') {
                    derivedPermissions = ['pos.access', 'orders.view', 'cashier.view', 'sessions.manage'];
                } else if (userRole === 'worker') {
                    derivedPermissions = ['pos.access', 'orders.view', 'sessions.manage'];
                }
                setPermissions(derivedPermissions);
            }
        } else {
            setPermissions([]);
        }
        setLoading(false);
    }, [user, currentBranch]);

    const hasPermission = (permission: string) => {
        if (permissions.includes('*')) return true;
        const normalizedTarget = permission.replace(':', '.').toLowerCase();

        // Custom alias mapping for flexibility
        const aliases: Record<string, string[]> = {
            'sessions.manage': ['session.manage', 'sessions.manage', 'session:manage', 'sessions:manage'],
            'session.manage': ['session.manage', 'sessions.manage', 'session:manage', 'sessions:manage']
        };

        const searchTerms = aliases[normalizedTarget] || [normalizedTarget];

        return permissions.some(p => {
            const normalizedP = p.replace(':', '.').toLowerCase();
            return searchTerms.includes(normalizedP);
        });
    };

    const hasAnyPermission = (requiredPermissions: string[]) => {
        if (permissions.includes('*')) return true;
        return requiredPermissions.some(p => hasPermission(p));
    };

    return (
        <PermissionContext.Provider
            value={{
                permissions,
                hasPermission,
                hasAnyPermission,
                loading
            }}
        >
            {children}
        </PermissionContext.Provider>
    );
};

export const usePermission = () => {
    const context = useContext(PermissionContext);
    if (context === undefined) {
        throw new Error('usePermission must be used within a PermissionProvider');
    }
    return context;
};
