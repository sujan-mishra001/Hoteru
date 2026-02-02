import React, { createContext, useContext, useState, useCallback, useEffect } from 'react';

export interface Activity {
    id: string;
    title: string;
    description: string;
    timestamp: Date;
    type: 'auth' | 'order' | 'update' | 'inventory' | 'system';
}

interface ActivityContextType {
    activities: Activity[];
    logActivity: (title: string, description: string, type: Activity['type']) => void;
    clearActivities: () => void;
    unreadCount: number;
    markAsRead: () => void;
}

const ActivityContext = createContext<ActivityContextType | undefined>(undefined);

export const useActivity = () => {
    const context = useContext(ActivityContext);
    if (!context) {
        throw new Error('useActivity must be used within an ActivityProvider');
    }
    return context;
};

export const ActivityProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [activities, setActivities] = useState<Activity[]>(() => {
        const saved = localStorage.getItem('dautari_activities');
        if (saved) {
            try {
                const parsed = JSON.parse(saved);
                return parsed.map((a: any) => ({ ...a, timestamp: new Date(a.timestamp) }));
            } catch (e) {
                return [];
            }
        }
        return [];
    });

    const [unreadCount, setUnreadCount] = useState(0);

    useEffect(() => {
        localStorage.setItem('dautari_activities', JSON.stringify(activities));
    }, [activities]);

    const logActivity = useCallback((title: string, description: string, type: Activity['type']) => {
        const newActivity: Activity = {
            id: Date.now().toString(),
            title,
            description,
            timestamp: new Date(),
            type
        };
        setActivities(prev => [newActivity, ...prev].slice(0, 50)); // Keep last 50
        setUnreadCount(prev => prev + 1);
    }, []);

    const clearActivities = useCallback(() => {
        setActivities([]);
        setUnreadCount(0);
    }, []);

    const markAsRead = useCallback(() => {
        setUnreadCount(0);
    }, []);

    return (
        <ActivityContext.Provider value={{ activities, logActivity, clearActivities, unreadCount, markAsRead }}>
            {children}
        </ActivityContext.Provider>
    );
};
