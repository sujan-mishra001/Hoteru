import React, { createContext, useContext, useState, useEffect } from 'react';
import { useBranch } from './BranchProvider';
import { inventoryAPI } from '../../services/api';

interface InventoryContextType {
    hasLowStock: boolean;
    checkLowStock: () => Promise<void>;
}

const InventoryContext = createContext<InventoryContextType | undefined>(undefined);

export const InventoryProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const { currentBranch } = useBranch();
    const [hasLowStock, setHasLowStock] = useState(false);

    const checkLowStock = async () => {
        if (!currentBranch) return;
        try {
            const res = await inventoryAPI.getProducts();
            const items = res.data || [];
            const low = items.some((p: any) => p.status === 'Low Stock' || p.status === 'Out of Stock');
            setHasLowStock(low);
        } catch (err) {
            console.error("Failed to check stock", err);
        }
    };

    useEffect(() => {
        checkLowStock();
        const interval = setInterval(checkLowStock, 60000); // Check every minute
        return () => clearInterval(interval);
    }, [currentBranch]);

    return (
        <InventoryContext.Provider value={{ hasLowStock, checkLowStock }}>
            {children}
        </InventoryContext.Provider>
    );
};

export const useInventory = () => {
    const context = useContext(InventoryContext);
    if (!context) {
        throw new Error('useInventory must be used within an InventoryProvider');
    }
    return context;
};
