import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
    Box,
    Typography,
    Paper,
    Tabs,
    Tab,
    List,
    ListItem,
    ListItemButton,
    ListItemIcon,
    ListItemText,
    Grid,
    TextField,
    Button,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    InputAdornment,
    Avatar,
    CircularProgress,
    Chip,
    IconButton
} from '@mui/material';
import {
    Settings as SettingsIcon,
    Utensils,
    Building2,
    User,
    Wallet,
    CreditCard,
    Printer,
    ArrowLeftRight,
    Smartphone,
    Package,
    Square,
    Truck,
    Warehouse,
    QrCode,
    Tag,
    GitMerge,
    Monitor,
    Search,
    Save,
    ChevronRight,
    Plus,
    MoreVertical,
    MapPin
} from 'lucide-react';
import { menuAPI, settingsAPI, branchAPI } from '../../services/api';

const Settings: React.FC = () => {
    const navigate = useNavigate();
    const [mainTab, setMainTab] = useState(0); // 0: General, 1: Restaurant
    const [subTab, setSubTab] = useState('company-profile');
    const [loading, setLoading] = useState(false);

    // States for Update Menu Rate
    const [menuItems, setMenuItems] = useState<any[]>([]);
    const [searchQuery, setSearchQuery] = useState('');
    const [updatedPrices, setUpdatedPrices] = useState<{ [key: number]: number }>({});

    // States for Branch Management
    const [branches, setBranches] = useState<any[]>([]);

    useEffect(() => {
        if (mainTab === 0 && subTab === 'company-profile') {
            loadCompanySettings();
        } else if (mainTab === 1 && subTab === 'update-menu-rate') {
            loadMenuItems();
        } else if (mainTab === 1 && subTab === 'add-branches') {
            loadBranches();
        }
    }, [mainTab, subTab]);

    const loadCompanySettings = async () => {
        try {
            setLoading(true);
            await settingsAPI.getCompanySettings();
            // Data is displayed via static placeholders for now as per design
        } catch (error) {
            console.error('Error loading company settings:', error);
        } finally {
            setLoading(false);
        }
    };

    const loadMenuItems = async () => {
        try {
            setLoading(true);
            const res = await menuAPI.getItems();
            setMenuItems(res.data || []);
        } catch (error) {
            console.error('Error loading menu items:', error);
        } finally {
            setLoading(false);
        }
    };

    const loadBranches = async () => {
        try {
            setLoading(true);
            const res = await branchAPI.getAll();
            setBranches(res.data || []);
        } catch (error) {
            console.error('Error loading branches:', error);
        } finally {
            setLoading(false);
        }
    };

    const handlePriceChange = (id: number, val: string) => {
        const price = parseFloat(val);
        if (!isNaN(price)) {
            setUpdatedPrices(prev => ({ ...prev, [id]: price }));
        }
    };

    const handleSaveMenuRates = async () => {
        console.log('Saving prices:', updatedPrices);
        alert('Changes saved successfully (Simulation)');
    };

    const renderGeneralSidebar = () => (
        <List sx={{ p: 0 }}>
            {[
                { id: 'company-profile', text: 'Company Profile', icon: <Building2 size={20} /> },
                { id: 'profile', text: 'Profile', icon: <User size={20} /> },
                { id: 'opening-balance', text: 'Opening Balance', icon: <Wallet size={20} /> },
                { id: 'payment-modes', text: 'Payment Modes', icon: <CreditCard size={20} /> },
                { id: 'add-printer', text: 'Add Printer', icon: <Printer size={20} /> },
                { id: 'import-export', text: 'Import/Export', icon: <ArrowLeftRight size={20} /> },
                { id: 'fonepay-setup', text: 'Fonepay Setup', icon: <Smartphone size={20} /> },
                { id: 'plans-subscription', text: 'Plans & Subscription', icon: <Package size={20} /> },
            ].map((item) => (
                <ListItem key={item.id} disablePadding>
                    <ListItemButton
                        selected={subTab === item.id}
                        onClick={() => setSubTab(item.id)}
                        sx={{
                            borderRadius: '10px',
                            mb: 0.5,
                            '&.Mui-selected': {
                                bgcolor: 'rgba(255, 140, 0, 0.08)',
                                color: '#FFC107',
                                '& .MuiListItemIcon-root': { color: '#FFC107' }
                            }
                        }}
                    >
                        <ListItemIcon sx={{ minWidth: 40, color: '#64748b' }}>{item.icon}</ListItemIcon>
                        <ListItemText primary={item.text} primaryTypographyProps={{ fontWeight: 600, fontSize: '0.875rem' }} />
                        {subTab === item.id && <ChevronRight size={16} />}
                    </ListItemButton>
                </ListItem>
            ))}
        </List>
    );

    const renderRestaurantSidebar = () => (
        <List sx={{ p: 0 }}>
            {[
                { id: 'update-menu-rate', text: 'Update Menu Rate', icon: <Utensils size={20} /> },
                { id: 'manage-tables', text: 'Manage Tables', icon: <Square size={20} /> },
                { id: 'manage-delivery', text: 'Manage Delivery Partner', icon: <Truck size={20} /> },
                { id: 'storage-area', text: 'Storage Area', icon: <Warehouse size={20} /> },
                { id: 'add-qr-payment', text: 'Add QR Payment', icon: <QrCode size={20} /> },
                { id: 'manage-discount', text: 'Manage Discount', icon: <Tag size={20} /> },
                { id: 'add-branches', text: 'Add Branches', icon: <GitMerge size={20} /> },
                { id: 'digital-menu', text: 'Digital Menu', icon: <Monitor size={20} /> },
            ].map((item) => (
                <ListItem key={item.id} disablePadding>
                    <ListItemButton
                        selected={subTab === item.id}
                        onClick={() => setSubTab(item.id)}
                        sx={{
                            borderRadius: '10px',
                            mb: 0.5,
                            '&.Mui-selected': {
                                bgcolor: 'rgba(255, 140, 0, 0.08)',
                                color: '#FFC107',
                                '& .MuiListItemIcon-root': { color: '#FFC107' }
                            }
                        }}
                    >
                        <ListItemIcon sx={{ minWidth: 40, color: '#64748b' }}>{item.icon}</ListItemIcon>
                        <ListItemText primary={item.text} primaryTypographyProps={{ fontWeight: 600, fontSize: '0.875rem' }} />
                        {subTab === item.id && <ChevronRight size={16} />}
                    </ListItemButton>
                </ListItem>
            ))}
        </List>
    );

    const renderCompanyProfile = () => (
        <Box>
            <Typography variant="h6" fontWeight={800} sx={{ mb: 3 }}>Company Profile</Typography>

            <Box sx={{ mb: 4 }}>
                <Typography variant="subtitle2" fontWeight={700} color="text.secondary" sx={{ mb: 2, textTransform: 'uppercase' }}>General Settings</Typography>
                <Paper sx={{ p: 3, borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: 'none' }}>
                    <Grid container spacing={4} alignItems="center">
                        <Grid size={{ xs: 12, md: 2 }} sx={{ display: 'flex', justifyContent: 'center' }}>
                            <Avatar
                                src="/logo.png"
                                sx={{ width: 100, height: 100, borderRadius: '16px', bgcolor: '#f8fafc', border: '2px solid #e2e8f0' }}
                            />
                        </Grid>
                        <Grid size={{ xs: 12, md: 5 }}>
                            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                                <Box>
                                    <Typography variant="caption" color="text.secondary" fontWeight={700}>COMPANY NAME</Typography>
                                    <Typography variant="body1" fontWeight={700}>HOTERU</Typography>
                                </Box>
                                <Box>
                                    <Typography variant="caption" color="text.secondary" fontWeight={700}>EMAIL ADDRESS</Typography>
                                    <Typography variant="body1">info@hoteru.com</Typography>
                                </Box>
                                <Box>
                                    <Typography variant="caption" color="text.secondary" fontWeight={700}>ADDRESS</Typography>
                                    <Typography variant="body1">Kirtipur, Kathmandu</Typography>
                                </Box>
                                <Box>
                                    <Typography variant="caption" color="text.secondary" fontWeight={700}>REGISTRATION NO.</Typography>
                                    <Typography variant="body1">23432432</Typography>
                                </Box>
                            </Box>
                        </Grid>
                        <Grid size={{ xs: 12, md: 5 }}>
                            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                                <Box>
                                    <Typography variant="caption" color="text.secondary" fontWeight={700}>TAGLINE</Typography>
                                    <Typography variant="body1">HOTERU</Typography>
                                </Box>
                                <Box>
                                    <Typography variant="caption" color="text.secondary" fontWeight={700}>CONTACT NO.</Typography>
                                    <Typography variant="body1">9800000000</Typography>
                                </Box>
                                <Box>
                                    <Typography variant="caption" color="text.secondary" fontWeight={700}>VAT/PAN NO.</Typography>
                                    <Typography variant="body1">39284032</Typography>
                                </Box>
                                <Box>
                                    <Typography variant="caption" color="text.secondary" fontWeight={700}>START DATE</Typography>
                                    <Typography variant="body1">2025-08-26</Typography>
                                </Box>
                            </Box>
                        </Grid>
                    </Grid>
                </Paper>
            </Box>

            <Box sx={{ mb: 4 }}>
                <Typography variant="subtitle2" fontWeight={700} color="text.secondary" sx={{ mb: 2, textTransform: 'uppercase' }}>Invoice Settings</Typography>
                <Paper sx={{ p: 3, borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: 'none' }}>
                    <Grid container spacing={4}>
                        <Grid size={{ xs: 12, md: 6 }}>
                            <Box>
                                <Typography variant="caption" color="text.secondary" fontWeight={700}>BILL HEADING</Typography>
                                <Typography variant="body1">-</Typography>
                            </Box>
                            <Box sx={{ mt: 2 }}>
                                <Typography variant="caption" color="text.secondary" fontWeight={700}>IS TAX</Typography>
                                <Typography variant="body1" sx={{ color: 'text.disabled' }}>inactive</Typography>
                            </Box>
                        </Grid>
                        <Grid size={{ xs: 12, md: 6 }}>
                            <Box>
                                <Typography variant="caption" color="text.secondary" fontWeight={700}>BILL REMARKS</Typography>
                                <Typography variant="body1">-</Typography>
                            </Box>
                        </Grid>
                    </Grid>
                </Paper>
            </Box>

            <Box>
                <Typography variant="subtitle2" fontWeight={700} color="text.secondary" sx={{ mb: 2, textTransform: 'uppercase' }}>Other Settings</Typography>
                <Paper sx={{ p: 3, borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: 'none' }}>
                    <Grid container spacing={4}>
                        <Grid size={{ xs: 12, md: 6 }}>
                            <Box>
                                <Typography variant="caption" color="text.secondary" fontWeight={700}>DELIVERY STATUS</Typography>
                                <Typography variant="body1">false</Typography>
                            </Box>
                            <Box sx={{ mt: 2 }}>
                                <Typography variant="caption" color="text.secondary" fontWeight={700}>PAY FIRST</Typography>
                                <Typography variant="body1">false</Typography>
                            </Box>
                        </Grid>
                        <Grid size={{ xs: 12, md: 6 }}>
                            <Box>
                                <Typography variant="caption" color="text.secondary" fontWeight={700}>NOTIFY TABLE TRANSFER</Typography>
                                <Typography variant="body1">false</Typography>
                            </Box>
                            <Box sx={{ mt: 2 }}>
                                <Typography variant="caption" color="text.secondary" fontWeight={700}>IP ADDRESS</Typography>
                                <Typography variant="body1">192.168.1.21</Typography>
                            </Box>
                        </Grid>
                    </Grid>
                </Paper>
            </Box>
        </Box>
    );

    const renderUpdateMenuRate = () => (
        <Box>
            <Typography variant="h6" fontWeight={800} sx={{ mb: 3 }}>Update Menu Rate</Typography>

            <Paper sx={{ p: 0, mb: 3, borderRadius: '12px', border: '1px solid #e2e8f0', boxShadow: 'none', overflow: 'hidden' }}>
                <Box sx={{ p: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #e2e8f0' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Box sx={{ bgcolor: 'rgba(255, 140, 0, 0.1)', p: 0.5, px: 1, borderRadius: '6px', color: '#FFC107', display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Utensils size={14} />
                            <Typography variant="caption" fontWeight={800}>MENUS</Typography>
                        </Box>
                    </Box>
                    <Button
                        variant="contained"
                        size="small"
                        startIcon={<Save size={16} />}
                        onClick={handleSaveMenuRates}
                        sx={{ bgcolor: '#4f46e5', '&:hover': { bgcolor: '#4338ca' }, borderRadius: '6px', textTransform: 'none', fontWeight: 700 }}
                    >
                        Save Changes
                    </Button>
                </Box>

                <Box sx={{ p: 2 }}>
                    <Typography variant="caption" fontWeight={800} color="text.secondary" sx={{ display: 'block', mb: 1 }}>MENUS</Typography>
                    <TextField
                        fullWidth
                        size="small"
                        placeholder="Search..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        InputProps={{
                            startAdornment: (
                                <InputAdornment position="start">
                                    <Search size={18} color="#94a3b8" />
                                </InputAdornment>
                            ),
                        }}
                        sx={{
                            '& .MuiOutlinedInput-root': { borderRadius: '6px', bgcolor: '#fff' },
                            '& .MuiOutlinedInput-input': { py: 1 }
                        }}
                    />
                </Box>

                <TableContainer>
                    <Table size="small">
                        <TableHead sx={{ bgcolor: '#fff', borderTop: '1px solid #e2e8f0' }}>
                            <TableRow>
                                <TableCell sx={{ fontWeight: 800, fontSize: '0.7rem', color: '#1e293b' }}>MENU NAME</TableCell>
                                <TableCell sx={{ fontWeight: 800, fontSize: '0.7rem', color: '#1e293b' }}>CURRENT PRICE</TableCell>
                                <TableCell sx={{ fontWeight: 800, fontSize: '0.7rem', color: '#1e293b' }}>NEW PRICE</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {loading ? (
                                <TableRow><TableCell colSpan={3} align="center" padding="normal"><CircularProgress size={20} sx={{ color: '#FFC107' }} /></TableCell></TableRow>
                            ) : menuItems
                                .filter(item => item.name.toLowerCase().includes(searchQuery.toLowerCase()))
                                .map((item) => (
                                    <TableRow key={item.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                                        <TableCell sx={{ fontSize: '0.8rem', color: '#475569' }}>{item.name}</TableCell>
                                        <TableCell sx={{ fontSize: '0.8rem', color: '#475569' }}>{item.price}</TableCell>
                                        <TableCell sx={{ width: 140 }}>
                                            <TextField
                                                size="small"
                                                fullWidth
                                                placeholder=""
                                                onChange={(e) => handlePriceChange(item.id, e.target.value)}
                                                sx={{
                                                    '& .MuiOutlinedInput-root': { borderRadius: '4px', bgcolor: '#f8fafc', height: 32 },
                                                    '& .MuiOutlinedInput-input': { fontSize: '0.8rem' }
                                                }}
                                            />
                                        </TableCell>
                                    </TableRow>
                                ))}
                        </TableBody>
                    </Table>
                </TableContainer>

                <Box sx={{ p: 1, borderTop: '1px solid #e2e8f0', display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: 2 }}>
                    <Typography variant="caption" color="text.secondary">Rows per page: 15</Typography>
                    <Typography variant="caption" color="text.secondary">1-15 of {menuItems.length}</Typography>
                </Box>
            </Paper>
        </Box>
    );

    const renderBranchManagement = () => (
        <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h6" fontWeight={800}>Manage Branches</Typography>
                <Button
                    variant="contained"
                    startIcon={<Plus size={18} />}
                    onClick={() => navigate('/branches/create')}
                    sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', borderRadius: '8px', fontWeight: 700 }}
                >
                    Create Branch
                </Button>
            </Box>

            <Grid container spacing={3}>
                {loading ? (
                    <Box sx={{ width: '100%', display: 'flex', justifyContent: 'center', p: 4 }}>
                        <CircularProgress sx={{ color: '#FFC107' }} />
                    </Box>
                ) : branches.length === 0 ? (
                    <Box sx={{ width: '100%', textAlign: 'center', p: 4 }}>
                        <Typography color="text.secondary">No branches found. Create your first branch.</Typography>
                    </Box>
                ) : branches.map((branch) => (
                    <Grid size={{ xs: 12, md: 6 }} key={branch.id}>
                        <Paper sx={{ p: 2.5, borderRadius: '12px', border: '1px solid #e2e8f0', boxShadow: 'none' }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                                <Box sx={{ display: 'flex', gap: 2 }}>
                                    <Avatar sx={{ bgcolor: '#fff7ed', color: '#FFC107', borderRadius: '8px' }}>
                                        <Building2 size={20} />
                                    </Avatar>
                                    <Box>
                                        <Typography variant="subtitle1" fontWeight={800}>{branch.name}</Typography>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5 }}>
                                            <Typography variant="caption" sx={{ bgcolor: '#f1f5f9', px: 1, py: 0.2, borderRadius: '4px', fontWeight: 600, color: '#64748b' }}>
                                                {branch.code}
                                            </Typography>
                                            {branch.is_primary && (
                                                <Chip label="Primary" size="small" color="primary" sx={{ height: 20, fontSize: '0.65rem' }} />
                                            )}
                                        </Box>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 1 }}>
                                            <MapPin size={14} color="#94a3b8" />
                                            <Typography variant="caption" color="text.secondary">{branch.location || 'No location set'}</Typography>
                                        </Box>
                                    </Box>
                                </Box>
                                <IconButton size="small">
                                    <MoreVertical size={16} />
                                </IconButton>
                            </Box>
                        </Paper>
                    </Grid>
                ))}
            </Grid>
        </Box>
    );

    return (
        <Box sx={{ height: 'calc(100vh - 120px)', display: 'flex', flexDirection: 'column' }}>
            {/* Top Level Tabs */}
            <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
                <Tabs
                    value={mainTab}
                    onChange={(_, v) => {
                        setMainTab(v);
                        setSubTab(v === 0 ? 'company-profile' : 'update-menu-rate');
                    }}
                    sx={{
                        '& .MuiTabs-indicator': { bgcolor: '#FFC107', height: 3 },
                        '& .MuiTab-root': { fontWeight: 700, textTransform: 'uppercase', fontSize: '0.8rem', color: '#64748b', minWidth: 160 },
                        '& .MuiTab-root.Mui-selected': { color: '#2C1810' }
                    }}
                >
                    <Tab label="General Settings" icon={<SettingsIcon size={18} />} iconPosition="start" />
                    <Tab label="Restaurant" icon={<Utensils size={18} />} iconPosition="start" />
                </Tabs>
            </Box>

            <Grid container spacing={3} sx={{ flexGrow: 1, overflow: 'hidden' }}>
                {/* Fixed Sidebar */}
                <Grid size={{ xs: 12, md: 3 }} sx={{ height: '100%', overflowY: 'auto' }}>
                    <Paper sx={{ p: 1, borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: 'none', height: '100%' }}>
                        {mainTab === 0 ? renderGeneralSidebar() : renderRestaurantSidebar()}
                    </Paper>
                </Grid>

                {/* Sub-tab Content Area */}
                <Grid size={{ xs: 12, md: 9 }} sx={{ height: '100%', overflowY: 'auto' }}>
                    <Box sx={{ pb: 4 }}>
                        {mainTab === 0 ? (
                            subTab === 'company-profile' ? renderCompanyProfile() : (
                                <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '400px' }}>
                                    <Typography color="text.secondary">Configuration for <strong>{subTab}</strong> coming soon.</Typography>
                                </Box>
                            )
                        ) : (
                            subTab === 'update-menu-rate' ? renderUpdateMenuRate() :
                                subTab === 'add-branches' ? renderBranchManagement() : (
                                    <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '400px' }}>
                                        <Typography color="text.secondary">Configuration for <strong>{subTab}</strong> coming soon.</Typography>
                                    </Box>
                                )
                        )}
                    </Box>
                </Grid>
            </Grid>
        </Box>
    );
};

export default Settings;

