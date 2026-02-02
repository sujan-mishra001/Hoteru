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
    IconButton
} from '@mui/material';
import { UserPlus, Search, Phone, History, X, Edit2, Trash2 } from 'lucide-react';
import { customersAPI } from '../../services/api';

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
        } catch (error: any) {
            alert(error.response?.data?.detail || 'Error creating customer');
        }
    };

    const handleEditCustomer = async () => {
        if (!editingCustomer || !editingCustomer.name.trim()) return;
        try {
            await customersAPI.update(editingCustomer.id, editingCustomer);
            setEditingCustomer(null);
            setOpenEditDialog(false);
            loadCustomers();
        } catch (error: any) {
            alert(error.response?.data?.detail || 'Error updating customer');
        }
    };

    const handleDeleteCustomer = async (id: number) => {
        if (!window.confirm('Are you sure you want to delete this customer?')) return;
        try {
            await customersAPI.delete(id);
            loadCustomers();
        } catch (error: any) {
            alert(error.response?.data?.detail || 'Error deleting customer');
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
                    sx={{ bgcolor: '#FF8C00', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', borderRadius: '10px' }}
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
                                                <Avatar sx={{ bgcolor: '#fff7ed', color: '#FF8C00', fontWeight: 700 }}>
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
                                        <TableCell><Typography fontWeight={700} color="#10b981">NPRs. {spent.toLocaleString()}</Typography></TableCell>
                                        <TableCell><Typography fontWeight={700} color={due > 0 ? "#ef4444" : "#64748b"}>NPRs. {due.toLocaleString()}</Typography></TableCell>
                                        <TableCell align="right">
                                            <Box sx={{ display: 'flex', gap: 1, justifyContent: 'flex-end' }}>
                                                <IconButton size="small" onClick={() => { setEditingCustomer(customer); setOpenEditDialog(true); }} sx={{ color: '#64748b' }}><Edit2 size={16} /></IconButton>
                                                <IconButton size="small" onClick={() => handleDeleteCustomer(customer.id)} sx={{ color: '#ef4444' }}><Trash2 size={16} /></IconButton>
                                                <Button variant="outlined" size="small" startIcon={<History size={14} />} sx={{ textTransform: 'none', borderRadius: '8px', color: '#64748b', borderColor: '#e2e8f0' }}>History</Button>
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
                    <Button onClick={handleCreateCustomer} variant="contained" sx={{ bgcolor: '#FF8C00', '&:hover': { bgcolor: '#FF7700' } }}>Create Customer</Button>
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
                    <Button onClick={handleEditCustomer} variant="contained" sx={{ bgcolor: '#FF8C00', '&:hover': { bgcolor: '#FF7700' } }}>Update Customer</Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default Customers;
