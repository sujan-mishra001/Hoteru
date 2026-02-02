import React, { useState } from 'react';
import { Box, Tooltip, IconButton, Avatar, Typography, Menu, MenuItem, ListItemIcon, Divider, Dialog, DialogTitle, DialogContent, DialogContentText, DialogActions, Button } from '@mui/material';
import {
    Grid2X2,
    Utensils,
    ShoppingBag,
    Wallet,
    UserCircle,
    LogOut,
    LayoutDashboard,
    Settings,
    HelpCircle
} from 'lucide-react';
import { useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuth } from '../providers/AuthProvider';
import { usePermission } from '../providers/PermissionProvider';

const POSLayout: React.FC = () => {
    const navigate = useNavigate();
    const location = useLocation();
    const { logout, user } = useAuth();
    const { hasPermission } = usePermission();
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
    const [logoutDialogOpen, setLogoutDialogOpen] = useState(false);
    const open = Boolean(anchorEl);



    const handleAccountClick = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorEl(event.currentTarget);
    };

    const handleClose = () => {
        setAnchorEl(null);
    };

    const menuItems = [
        { icon: <Grid2X2 size={24} />, label: 'Tables', path: '/pos/tables' },
        { icon: <Utensils size={24} />, label: 'KOT', path: '/pos/kot' },
        { icon: <ShoppingBag size={24} />, label: 'Orders', path: '/pos/orders' },
        { icon: <Wallet size={24} />, label: 'Cashier', path: '/pos/cashier' },
        { icon: <UserCircle size={24} />, label: 'Customers', path: '/pos/customers' },
    ];

    return (
        <Box sx={{ display: 'flex', minHeight: '100vh', bgcolor: '#fdfdfd' }}>
            {/* Narrow POS Sidebar */}
            <Box sx={{
                width: 80,
                bgcolor: 'white',
                borderRight: '1px solid #f1f5f9',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                py: 3,
                position: 'fixed',
                height: '100vh',
                zIndex: 1200
            }}>

                {/* Nav Items */}
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, flexGrow: 1 }}>
                    {menuItems.map((item) => {
                        const isActive = location.pathname === item.path ||
                            (item.path === '/pos' && location.pathname.startsWith('/pos/order')) ||
                            (item.path === '/pos' && location.pathname.startsWith('/pos/billing'));
                        return (
                            <Tooltip key={item.label} title={item.label} placement="right">
                                <Box
                                    onClick={() => navigate(item.path)}
                                    sx={{
                                        display: 'flex',
                                        flexDirection: 'column',
                                        alignItems: 'center',
                                        cursor: 'pointer',
                                        gap: 0.5,
                                        p: 1,
                                        borderRadius: '12px',
                                        border: isActive ? '1px solid #FF8C00' : '1px solid transparent',
                                        bgcolor: isActive ? '#fff7ed' : 'transparent',
                                        color: isActive ? '#FF8C00' : '#94a3b8',
                                        transition: 'all 0.2s',
                                        '&:hover': {
                                            color: '#FF8C00',
                                            bgcolor: '#fff7ed'
                                        }
                                    }}
                                >
                                    {item.icon}
                                    <Typography variant="caption" sx={{ fontSize: '10px', fontWeight: isActive ? 700 : 500 }}>
                                        {item.label}
                                    </Typography>
                                </Box>
                            </Tooltip>
                        );
                    })}
                </Box>

                {/* Back to Dashboard & Logout */}
                <Box sx={{ pb: 2, display: 'flex', flexDirection: 'column', gap: 1 }}>
                    {hasPermission('dashboard.view') && (
                        <>
                            <Tooltip title="Admin Panel" placement="right">
                                <IconButton
                                    onClick={() => navigate('/dashboard')}
                                    sx={{ color: '#94a3b8', '&:hover': { color: '#FF8C00' } }}
                                >
                                    <LayoutDashboard size={20} />
                                </IconButton>
                            </Tooltip>
                        </>
                    )}

                    <Box
                        onClick={handleAccountClick}
                        sx={{
                            mt: 1,
                            display: 'flex',
                            flexDirection: 'column',
                            alignItems: 'center',
                            gap: 0.5,
                            cursor: 'pointer',
                            p: 1,
                            borderRadius: '12px',
                            '&:hover': { bgcolor: '#f8fafc' },
                            transition: 'all 0.2s'
                        }}
                    >
                        <Avatar sx={{
                            width: 32,
                            height: 32,
                            bgcolor: open ? '#FF8C00' : '#f1f5f9',
                            color: open ? 'white' : '#94a3b8',
                            fontSize: '14px',
                            fontWeight: 700,
                            transition: 'all 0.2s'
                        }}>
                            {user?.username?.charAt(0).toUpperCase() || 'U'}
                        </Avatar>
                        <Typography variant="caption" sx={{ fontSize: '10px', color: open ? '#FF8C00' : '#94a3b8', fontWeight: 600 }}>Account</Typography>
                    </Box>

                    <Menu
                        anchorEl={anchorEl}
                        open={open}
                        onClose={handleClose}
                        onClick={handleClose}
                        transformOrigin={{ horizontal: 'left', vertical: 'bottom' }}
                        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
                        sx={{
                            '& .MuiPaper-root': {
                                width: 180,
                                borderRadius: '12px',
                                mt: -1,
                                ml: 1,
                                boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
                                border: '1px solid #f1f5f9'
                            }
                        }}
                    >
                        <Box sx={{ px: 2, py: 1.5 }}>
                            <Typography variant="subtitle2" fontWeight={800} color="#1e293b" sx={{ lineHeight: 1.2 }}>
                                {user?.username || 'User'}
                            </Typography>
                            <Typography variant="caption" color="text.secondary" sx={{ textTransform: 'capitalize' }}>
                                {user?.role || 'Staff Member'}
                            </Typography>
                        </Box>
                        <Divider sx={{ my: 0.5, borderColor: '#f1f5f9' }} />
                        <MenuItem onClick={() => navigate('/pos/settings')} sx={{ py: 1, gap: 1.5, fontSize: '14px', fontWeight: 600 }}>
                            <ListItemIcon sx={{ minWidth: 'auto !important' }}>
                                <Settings size={18} color="#64748b" />
                            </ListItemIcon>
                            Settings
                        </MenuItem>
                        <MenuItem onClick={() => navigate('/pos/support')} sx={{ py: 1, gap: 1.5, fontSize: '14px', fontWeight: 600 }}>
                            <ListItemIcon sx={{ minWidth: 'auto !important' }}>
                                <HelpCircle size={18} color="#64748b" />
                            </ListItemIcon>
                            Support
                        </MenuItem>
                        <Divider sx={{ my: 0.5, borderColor: '#f1f5f9' }} />
                        <MenuItem onClick={() => setLogoutDialogOpen(true)} sx={{ py: 1, gap: 1.5, fontSize: '14px', fontWeight: 600, color: '#ef4444' }}>
                            <ListItemIcon sx={{ minWidth: 'auto !important' }}>
                                <LogOut size={18} color="#ef4444" />
                            </ListItemIcon>
                            Logout
                        </MenuItem>
                    </Menu>
                </Box>
            </Box>

            {/* Main Content */}
            <Box sx={{
                flexGrow: 1,
                ml: '80px',
                p: 4,
                width: 'calc(100% - 80px)'
            }}>
                <Outlet />

                {/* Logout Confirmation Dialog */}
                <Dialog
                    open={logoutDialogOpen}
                    onClose={() => setLogoutDialogOpen(false)}
                    PaperProps={{
                        sx: { borderRadius: '16px', p: 1 }
                    }}
                >
                    <DialogTitle sx={{ fontWeight: 800 }}>Confirm Logout</DialogTitle>
                    <DialogContent>
                        <DialogContentText sx={{ fontWeight: 500, color: '#64748b' }}>
                            Are you really want to logout?
                        </DialogContentText>
                    </DialogContent>
                    <DialogActions sx={{ p: 2, gap: 1 }}>
                        <Button
                            onClick={() => setLogoutDialogOpen(false)}
                            sx={{ color: '#64748b', fontWeight: 700, textTransform: 'none' }}
                        >
                            Cancel
                        </Button>
                        <Button
                            onClick={() => {
                                logout();
                                navigate('/login');
                            }}
                            variant="contained"
                            sx={{
                                bgcolor: '#ef4444',
                                '&:hover': { bgcolor: '#dc2626' },
                                fontWeight: 700,
                                textTransform: 'none',
                                borderRadius: '10px',
                                px: 3
                            }}
                        >
                            Logout
                        </Button>
                    </DialogActions>
                </Dialog>
            </Box>
        </Box>
    );
};

export default POSLayout;
