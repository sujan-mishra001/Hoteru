import React from 'react';
import { BottomNavigation, BottomNavigationAction, Paper } from '@mui/material';
import { useNavigate, useLocation } from 'react-router-dom';
import { Home, ShoppingBag, UserCircle, Utensils, Receipt } from 'lucide-react';

const BottomNav: React.FC = () => {
    const navigate = useNavigate();
    const location = useLocation();

    const getActiveIndex = () => {
        const path = location.pathname;
        if (path.includes('/dashboard')) return 0;
        if (path.includes('/orders')) return 1;
        if (path.includes('/users') || path.includes('/settings')) return 2;
        if (path.includes('/menu')) return 3;
        if (path.includes('/reports')) return 4;
        return 0;
    };

    const handleChange = (_event: React.SyntheticEvent, newValue: number) => {
        const routes = ['/dashboard', '/orders', '/users', '/menu', '/reports'];
        navigate(routes[newValue]);
    };

    return (
        <Paper
            sx={{
                position: 'fixed',
                bottom: 0,
                left: 0,
                right: 0,
                zIndex: 1100,
                display: { xs: 'block', lg: 'none' },
                boxShadow: '0 -5px 10px rgba(0, 0, 0, 0.05)',
                borderTop: '1px solid #e2e8f0'
            }}
            elevation={3}
        >
            <BottomNavigation
                value={getActiveIndex()}
                onChange={handleChange}
                showLabels
                sx={{
                    height: 70,
                    bgcolor: 'white',
                    '& .MuiBottomNavigationAction-root': {
                        minWidth: 'auto',
                        color: '#9ca3af',
                        fontWeight: 600,
                        fontSize: '12px',
                        '&.Mui-selected': {
                            color: '#FFC107',
                            fontWeight: 700
                        }
                    },
                    '& .MuiBottomNavigationAction-label': {
                        fontSize: '12px',
                        '&.Mui-selected': {
                            fontSize: '12px'
                        }
                    }
                }}
            >
                <BottomNavigationAction
                    label="Home"
                    icon={<Home size={20} />}
                />
                <BottomNavigationAction
                    label="Orders"
                    icon={<ShoppingBag size={20} />}
                />
                <BottomNavigationAction
                    label="Profile"
                    icon={<UserCircle size={20} />}
                />
                <BottomNavigationAction
                    label="Menu"
                    icon={<Utensils size={20} />}
                />
                <BottomNavigationAction
                    label="Expenses"
                    icon={<Receipt size={20} />}
                />
            </BottomNavigation>
        </Paper>
    );
};

export default BottomNav;
