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
    MenuItem
} from '@mui/material';
import { Plus, X } from 'lucide-react';
import { inventoryAPI } from '../../../services/api';

const Adjustment: React.FC = () => {
    const [adjustments, setAdjustments] = useState<any[]>([]);
    const [products, setProducts] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [openDialog, setOpenDialog] = useState(false);
    const [formData, setFormData] = useState({
        product_id: '',
        quantity: 0,
        notes: ''
    });

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setLoading(true);
            const [adjustmentsRes, productsRes] = await Promise.all([
                inventoryAPI.getAdjustments(),
                inventoryAPI.getProducts()
            ]);
            setAdjustments(adjustmentsRes.data || []);
            setProducts(productsRes.data || []);
        } catch (error) {
            console.error('Error loading data:', error);
            setAdjustments([]);
            setProducts([]);
        } finally {
            setLoading(false);
        }
    };

    const handleOpenDialog = () => {
        setFormData({ product_id: '', quantity: 0, notes: '' });
        setOpenDialog(true);
    };

    const handleCloseDialog = () => {
        setOpenDialog(false);
        setFormData({ product_id: '', quantity: 0, notes: '' });
    };

    const handleSubmit = async () => {
        try {
            await inventoryAPI.createAdjustment({
                ...formData,
                transaction_type: 'Adjustment'
            });
            handleCloseDialog();
            loadData();
        } catch (error) {
            console.error('Error creating adjustment:', error);
            alert('Error creating adjustment. Please try again.');
        }
    };

    return (
        <Box>
            <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b' }}>Inventory Adjustment</Typography>
                <Button
                    variant="contained"
                    startIcon={<Plus size={18} />}
                    onClick={handleOpenDialog}
                    sx={{ bgcolor: '#FF8C00', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', borderRadius: '10px' }}
                >
                    New Adjustment
                </Button>
            </Box>

            <TableContainer component={Paper} sx={{ borderRadius: '16px' }}>
                <Table>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700 }}>Date</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Product</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Quantity</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Notes</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={4} align="center">Loading...</TableCell>
                            </TableRow>
                        ) : adjustments.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={4} align="center">No adjustments found. Create your first adjustment to get started.</TableCell>
                            </TableRow>
                        ) : (
                            adjustments.map((adj) => (
                                <TableRow key={adj.id} hover>
                                    <TableCell>{new Date(adj.created_at).toLocaleDateString()}</TableCell>
                                    <TableCell>{adj.product?.name || 'N/A'}</TableCell>
                                    <TableCell>{adj.quantity}</TableCell>
                                    <TableCell>{adj.notes || '-'}</TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
                <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography fontWeight={800}>New Inventory Adjustment</Typography>
                    <IconButton onClick={handleCloseDialog} size="small">
                        <X size={20} />
                    </IconButton>
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
                        <TextField
                            select
                            label="Product"
                            fullWidth
                            value={formData.product_id}
                            onChange={(e) => setFormData({ ...formData, product_id: e.target.value })}
                            required
                        >
                            {products.map((product) => (
                                <MenuItem key={product.id} value={product.id}>
                                    {product.name}
                                </MenuItem>
                            ))}
                        </TextField>
                        <TextField
                            label="Adjustment Quantity"
                            type="number"
                            fullWidth
                            value={formData.quantity}
                            onChange={(e) => setFormData({ ...formData, quantity: parseFloat(e.target.value) || 0 })}
                            helperText="Use positive for increase, negative for decrease"
                            required
                        />
                        <TextField
                            label="Notes"
                            multiline
                            rows={3}
                            fullWidth
                            value={formData.notes}
                            onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                        />
                        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2, mt: 2 }}>
                            <Button onClick={handleCloseDialog}>Cancel</Button>
                            <Button variant="contained" onClick={handleSubmit} sx={{ bgcolor: '#FF8C00' }}>
                                Create Adjustment
                            </Button>
                        </Box>
                    </Box>
                </DialogContent>
            </Dialog>
        </Box>
    );
};

export default Adjustment;

