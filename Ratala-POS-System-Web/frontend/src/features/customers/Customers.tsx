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
    InputAdornment,
    Avatar,
    CircularProgress,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    IconButton,
    Chip,
    Divider,
    Snackbar,
    Alert
} from '@mui/material';
import { UserPlus, Search, Phone, History, X, Edit2, Trash2, Calendar, Receipt, Banknote } from 'lucide-react';
import { customersAPI, ordersAPI } from '../../services/api';

interface Customer {
    id: number;
    name: string;
    phone?: string;
    email?: string;
    address?: string;
    customer_type?: string;
    total_spent?: number;
    total_visits?: number;
    due_amount?: number;
    created_at: string;
}

const Customers: React.FC = () => {
    const [customers, setCustomers] = useState<Customer[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [openDialog, setOpenDialog] = useState(false);
    const [newCustomer, setNewCustomer] = useState({ name: '', phone: '', email: '' });
    const [editingCustomer, setEditingCustomer] = useState<Customer | null>(null);
    const [openEditDialog, setOpenEditDialog] = useState(false);

    // History States
    const [openHistoryDialog, setOpenHistoryDialog] = useState(false);
    const [selectedCustomerHistory, setSelectedCustomerHistory] = useState<Customer | null>(null);
    const [customerOrders, setCustomerOrders] = useState<any[]>([]);
    const [historyLoading, setHistoryLoading] = useState(false);
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

    const showSnackbar = (message: string, severity: 'success' | 'error' = 'success') => {
        setSnackbar({ open: true, message, severity });
    };
    useEffect(() => {
        loadCustomers();
    }, []);

    const loadCustomers = async () => {
        try {
            setLoading(true);
            const response = await customersAPI.getAll();
            const customersData = Array.isArray(response.data) ? response.data : (response.data?.data || response.data || []);
            setCustomers(customersData);
        } catch (error: any) {
            console.error('Error loading customers:', error);
            setCustomers([]);
        } finally {
            setLoading(false);
        }
    };



    const handleCreateCustomer = async () => {
        if (!newCustomer.name.trim()) return;
        try {
            await customersAPI.create(newCustomer);
            setNewCustomer({ name: '', phone: '', email: '' });
            setOpenDialog(false);
            loadCustomers();
            showSnackbar('Customer registered successfully');
        } catch (error: any) {
            showSnackbar(error.response?.data?.detail || 'Error creating customer', 'error');
        }
    };

    const handleEditCustomer = async () => {
        if (!editingCustomer || !editingCustomer.name.trim()) return;
        try {
            await customersAPI.update(editingCustomer.id, editingCustomer);
            setEditingCustomer(null);
            setOpenEditDialog(false);
            loadCustomers();
            showSnackbar('Customer information updated successfully');
        } catch (error: any) {
            showSnackbar(error.response?.data?.detail || 'Error updating customer', 'error');
        }
    };

    const handleDeleteCustomer = async (id: number) => {
        if (!window.confirm('Are you sure you want to delete this customer?')) return;
        try {
            await customersAPI.delete(id);
            loadCustomers();
            showSnackbar('Customer deleted successfully');
        } catch (error: any) {
            showSnackbar(error.response?.data?.detail || 'Error deleting customer', 'error');
        }
    };

    const handleOpenHistory = async (customer: Customer) => {
        setSelectedCustomerHistory(customer);
        setOpenHistoryDialog(true);
        try {
            setHistoryLoading(true);
            const response = await ordersAPI.getAll({ customer_id: customer.id });
            setCustomerOrders(response.data || []);
        } catch (error) {
            console.error('Error loading customer history:', error);
            setCustomerOrders([]);
        } finally {
            setHistoryLoading(false);
        }
    };

    const [settleDialogOpen, setSettleDialogOpen] = useState(false);
    const [selectedCustomerForSettle, setSelectedCustomerForSettle] = useState<Customer | null>(null);
    const [settleAmount, setSettleAmount] = useState<string>('');

    const handleSettleDue = async () => {
        if (!selectedCustomerForSettle || !settleAmount) return;
        const amount = parseFloat(settleAmount);
        if (isNaN(amount) || amount <= 0) {
            showSnackbar('Please enter a valid amount', 'error');
            return;
        }

        try {
            const currentDue = selectedCustomerForSettle.due_amount || 0;
            const newDue = Math.max(0, currentDue - amount);

            await customersAPI.update(selectedCustomerForSettle.id, {
                due_amount: newDue
            });

            showSnackbar(`Payment of NPRs. ${amount} recorded for ${selectedCustomerForSettle.name}`);
            setSettleDialogOpen(false);
            setSettleAmount('');
            loadCustomers();
        } catch (error: any) {
            showSnackbar(error.response?.data?.detail || 'Error recording payment', 'error');
        }
    };

    const filteredCustomers = customers.filter(customer =>
        customer.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        customer.phone?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <Box>
            <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="h5" fontWeight={800}>Customer Database</Typography>
                <Button
                    variant="contained"
                    startIcon={<UserPlus size={18} />}
                    onClick={() => setOpenDialog(true)}
                    sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', borderRadius: '10px' }}
                >
                    Register New Customer
                </Button>
            </Box>

            <Paper sx={{ p: 2, mb: 3, borderRadius: '12px', display: 'flex', gap: 2 }}>
                <TextField
                    size="small"
                    placeholder="Search by name or phone..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    InputProps={{
                        startAdornment: (
                            <InputAdornment position="start">
                                <Search size={18} color="#64748b" />
                            </InputAdornment>
                        ),
                    }}
                    sx={{ flexGrow: 1 }}
                />
            </Paper>

            <TableContainer component={Paper} sx={{ borderRadius: '16px', boxShadow: '0 4px 20px rgba(0,0,0,0.02)' }}>
                <Table>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700 }}>Customer Name</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Contact Info</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Visits</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Total Spent</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Due Payment</TableCell>
                            <TableCell sx={{ fontWeight: 700 }} align="right">Actions</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={5} align="center" sx={{ py: 4 }}>
                                    <CircularProgress />
                                </TableCell>
                            </TableRow>
                        ) : filteredCustomers.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={5} align="center" sx={{ py: 4 }}>
                                    <Typography variant="body2" color="text.secondary">No customers found</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            filteredCustomers.map((customer) => {
                                const visits = customer.total_visits || 0;
                                const spent = customer.total_spent || 0;
                                const due = customer.due_amount || 0;
                                return (
                                    <TableRow key={customer.id} hover>
                                        <TableCell>
                                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                                <Avatar sx={{ bgcolor: '#fff7ed', color: '#FFC107', fontWeight: 700 }}>
                                                    {customer.name[0]?.toUpperCase()}
                                                </Avatar>
                                                <Box>
                                                    <Typography variant="subtitle2" fontWeight={700}>{customer.name}</Typography>
                                                    <Typography variant="caption" color="text.secondary">ID: #C00{customer.id}</Typography>
                                                </Box>
                                            </Box>
                                        </TableCell>
                                        <TableCell>
                                            <Box sx={{ display: 'flex', flexDirection: 'column' }}>
                                                {customer.phone && (
                                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                                                        <Phone size={12} color="#64748b" />
                                                        <Typography variant="body2">{customer.phone}</Typography>
                                                    </Box>
                                                )}
                                                {customer.email && <Typography variant="caption" color="text.secondary">{customer.email}</Typography>}
                                            </Box>
                                        </TableCell>
                                        <TableCell><Typography fontWeight={600}>{visits}</Typography></TableCell>
                                        <TableCell><Typography fontWeight={700} color="#10b981">NPRs. {Number(spent).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography></TableCell>
                                        <TableCell><Typography fontWeight={700} color={due > 0 ? "#ef4444" : "#64748b"}>NPRs. {Number(due).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography></TableCell>
                                        <TableCell align="right">
                                            <Box sx={{ display: 'flex', gap: 1, justifyContent: 'flex-end' }}>
                                                <IconButton size="small" onClick={() => { setSelectedCustomerForSettle(customer); setSettleAmount(''); setSettleDialogOpen(true); }} sx={{ color: '#10b981' }} title="Record Payment">
                                                    <Banknote size={16} />
                                                </IconButton>
                                                <IconButton size="small" onClick={() => { setEditingCustomer(customer); setOpenEditDialog(true); }} sx={{ color: '#64748b' }}><Edit2 size={16} /></IconButton>
                                                <IconButton size="small" onClick={() => handleDeleteCustomer(customer.id)} sx={{ color: '#ef4444' }}><Trash2 size={16} /></IconButton>
                                                <Button
                                                    variant="outlined"
                                                    size="small"
                                                    startIcon={<History size={14} />}
                                                    onClick={() => handleOpenHistory(customer)}
                                                    sx={{ textTransform: 'none', borderRadius: '8px', color: '#64748b', borderColor: '#e2e8f0' }}
                                                >
                                                    History
                                                </Button>
                                            </Box>
                                        </TableCell>
                                    </TableRow>
                                );
                            })
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            {/* Create Customer Dialog */}
            <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
                <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography fontWeight={800}>Register New Customer</Typography>
                    <IconButton onClick={() => setOpenDialog(false)} size="small"><X size={20} /></IconButton>
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
                        <TextField label="Customer Name *" fullWidth value={newCustomer.name} onChange={(e) => setNewCustomer({ ...newCustomer, name: e.target.value })} />
                        <TextField label="Phone Number" fullWidth value={newCustomer.phone} onChange={(e) => setNewCustomer({ ...newCustomer, phone: e.target.value })} />
                        <TextField label="Email" fullWidth type="email" value={newCustomer.email} onChange={(e) => setNewCustomer({ ...newCustomer, email: e.target.value })} />
                    </Box>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
                    <Button onClick={handleCreateCustomer} variant="contained" sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' } }}>Create Customer</Button>
                </DialogActions>
            </Dialog>

            {/* Edit Customer Dialog */}
            <Dialog open={openEditDialog} onClose={() => setOpenEditDialog(false)} maxWidth="sm" fullWidth>
                <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography fontWeight={800}>Edit Customer Information</Typography>
                    <IconButton onClick={() => setOpenEditDialog(false)} size="small"><X size={20} /></IconButton>
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
                        <TextField label="Customer Name *" fullWidth value={editingCustomer?.name || ''} onChange={(e) => editingCustomer && setEditingCustomer({ ...editingCustomer, name: e.target.value })} />
                        <TextField label="Phone Number" fullWidth value={editingCustomer?.phone || ''} onChange={(e) => editingCustomer && setEditingCustomer({ ...editingCustomer, phone: e.target.value })} />
                        <TextField label="Email" fullWidth type="email" value={editingCustomer?.email || ''} onChange={(e) => editingCustomer && setEditingCustomer({ ...editingCustomer, email: e.target.value })} />
                        <TextField label="Address" fullWidth multiline rows={2} value={editingCustomer?.address || ''} onChange={(e) => editingCustomer && setEditingCustomer({ ...editingCustomer, address: e.target.value })} />
                    </Box>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpenEditDialog(false)}>Cancel</Button>
                    <Button onClick={handleEditCustomer} variant="contained" sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' } }}>Update Customer</Button>
                </DialogActions>
            </Dialog>

            {/* History Dialog */}
            <Dialog open={openHistoryDialog} onClose={() => setOpenHistoryDialog(false)} maxWidth="md" fullWidth>
                <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #f1f5f9' }}>
                    <Box>
                        <Typography fontWeight={800}>Order History</Typography>
                        <Typography variant="body2" color="text.secondary">{selectedCustomerHistory?.name}</Typography>
                    </Box>
                    <IconButton onClick={() => setOpenHistoryDialog(false)} size="small"><X size={20} /></IconButton>
                </DialogTitle>
                <DialogContent sx={{ p: 0, bgcolor: '#f8fafc' }}>
                    {historyLoading ? (
                        <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}><CircularProgress /></Box>
                    ) : customerOrders.length === 0 ? (
                        <Box sx={{ py: 8, textAlign: 'center' }}>
                            <Typography color="text.secondary">No past orders found for this customer.</Typography>
                        </Box>
                    ) : (
                        <Box sx={{ p: 2 }}>
                            {customerOrders.map((order) => (
                                <Paper key={order.id} sx={{ p: 2, mb: 1.5, borderRadius: '12px', border: '1px solid #e2e8f0' }} elevation={0}>
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1.5 }}>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <Receipt size={16} color="#FFC107" />
                                            <Typography fontWeight={700}>#{order.order_number}</Typography>
                                            <Chip
                                                label={order.status}
                                                size="small"
                                                sx={{
                                                    height: 20,
                                                    fontSize: '10px',
                                                    fontWeight: 800,
                                                    bgcolor: order.status === 'Paid' ? '#dcfce7' : '#fef2f2',
                                                    color: order.status === 'Paid' ? '#16a34a' : '#ef4444'
                                                }}
                                            />
                                        </Box>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, color: '#64748b' }}>
                                            <Calendar size={14} />
                                            <Typography variant="caption">{new Date(order.created_at).toLocaleDateString()} {new Date(order.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</Typography>
                                        </Box>
                                    </Box>

                                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mb: 1.5 }}>
                                        {order.items?.map((item: any) => (
                                            <Chip key={item.id} label={`${item.quantity}x ${item.menu_item?.name}`} size="small" variant="outlined" sx={{ borderRadius: '6px', fontSize: '11px' }} />
                                        ))}
                                    </Box>

                                    <Divider sx={{ mb: 1.5, borderStyle: 'dashed' }} />

                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                        <Typography variant="body2" color="text.secondary">{order.order_type} Order</Typography>
                                        <Typography fontWeight={800} color="#1e293b">Total: NPRs. {Number(order.net_amount).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                                    </Box>
                                </Paper>
                            ))}
                        </Box>
                    )}
                </DialogContent>
                <DialogActions sx={{ p: 2, borderTop: '1px solid #f1f5f9' }}>
                    <Button onClick={() => setOpenHistoryDialog(false)} variant="contained" sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' } }}>Close</Button>
                </DialogActions>
            </Dialog>
            {/* Settle Due Dialog */}
            <Dialog open={settleDialogOpen} onClose={() => setSettleDialogOpen(false)} maxWidth="xs" fullWidth>
                <DialogTitle sx={{ borderBottom: '1px solid #f1f5f9' }}>
                    <Typography fontWeight={800}>Record Customer Payment</Typography>
                    <Typography variant="body2" color="text.secondary">For {selectedCustomerForSettle?.name}</Typography>
                </DialogTitle>
                <DialogContent sx={{ pt: 3 }}>
                    <Box sx={{ mb: 2, p: 2, bgcolor: '#fef2f2', borderRadius: '12px', border: '1px solid #fee2e2' }}>
                        <Typography variant="caption" color="error" fontWeight={700}>TOTAL OUTSTANDING DUE</Typography>
                        <Typography variant="h5" color="error" fontWeight={900}>
                            NPRs. {Number(selectedCustomerForSettle?.due_amount || 0).toLocaleString()}
                        </Typography>
                    </Box>
                    <TextField
                        fullWidth
                        label="Payment Amount"
                        type="number"
                        value={settleAmount}
                        onChange={(e) => setSettleAmount(e.target.value)}
                        autoFocus
                        InputProps={{
                            startAdornment: <Typography sx={{ mr: 1, fontWeight: 700, color: '#94a3b8' }}>NPRs.</Typography>,
                        }}
                    />
                </DialogContent>
                <DialogActions sx={{ p: 2, borderTop: '1px solid #f1f5f9' }}>
                    <Button onClick={() => setSettleDialogOpen(false)}>Cancel</Button>
                    <Button
                        onClick={handleSettleDue}
                        variant="contained"
                        sx={{ bgcolor: '#10b981', '&:hover': { bgcolor: '#059669' }, fontWeight: 700 }}
                    >
                        Receive Payment
                    </Button>
                </DialogActions>
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

export default Customers;

