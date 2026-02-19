import React, { useState, useEffect } from 'react';
import {
    Box,
    Typography,
    Paper,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Button,
    TextField,
    Dialog,
    DialogTitle,
    DialogContent,
    IconButton,
    InputAdornment,
    Chip,
    MenuItem,
    Snackbar,
    Alert
} from '@mui/material';
import { Plus, Search, X, Edit, Trash2, Package, Zap } from 'lucide-react';

import { inventoryAPI } from '../../../services/api';
import { useInventory } from '../../../app/providers/InventoryProvider';
import BeautifulConfirm from '../../../components/common/BeautifulConfirm';

const Products: React.FC = () => {
    const [products, setProducts] = useState<any[]>([]);
    const [units, setUnits] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const { checkLowStock } = useInventory();
    const [openDialog, setOpenDialog] = useState(false);
    const [editingProduct, setEditingProduct] = useState<any>(null);
    const [formData, setFormData] = useState({
        name: '',
        category: '',
        unit_id: '',
        current_stock: 0,
        min_stock: 0,
        product_type: 'Raw'
    });
    const [rawSearch, setRawSearch] = useState('');
    const [processedSearch, setProcessedSearch] = useState('');
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });
    const [confirmDelete, setConfirmDelete] = useState<{ open: boolean, id: number | null }>({ open: false, id: null });

    const showSnackbar = (message: string, severity: 'success' | 'error' = 'success') => {
        setSnackbar({ open: true, message, severity });
    };

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setLoading(true);
            const [productsRes, unitsRes] = await Promise.all([
                inventoryAPI.getProducts(),
                inventoryAPI.getUnits()
            ]);
            setProducts(productsRes.data || []);
            setUnits(unitsRes.data || []);
        } catch (error) {
            console.error('Error loading data:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleOpenDialog = (type: 'Raw' | 'Semi-Finished' | 'Finished', product?: any) => {
        if (product) {
            setEditingProduct(product);
            setFormData({
                name: product.name || '',
                category: product.category || '',
                unit_id: product.unit_id || '',
                current_stock: product.current_stock || 0,
                min_stock: product.min_stock || 0,
                product_type: product.product_type || type
            });
        } else {
            setEditingProduct(null);
            setFormData({ name: '', category: '', unit_id: '', current_stock: 0, min_stock: 0, product_type: type });
        }
        setOpenDialog(true);
    };

    const handleCloseDialog = () => {
        setOpenDialog(false);
        setEditingProduct(null);
    };

    const handleSubmit = async () => {
        try {
            if (editingProduct) {
                await inventoryAPI.updateProduct(editingProduct.id, formData);
            } else {
                await inventoryAPI.createProduct(formData);
            }
            checkLowStock();
            handleCloseDialog();
            loadData();
            showSnackbar(`Product ${editingProduct ? 'updated' : 'created'} successfully`);
        } catch (error: any) {
            showSnackbar(error.response?.data?.detail || 'Error saving product', 'error');
        }
    };

    const handleDelete = async (id: number) => {
        setConfirmDelete({ open: true, id });
    };

    const confirmDeleteAction = async () => {
        if (!confirmDelete.id) return;
        try {
            await inventoryAPI.deleteProduct(confirmDelete.id);
            setConfirmDelete({ open: false, id: null });
            checkLowStock();
            loadData();
            showSnackbar('Product deleted successfully');
        } catch (error: any) {
            showSnackbar(error.response?.data?.detail || 'Error deleting product', 'error');
        }
    };

    const rawMaterials = products.filter(p =>
        p.product_type === 'Raw' &&
        (p.name?.toLowerCase().includes(rawSearch.toLowerCase()) || p.category?.toLowerCase().includes(rawSearch.toLowerCase()))
    );

    const processedGoods = products.filter(p =>
        (p.product_type === 'Semi-Finished' || p.product_type === 'Finished') &&
        (p.name?.toLowerCase().includes(processedSearch.toLowerCase()) || p.category?.toLowerCase().includes(processedSearch.toLowerCase()))
    );

    const renderProductTable = (items: any[]) => (
        <TableContainer component={Paper} sx={{ borderRadius: '16px', flexGrow: 1, boxShadow: 'none', border: '1px solid #e2e8f0' }}>
            <Table stickyHeader size="small">
                <TableHead>
                    <TableRow sx={{ '& th': { bgcolor: '#f8fafc', fontWeight: 700 } }}>
                        <TableCell>Name</TableCell>
                        <TableCell>Stock</TableCell>
                        <TableCell>Status</TableCell>
                        <TableCell align="right">Actions</TableCell>
                    </TableRow>
                </TableHead>
                <TableBody>
                    {loading ? (
                        <TableRow><TableCell colSpan={4} align="center">Loading...</TableCell></TableRow>
                    ) : items.length === 0 ? (
                        <TableRow><TableCell colSpan={4} align="center">No items found</TableCell></TableRow>
                    ) : (
                        items.map((product) => (
                            <TableRow key={product.id} hover>
                                <TableCell>
                                    <Box>
                                        <Typography variant="body2" sx={{ fontWeight: 600 }}>{product.name}</Typography>
                                        <Typography variant="caption" color="text.secondary">{product.category || '-'}</Typography>
                                    </Box>
                                </TableCell>
                                <TableCell>
                                    <Typography variant="body2" sx={{ fontWeight: 700 }}>
                                        {Number(product.current_stock || 0).toFixed(1)} <span style={{ fontSize: '0.75rem' }}>{product.unit?.abbreviation}</span>
                                    </Typography>
                                </TableCell>
                                <TableCell>
                                    <Chip
                                        label={product.status || 'In Stock'}
                                        size="small"
                                        sx={{
                                            fontSize: '0.65rem',
                                            fontWeight: 800,
                                            height: 20,
                                            bgcolor: (product.status === 'Low Stock' ? '#fffbeb' : product.status === 'Out of Stock' ? '#fef2f2' : '#f0fdf4'),
                                            color: (product.status === 'Low Stock' ? '#d97706' : product.status === 'Out of Stock' ? '#dc2626' : '#16a34a')
                                        }}
                                    />
                                    {product.product_type === 'Finished' && (
                                        <Chip label="Finished" size="small" variant="outlined" sx={{ ml: 0.5, height: 20, fontSize: '0.6rem', color: '#0ea5e9', borderColor: '#0ea5e9' }} />
                                    )}
                                </TableCell>
                                <TableCell align="right">
                                    <IconButton size="small" onClick={() => handleOpenDialog(product.product_type, product)}><Edit size={14} /></IconButton>
                                    <IconButton size="small" onClick={() => handleDelete(product.id)} color="error"><Trash2 size={14} /></IconButton>
                                </TableCell>
                            </TableRow>
                        ))
                    )}
                </TableBody>
            </Table>
        </TableContainer>
    );

    return (
        <Box sx={{ height: 'calc(100vh - 120px)', display: 'flex', flexDirection: 'column' }}>
            <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b' }}>Inventory Master</Typography>
                <Typography variant="body2" color="text.secondary">Total Items: {products.length}</Typography>
            </Box>

            <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 3, flexGrow: 1, minHeight: 0 }}>
                {/* LEFT COLUMN: RAW MATERIALS */}
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <Box sx={{ p: 2, bgcolor: '#f1f5f9', borderRadius: '20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                            <Box sx={{ p: 1, bgcolor: '#fff', borderRadius: '12px', boxShadow: '0 2px 4px rgba(0,0,0,0.05)' }}>
                                <Package size={20} color="#64748b" />
                            </Box>
                            <Box>
                                <Typography variant="subtitle1" sx={{ fontWeight: 800 }}>Raw Materials</Typography>
                                <Typography variant="caption" color="text.secondary">{rawMaterials.length} Items</Typography>
                            </Box>
                        </Box>
                        <Button
                            variant="contained"
                            size="small"
                            startIcon={<Plus size={16} />}
                            onClick={() => handleOpenDialog('Raw')}
                            sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, borderRadius: '8px', textTransform: 'none' }}
                        >
                            Add Raw
                        </Button>
                    </Box>
                    <TextField
                        size="small"
                        placeholder="Search Raw Materials..."
                        value={rawSearch}
                        onChange={(e) => setRawSearch(e.target.value)}
                        InputProps={{ startAdornment: <InputAdornment position="start"><Search size={16} /></InputAdornment> }}
                        sx={{ bgcolor: '#fff', borderRadius: '8px' }}
                    />
                    {renderProductTable(rawMaterials)}
                </Box>

                {/* RIGHT COLUMN: PROCESSED GOODS */}
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <Box sx={{ p: 2, bgcolor: '#f0f9ff', borderRadius: '20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                            <Box sx={{ p: 1, bgcolor: '#fff', borderRadius: '12px', boxShadow: '0 2px 4px rgba(0,0,0,0.05)' }}>
                                <Zap size={20} color="#0ea5e9" />
                            </Box>
                            <Box>
                                <Typography variant="subtitle1" sx={{ fontWeight: 800 }}>Processed Goods</Typography>
                                <Typography variant="caption" color="text.secondary">{processedGoods.length} Semi-Finished </Typography>
                            </Box>
                        </Box>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                            <Button
                                variant="contained"
                                size="small"
                                startIcon={<Plus size={16} />}
                                onClick={() => handleOpenDialog('Semi-Finished')}
                                sx={{ bgcolor: '#0ea5e9', '&:hover': { bgcolor: '#0284c7' }, borderRadius: '8px', textTransform: 'none' }}
                            >
                                Add Semi
                            </Button>
                        </Box>
                    </Box>
                    <TextField
                        size="small"
                        placeholder="Search Processed Goods..."
                        value={processedSearch}
                        onChange={(e) => setProcessedSearch(e.target.value)}
                        InputProps={{ startAdornment: <InputAdornment position="start"><Search size={16} /></InputAdornment> }}
                        sx={{ bgcolor: '#fff', borderRadius: '8px' }}
                    />
                    {renderProductTable(processedGoods)}
                </Box>
            </Box>

            {/* FORM DIALOG */}
            <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
                <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography fontWeight={800}>{editingProduct ? 'Edit Product' : `New ${formData.product_type}`}</Typography>
                    <IconButton onClick={handleCloseDialog} size="small"><X size={20} /></IconButton>
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5, pt: 1 }}>
                        <TextField
                            label="Product Name"
                            fullWidth
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            required
                        />
                        <TextField
                            label="Category"
                            fullWidth
                            value={formData.category}
                            onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                        />
                        <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2 }}>
                            <TextField
                                select
                                label="Base Unit"
                                fullWidth
                                value={formData.unit_id}
                                onChange={(e) => setFormData({ ...formData, unit_id: e.target.value })}
                                required
                            >
                                {units.map((unit) => <MenuItem key={unit.id} value={unit.id}>{unit.name} ({unit.abbreviation})</MenuItem>)}
                            </TextField>
                            <TextField
                                select
                                label="Product Type"
                                fullWidth
                                value={formData.product_type}
                                onChange={(e) => setFormData({ ...formData, product_type: e.target.value })}
                                sx={{ '& .MuiInputBase-root': { bgcolor: formData.product_type === 'Raw' ? '#f8fafc' : '#f0f9ff' } }}
                            >
                                <MenuItem value="Raw">Raw Material</MenuItem>
                                <MenuItem value="Semi-Finished">Semi-Finished</MenuItem>
                                <MenuItem value="Finished">Finished Good</MenuItem>
                            </TextField>
                        </Box>
                        <Box sx={{ display: 'grid', gridTemplateColumns: '1fr', gap: 2 }}>
                            <TextField
                                label="Alert Level (Minimum Stock)"
                                type="number"
                                fullWidth
                                value={formData.min_stock}
                                onChange={(e) => setFormData({ ...formData, min_stock: parseFloat(e.target.value) || 0 })}
                                helperText="System will alert you when stock falls below this level"
                            />
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2, mt: 2 }}>
                            <Button onClick={handleCloseDialog}>Cancel</Button>
                            <Button variant="contained" onClick={handleSubmit} sx={{ bgcolor: formData.product_type === 'Raw' ? '#FFC107' : '#0ea5e9' }}>
                                {editingProduct ? 'Update Item' : `Save ${formData.product_type}`}
                            </Button>
                        </Box>
                    </Box>
                </DialogContent>
            </Dialog>

            <Snackbar open={snackbar.open} autoHideDuration={4000} onClose={() => setSnackbar({ ...snackbar, open: false })} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
                <Alert severity={snackbar.severity} sx={{ borderRadius: '12px', fontWeight: 600 }}>{snackbar.message}</Alert>
            </Snackbar>

            <BeautifulConfirm
                open={confirmDelete.open}
                title="Delete Product"
                message="Are you sure you want to delete this product? This action cannot be undone and might affect your transaction history."
                onConfirm={confirmDeleteAction}
                onCancel={() => setConfirmDelete({ open: false, id: null })}
                confirmText="Yes, Delete Product"
                isDestructive
            />
        </Box>
    );
};

export default Products;

