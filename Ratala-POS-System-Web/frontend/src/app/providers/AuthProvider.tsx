import React, { createContext, useContext, useState, useEffect } from 'react';
import { authAPI } from '../../services/api';
import { sessionManager } from '../../utils/sessionManager';

export interface User {
    id?: number;
    username: string;
    role: string;
    full_name?: string;
    email?: string;
    organization_id?: number;
    current_branch_id?: number;
    is_organization_owner?: boolean;
    permissions?: string[];
}


interface AuthContextType {
    user: User | null;
    token: string | null;
    isAuthenticated: boolean;
    login: (token: string, expiresInMinutes?: number) => Promise<void>;
    logout: () => void;
    loading: boolean;
    isSessionValid: () => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [user, setUser] = useState<User | null>(null);
    const [token, setToken] = useState<string | null>(sessionManager.getToken());
    const [loading, setLoading] = useState(true);

    const logout = () => {
        sessionManager.clearSession();
        setToken(null);
        setUser(null);
    };

    const isSessionValid = () => {
        return sessionManager.isSessionValid();
    };

    useEffect(() => {
        // Set up session expiration handler
        sessionManager.onExpired(() => {
            console.log('Session expired - logging out');
            logout();
            window.location.href = '/login?reason=session_expired';
        });

        const fetchUser = async () => {
            if (token && sessionManager.isSessionValid()) {
                try {
                    const response = await authAPI.getCurrentUser();
                    setUser({
                        id: response.data.id,
                        username: response.data.username,
                        role: response.data.role,
                        full_name: response.data.full_name,
                        email: response.data.email,
                        organization_id: response.data.organization_id,
                        current_branch_id: response.data.current_branch_id,
                        is_organization_owner: response.data.is_organization_owner,
                        permissions: response.data.permissions
                    });
                } catch (error) {
                    console.error('Error fetching user:', error);
                    logout();
                }
            } else if (token && !sessionManager.isSessionValid()) {
                // Token exists but session is invalid
                console.log('Session invalid - logging out');
                logout();
            }
            setLoading(false);
        };
        fetchUser();

        // Cleanup on unmount
        return () => {
            // Session manager cleanup is handled internally
        };
    }, [token]);

    const login = async (newToken: string, expiresInMinutes: number = 30) => {
        try {
            const response = await authAPI.getCurrentUser(newToken);
            const userData = {
                id: response.data.id,
                username: response.data.username,
                role: response.data.role,
                full_name: response.data.full_name,
                email: response.data.email,
                organization_id: response.data.organization_id,
                current_branch_id: response.data.current_branch_id,
                is_organization_owner: response.data.is_organization_owner,
                permissions: response.data.permissions
            };

            // Set session with expiration tracking
            sessionManager.setSession(
                newToken,
                expiresInMinutes,
                userData.role,
                userData.current_branch_id
            );

            setToken(newToken);
            setUser(userData);
        } catch (error) {
            console.error('Error fetching user after login:', error);
            throw error;
        }
    };

    return (
        <AuthContext.Provider
            value={{
                user,
                token,
                isAuthenticated: !!user && isSessionValid(),
                login,
                logout,
                loading,
                isSessionValid
            }}
        >
            {children}
        </AuthContext.Provider>
    );
};


export const useAuth = () => {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};
