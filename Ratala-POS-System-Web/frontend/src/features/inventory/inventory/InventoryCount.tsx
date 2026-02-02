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
    MenuItem,
    Chip,
    Card,
    CardContent
} from '@mui/material';
import { X, ClipboardCheck, History, AlertCircle, CheckCircle2, TrendingDown, TrendingUp, Package } from 'lucide-react';
import { inventoryAPI } from '../../../services/api';

const InventoryCount: React.FC = () => {
    const [counts, setCounts] = useState<any[]>([]);
    const [products, setProducts] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [openDialog, setOpenDialog] = useState(false);
    const [formData, setFormData] = useState({
        product_id: '',
        counted_quantity: 0,
        notes: ''
    });
    const [selectedProduct, setSelectedProduct] = useState<any>(null);

    useEffect(() => {
        loadData();
    }, []);

    useEffect(() => {
        if (formData.product_id) {
            const product = products.find(p => p.id === formData.product_id);
            setSelectedProduct(product || null);
        } else {
            setSelectedProduct(null);
        }
    }, [formData.product_id, products]);

    const loadData = async () => {
        try {
            setLoading(true);
            const [countsRes, productsRes] = await Promise.all([
                inventoryAPI.getCounts(),
                inventoryAPI.getProducts()
            ]);
            setCounts(countsRes.data || []);
            setProducts(productsRes.data || []);
        } catch (error) {
            console.error('Error loading data:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleOpenDialog = () => {
        setFormData({ product_id: '', counted_quantity: 0, notes: '' });
        setOpenDialog(true);
    };

    const handleCloseDialog = () => {
        setOpenDialog(false);
        setFormData({ product_id: '', counted_quantity: 0, notes: '' });
    };

    const handleSubmit = async () => {
        try {
            await inventoryAPI.createCount(formData);
            handleCloseDialog();
            loadData();
        } catch (error) {
            console.error('Error creating count:', error);
            alert('Error creating count. Please try again.');
        }
    };

    const diff = selectedProduct ? (formData.counted_quantity - selectedProduct.current_stock) : 0;

    return (
        <Box sx={{ p: 1 }}>
            <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                    <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b', mb: 0.5 }}>Inventory Audit</Typography>
                    <Typography variant="body2" color="text.secondary">Verify physical stock levels and automatically reconcile mismatches.</Typography>
                </Box>
                <Button
                    variant="contained"
                    startIcon={<ClipboardCheck size={18} />}
                    onClick={handleOpenDialog}
                    sx={{
                        bgcolor: '#FF8C00',
                        '&:hover': { bgcolor: '#FF7700' },
                        textTransform: 'none',
                        borderRadius: '12px',
                        px: 3,
                        py: 1,
                        boxShadow: '0 4px 14px 0 rgba(255, 140, 0, 0.39)'
                    }}
                >
                    Record New Count
                </Button>
            </Box>

            <Paper sx={{ borderRadius: '20px', boxShadow: '0 4px 20px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
                <TableContainer>
                    <Table>
                        <TableHead sx={{ bgcolor: '#f8fafc' }}>
                            <TableRow>
                                <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>DATE</TableCell>
                                <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>PRODUCT</TableCell>
                                <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>REASON / NOTES</TableCell>
                                <TableCell sx={{ fontWeight: 700, color: '#64748b' }} align="right">SYSTEM</TableCell>
                                <TableCell sx={{ fontWeight: 700, color: '#64748b' }} align="right">PHYSICAL</TableCell>
                                <TableCell sx={{ fontWeight: 700, color: '#64748b' }} align="right">DIFFERENCE</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {loading ? (
                                <TableRow>
                                    <TableCell colSpan={6} align="center" sx={{ py: 10 }}>Loading history...</TableCell>
                                </TableRow>
                            ) : counts.length === 0 ? (
                                <TableRow>
                                    <TableCell colSpan={6} align="center" sx={{ py: 12 }}>
                                        <History size={48} color="#94a3b8" style={{ marginBottom: '16px' }} />
                                        <Typography variant="h6" color="text.secondary">No count entries found.</Typography>
                                        <Typography variant="body2" color="text.secondary">Perform a physical count to sync your system stock.</Typography>
                                    </TableCell>
                                </TableRow>
                            ) : (
                                counts.map((count) => {
                                    // Difference is stored and available in count.quantity since it's an InventoryTransaction
                                    const difference = count.quantity;
                                    return (
                                        <TableRow key={count.id} hover>
                                            <TableCell sx={{ color: '#64748b' }}>{new Date(count.created_at).toLocaleString()}</TableCell>
                                            <TableCell sx={{ fontWeight: 700, color: '#1e293b' }}>{count.product?.name}</TableCell>
                                            <TableCell>
                                                <Typography variant="body2" color="text.secondary" sx={{ maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                                    {count.notes}
                                                </Typography>
                                            </TableCell>
                                            <TableCell align="right" sx={{ fontWeight: 500 }}>{count.product?.current_stock || 0}</TableCell>
                                            <TableCell align="right" sx={{ fontWeight: 700 }}>
                                                {/* In our API, note stores the physical count in the string */}
                                                {/* For a cleaner UI, we could have added a column, but derived it's OK */}
                                                {(count.product?.current_stock || 0) + difference}
                                            </TableCell>
                                            <TableCell align="right">
                                                <Chip
                                                    label={difference === 0 ? 'Exact Match' : `${difference > 0 ? '+' : ''}${difference}`}
                                                    size="small"
                                                    icon={difference > 0 ? <TrendingUp size={14} /> : difference < 0 ? <TrendingDown size={14} /> : <CheckCircle2 size={14} />}
                                                    sx={{
                                                        bgcolor: difference === 0 ? '#f0fdf4' : difference > 0 ? '#eff6ff' : '#fef2f2',
                                                        color: difference === 0 ? '#10b981' : difference > 0 ? '#3b82f6' : '#ef4444',
                                                        fontWeight: 700,
                                                        borderRadius: '6px',
                                                        '& .MuiChip-icon': { color: 'inherit' }
                                                    }}
                                                />
                                            </TableCell>
                                        </TableRow>
                                    );
                                })
                            )}
                        </TableBody>
                    </Table>
                </TableContainer>
            </Paper>

            <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth sx={{ '& .MuiDialog-paper': { borderRadius: '24px' } }}>
                <DialogTitle sx={{ p: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                        <Box sx={{ p: 1, bgcolor: '#FFF7ED', borderRadius: '12px' }}>
                            <ClipboardCheck size={24} color="#FF8C00" />
                        </Box>
                        <Typography variant="h5" sx={{ fontWeight: 800 }}>Record Physical Count</Typography>
                    </Box>
                    <IconButton onClick={handleCloseDialog} size="small" sx={{ color: '#94a3b8' }}>
                        <X size={24} />
                    </IconButton>
                </DialogTitle>
                <DialogContent sx={{ p: 3 }}>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, mt: 1 }}>
                        <TextField
                            select
                            label="Select Product to Count"
                            fullWidth
                            value={formData.product_id}
                            onChange={(e) => setFormData({ ...formData, product_id: e.target.value })}
                            required
                        >
                            {products.map((product) => (
                                <MenuItem key={product.id} value={product.id}>
                                    {product.name} ({product.unit?.abbreviation})
                                </MenuItem>
                            ))}
                        </TextField>

                        {selectedProduct && (
                            <Card variant="outlined" sx={{ borderRadius: '16px', bgcolor: '#f8fafc', border: '1px solid #e2e8f0' }}>
                                <CardContent sx={{ p: 2 }}>
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                        <Box>
                                            <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 700, textTransform: 'uppercase' }}>Current System Stock</Typography>
                                            <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b' }}>
                                                {selectedProduct.current_stock} <Typography component="span" variant="h6" color="text.secondary">{selectedProduct.unit?.abbreviation}</Typography>
                                            </Typography>
                                        </Box>
                                        <Box sx={{ p: 1.5, bgcolor: '#fff', borderRadius: '12px', boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}>
                                            <Package size={32} color="#FF8C00" />
                                        </Box>
                                    </Box>
                                </CardContent>
                            </Card>
                        )}

                        <TextField
                            label="Physical Quantity Counted"
                            type="number"
                            fullWidth
                            value={formData.counted_quantity}
                            onChange={(e) => setFormData({ ...formData, counted_quantity: parseFloat(e.target.value) || 0 })}
                            required
                            inputProps={{ min: 0, step: 0.01 }}
                            autoFocus
                        />

                        {selectedProduct && (
                            <Box sx={{ p: 2, borderRadius: '16px', border: '1px solid', borderColor: diff === 0 ? '#dcfce7' : diff > 0 ? '#dbeafe' : '#fee2e2', bgcolor: diff === 0 ? '#f0fdf4' : diff > 0 ? '#eff6ff' : '#fef2f2' }}>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                                    {diff === 0 ? <CheckCircle2 size={20} color="#10b981" /> : <AlertCircle size={20} color={diff > 0 ? '#3b82f6' : '#ef4444'} />}
                                    <Typography variant="body2" sx={{ fontWeight: 700, color: diff === 0 ? '#10b981' : diff > 0 ? '#1e40af' : '#991b1b' }}>
                                        {diff === 0
                                            ? "Physical count matches system stock perfectly."
                                            : `Found a difference of ${diff > 0 ? '+' : ''}${diff} ${selectedProduct.unit?.abbreviation}.`
                                        }
                                    </Typography>
                                </Box>
                                {diff !== 0 && (
                                    <Typography variant="caption" sx={{ display: 'block', mt: 0.5, color: diff > 0 ? '#3b82f6' : '#ef4444' }}>
                                        The system will create an auto-adjustment transaction to reconcile this.
                                    </Typography>
                                )}
                            </Box>
                        )}

                        <TextField
                            label="Notes / Reason for Discrepancy"
                            multiline
                            rows={3}
                            fullWidth
                            value={formData.notes}
                            onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                            placeholder="e.g., Damaged items found, Shipment missing unit, etc."
                        />

                        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2, mt: 2 }}>
                            <Button onClick={handleCloseDialog} sx={{ px: 3, borderRadius: '10px' }}>Cancel</Button>
                            <Button
                                variant="contained"
                                color="primary"
                                onClick={handleSubmit}
                                disabled={!formData.product_id}
                                sx={{
                                    bgcolor: '#FF8C00',
                                    '&:hover': { bgcolor: '#FF7700' },
                                    px: 4,
                                    py: 1.2,
                                    borderRadius: '12px',
                                    textTransform: 'none',
                                    fontWeight: 700,
                                    boxShadow: '0 4px 14px 0 rgba(255, 140, 0, 0.39)'
                                }}
                            >
                                Finish & Reconcile
                            </Button>
                        </Box>
                    </Box>
                </DialogContent>
            </Dialog>
        </Box>
    );
};

export default InventoryCount;
