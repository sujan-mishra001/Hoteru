import React, { createContext, useContext } from 'react';
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
    const { permissions, loading } = React.useMemo(() => {
        if (!user) {
            return { permissions: [], loading: false };
        }

        // If we have a user but no branch, we might still be loading or at branch selection
        // In this system, permissions are generally branch-agnostic for the root user 
        // but let's be safe.
        if (user && !currentBranch) {
            // If we are at branch selection, we don't want to block, but we also 
            // don't have enough info to commit to permissions yet if they depend on branch.
            // However, the backend returns permissions on the user object.
            if (Array.isArray(user.permissions)) {
                return { permissions: user.permissions, loading: false };
            }
            return { permissions: [], loading: true };
        }

        let derivedPermissions: string[] = [];
        if (Array.isArray(user.permissions)) {
            derivedPermissions = user.permissions;
        } else {
            const userRole = user.role.toLowerCase();
            if (userRole === 'admin') {
                derivedPermissions = ['*'];
            } else if (userRole === 'manager') {
                derivedPermissions = ['dashboard.view', 'pos.access'];
            } else {
                derivedPermissions = ['pos.access'];
            }
        }

        return { permissions: derivedPermissions, loading: false };
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

