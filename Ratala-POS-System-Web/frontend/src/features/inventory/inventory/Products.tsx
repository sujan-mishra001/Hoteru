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
import { Plus, Search, X, Edit, Trash2 } from 'lucide-react';

import { inventoryAPI } from '../../../services/api';
import { useInventory } from '../../../app/providers/InventoryProvider';

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
        min_stock: 0
    });
    const [searchTerm, setSearchTerm] = useState('');
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

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
            setProducts([]);
            setUnits([]);
        } finally {
            setLoading(false);
        }
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'In Stock': return '#22c55e';
            case 'Low Stock': return '#f59e0b';
            case 'Out of Stock': return '#ef4444';
            default: return '#64748b';
        }
    };

    const handleOpenDialog = (product?: any) => {
        if (product) {
            setEditingProduct(product);
            setFormData({
                name: product.name || '',
                category: product.category || '',
                unit_id: product.unit_id || '',
                current_stock: product.current_stock || 0,
                min_stock: product.min_stock || 0
            });
        } else {
            setEditingProduct(null);
            setFormData({ name: '', category: '', unit_id: '', current_stock: 0, min_stock: 0 });
        }
        setOpenDialog(true);
    };

    const handleCloseDialog = () => {
        setOpenDialog(false);
        setEditingProduct(null);
        setFormData({ name: '', category: '', unit_id: '', current_stock: 0, min_stock: 0 });
    };

    const handleSubmit = async () => {
        try {
            if (editingProduct) {
                await inventoryAPI.updateProduct(editingProduct.id, formData);
            } else {
                await inventoryAPI.createProduct(formData);
            }
            // Trigger global stock check
            checkLowStock();
            handleCloseDialog();
            loadData();
            showSnackbar(`Product ${editingProduct ? 'updated' : 'created'} successfully`);
        } catch (error: any) {
            console.error('Error saving product:', error);
            showSnackbar(error.response?.data?.detail || 'Error saving product', 'error');
        }
    };

    const handleDelete = async (id: number) => {
        if (!confirm('Are you sure you want to delete this product?')) return;
        try {
            await inventoryAPI.deleteProduct(id);
            checkLowStock();
            loadData();
            showSnackbar('Product deleted successfully');
        } catch (error: any) {
            console.error('Error deleting product:', error);
            showSnackbar(error.response?.data?.detail || 'Error deleting product', 'error');
        }
    };

    const filteredProducts = products.filter(product =>
        product.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        product.category?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <Box>
            <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b' }}>Products</Typography>
                <Box sx={{ display: 'flex', gap: 2 }}>
                    <Button
                        variant="contained"
                        startIcon={<Plus size={18} />}
                        onClick={() => handleOpenDialog()}
                        sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', borderRadius: '10px' }}
                    >
                        Add Product
                    </Button>
                </Box>
            </Box>

            <Paper sx={{ p: 2, mb: 3, borderRadius: '12px' }}>
                <TextField
                    size="small"
                    placeholder="Search products..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    InputProps={{
                        startAdornment: (
                            <InputAdornment position="start">
                                <Search size={18} color="#64748b" />
                            </InputAdornment>
                        ),
                    }}
                    sx={{ width: 300 }}
                />
            </Paper>

            <TableContainer component={Paper} sx={{ borderRadius: '16px' }}>
                <Table>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700 }}>Name</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Category</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Current Stock</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Status</TableCell>
                            <TableCell sx={{ fontWeight: 700 }} align="right">Actions</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={5} align="center">Loading...</TableCell>
                            </TableRow>
                        ) : filteredProducts.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={5} align="center">No products found. Add your first product to get started.</TableCell>
                            </TableRow>
                        ) : (
                            filteredProducts.map((product) => (
                                <TableRow key={product.id} hover>
                                    <TableCell sx={{ fontWeight: 600 }}>{product.name || 'N/A'}</TableCell>
                                    <TableCell>{product.category || '-'}</TableCell>
                                    <TableCell>
                                        {Number(product.current_stock || 0).toFixed(2)} {product.unit?.abbreviation || ''}
                                    </TableCell>
                                    <TableCell>
                                        <Chip
                                            label={product.status || 'In Stock'}
                                            size="small"
                                            sx={{
                                                bgcolor: `${getStatusColor(product.status || 'In Stock')}15`,
                                                color: getStatusColor(product.status || 'In Stock'),
                                                fontWeight: 700
                                            }}
                                        />
                                    </TableCell>
                                    <TableCell align="right">
                                        <IconButton size="small" onClick={() => handleOpenDialog(product)}>
                                            <Edit size={16} />
                                        </IconButton>
                                        <IconButton size="small" onClick={() => handleDelete(product.id)}>
                                            <Trash2 size={16} />
                                        </IconButton>
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
                <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography fontWeight={800}>{editingProduct ? 'Edit Product' : 'Add New Product'}</Typography>
                    <IconButton onClick={handleCloseDialog} size="small">
                        <X size={20} />
                    </IconButton>
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
                        <TextField
                            label="Product Name"
                            fullWidth
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            placeholder="e.g., Coffee Beans"
                            required
                        />
                        <TextField
                            label="Category"
                            fullWidth
                            value={formData.category}
                            onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                            placeholder="e.g., Raw Material"
                        />
                        <TextField
                            select
                            label="Unit of Measurement"
                            fullWidth
                            value={formData.unit_id}
                            onChange={(e) => setFormData({ ...formData, unit_id: e.target.value })}
                            required
                        >
                            {units.map((unit) => (
                                <MenuItem key={unit.id} value={unit.id}>
                                    {unit.name} ({unit.abbreviation})
                                </MenuItem>
                            ))}
                        </TextField>
                        <TextField
                            label="Current Stock"
                            type="number"
                            fullWidth
                            value={formData.current_stock}
                            onChange={(e) => setFormData({ ...formData, current_stock: parseFloat(e.target.value) || 0 })}
                        />
                        <TextField
                            label="Minimum Stock"
                            type="number"
                            fullWidth
                            value={formData.min_stock}
                            onChange={(e) => setFormData({ ...formData, min_stock: parseFloat(e.target.value) || 0 })}
                        />
                        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2, mt: 2 }}>
                            <Button onClick={handleCloseDialog}>Cancel</Button>
                            <Button variant="contained" onClick={handleSubmit} sx={{ bgcolor: '#FFC107' }}>
                                {editingProduct ? 'Update' : 'Create'}
                            </Button>
                        </Box>
                    </Box>
                </DialogContent>
            </Dialog>
            <Snackbar
                open={snackbar.open}
                autoHideDuration={4000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            >
                <Alert severity={snackbar.severity} sx={{ width: '100%', borderRadius: '12px', fontWeight: 600 }}>
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </Box>
    );
};

export default Products;

