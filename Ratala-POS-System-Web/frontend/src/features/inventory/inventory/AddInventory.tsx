import React, { useState, useEffect } from 'react';
import {
    Box,
    Typography,
    Paper,
    Tabs,
    Tab,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Button,
    TextField,
    MenuItem,
    Chip,
    CircularProgress,
    IconButton,
    InputAdornment,
    Snackbar,
    Alert
} from '@mui/material';
import {
    RefreshCw,
    History,
    Package,
    Search,
    ArrowUpCircle,
    ArrowDownCircle,
    X
} from 'lucide-react';
import { inventoryAPI } from '../../../services/api';
import { useInventory } from '../../../app/providers/InventoryProvider';

interface TabPanelProps {
    children?: React.ReactNode;
    index: number;
    value: number;
}

function TabPanel(props: TabPanelProps) {
    const { children, value, index, ...other } = props;
    return (
        <div role="tabpanel" hidden={value !== index} {...other}>
            {value === index && <Box sx={{ pt: 3 }}>{children}</Box>}
        </div>
    );
}

const AddInventory: React.FC = () => {
    const [tabValue, setTabValue] = useState(0);
    const [products, setProducts] = useState<any[]>([]);
    const [transactions, setTransactions] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [submitting, setSubmitting] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');

    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });
    const { checkLowStock } = useInventory();

    // Forms State
    // Forms State
    const [adjustForm, setAdjustForm] = useState({ product_id: '', quantity: 0, notes: '' });
    const [adjustType, setAdjustType] = useState('+');

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setLoading(true);
            const [productsRes, transactionsRes] = await Promise.all([
                inventoryAPI.getProducts(),
                inventoryAPI.getTransactions()
            ]);
            setProducts(productsRes.data || []);
            setTransactions(transactionsRes.data || []);
        } catch (error) {
            console.error('Error loading inventory data:', error);
        } finally {
            setLoading(false);
        }
    };



    const handleAdjustSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!adjustForm.product_id || adjustForm.quantity === 0 || !adjustForm.notes) {
            setSnackbar({ open: true, message: 'Reason and quantity are required', severity: 'error' });
            return;
        }
        try {
            setSubmitting(true);
            const finalQuantity = adjustType === '+' ? Math.abs(adjustForm.quantity) : -Math.abs(adjustForm.quantity);
            await inventoryAPI.createAdjustment({ ...adjustForm, quantity: finalQuantity });
            setSnackbar({ open: true, message: 'Adjustment recorded successfully', severity: 'success' });
            checkLowStock();
            setAdjustForm({ product_id: '', quantity: 0, notes: '' });
            setAdjustType('+');
            loadData();
        } catch (error) {
            setSnackbar({ open: true, message: 'Failed to adjust stock', severity: 'error' });
        } finally {
            setSubmitting(false);
        }
    };

    const filteredProducts = products.filter(p =>
        p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.category?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const recentTransactions = transactions.slice(0, 10);

    return (
        <Box sx={{ p: 1 }}>
            {/* Header */}
            <Box sx={{ mb: 3 }}>
                <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b' }}>Stock Management</Typography>
            </Box>

            <Paper sx={{ borderRadius: '24px', overflow: 'hidden', boxShadow: '0 4px 20px rgba(0,0,0,0.05)', border: '1px solid #f1f5f9' }}>
                <Tabs
                    value={tabValue}
                    onChange={(_, val) => setTabValue(val)}
                    sx={{
                        px: 2,
                        pt: 2,
                        bgcolor: '#f8fafc',
                        borderBottom: '1px solid #f1f5f9',
                        '& .MuiTab-root': { textTransform: 'none', fontWeight: 700, fontSize: '0.95rem', minWidth: 140 },
                        '& .Mui-selected': { color: '#FFC107 !important' },
                        '& .MuiTabs-indicator': { bgcolor: '#FFC107', height: 3, borderRadius: '3px 3px 0 0' }
                    }}
                >
                    <Tab icon={<RefreshCw size={18} />} iconPosition="start" label="Adjust Stock" />
                    <Tab icon={<Package size={18} />} iconPosition="start" label="Show Stock" />
                    <Tab icon={<History size={18} />} iconPosition="start" label="Recent Transactions" />
                </Tabs>

                <Box sx={{ p: 3 }}>
                    {/* Adjust Stock Tab */}
                    <TabPanel value={tabValue} index={0}>
                        <Box sx={{ maxWidth: 800, mx: 'auto' }}>
                            <form onSubmit={handleAdjustSubmit}>
                                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 3 }}>
                                    <TextField
                                        select
                                        label="Select Product"
                                        fullWidth
                                        value={adjustForm.product_id}
                                        onChange={(e) => setAdjustForm({ ...adjustForm, product_id: e.target.value })}
                                        required
                                    >
                                        {products.map((p) => (
                                            <MenuItem key={p.id} value={p.id}>{p.name} ({Number(p.current_stock).toFixed(2)} {p.unit?.abbreviation} current)</MenuItem>
                                        ))}
                                    </TextField>
                                    <Box sx={{ display: 'flex', gap: 2 }}>
                                        <TextField
                                            select
                                            label="Operation"
                                            value={adjustType}
                                            onChange={(e) => setAdjustType(e.target.value)}
                                            sx={{ width: 140 }}
                                        >
                                            <MenuItem value="+">Add (+)</MenuItem>
                                            <MenuItem value="-">Deduct (-)</MenuItem>
                                        </TextField>
                                        <TextField
                                            label="Quantity"
                                            type="number"
                                            fullWidth
                                            value={adjustForm.quantity || ''}
                                            onChange={(e) => setAdjustForm({ ...adjustForm, quantity: Math.abs(parseFloat(e.target.value)) || 0 })}
                                            required
                                            InputProps={{ inputProps: { min: 0 } }}
                                        />
                                    </Box>
                                    <Box sx={{ gridColumn: { md: 'span 2' } }}>
                                        <TextField
                                            label="Reason for Adjustment"
                                            fullWidth
                                            multiline
                                            rows={3}
                                            required
                                            value={adjustForm.notes}
                                            onChange={(e) => setAdjustForm({ ...adjustForm, notes: e.target.value })}
                                            placeholder="e.g. Spillage, Found extra unit, Damaged in transport"
                                        />
                                    </Box>
                                    <Box sx={{ gridColumn: { md: 'span 2' }, textAlign: 'right' }}>
                                        <Button
                                            variant="contained"
                                            type="submit"
                                            disabled={submitting}
                                            sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, minWidth: 200, py: 1.5, borderRadius: '12px', fontWeight: 700 }}
                                        >
                                            {submitting ? <CircularProgress size={20} color="inherit" /> : 'Confirm Adjustment'}
                                        </Button>
                                    </Box>
                                </Box>
                            </form>
                        </Box>
                    </TabPanel>

                    {/* Show Stock Tab (View Only Mode) */}
                    <TabPanel value={tabValue} index={1}>
                        <Box sx={{ mb: 3, display: 'flex', gap: 2 }}>
                            <TextField
                                fullWidth
                                placeholder="Search products..."
                                size="small"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                                InputProps={{
                                    startAdornment: <InputAdornment position="start"><Search size={18} color="#94a3b8" /></InputAdornment>,
                                    endAdornment: searchTerm && (
                                        <IconButton size="small" onClick={() => setSearchTerm('')}><X size={16} /></IconButton>
                                    )
                                }}
                                sx={{ maxWidth: 500 }}
                            />
                        </Box>
                        <TableContainer sx={{ borderRadius: '16px', border: '1px solid #f1f5f9' }}>
                            <Table>
                                <TableHead sx={{ bgcolor: '#f8fafc' }}>
                                    <TableRow>
                                        <TableCell sx={{ fontWeight: 700 }}>PRODUCT NAME</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>CATEGORY</TableCell>
                                        <TableCell align="right" sx={{ fontWeight: 700 }}>AVAILABLE STOCK</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>STATUS</TableCell>
                                    </TableRow>
                                </TableHead>
                                <TableBody>
                                    {loading ? (
                                        <TableRow><TableCell colSpan={4} align="center" sx={{ py: 6 }}><CircularProgress size={24} sx={{ color: '#FFC107' }} /></TableCell></TableRow>
                                    ) : filteredProducts.length === 0 ? (
                                        <TableRow><TableCell colSpan={4} align="center" sx={{ py: 6 }}>No products found.</TableCell></TableRow>
                                    ) : (
                                        filteredProducts.map((p) => (
                                            <TableRow key={p.id} hover>
                                                <TableCell sx={{ fontWeight: 600 }}>{p.name}</TableCell>
                                                <TableCell><Chip label={p.category || 'General'} size="small" sx={{ fontSize: '0.75rem', bgcolor: '#f1f5f9' }} /></TableCell>
                                                <TableCell align="right" sx={{ fontWeight: 800, color: p.current_stock <= (p.min_stock || 0) ? '#ef4444' : '#1e293b' }}>
                                                    {Number(p.current_stock).toFixed(2)} {p.unit?.abbreviation}
                                                </TableCell>
                                                <TableCell>
                                                    <Chip
                                                        label={p.status}
                                                        size="small"
                                                        sx={{
                                                            fontWeight: 700,
                                                            bgcolor: p.status === 'In Stock' ? '#dcfce7' : p.status === 'Low Stock' ? '#fffbeb' : '#fef2f2',
                                                            color: p.status === 'In Stock' ? '#16a34a' : p.status === 'Low Stock' ? '#d97706' : '#ef4444'
                                                        }}
                                                    />
                                                </TableCell>
                                            </TableRow>
                                        ))
                                    )}
                                </TableBody>
                            </Table>
                        </TableContainer>
                    </TabPanel>

                    {/* Recent Transactions Tab */}
                    <TabPanel value={tabValue} index={2}>

                        <TableContainer sx={{ borderRadius: '16px', border: '1px solid #f1f5f9' }}>
                            <Table>
                                <TableHead sx={{ bgcolor: '#f8fafc' }}>
                                    <TableRow>
                                        <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem', color: '#64748b' }}>DATE & TIME</TableCell>
                                        <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem', color: '#64748b' }}>PRODUCT</TableCell>
                                        <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem', color: '#64748b' }}>TYPE</TableCell>
                                        <TableCell align="right" sx={{ fontWeight: 700, fontSize: '0.75rem', color: '#64748b' }}>QUANTITY</TableCell>
                                        <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem', color: '#64748b' }}>NOTES</TableCell>
                                    </TableRow>
                                </TableHead>
                                <TableBody>
                                    {loading ? (
                                        <TableRow><TableCell colSpan={5} align="center" sx={{ py: 6 }}><CircularProgress size={20} /></TableCell></TableRow>
                                    ) : recentTransactions.length === 0 ? (
                                        <TableRow><TableCell colSpan={5} align="center" sx={{ py: 6 }}>No recent activity.</TableCell></TableRow>
                                    ) : (
                                        recentTransactions.map((txn) => (
                                            <TableRow key={txn.id} hover>
                                                <TableCell sx={{ color: '#94a3b8', fontSize: '0.85rem' }}>{new Date(txn.created_at).toLocaleString()}</TableCell>
                                                <TableCell sx={{ fontWeight: 700 }}>{txn.product?.name}</TableCell>
                                                <TableCell>
                                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                                        {['IN', 'Add', 'Production_IN'].includes(txn.transaction_type) ? (
                                                            <ArrowUpCircle size={14} color="#16a34a" />
                                                        ) : (
                                                            <ArrowDownCircle size={14} color="#ef4444" />
                                                        )}
                                                        <Typography variant="caption" sx={{ fontWeight: 800, color: ['IN', 'Add', 'Production_IN'].includes(txn.transaction_type) ? '#16a34a' : '#ef4444' }}>
                                                            {txn.transaction_type}
                                                        </Typography>
                                                    </Box>
                                                </TableCell>
                                                <TableCell align="right" sx={{ fontWeight: 800, color: ['IN', 'Add', 'Production_IN'].includes(txn.transaction_type) ? '#16a34a' : '#ef4444' }}>
                                                    {['IN', 'Add', 'Production_IN'].includes(txn.transaction_type) ? '+' : ''}{Number(txn.quantity).toFixed(2)}
                                                </TableCell>
                                                <TableCell sx={{ color: '#64748b', fontSize: '0.85rem' }}>{txn.notes || '-'}</TableCell>
                                            </TableRow>
                                        ))
                                    )}
                                </TableBody>
                            </Table>
                        </TableContainer>
                    </TabPanel>
                </Box>
            </Paper>

            <Snackbar
                open={snackbar.open}
                autoHideDuration={4000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            >
                <Alert severity={snackbar.severity} sx={{ borderRadius: '12px', fontWeight: 600 }}>{snackbar.message}</Alert>
            </Snackbar>
        </Box>
    );
};

export default AddInventory;

