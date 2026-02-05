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
    Chip,
    Avatar,
    CircularProgress,
    IconButton,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
} from '@mui/material';
import {
    Settings as SettingsIcon,
    Utensils,
    Building2,
    User,
    Wallet,
    CreditCard,
    ArrowLeftRight,
    Package,
    Square,
    Truck,
    QrCode,
    GitMerge,
    Monitor,
    Search,
    Save,
    ChevronRight,
    Plus,
    MoreVertical,
    MapPin,
    Printer,
    FileText,
    Download,
    Check
} from 'lucide-react';
import QRManagement from './QRManagement';
import FloorTableSettings from './FloorTableSettings';
import { menuAPI, settingsAPI, branchAPI, authAPI, deliveryAPI, reportsAPI, qrAPI } from '../../services/api';
import { useAuth } from '../../app/providers/AuthProvider';

const Settings: React.FC = () => {
    const navigate = useNavigate();
    const [mainTab, setMainTab] = useState(0); // 0: General, 1: Restaurant
    const [subTab, setSubTab] = useState('company-profile');
    const [loading, setLoading] = useState(false);
    const [companySettings, setCompanySettings] = useState<any>({
        company_name: '',
        email: '',
        phone: '',
        address: '',
        vat_pan_no: '',
        registration_no: '',
        start_date: '',
        invoice_prefix: 'INV',
        tax_rate: 13,
        service_charge_rate: 10,
        discount_rate: 0,
        show_vat_on_invoice: true
    });

    // States for Update Menu Rate
    const [menuItems, setMenuItems] = useState<any[]>([]);
    const [searchQuery, setSearchQuery] = useState('');
    const [updatedPrices, setUpdatedPrices] = useState<{ [key: number]: number }>({});

    // States for Branch Management
    const [branches, setBranches] = useState<any[]>([]);

    // States for Delivery Partners
    const [deliveryPartners, setDeliveryPartners] = useState<any[]>([]);
    const [openDeliveryDialog, setOpenDeliveryDialog] = useState(false);
    const [editingPartner, setEditingPartner] = useState<any>(null);
    const [partnerForm, setPartnerForm] = useState({ name: '', phone: '', vehicle_number: '', status: 'Active' });

    // States for User Profile
    const { user, updateUser } = useAuth();
    const [profileForm, setProfileForm] = useState({ full_name: '', email: '', username: '', password: '' });
    const [qrSrc, setQrSrc] = useState<string>('');
    const [uploading, setUploading] = useState(false);

    useEffect(() => {
        if (mainTab === 0 && subTab === 'company-profile') {
            loadCompanySettings();
        } else if (mainTab === 0 && subTab === 'profile') {
            if (user) setProfileForm({ full_name: user.full_name || '', email: user.email || '', username: user.username || '', password: '' });
        } else if (mainTab === 1 && subTab === 'update-menu-rate') {
            loadMenuItems();
        } else if (mainTab === 1 && subTab === 'add-branches') {
            loadBranches();
        } else if (mainTab === 1 && subTab === 'manage-delivery') {
            loadDeliveryPartners();
        }
    }, [mainTab, subTab, user]);

    const loadDeliveryPartners = async () => {
        try {
            setLoading(true);
            const res = await deliveryAPI.getAll();
            setDeliveryPartners(res.data || []);
        } catch (error) {
            console.error('Error loading delivery partners:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleReportExport = async (type: string, format: 'pdf' | 'excel' = 'pdf') => {
        try {
            setLoading(true);
            const res = format === 'pdf'
                ? await reportsAPI.exportPDF(type, {})
                : await reportsAPI.exportExcel(type, {});

            const blob = new Blob([res.data], {
                type: format === 'pdf' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            });
            const url = window.URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `${type}_report_${new Date().toISOString().split('T')[0]}.${format === 'pdf' ? 'pdf' : 'xlsx'}`);
            document.body.appendChild(link);
            link.click();
            link.remove();
            window.URL.revokeObjectURL(url);
        } catch (error) {
            console.error('Export failed:', error);
            alert('Failed to export report');
        } finally {
            setLoading(false);
        }
    };

    const handleExportAll = async () => {
        try {
            setLoading(true);
            const res = await reportsAPI.exportAllExcel();
            const blob = new Blob([res.data], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
            const url = window.URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            const prefix = user?.organization_id || 'Business';
            link.setAttribute('download', `${prefix}_Master_Report_${new Date().toISOString().split('T')[0]}.xlsx`);
            document.body.appendChild(link);
            link.click();
            link.remove();
            window.URL.revokeObjectURL(url);
        } catch (error) {
            console.error('Master export failed:', error);
            alert('Failed to export master report');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (subTab === 'digital-menu') {
            let objectUrl = '';
            qrAPI.getMenuQR().then(res => {
                const blob = new Blob([res.data], { type: 'image/png' });
                objectUrl = URL.createObjectURL(blob);
                setQrSrc(objectUrl);
            }).catch(err => {
                console.error('Error fetching QR:', err);
            });
            return () => {
                if (objectUrl) URL.revokeObjectURL(objectUrl);
                setQrSrc('');
            };
        }
    }, [subTab]);

    const loadCompanySettings = async () => {
        try {
            setLoading(true);
            const res = await settingsAPI.getCompanySettings();
            if (res.data) {
                setCompanySettings(res.data);
            }
        } catch (error) {
            console.error('Error loading company settings:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleSettingsChange = (field: string, value: any) => {
        setCompanySettings((prev: any) => ({ ...prev, [field]: value }));
    };

    const handleSaveSettings = async () => {
        try {
            setLoading(true);
            await settingsAPI.updateCompanySettings(companySettings);
            alert('Company settings updated successfully!');
        } catch (error) {
            console.error('Error updating company settings:', error);
            alert('Failed to update company settings');
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
                { id: 'import-export', text: 'Import/Export', icon: <ArrowLeftRight size={20} /> },
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
                { id: 'add-qr-payment', text: 'Add QR Payment', icon: <QrCode size={20} /> },
                { id: 'printer-setup', text: 'Printer Setup', icon: <Printer size={20} /> },
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
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h6" fontWeight={800}>Company Profile</Typography>
                <Button
                    variant="contained"
                    startIcon={<Save size={18} />}
                    onClick={handleSaveSettings}
                    sx={{ bgcolor: '#4f46e5', '&:hover': { bgcolor: '#4338ca' }, textTransform: 'none', borderRadius: '8px', fontWeight: 700 }}
                >
                    Update Settings
                </Button>
            </Box>

            <Box sx={{ mb: 4 }}>
                <Typography variant="subtitle2" fontWeight={700} color="text.secondary" sx={{ mb: 2, textTransform: 'uppercase' }}>General Settings</Typography>
                <Paper sx={{ p: 3, borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: 'none' }}>
                    <Grid container spacing={3}>
                        <Grid size={{ xs: 12, md: 6 }}>
                            <TextField
                                fullWidth
                                label="Company Name"
                                value={companySettings.company_name}
                                onChange={(e) => handleSettingsChange('company_name', e.target.value)}
                                sx={{ mb: 2 }}
                            />
                            <TextField
                                fullWidth
                                label="Email Address"
                                value={companySettings.email}
                                onChange={(e) => handleSettingsChange('email', e.target.value)}
                                sx={{ mb: 2 }}
                            />
                            <TextField
                                fullWidth
                                label="Address"
                                value={companySettings.address}
                                onChange={(e) => handleSettingsChange('address', e.target.value)}
                            />
                        </Grid>
                        <Grid size={{ xs: 12, md: 6 }}>
                            <TextField
                                fullWidth
                                label="Contact No."
                                value={companySettings.phone}
                                onChange={(e) => handleSettingsChange('phone', e.target.value)}
                                sx={{ mb: 2 }}
                            />
                            <TextField
                                fullWidth
                                label="VAT/PAN No."
                                value={companySettings.vat_pan_no}
                                onChange={(e) => handleSettingsChange('vat_pan_no', e.target.value)}
                                sx={{ mb: 2 }}
                            />
                            <TextField
                                fullWidth
                                label="Registration No."
                                value={companySettings.registration_no}
                                onChange={(e) => handleSettingsChange('registration_no', e.target.value)}
                            />
                        </Grid>
                    </Grid>
                </Paper>
            </Box>

            <Box sx={{ mb: 4 }}>
                <Typography variant="subtitle2" fontWeight={700} color="text.secondary" sx={{ mb: 2, textTransform: 'uppercase' }}>Business Rates & Charges</Typography>
                <Paper sx={{ p: 3, borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: 'none' }}>
                    <Grid container spacing={3}>
                        <Grid size={{ xs: 12, md: 4 }}>
                            <TextField
                                fullWidth
                                type="number"
                                label="Tax Rate (%)"
                                value={companySettings.tax_rate}
                                onChange={(e) => handleSettingsChange('tax_rate', parseFloat(e.target.value))}
                                InputProps={{ endAdornment: <InputAdornment position="end">%</InputAdornment> }}
                            />
                        </Grid>
                        <Grid size={{ xs: 12, md: 4 }}>
                            <TextField
                                fullWidth
                                type="number"
                                label="Service Charge (%)"
                                value={companySettings.service_charge_rate}
                                onChange={(e) => handleSettingsChange('service_charge_rate', parseFloat(e.target.value))}
                                InputProps={{ endAdornment: <InputAdornment position="end">%</InputAdornment> }}
                            />
                        </Grid>
                        <Grid size={{ xs: 12, md: 4 }}>
                            <TextField
                                fullWidth
                                type="number"
                                label="Default Discount (%)"
                                value={companySettings.discount_rate}
                                onChange={(e) => handleSettingsChange('discount_rate', parseFloat(e.target.value))}
                                InputProps={{ endAdornment: <InputAdornment position="end">%</InputAdornment> }}
                            />
                        </Grid>
                    </Grid>
                </Paper>
            </Box>

            <Box sx={{ mb: 4 }}>
                <Typography variant="subtitle2" fontWeight={700} color="text.secondary" sx={{ mb: 2, textTransform: 'uppercase' }}>Invoice Settings</Typography>
                <Paper sx={{ p: 3, borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: 'none' }}>
                    <Grid container spacing={3}>
                        <Grid size={{ xs: 12, md: 6 }}>
                            <TextField
                                fullWidth
                                label="Invoice Prefix"
                                value={companySettings.invoice_prefix}
                                onChange={(e) => handleSettingsChange('invoice_prefix', e.target.value)}
                            />
                        </Grid>
                        <Grid size={{ xs: 12, md: 6 }}>
                            <TextField
                                fullWidth
                                label="Invoice Footer Text"
                                value={companySettings.invoice_footer_text}
                                onChange={(e) => handleSettingsChange('invoice_footer_text', e.target.value)}
                            />
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

    const renderUserProfile = () => (
        <Box>
            <Typography variant="h6" fontWeight={800} sx={{ mb: 3 }}>My Profile</Typography>
            <Paper sx={{ p: 4, borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: 'none' }}>
                <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', mb: 4 }}>
                    <Box sx={{ position: 'relative' }}>
                        <Avatar
                            src={user?.profile_image_url ? `${import.meta.env.VITE_API_URL || 'http://localhost:8000'}${user.profile_image_url}` : undefined}
                            sx={{ width: 120, height: 120, mb: 2, border: '4px solid #f8fafc', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
                        >
                            {user?.full_name?.charAt(0) || 'U'}
                        </Avatar>
                        <IconButton
                            component="label"
                            sx={{
                                position: 'absolute', bottom: 15, right: 0, bgcolor: '#FFC107',
                                '&:hover': { bgcolor: '#FF7700' }, color: 'white', border: '2px solid white'
                            }}
                        >
                            <input
                                type="file" hidden accept="image/*"
                                onChange={async (e) => {
                                    if (e.target.files?.[0]) {
                                        const formData = new FormData();
                                        formData.append('file', e.target.files[0]);
                                        try {
                                            setUploading(true);
                                            await authAPI.updatePhoto(formData);
                                            // Refresh user context
                                            const updatedUser = await authAPI.getCurrentUser();
                                            updateUser(updatedUser.data);
                                            alert('Profile picture updated!');
                                        } catch (err) {
                                            alert('Failed to upload photo');
                                        } finally {
                                            setUploading(false);
                                        }
                                    }
                                }}
                            />
                            <Plus size={16} />
                        </IconButton>
                    </Box>
                    <Typography variant="h6" fontWeight={700}>{user?.full_name}</Typography>
                    <Typography variant="body2" color="text.secondary">{user?.role?.toUpperCase()}</Typography>
                </Box>

                <Grid container spacing={3}>
                    <Grid size={{ xs: 12, md: 6 }}>
                        <TextField
                            fullWidth label="Full Name" value={profileForm.full_name}
                            onChange={(e) => setProfileForm({ ...profileForm, full_name: e.target.value })}
                        />
                    </Grid>
                    <Grid size={{ xs: 12, md: 6 }}>
                        <TextField
                            fullWidth label="Email" value={profileForm.email}
                            onChange={(e) => setProfileForm({ ...profileForm, email: e.target.value })}
                        />
                    </Grid>
                    <Grid size={{ xs: 12, md: 6 }}>
                        <TextField
                            fullWidth label="Username" value={profileForm.username}
                            onChange={(e) => setProfileForm({ ...profileForm, username: e.target.value })}
                        />
                    </Grid>
                    <Grid size={{ xs: 12, md: 6 }}>
                        <TextField
                            fullWidth label="New Password (Optional)" type="password" value={profileForm.password}
                            onChange={(e) => setProfileForm({ ...profileForm, password: e.target.value })}
                        />
                    </Grid>
                </Grid>
                <Button
                    variant="contained" sx={{ mt: 4, bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, fontWeight: 700 }}
                    onClick={async () => {
                        try {
                            setLoading(true);
                            await authAPI.updateMe(profileForm);
                            const updatedUser = await authAPI.getCurrentUser();
                            updateUser(updatedUser.data);
                            alert('Profile updated successfully!');
                        } catch (err) {
                            alert('Failed to update profile');
                        } finally {
                            setLoading(false);
                        }
                    }}
                >
                    Save Changes
                </Button>
            </Paper>
        </Box>
    );

    const renderImportExport = () => (
        <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h6" fontWeight={800}>Import & Export Data</Typography>
                <Button
                    variant="contained"
                    startIcon={<FileText size={18} />}
                    onClick={handleExportAll}
                    disabled={loading}
                    sx={{ bgcolor: '#10b981', '&:hover': { bgcolor: '#059669' }, fontWeight: 700 }}
                >
                    {loading ? <CircularProgress size={20} color="inherit" /> : 'Export Master Report (Excel)'}
                </Button>
            </Box>
            <Grid container spacing={3}>
                {[
                    { title: 'Sales Reports', desc: 'Download all sales data and summaries', type: 'sales' },
                    { title: 'Inventory Data', desc: 'Current stock levels and consumption', type: 'inventory' },
                    { title: 'Customer Analytics', desc: 'Visit frequency and total spending', type: 'customers' },
                    { title: 'Staff Performance', desc: 'Shift logs and order statistics', type: 'staff' },
                    { title: 'Session Reports', desc: 'Detailed session and shift data', type: 'session' },
                    { title: 'Day Book', desc: 'Full transaction ledger for today', type: 'day-book' }
                ].map((item, idx) => (
                    <Grid size={{ xs: 12, md: 4 }} key={idx}>
                        <Paper sx={{ p: 3, borderRadius: '16px', border: '1px solid #e2e8f0', textAlign: 'center' }}>
                            <FileText size={40} color="#FFC107" style={{ marginBottom: 16 }} />
                            <Typography variant="subtitle1" fontWeight={700}>{item.title}</Typography>
                            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 2 }}>{item.desc}</Typography>
                            <Box sx={{ display: 'flex', justifyContent: 'center', gap: 1 }}>
                                <Button
                                    variant="outlined" startIcon={<Download size={16} />} size="small"
                                    onClick={() => handleReportExport(item.type, 'pdf')}
                                    disabled={loading}
                                >
                                    PDF
                                </Button>
                                <Button
                                    variant="outlined" startIcon={<Download size={16} />} size="small"
                                    onClick={() => handleReportExport(item.type, 'excel')}
                                    disabled={loading}
                                    sx={{ color: '#10b981', borderColor: '#10b981', '&:hover': { borderColor: '#059669', bgcolor: '#f0fdf4' } }}
                                >
                                    Excel
                                </Button>
                            </Box>
                        </Paper>
                    </Grid>
                ))}
            </Grid>
        </Box>
    );

    const renderPlansSubscription = () => (
        <Box>
            <Typography variant="h6" fontWeight={800} sx={{ mb: 3 }}>Plans & Subscription</Typography>
            <Grid container spacing={3}>
                {[
                    { name: 'Free', price: 'Rs. 0', features: ['1 Branch', '5 Users', 'Basic POS', 'Email Support'], current: true },
                    { name: 'Standard', price: 'Rs. 5,000/mo', features: ['3 Branches', '15 Users', 'Advanced Inventory', 'Priority Support'] },
                    { name: 'Premium', price: 'Rs. 12,000/mo', features: ['Unlimited Branches', 'Unlimited Users', 'Multi-tenant Support', '24/7 Support'] }
                ].map((plan, idx) => (
                    <Grid size={{ xs: 12, md: 4 }} key={idx}>
                        <Paper sx={{ p: 4, borderRadius: '20px', border: '1px solid', borderColor: plan.current ? '#FFC107' : '#e2e8f0', position: 'relative', overflow: 'hidden' }}>
                            {plan.current && <Box sx={{ position: 'absolute', top: 12, right: 12, bgcolor: '#FFC107', color: 'white', px: 1, py: 0.5, borderRadius: '4px', fontSize: '10px', fontWeight: 800 }}>CURRENT PLAN</Box>}
                            <Typography variant="h5" fontWeight={800} sx={{ mb: 1 }}>{plan.name}</Typography>
                            <Typography variant="h4" fontWeight={900} color="#FFC107" sx={{ mb: 3 }}>{plan.price}</Typography>
                            <List>
                                {plan.features.map((f, i) => (
                                    <ListItem key={i} disablePadding sx={{ mb: 1 }}>
                                        <ListItemIcon sx={{ minWidth: 30, color: '#10b981' }}><Check size={16} /></ListItemIcon>
                                        <ListItemText primary={f} primaryTypographyProps={{ fontSize: '13px', fontWeight: 600 }} />
                                    </ListItem>
                                ))}
                            </List>
                            <Button fullWidth variant={plan.current ? 'contained' : 'outlined'} sx={{ mt: 3, borderRadius: '10px', fontWeight: 800, bgcolor: plan.current ? '#FFC107' : 'transparent', '&:hover': { bgcolor: plan.current ? '#FF7700' : 'rgba(255, 140, 0, 0.05)' } }}>
                                {plan.current ? 'Already Gained' : 'Upgrade Now'}
                            </Button>
                        </Paper>
                    </Grid>
                ))}
            </Grid>
        </Box>
    );

    const renderDeliveryPartners = () => (
        <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h6" fontWeight={800}>Manage Delivery Partners</Typography>
                <Button
                    variant="contained" startIcon={<Plus size={18} />}
                    onClick={() => { setEditingPartner(null); setPartnerForm({ name: '', phone: '', vehicle_number: '', status: 'Active' }); setOpenDeliveryDialog(true); }}
                    sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, fontWeight: 700 }}
                >
                    Add Partner
                </Button>
            </Box>

            <Grid container spacing={2}>
                {deliveryPartners.map((p) => (
                    <Grid size={{ xs: 12, md: 4 }} key={p.id}>
                        <Paper sx={{ p: 2, borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                <Typography fontWeight={700}>{p.name}</Typography>
                                <Chip label={p.status} size="small" color={p.status === 'Active' ? 'success' : 'default'} sx={{ height: 20, fontSize: '10px' }} />
                            </Box>
                            <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>Phone: {p.phone || '-'}</Typography>
                            <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>Vehicle: {p.vehicle_number || '-'}</Typography>
                            <Box sx={{ mt: 2, display: 'flex', gap: 1 }}>
                                <Button size="small" onClick={() => { setEditingPartner(p); setPartnerForm({ name: p.name, phone: p.phone, vehicle_number: p.vehicle_number, status: p.status }); setOpenDeliveryDialog(true); }}>Edit</Button>
                                <Button size="small" color="error" onClick={async () => { if (confirm('Remove partner?')) { await deliveryAPI.delete(p.id); loadDeliveryPartners(); } }}>Delete</Button>
                            </Box>
                        </Paper>
                    </Grid>
                ))}
            </Grid>

            <Dialog open={openDeliveryDialog} onClose={() => setOpenDeliveryDialog(false)}>
                <Box sx={{ p: 4, width: 400 }}>
                    <Typography variant="h6" fontWeight={800} mb={3}>{editingPartner ? 'Edit Partner' : 'Add Partner'}</Typography>
                    <TextField fullWidth label="Partner Name" sx={{ mb: 2 }} value={partnerForm.name} onChange={(e) => setPartnerForm({ ...partnerForm, name: e.target.value })} />
                    <TextField fullWidth label="Phone" sx={{ mb: 2 }} value={partnerForm.phone} onChange={(e) => setPartnerForm({ ...partnerForm, phone: e.target.value })} />
                    <TextField fullWidth label="Vehicle Number" sx={{ mb: 2 }} value={partnerForm.vehicle_number} onChange={(e) => setPartnerForm({ ...partnerForm, vehicle_number: e.target.value })} />
                    <Button
                        fullWidth variant="contained" sx={{ mt: 2, bgcolor: '#FFC107' }}
                        onClick={async () => {
                            if (editingPartner) await deliveryAPI.update(editingPartner.id, partnerForm);
                            else await deliveryAPI.create(partnerForm);
                            setOpenDeliveryDialog(false);
                            loadDeliveryPartners();
                        }}
                    >
                        Save Partner
                    </Button>
                </Box>
            </Dialog>
        </Box>
    );

    const renderDigitalMenu = () => (
        <Box>
            <Typography variant="h6" fontWeight={800} sx={{ mb: 3 }}>Digital Menu QR</Typography>
            <Paper sx={{ p: 4, borderRadius: '20px', border: '1px solid #e2e8f0', textAlign: 'center', maxWidth: 400, mx: 'auto' }}>
                <Box
                    sx={{
                        width: '100%', height: 300, bgcolor: '#f1f5f9', mb: 3, borderRadius: '12px',
                        display: 'flex', alignItems: 'center', justifyContent: 'center'
                    }}
                >
                    {qrSrc ? (
                        <img
                            src={qrSrc}
                            alt="Digital Menu QR"
                            style={{ width: 250, height: 250 }}
                        />
                    ) : (
                        <Box sx={{ width: 250, height: 250, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <CircularProgress />
                        </Box>
                    )}
                    {!qrSrc && <QrCode size={100} color="#cbd5e1" id="placeholder-qr" style={{ position: 'absolute' }} />}
                </Box>
                <Typography variant="subtitle1" fontWeight={700}>Professional Digital Menu</Typography>
                <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 3 }}>
                    This QR links directly to your real-time menu. Customers can scan it to browse items, categories, and prices.
                </Typography>
                <Button
                    fullWidth variant="contained" startIcon={<Download size={18} />} sx={{ bgcolor: '#2C1810', '&:hover': { bgcolor: '#000' } }}
                    onClick={async () => {
                        try {
                            const res = await qrAPI.getMenuQR();
                            const blob = new Blob([res.data], { type: 'image/png' });
                            const url = window.URL.createObjectURL(blob);
                            const link = document.createElement('a');
                            link.href = url;
                            link.setAttribute('download', 'digital-menu-qr.png');
                            document.body.appendChild(link);
                            link.click();
                            link.remove();
                        } catch (err) {
                            console.error('Download error:', err);
                        }
                    }}
                >
                    Download QR Code
                </Button>
            </Paper>
        </Box>
    );

    const renderPrinterSetup = () => (
        <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h6" fontWeight={800}>Printer Setup</Typography>
                <Button
                    variant="contained"
                    startIcon={<Plus size={18} />}
                    sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, color: '#000', textTransform: 'none', borderRadius: '8px', fontWeight: 700 }}
                >
                    Add Printer
                </Button>
            </Box>

            <Paper sx={{ p: 4, textAlign: 'center', borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: 'none' }}>
                <Printer size={64} color="#94a3b8" />
                <Typography variant="h6" sx={{ mt: 2 }} fontWeight={700}>No Printers Configured</Typography>
                <Typography color="text.secondary" sx={{ mb: 3 }}>
                    Configure your kitchen, bar, and billing printers here.
                </Typography>
                <Button
                    variant="outlined"
                    startIcon={<Plus size={18} />}
                    sx={{ borderRadius: '8px', textTransform: 'none', fontWeight: 600 }}
                >
                    Connect New Printer
                </Button>
            </Paper>
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
                            subTab === 'company-profile' ? renderCompanyProfile() :
                                subTab === 'profile' ? renderUserProfile() :
                                    subTab === 'import-export' ? renderImportExport() :
                                        subTab === 'plans-subscription' ? renderPlansSubscription() : (
                                            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '400px' }}>
                                                <Typography color="text.secondary">Configuration for <strong>{subTab}</strong> coming soon.</Typography>
                                            </Box>
                                        )
                        ) : (
                            subTab === 'update-menu-rate' ? renderUpdateMenuRate() :
                                subTab === 'manage-tables' ? <FloorTableSettings /> :
                                    subTab === 'manage-delivery' ? renderDeliveryPartners() :
                                        subTab === 'add-qr-payment' ? <QRManagement /> :
                                            subTab === 'printer-setup' ? renderPrinterSetup() :
                                                subTab === 'add-branches' ? renderBranchManagement() :
                                                    subTab === 'digital-menu' ? renderDigitalMenu() : (
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
