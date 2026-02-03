import React, { createContext, useContext, useState, useCallback } from 'react';
import BeautifulAlert from '../../components/common/BeautifulAlert';
import BeautifulConfirm from '../../components/common/BeautifulConfirm';

interface NotificationContextType {
    showAlert: (message: string, severity?: 'success' | 'error' | 'warning' | 'info') => void;
    showConfirm: (options: ConfirmOptions) => void;
}

interface ConfirmOptions {
    title: string;
    message: string;
    onConfirm: () => void;
    onCancel?: () => void;
    confirmText?: string;
    cancelText?: string;
    isDestructive?: boolean;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

export const useNotification = () => {
    const context = useContext(NotificationContext);
    if (!context) {
        throw new Error('useNotification must be used within a NotificationProvider');
    }
    return context;
};

export const NotificationProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    // Alert State
    const [alert, setAlert] = useState<{ open: boolean; message: string; severity: 'success' | 'error' | 'warning' | 'info' }>({
        open: false,
        message: '',
        severity: 'success'
    });

    // Confirm State
    const [confirm, setConfirm] = useState<{
        open: boolean;
        title: string;
        message: string;
        confirmText: string;
        cancelText: string;
        isDestructive: boolean;
        onConfirm: () => void;
        onCancel: () => void;
    }>({
        open: false,
        title: '',
        message: '',
        confirmText: 'Confirm',
        cancelText: 'Cancel',
        isDestructive: false,
        onConfirm: () => { },
        onCancel: () => { }
    });

    const showAlert = useCallback((message: string, severity: 'success' | 'error' | 'warning' | 'info' = 'success') => {
        setAlert({ open: true, message, severity });
        // Auto-close alert after 4s
        setTimeout(() => {
            setAlert(prev => ({ ...prev, open: false }));
        }, 4000);
    }, []);

    const showConfirm = useCallback((options: ConfirmOptions) => {
        setConfirm({
            open: true,
            title: options.title,
            message: options.message,
            confirmText: options.confirmText || 'Confirm',
            cancelText: options.cancelText || 'Cancel',
            isDestructive: options.isDestructive || false,
            onConfirm: () => {
                options.onConfirm();
                setConfirm(prev => ({ ...prev, open: false }));
            },
            onCancel: () => {
                if (options.onCancel) options.onCancel();
                setConfirm(prev => ({ ...prev, open: false }));
            }
        });
    }, []);

    return (
        <NotificationContext.Provider value={{ showAlert, showConfirm }}>
            {children}
            <BeautifulAlert
                open={alert.open}
                message={alert.message}
                severity={alert.severity}
                onClose={() => setAlert(prev => ({ ...prev, open: false }))}
            />
            <BeautifulConfirm
                open={confirm.open}
                title={confirm.title}
                message={confirm.message}
                confirmText={confirm.confirmText}
                cancelText={confirm.cancelText}
                isDestructive={confirm.isDestructive}
                onConfirm={confirm.onConfirm}
                onCancel={confirm.onCancel}
            />
        </NotificationContext.Provider>
    );
};

