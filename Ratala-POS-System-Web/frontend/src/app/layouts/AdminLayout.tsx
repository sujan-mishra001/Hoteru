import React, { useState } from 'react';
import { Box, Drawer, List, ListItem, ListItemButton, ListItemIcon, ListItemText, AppBar, Toolbar, Typography, IconButton, Avatar, Menu, MenuItem, Divider, Button, Tooltip, Dialog, DialogTitle, DialogContent, DialogContentText, DialogActions } from '@mui/material';
import {
    LayoutDashboard,
    Store,
    Users,
    Package,
    ShoppingBag,
    UserCircle,
    BarChart3,
    Settings,
    LogOut,
    Menu as MenuIcon,
    Utensils,
    MonitorDot,
    ChevronDown,
    Building2
} from 'lucide-react';
import { useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuth } from '../providers/AuthProvider';
import { useBranch } from '../providers/BranchProvider';
import BottomNav from '../../components/layout/BottomNav';

const drawerWidth = 260;

const AdminLayout: React.FC = () => {
    const navigate = useNavigate();
    const location = useLocation();
    const { logout, user } = useAuth();
    const { currentBranch, selectBranch, accessibleBranches } = useBranch();

    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
    const [branchAnchorEl, setBranchAnchorEl] = useState<null | HTMLElement>(null);

    // State for collapsible submenus
    const [openMenus, setOpenMenus] = useState<{ [key: string]: boolean }>({});
    const [mobileOpen, setMobileOpen] = useState(false);
    const [logoutDialogOpen, setLogoutDialogOpen] = useState(false);

    const handleDrawerToggle = () => {
        setMobileOpen(!mobileOpen);
    };

    const toggleMenu = (text: string) => {
        setOpenMenus(prev => ({ ...prev, [text]: !prev[text] }));
    };

    const handleProfileMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorEl(event.currentTarget);
    };

    const handleBranchMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
        setBranchAnchorEl(event.currentTarget);
    };

    const handleClose = () => {
        setAnchorEl(null);
        setBranchAnchorEl(null);
    };

    const handleLogout = () => {
        setLogoutDialogOpen(true);
        handleClose();
    };

    const confirmLogout = () => {
        logout();
        navigate('/login');
    };

    // Menu Definitions
    const sidebarItems = [
        { text: 'Dashboard', icon: <LayoutDashboard size={20} />, path: '/dashboard' },
        { text: 'Customers', icon: <UserCircle size={20} />, path: '/customers' },
    ];

    const restaurantItems = [
        { text: 'Orders', icon: <Utensils size={20} />, path: '/orders' },
        // { text: 'Delivery Partners', icon: <Truck size={20} />, path: '/delivery-partners' }, // Not implemented
        {
            text: 'Manage Menu',
            icon: <MenuIcon size={20} />,
            path: '/menu',
            hasSub: false
        },
        {
            text: 'Floors & Tables',
            icon: <Building2 size={20} />,
            path: '/floor-tables',
            adminOnly: true
        },
    ];

    const setupItems = [
        {
            text: 'User Management',
            icon: <Users size={20} />,
            path: '/users',
            hasSub: true,
            adminOnly: true,
            subItems: [
                { text: 'Staff', path: '/users' },
                { text: 'Roles', path: '/roles' }
            ]
        },
        {
            text: 'Inventory',
            icon: <Package size={20} />,
            path: '/inventory',
            hasSub: true,
            subItems: [
                { text: 'Products', path: '/inventory/products' },
                { text: 'Units', path: '/inventory/units' },
                { text: 'Stock Management', path: '/inventory/add' },
                { text: 'Counts', path: '/inventory/count' },
                { text: 'BOM', path: '/inventory/bom' },
                { text: 'Production', path: '/inventory/production' }
            ]
        },
        {
            text: 'Purchase',
            icon: <ShoppingBag size={20} />,
            path: '/purchase',
            hasSub: true,
            subItems: [
                { text: 'Suppliers', path: '/purchase/supplier' },
                { text: 'Bills', path: '/purchase/bill' },
                { text: 'Returns', path: '/purchase/return' }
            ]
        },
        { text: 'Reports', icon: <BarChart3 size={20} />, path: '/reports' },
        { text: 'Settings', icon: <Settings size={20} />, path: '/settings' },
    ];

    const renderMenuItems = (items: any[]) => {
        return items.filter(item => !item.adminOnly || user?.role === 'admin' || user?.role === 'Admin').map((item) => {
            // Check if any subitem is active to auto-expand or highlight parent
            const isSubActive = item.subItems?.some((sub: any) => location.pathname === sub.path);
            const isActive = location.pathname === item.path;

            return (
                <React.Fragment key={item.text}>
                    <ListItem disablePadding sx={{ mb: 0.5 }}>
                        <ListItemButton
                            onClick={() => item.hasSub ? toggleMenu(item.text) : navigate(item.path)}
                            selected={isActive || isSubActive}
                            sx={{
                                borderRadius: '10px',
                                mx: 1,
                                '&.Mui-selected': { bgcolor: 'rgba(255, 140, 0, 0.08)', color: '#FFC107' },
                                '&.Mui-selected .MuiListItemIcon-root': { color: '#FFC107' },
                                '&:hover': { bgcolor: 'rgba(0,0,0,0.04)' }
                            }}
                        >
                            <ListItemIcon sx={{ minWidth: 40, color: '#64748b' }}>{item.icon}</ListItemIcon>
                            <ListItemText primary={item.text} primaryTypographyProps={{ fontSize: '0.9rem', fontWeight: 600 }} />
                            {item.hasSub && (
                                item.isOpen || openMenus[item.text] ? <ChevronDown size={16} /> : <Box sx={{ transform: 'rotate(-90deg)' }}><ChevronDown size={16} /></Box>
                            )}
                        </ListItemButton>
                    </ListItem>
                    {item.hasSub && (openMenus[item.text] || isSubActive) && ( // Auto-expand if active
                        <List disablePadding sx={{ pl: 2 }}>
                            {item.subItems.filter((sub: any) => !sub.adminOnly || user?.role === 'admin' || user?.role === 'Admin').map((sub: any) => (
                                <ListItem key={sub.text} disablePadding sx={{ mb: 0.2 }}>
                                    <ListItemButton
                                        onClick={() => navigate(sub.path)}
                                        selected={location.pathname === sub.path}
                                        sx={{
                                            borderRadius: '8px',
                                            py: 0.5,
                                            mx: 1,
                                            pl: 4,
                                            '&.Mui-selected': { color: '#FFC107', bgcolor: 'transparent' },
                                            '&:hover': { color: '#FFC107', bgcolor: 'transparent' }
                                        }}
                                    >
                                        <Box sx={{ width: 6, height: 6, borderRadius: '50%', bgcolor: location.pathname === sub.path ? '#FFC107' : '#cbd5e1', mr: 2 }} />
                                        <ListItemText
                                            primary={sub.text}
                                            primaryTypographyProps={{ fontSize: '0.85rem', fontWeight: 500 }}
                                        />
                                    </ListItemButton>
                                </ListItem>
                            ))}
                        </List>
                    )}
                </React.Fragment>
            )
        });
    };

    const drawerContent = (
        <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column', bgcolor: 'white' }}>
            <Box sx={{ p: 3, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {/* Welcome Message Instead of Logo */}
                <Box sx={{ display: 'flex', flexDirection: 'column', width: '100%', px: 1 }}>
                    <Typography variant="caption" color="text.secondary" fontWeight={700} sx={{ textTransform: 'uppercase', letterSpacing: 0.5, mb: 0.5 }}>
                        Welcome to
                    </Typography>
                    <Typography variant="h6" fontWeight={800} color="#FFC107" sx={{ lineHeight: 1.2, wordBreak: 'break-word' }}>
                        {currentBranch?.name || 'HOTERU'}
                    </Typography>
                </Box>
            </Box>

            <Box sx={{ flexGrow: 1, overflowY: 'auto', py: 1 }}>
                <List>
                    {renderMenuItems(sidebarItems)}
                </List>
                <Divider sx={{ my: 1.5, mx: 2 }} >
                    <Typography variant="caption" color="text.secondary">RESTAURANT</Typography>
                </Divider>
                <List>
                    {renderMenuItems(restaurantItems)}
                </List>
                <Divider sx={{ my: 1.5, mx: 2 }} >
                    <Typography variant="caption" color="text.secondary">SETUP</Typography>
                </Divider>
                <List>
                    {renderMenuItems(setupItems)}
                </List>
            </Box>

            <Box sx={{ p: 2, borderTop: '1px solid #f1f5f9' }}>
                <ListItemButton onClick={handleLogout} sx={{ borderRadius: '10px', color: '#ef4444' }}>
                    <ListItemIcon sx={{ minWidth: 40, color: '#ef4444' }}><LogOut size={20} /></ListItemIcon>
                    <ListItemText primary="Logout" primaryTypographyProps={{ fontSize: '0.9rem', fontWeight: 600 }} />
                </ListItemButton>
            </Box>
        </Box>
    );

    return (
        <Box sx={{ display: 'flex', bgcolor: '#f8fafc', minHeight: '100vh' }}>
            <AppBar
                position="fixed"
                sx={{
                    zIndex: (theme) => theme.zIndex.drawer + 1,
                    width: { lg: `calc(100% - ${drawerWidth}px)` },
                    ml: { lg: `${drawerWidth}px` },
                    bgcolor: 'white',
                    color: '#1e293b',
                    boxShadow: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
                    borderBottom: '1px solid #e2e8f0'
                }}
            >
                <Toolbar sx={{ justifyContent: 'space-between' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <IconButton
                            color="inherit"
                            aria-label="open drawer"
                            onClick={() => setMobileOpen(!mobileOpen)}
                            edge="start"
                            sx={{ mr: 2, display: { lg: 'none' } }}
                        >
                            <MenuIcon />
                        </IconButton>
                        <Box sx={{ display: { xs: 'none', sm: 'block' } }}>
                            <Typography variant="subtitle1" fontWeight={700} color="#1e293b">
                                {
                                    location.pathname.includes('/dashboard') ? 'Dashboard' :
                                        location.pathname.includes('/inventory') ? 'Inventory' :
                                            location.pathname.includes('/orders') ? 'Orders' :
                                                'Admin'
                                }
                            </Typography>
                        </Box>
                    </Box>

                    <Box sx={{ display: 'flex', alignItems: 'center', gap: { xs: 0.5, sm: 1, md: 2 } }}>
                        {/* Branch Selector */}
                        <Box
                            onClick={handleBranchMenuOpen}
                            sx={{
                                display: { xs: 'none', sm: 'flex' },
                                alignItems: 'center',
                                gap: 1,
                                cursor: 'pointer',
                                px: { xs: 1, sm: 2 },
                                py: 0.8,
                                borderRadius: '8px',
                                bgcolor: '#f8fafc',
                                border: '1px solid #e2e8f0',
                                '&:hover': { bgcolor: '#f1f5f9' }
                            }}
                        >
                            <Store size={16} color="#64748b" />
                            <Box sx={{ display: { xs: 'none', md: 'block' } }}>
                                <Typography variant="caption" color="text.secondary" sx={{ display: 'block', lineHeight: 1, fontSize: '0.7rem' }}>BRANCH</Typography>
                                <Typography variant="subtitle2" sx={{ fontWeight: 700, lineHeight: 1.2 }}>{currentBranch?.name || 'Select'}</Typography>
                            </Box>
                            <ChevronDown size={14} color="#94a3b8" />
                        </Box>

                        <Menu
                            anchorEl={branchAnchorEl}
                            open={Boolean(branchAnchorEl)}
                            onClose={handleClose}
                            PaperProps={{
                                sx: { width: 220, mt: 1, borderRadius: '12px', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }
                            }}
                        >
                            <Typography sx={{ px: 2, py: 1, fontWeight: 700, fontSize: '0.75rem', color: '#64748b', textTransform: 'uppercase' }}>Switch Branch</Typography>
                            {accessibleBranches.map((branch) => (
                                <MenuItem
                                    key={branch.id}
                                    onClick={() => { selectBranch(branch.id); handleClose(); }}
                                    selected={currentBranch?.id === branch.id}
                                >
                                    {branch.name}
                                </MenuItem>
                            ))}
                            <Divider />
                            <MenuItem onClick={() => { navigate('/branches/create'); handleClose(); }}>
                                <ListItemIcon><Store size={18} /></ListItemIcon>
                                Create New Branch
                            </MenuItem>
                        </Menu>

                        {/* Top Bar Actions */}
                        <Tooltip title="Open POS">
                            <Button
                                variant="contained"
                                onClick={() => navigate('/pos')}
                                startIcon={<MonitorDot size={18} />}
                                sx={{
                                    bgcolor: '#FFC107',
                                    textTransform: 'none',
                                    fontWeight: 700,
                                    boxShadow: 'none',
                                    minWidth: { xs: 'auto', sm: '64px' },
                                    px: { xs: 1.5, sm: 2 },
                                    '&:hover': { bgcolor: '#e67e00', boxShadow: 'none' },
                                    '& .MuiButton-startIcon': { mr: { xs: 0, sm: 1 } }
                                }}
                            >
                                <Box sx={{ display: { xs: 'none', sm: 'block' } }}>POS</Box>
                            </Button>
                        </Tooltip>

                        {/* Profile */}
                        <IconButton onClick={handleProfileMenuOpen} sx={{ p: 0.5 }}>
                            <Avatar sx={{ width: 36, height: 36, bgcolor: '#FFC107', fontWeight: 700, fontSize: '1rem' }}>
                                {user?.username?.charAt(0).toUpperCase()}
                            </Avatar>
                        </IconButton>

                        <Menu
                            anchorEl={anchorEl}
                            open={Boolean(anchorEl)}
                            onClose={handleClose}
                            PaperProps={{
                                sx: { width: 200, mt: 1, borderRadius: '12px', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }
                            }}
                        >
                            <Box sx={{ px: 2, py: 1 }}>
                                <Typography variant="subtitle2" fontWeight={700}>{user?.username}</Typography>
                                <Typography variant="caption" color="text.secondary">{user?.role}</Typography>
                            </Box>
                            <Divider />
                            <MenuItem onClick={handleLogout} sx={{ color: '#ef4444' }}>
                                <ListItemIcon><LogOut size={18} color="#ef4444" /></ListItemIcon>
                                Logout
                            </MenuItem>
                        </Menu>
                    </Box>
                </Toolbar>
            </AppBar>

            <Box
                component="nav"
                sx={{ width: { lg: drawerWidth }, flexShrink: { lg: 0 } }}
            >
                {/* Mobile Drawer */}
                <Drawer
                    variant="temporary"
                    open={mobileOpen}
                    onClose={handleDrawerToggle}
                    ModalProps={{ keepMounted: true }}
                    sx={{
                        display: { xs: 'block', lg: 'none' },
                        '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth, borderRight: 'none' },
                    }}
                >
                    {drawerContent}
                </Drawer>
                {/* Desktop Drawer */}
                <Drawer
                    variant="permanent"
                    sx={{
                        display: { xs: 'none', lg: 'block' },
                        '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth, borderRight: '1px solid #e2e8f0', bgcolor: 'white' },
                    }}
                    open
                >
                    {drawerContent}
                </Drawer>
            </Box>

            <Box component="main" sx={{ flexGrow: 1, p: { xs: 2, sm: 3 }, pt: { xs: 9, sm: 10 }, pb: { xs: 10, lg: 3 }, bgcolor: '#f8fafc', minHeight: '100vh', width: { lg: `calc(100% - ${drawerWidth}px)` } }}>
                <Outlet />
            </Box>

            {/* Mobile Bottom Navigation */}
            <BottomNav />

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
                        onClick={confirmLogout}
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
    );
};

export default AdminLayout;

