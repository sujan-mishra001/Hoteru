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
    Chip,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
    MenuItem,
    CircularProgress,
    Snackbar,
    Alert
} from '@mui/material';
import { Plus, FileText, Check, Clock, Trash2, ShoppingCart } from 'lucide-react';
import { purchaseAPI, inventoryAPI } from '../../../services/api';
import { IconButton, Divider } from '@mui/material';
import { useInventory } from '../../../app/providers/InventoryProvider';

const PurchaseBill: React.FC = () => {
    const [bills, setBills] = useState<any[]>([]);
    const [suppliers, setSuppliers] = useState<any[]>([]);
    const [products, setProducts] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [units, setUnits] = useState<any[]>([]);
    const [openDialog, setOpenDialog] = useState(false);
    const [openProductDialog, setOpenProductDialog] = useState(false);
    const [submitting, setSubmitting] = useState(false);
    const [productSaving, setProductSaving] = useState(false);
    const [snackbar, setSnackbar] = useState<{ open: boolean, message: string, severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });
    const { checkLowStock } = useInventory();

    // New Bill Form State
    const [newBill, setNewBill] = useState<{
        supplier_id: string;
        total_amount: number;
        status: string;
        order_date: string;
        paid_date: string;
        items: any[];
    }>({
        supplier_id: '',
        total_amount: 0,
        status: 'Pending',
        order_date: new Date().toISOString().split('T')[0],
        paid_date: '',
        items: []
    });

    const [billItemForm, setBillItemForm] = useState({
        product_id: '',
        quantity: 1,
        unit_id: '',
        rate: 0
    });

    const [newProductForm, setNewProductForm] = useState({
        name: '',
        category: '',
        unit_id: '',
        min_stock: 0
    });

    // Detail/Edit State
    const [selectedBill, setSelectedBill] = useState<any>(null);
    const [openDetailDialog, setOpenDetailDialog] = useState(false);

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setLoading(true);
            const [billsRes, suppliersRes, productsRes, unitsRes] = await Promise.all([
                purchaseAPI.getBills(),
                purchaseAPI.getSuppliers(),
                inventoryAPI.getProducts(),
                inventoryAPI.getUnits()
            ]);
            setBills(billsRes.data || []);
            setSuppliers(suppliersRes.data || []);
            setProducts(productsRes.data || []);
            setUnits(unitsRes.data || []);
        } catch (error) {
            console.error('Error loading data:', error);
            setSnackbar({ open: true, message: 'Failed to load data', severity: 'error' });
        } finally {
            setLoading(false);
        }
    };

    const handleCreateProduct = async () => {
        if (!newProductForm.name || !newProductForm.unit_id) {
            setSnackbar({ open: true, message: 'Name and unit are required', severity: 'error' });
            return;
        }

        try {
            setProductSaving(true);
            const res = await inventoryAPI.createProduct({
                ...newProductForm,
                unit_id: parseInt(newProductForm.unit_id),
                product_type: 'Raw'
            });

            setSnackbar({ open: true, message: 'Product created!', severity: 'success' });
            checkLowStock();

            // Refresh products
            const productsRes = await inventoryAPI.getProducts();
            const allProducts = productsRes.data || [];
            setProducts(allProducts);

            // Auto-select the new product
            setBillItemForm(prev => ({ ...prev, product_id: res.data.id }));

            setOpenProductDialog(false);
            setNewProductForm({ name: '', category: '', unit_id: '', min_stock: 0 });
        } catch (error: any) {
            setSnackbar({ open: true, message: 'Failed to create product', severity: 'error' });
        } finally {
            setProductSaving(false);
        }
    };

    const addItemToBill = () => {
        if (!billItemForm.product_id || billItemForm.quantity <= 0 || billItemForm.rate < 0) {
            setSnackbar({ open: true, message: 'Please select a product and enter valid quantity/rate', severity: 'error' });
            return;
        }

        const product = products.find(p => p.id === billItemForm.product_id);
        const newItem = {
            ...billItemForm,
            product_id: parseInt(billItemForm.product_id as string),
            product_name: product?.name || 'Unknown',
            unit_id: billItemForm.unit_id ? parseInt(billItemForm.unit_id as string) : product?.unit_id,
            total: billItemForm.quantity * billItemForm.rate
        };

        const updatedItems = [...newBill.items, newItem];
        const newTotal = updatedItems.reduce((sum, item) => sum + item.total, 0);

        setNewBill({
            ...newBill,
            items: updatedItems,
            total_amount: newTotal
        });

        // Reset item form
        setBillItemForm({
            product_id: '',
            quantity: 1,
            unit_id: '',
            rate: 0
        });
    };

    const removeItemFromBill = (index: number) => {
        const updatedItems = newBill.items.filter((_, i) => i !== index);
        const newTotal = updatedItems.reduce((sum, item) => sum + item.total, 0);
        setNewBill({
            ...newBill,
            items: updatedItems,
            total_amount: newTotal
        });
    };

    const handleCreateBill = async () => {
        if (!newBill.supplier_id || newBill.items.length === 0) {
            setSnackbar({ open: true, message: 'Please select a supplier and add at least one item', severity: 'error' });
            return;
        }

        try {
            setSubmitting(true);
            const payload = {
                ...newBill,
                supplier_id: parseInt(newBill.supplier_id),
                total_amount: newBill.total_amount,
                paid_date: newBill.paid_date || null
            };

            await purchaseAPI.createBill(payload);
            setSnackbar({ open: true, message: 'Purchase bill created successfully', severity: 'success' });
            checkLowStock();
            setOpenDialog(false);
            setNewBill({
                supplier_id: '',
                total_amount: 0,
                status: 'Pending',
                order_date: new Date().toISOString().split('T')[0],
                paid_date: '',
                items: []
            });
            loadData();
        } catch (error: any) {
            console.error('Error creating bill:', error);
            setSnackbar({ open: true, message: error.response?.data?.detail || 'Failed to create bill', severity: 'error' });
        } finally {
            setSubmitting(false);
        }
    };

    const handleViewDetails = (bill: any) => {
        setSelectedBill({
            ...bill,
            paid_date: bill.paid_date ? new Date(bill.paid_date).toISOString().split('T')[0] : ''
        });
        setOpenDetailDialog(true);
    };

    const handleUpdateBill = async () => {
        if (!selectedBill) return;

        try {
            setSubmitting(true);
            const payload = {
                status: selectedBill.status,
                paid_date: selectedBill.paid_date || null
            };

            await purchaseAPI.updateBill(selectedBill.id, payload);
            setSnackbar({ open: true, message: 'Bill updated successfully', severity: 'success' });
            setOpenDetailDialog(false);
            loadData();
        } catch (error: any) {
            console.error('Error updating bill:', error);
            setSnackbar({ open: true, message: 'Failed to update bill', severity: 'error' });
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <Box>
            <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                    <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b' }}>Purchase Bills</Typography>
                    <Typography variant="body2" color="text.secondary">Manage purchase orders and bills</Typography>
                </Box>
                <Button
                    variant="contained"
                    startIcon={<Plus size={18} />}
                    onClick={() => setOpenDialog(true)}
                    sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', borderRadius: '10px', fontWeight: 700 }}
                >
                    New Purchase Bill
                </Button>
            </Box>

            <TableContainer component={Paper} sx={{ borderRadius: '16px', boxShadow: '0 4px 20px rgba(0,0,0,0.05)' }}>
                <Table>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>Bill Number</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>Supplier</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>Items</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>Order Date</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>Total Amount</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>Status</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }} align="right">Actions</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={6} align="center" sx={{ py: 4 }}>
                                    <CircularProgress sx={{ color: '#FFC107' }} size={24} />
                                </TableCell>
                            </TableRow>
                        ) : bills.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={6} align="center" sx={{ py: 6 }}>
                                    <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
                                        <FileText size={48} color="#cbd5e1" />
                                        <Typography color="text.secondary" fontWeight={500}>No purchase bills found</Typography>
                                        <Button size="small" variant="text" sx={{ color: '#FFC107' }} onClick={() => setOpenDialog(true)}>
                                            Create your first bill
                                        </Button>
                                    </Box>
                                </TableCell>
                            </TableRow>
                        ) : (
                            bills.map((bill) => (
                                <TableRow key={bill.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                                    <TableCell sx={{ fontWeight: 600, color: '#334155' }}>{bill.bill_number || 'N/A'}</TableCell>
                                    <TableCell>{bill.supplier?.name || 'N/A'}</TableCell>
                                    <TableCell>
                                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                                            {bill.items?.length || 0} items
                                        </Typography>
                                        <Typography variant="caption" color="text.secondary">
                                            {bill.items?.slice(0, 2).map((i: any) => i.product?.name).join(', ')}
                                            {(bill.items?.length > 2) ? '...' : ''}
                                        </Typography>
                                    </TableCell>
                                    <TableCell>{new Date(bill.order_date).toLocaleDateString()}</TableCell>
                                    <TableCell sx={{ fontWeight: 700, color: '#334155' }}>NPR {Number(bill.total_amount || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</TableCell>
                                    <TableCell>
                                        <Chip
                                            icon={bill.status === 'Paid' ? <Check size={14} /> : <Clock size={14} />}
                                            label={bill.status || 'Pending'}
                                            size="small"
                                            sx={{
                                                bgcolor: bill.status === 'Paid' ? '#ecfdf5' : '#fffbeb',
                                                color: bill.status === 'Paid' ? '#059669' : '#d97706',
                                                fontWeight: 700,
                                                borderColor: bill.status === 'Paid' ? '#10b98120' : '#f59e0b20',
                                                border: '1px solid'
                                            }}
                                        />
                                    </TableCell>
                                    <TableCell align="right">
                                        <Button
                                            size="small"
                                            variant="text"
                                            sx={{ color: '#FFC107', textTransform: 'none', fontWeight: 600 }}
                                            onClick={() => handleViewDetails(bill)}
                                        >
                                            View Details
                                        </Button>
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            <Dialog
                open={openDialog}
                onClose={() => setOpenDialog(false)}
                PaperProps={{ sx: { borderRadius: '16px', maxWidth: '800px', width: '100%' } }}
            >
                <DialogTitle sx={{ fontWeight: 800, display: 'flex', alignItems: 'center', gap: 1 }}>
                    <ShoppingCart size={24} color="#FFC107" />
                    Create Purchase Bill
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ pt: 1, display: 'flex', flexDirection: 'column', gap: 3 }}>
                        <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 2 }}>
                            <TextField
                                select
                                label="Supplier"
                                value={newBill.supplier_id}
                                onChange={(e) => setNewBill({ ...newBill, supplier_id: e.target.value })}
                                fullWidth
                                disabled={suppliers.length === 0}
                            >
                                {suppliers.map((supplier) => (
                                    <MenuItem key={supplier.id} value={supplier.id}>
                                        {supplier.name}
                                    </MenuItem>
                                ))}
                            </TextField>

                            <TextField
                                label="Order Date"
                                type="date"
                                value={newBill.order_date}
                                onChange={(e) => setNewBill({ ...newBill, order_date: e.target.value })}
                                fullWidth
                                InputLabelProps={{ shrink: true }}
                            />

                            <TextField
                                select
                                label="Status"
                                value={newBill.status}
                                onChange={(e) => setNewBill({ ...newBill, status: e.target.value })}
                                fullWidth
                            >
                                <MenuItem value="Pending">Pending</MenuItem>
                                <MenuItem value="Paid">Paid</MenuItem>
                            </TextField>
                        </Box>

                        <Divider>
                            <Chip label="Bill Items" size="small" />
                        </Divider>

                        {/* Item Entry Section */}
                        <Box sx={{ display: 'flex', gap: 2, alignItems: 'flex-start', bgcolor: '#f8fafc', p: 2, borderRadius: '12px' }}>
                            <Box sx={{ flex: 2, display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                                <TextField
                                    select
                                    label="Product"
                                    size="small"
                                    value={billItemForm.product_id}
                                    onChange={(e) => setBillItemForm({ ...billItemForm, product_id: e.target.value })}
                                    fullWidth
                                >
                                    {products
                                        .filter(p => p.product_type === 'Raw')
                                        .map((product) => (
                                            <MenuItem key={product.id} value={product.id}>
                                                {product.name}
                                            </MenuItem>
                                        ))}
                                </TextField>
                                <Button
                                    size="small"
                                    startIcon={<Plus size={14} />}
                                    onClick={() => setOpenProductDialog(true)}
                                    sx={{ p: 0, minWidth: 0, justifyContent: 'flex-start', color: '#FFC107', fontSize: '11px', '&:hover': { bgcolor: 'transparent', color: '#FF7700' } }}
                                >
                                    Add New Product
                                </Button>
                            </Box>
                            <TextField
                                label="Qty"
                                type="number"
                                size="small"
                                value={billItemForm.quantity}
                                onChange={(e) => setBillItemForm({ ...billItemForm, quantity: parseFloat(e.target.value) || 0 })}
                                sx={{ flex: 1 }}
                            />
                            <TextField
                                select
                                label="Unit"
                                size="small"
                                value={billItemForm.unit_id}
                                onChange={(e) => setBillItemForm({ ...billItemForm, unit_id: e.target.value })}
                                sx={{ flex: 1 }}
                            >
                                <MenuItem value=""><em>Base Unit</em></MenuItem>
                                {units.map((u) => (
                                    <MenuItem key={u.id} value={u.id}>{u.abbreviation}</MenuItem>
                                ))}
                            </TextField>
                            <TextField
                                label="Rate"
                                type="number"
                                size="small"
                                value={billItemForm.rate}
                                onChange={(e) => setBillItemForm({ ...billItemForm, rate: parseFloat(e.target.value) || 0 })}
                                sx={{ flex: 1 }}
                            />
                            <Button
                                variant="contained"
                                size="large"
                                onClick={addItemToBill}
                                sx={{ bgcolor: '#1e293b', flex: 0.5, py: 1 }}
                            >
                                <Plus size={20} />
                            </Button>
                        </Box>

                        {/* Items Table */}
                        <TableContainer sx={{ maxHeight: '300px' }}>
                            <Table size="small" stickyHeader>
                                <TableHead>
                                    <TableRow>
                                        <TableCell sx={{ fontWeight: 700 }}>Item</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>Qty</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>Unit</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>Rate</TableCell>
                                        <TableCell sx={{ fontWeight: 700 }}>Total</TableCell>
                                        <TableCell></TableCell>
                                    </TableRow>
                                </TableHead>
                                <TableBody>
                                    {newBill.items.map((item, index) => (
                                        <TableRow key={index}>
                                            <TableCell>{item.product_name}</TableCell>
                                            <TableCell>{Number(item.quantity).toFixed(2)}</TableCell>
                                            <TableCell>{units.find(u => u.id === item.unit_id)?.abbreviation || products.find(p => p.id === item.product_id)?.unit?.abbreviation || 'unit'}</TableCell>
                                            <TableCell>{Number(item.rate).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</TableCell>
                                            <TableCell sx={{ fontWeight: 700 }}>{Number(item.total).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</TableCell>
                                            <TableCell align="right">
                                                <IconButton size="small" color="error" onClick={() => removeItemFromBill(index)}>
                                                    <Trash2 size={16} />
                                                </IconButton>
                                            </TableCell>
                                        </TableRow>
                                    ))}
                                    {newBill.items.length === 0 && (
                                        <TableRow>
                                            <TableCell colSpan={6} align="center" sx={{ py: 4, color: '#94a3b8' }}>
                                                No items added yet
                                            </TableCell>
                                        </TableRow>
                                    )}
                                </TableBody>
                            </Table>
                        </TableContainer>

                        <Box sx={{ alignSelf: 'flex-end', display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 1 }}>
                            <Typography variant="body2" color="text.secondary">Total Amount</Typography>
                            <Typography variant="h4" sx={{ fontWeight: 800, color: '#FFC107' }}>
                                NPR {Number(newBill.total_amount).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                            </Typography>
                        </Box>

                        {newBill.status === 'Paid' && (
                            <TextField
                                label="Paid Date"
                                type="date"
                                value={newBill.paid_date}
                                onChange={(e) => setNewBill({ ...newBill, paid_date: e.target.value })}
                                fullWidth
                                InputLabelProps={{ shrink: true }}
                            />
                        )}
                    </Box>
                </DialogContent>
                <DialogActions sx={{ p: 3, pt: 0 }}>
                    <Button onClick={() => setOpenDialog(false)} sx={{ fontWeight: 600, color: '#64748b' }}>Cancel</Button>
                    <Button
                        variant="contained"
                        onClick={handleCreateBill}
                        disabled={submitting || suppliers.length === 0 || newBill.items.length === 0}
                        sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, borderRadius: '8px', fontWeight: 700, px: 4 }}
                    >
                        {submitting ? 'Creating...' : 'Create Bill'}
                    </Button>
                </DialogActions>
            </Dialog>

            {/* Quick Create Product Dialog */}
            <Dialog
                open={openProductDialog}
                onClose={() => setOpenProductDialog(false)}
                PaperProps={{ sx: { borderRadius: '12px', width: '400px' } }}
            >
                <DialogTitle sx={{ fontWeight: 800 }}>Create New Product</DialogTitle>
                <DialogContent>
                    <Box sx={{ pt: 1, display: 'flex', flexDirection: 'column', gap: 2 }}>
                        <TextField
                            fullWidth label="Product Name"
                            value={newProductForm.name}
                            onChange={(e) => setNewProductForm({ ...newProductForm, name: e.target.value })}
                        />
                        <TextField
                            fullWidth label="Category"
                            value={newProductForm.category}
                            onChange={(e) => setNewProductForm({ ...newProductForm, category: e.target.value })}
                        />
                        <TextField
                            select fullWidth label="Unit"
                            value={newProductForm.unit_id}
                            onChange={(e) => setNewProductForm({ ...newProductForm, unit_id: e.target.value })}
                        >
                            {units.map(u => <MenuItem key={u.id} value={u.id}>{u.name} ({u.abbreviation})</MenuItem>)}
                        </TextField>
                    </Box>
                </DialogContent>
                <DialogActions sx={{ p: 2 }}>
                    <Button onClick={() => setOpenProductDialog(false)}>Cancel</Button>
                    <Button
                        variant="contained"
                        onClick={handleCreateProduct}
                        disabled={productSaving}
                        sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, fontWeight: 700 }}
                    >
                        {productSaving ? 'Saving...' : 'Create Product'}
                    </Button>
                </DialogActions>
            </Dialog>

            {/* Edit/View Detail Dialog */}
            <Dialog
                open={openDetailDialog}
                onClose={() => setOpenDetailDialog(false)}
                PaperProps={{ sx: { borderRadius: '16px', maxWidth: '500px', width: '100%' } }}
            >
                <DialogTitle sx={{ fontWeight: 800 }}>Bill Details: {selectedBill?.bill_number}</DialogTitle>
                <DialogContent>
                    {selectedBill && (
                        <Box sx={{ pt: 1, display: 'flex', flexDirection: 'column', gap: 2 }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', bgcolor: '#f8fafc', p: 2, borderRadius: '12px' }}>
                                <Box>
                                    <Typography variant="caption" color="text.secondary">Supplier</Typography>
                                    <Typography fontWeight={600}>{selectedBill.supplier?.name || 'N/A'}</Typography>
                                </Box>
                                <Box sx={{ textAlign: 'right' }}>
                                    <Typography variant="caption" color="text.secondary">Total Amount</Typography>
                                    <Typography fontWeight={700} color="#FFC107">NPR {Number(selectedBill.total_amount || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                                </Box>
                            </Box>

                            <TextField
                                select
                                label="Status"
                                value={selectedBill.status}
                                onChange={(e) => setSelectedBill({ ...selectedBill, status: e.target.value })}
                                fullWidth
                            >
                                <MenuItem value="Pending">Pending</MenuItem>
                                <MenuItem value="Paid">Paid</MenuItem>
                            </TextField>

                            {selectedBill.status === 'Paid' && (
                                <TextField
                                    label="Paid Date"
                                    type="date"
                                    value={selectedBill.paid_date || ''}
                                    onChange={(e) => setSelectedBill({ ...selectedBill, paid_date: e.target.value })}
                                    fullWidth
                                    InputLabelProps={{ shrink: true }}
                                />
                            )}

                            <Box sx={{ mt: 1 }}>
                                <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>Bill Items</Typography>
                                <TableContainer sx={{ border: '1px solid #f1f5f9', borderRadius: '8px' }}>
                                    <Table size="small">
                                        <TableHead sx={{ bgcolor: '#f8fafc' }}>
                                            <TableRow>
                                                <TableCell sx={{ fontWeight: 600 }}>Item</TableCell>
                                                <TableCell sx={{ fontWeight: 600 }}>Qty</TableCell>
                                                <TableCell sx={{ fontWeight: 600 }}>Rate</TableCell>
                                                <TableCell sx={{ fontWeight: 600 }}>Total</TableCell>
                                            </TableRow>
                                        </TableHead>
                                        <TableBody>
                                            {selectedBill.items?.map((item: any, index: number) => (
                                                <TableRow key={index}>
                                                    <TableCell>{item.product?.name || 'Unknown'}</TableCell>
                                                    <TableCell>{Number(item.quantity).toFixed(2)}</TableCell>
                                                    <TableCell>{Number(item.rate).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</TableCell>
                                                    <TableCell sx={{ fontWeight: 600 }}>{Number(item.quantity * item.rate).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</TableCell>
                                                </TableRow>
                                            ))}
                                        </TableBody>
                                    </Table>
                                </TableContainer>
                            </Box>

                            <Box sx={{ mt: 1 }}>
                                <Typography variant="caption" color="text.secondary">Order Date: {new Date(selectedBill.order_date).toLocaleDateString()}</Typography>
                            </Box>
                        </Box>
                    )}
                </DialogContent>
                <DialogActions sx={{ p: 3, pt: 0 }}>
                    <Button onClick={() => setOpenDetailDialog(false)} sx={{ fontWeight: 600, color: '#64748b' }}>Close</Button>
                    <Button
                        variant="contained"
                        onClick={handleUpdateBill}
                        disabled={submitting}
                        sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, borderRadius: '8px', fontWeight: 700 }}
                    >
                        {submitting ? 'Updating...' : 'Update Status'}
                    </Button>
                </DialogActions>
            </Dialog>

            <Snackbar
                open={snackbar.open}
                autoHideDuration={6000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            >
                <Alert severity={snackbar.severity} onClose={() => setSnackbar({ ...snackbar, open: false })} sx={{ fontWeight: 500 }}>
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </Box>
    );
};

export default PurchaseBill;


