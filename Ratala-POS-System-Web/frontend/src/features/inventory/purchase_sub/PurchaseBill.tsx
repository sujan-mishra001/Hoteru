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
import { Plus, FileText, Check, Clock } from 'lucide-react';
import { purchaseAPI } from '../../../services/api';

const PurchaseBill: React.FC = () => {
    const [bills, setBills] = useState<any[]>([]);
    const [suppliers, setSuppliers] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [openDialog, setOpenDialog] = useState(false);
    const [submitting, setSubmitting] = useState(false);
    const [snackbar, setSnackbar] = useState<{ open: boolean, message: string, severity: 'success' | 'error' }>({ open: false, message: '', severity: 'success' });

    // New Bill Form State
    const [newBill, setNewBill] = useState({
        supplier_id: '',
        total_amount: '',
        status: 'Pending', // Pending, Paid
        order_date: new Date().toISOString().split('T')[0],
        paid_date: ''
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
            const [billsRes, suppliersRes] = await Promise.all([
                purchaseAPI.getBills(),
                purchaseAPI.getSuppliers()
            ]);
            setBills(billsRes.data || []);
            setSuppliers(suppliersRes.data || []);
        } catch (error) {
            console.error('Error loading data:', error);
            setSnackbar({ open: true, message: 'Failed to load data', severity: 'error' });
        } finally {
            setLoading(false);
        }
    };

    const handleCreateBill = async () => {
        if (!newBill.supplier_id || !newBill.total_amount) {
            setSnackbar({ open: true, message: 'Please fill in all required fields', severity: 'error' });
            return;
        }

        try {
            setSubmitting(true);
            const payload = {
                ...newBill,
                supplier_id: parseInt(newBill.supplier_id),
                total_amount: parseFloat(newBill.total_amount),
                paid_date: newBill.paid_date || null
            };

            await purchaseAPI.createBill(payload);
            setSnackbar({ open: true, message: 'Purchase bill created successfully', severity: 'success' });
            setOpenDialog(false);
            setNewBill({
                supplier_id: '',
                total_amount: '',
                status: 'Pending',
                order_date: new Date().toISOString().split('T')[0],
                paid_date: ''
            });
            loadData(); // Refresh list
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
                    sx={{ bgcolor: '#FF8C00', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', borderRadius: '10px', fontWeight: 700 }}
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
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>Order Date</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>Paid Date</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>Total Amount</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>Status</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }} align="right">Actions</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={6} align="center" sx={{ py: 4 }}>
                                    <CircularProgress sx={{ color: '#FF8C00' }} size={24} />
                                </TableCell>
                            </TableRow>
                        ) : bills.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={6} align="center" sx={{ py: 6 }}>
                                    <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 1 }}>
                                        <FileText size={48} color="#cbd5e1" />
                                        <Typography color="text.secondary" fontWeight={500}>No purchase bills found</Typography>
                                        <Button size="small" variant="text" sx={{ color: '#FF8C00' }} onClick={() => setOpenDialog(true)}>
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
                                    <TableCell>{new Date(bill.order_date).toLocaleDateString()}</TableCell>
                                    <TableCell>{bill.paid_date ? new Date(bill.paid_date).toLocaleDateString() : '-'}</TableCell>
                                    <TableCell sx={{ fontWeight: 700, color: '#334155' }}>NPR {bill.total_amount?.toLocaleString() || 0}</TableCell>
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
                                            sx={{ color: '#FF8C00', textTransform: 'none', fontWeight: 600 }}
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

            {/* Create Dialog */}
            <Dialog
                open={openDialog}
                onClose={() => setOpenDialog(false)}
                PaperProps={{ sx: { borderRadius: '16px', maxWidth: '500px', width: '100%' } }}
            >
                <DialogTitle sx={{ fontWeight: 800 }}>Create Purchase Bill</DialogTitle>
                <DialogContent>
                    <Box sx={{ pt: 1, display: 'flex', flexDirection: 'column', gap: 2 }}>
                        <TextField
                            select
                            label="Supplier"
                            value={newBill.supplier_id}
                            onChange={(e) => setNewBill({ ...newBill, supplier_id: e.target.value })}
                            fullWidth
                            disabled={suppliers.length === 0}
                            helperText={suppliers.length === 0 ? "No suppliers found. Please add a supplier first." : ""}
                        >
                            {suppliers.map((supplier) => (
                                <MenuItem key={supplier.id} value={supplier.id}>
                                    {supplier.name}
                                </MenuItem>
                            ))}
                        </TextField>

                        <TextField
                            label="Total Amount (NPR)"
                            type="number"
                            value={newBill.total_amount}
                            onChange={(e) => setNewBill({ ...newBill, total_amount: e.target.value })}
                            fullWidth
                            InputProps={{ inputProps: { min: 0 } }}
                        />

                        <Box sx={{ display: 'flex', gap: 2 }}>
                            <Box sx={{ flex: 1 }}>
                                <TextField
                                    label="Order Date"
                                    type="date"
                                    value={newBill.order_date}
                                    onChange={(e) => setNewBill({ ...newBill, order_date: e.target.value })}
                                    fullWidth
                                    InputLabelProps={{ shrink: true }}
                                />
                            </Box>
                            <Box sx={{ flex: 1 }}>
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
                        disabled={submitting || suppliers.length === 0}
                        sx={{ bgcolor: '#FF8C00', '&:hover': { bgcolor: '#FF7700' }, borderRadius: '8px', fontWeight: 700 }}
                    >
                        {submitting ? 'Creating...' : 'Create Bill'}
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
                                    <Typography fontWeight={700} color="#FF8C00">NPR {selectedBill.total_amount?.toLocaleString()}</Typography>
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
                        sx={{ bgcolor: '#FF8C00', '&:hover': { bgcolor: '#FF7700' }, borderRadius: '8px', fontWeight: 700 }}
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

