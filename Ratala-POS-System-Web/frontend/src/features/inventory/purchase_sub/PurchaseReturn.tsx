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
import { purchaseAPI } from '../../../services/api';

const PurchaseReturn: React.FC = () => {
    const [returns, setReturns] = useState<any[]>([]);
    const [bills, setBills] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [openDialog, setOpenDialog] = useState(false);
    const [formData, setFormData] = useState({
        purchase_bill_id: '',
        total_amount: 0,
        reason: ''
    });

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setLoading(true);
            const [returnsRes, billsRes] = await Promise.all([
                purchaseAPI.getReturns(),
                purchaseAPI.getBills()
            ]);
            setReturns(returnsRes.data || []);
            setBills(billsRes.data || []);
        } catch (error) {
            console.error('Error loading data:', error);
            setReturns([]);
            setBills([]);
        } finally {
            setLoading(false);
        }
    };

    const handleOpenDialog = () => {
        setFormData({ purchase_bill_id: '', total_amount: 0, reason: '' });
        setOpenDialog(true);
    };

    const handleCloseDialog = () => {
        setOpenDialog(false);
        setFormData({ purchase_bill_id: '', total_amount: 0, reason: '' });
    };

    const handleSubmit = async () => {
        try {
            await purchaseAPI.createReturn(formData);
            handleCloseDialog();
            loadData();
        } catch (error) {
            console.error('Error creating return:', error);
            alert('Error creating return. Please try again.');
        }
    };

    return (
        <Box>
            <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b' }}>Purchase Returns</Typography>
                <Button
                    variant="contained"
                    startIcon={<Plus size={18} />}
                    onClick={handleOpenDialog}
                    sx={{ bgcolor: '#FF8C00', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', borderRadius: '10px' }}
                >
                    New Return
                </Button>
            </Box>

            <TableContainer component={Paper} sx={{ borderRadius: '16px' }}>
                <Table>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700 }}>Return Number</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Purchase Bill</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Total Amount</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Reason</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Date</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={5} align="center">Loading...</TableCell>
                            </TableRow>
                        ) : returns.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={5} align="center">No returns found. Create your first return to get started.</TableCell>
                            </TableRow>
                        ) : (
                            returns.map((ret) => (
                                <TableRow key={ret.id} hover>
                                    <TableCell sx={{ fontWeight: 600 }}>{ret.return_number || 'N/A'}</TableCell>
                                    <TableCell>{ret.purchase_bill?.bill_number || 'N/A'}</TableCell>
                                    <TableCell sx={{ fontWeight: 700 }}>NPRs. {ret.total_amount?.toLocaleString() || 0}</TableCell>
                                    <TableCell>{ret.reason || '-'}</TableCell>
                                    <TableCell>{new Date(ret.created_at).toLocaleDateString()}</TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
                <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography fontWeight={800}>New Purchase Return</Typography>
                    <IconButton onClick={handleCloseDialog} size="small">
                        <X size={20} />
                    </IconButton>
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
                        <TextField
                            select
                            label="Purchase Bill"
                            fullWidth
                            value={formData.purchase_bill_id}
                            onChange={(e) => setFormData({ ...formData, purchase_bill_id: e.target.value })}
                            required
                        >
                            {bills.map((bill) => (
                                <MenuItem key={bill.id} value={bill.id}>
                                    {bill.bill_number} - {bill.supplier?.name}
                                </MenuItem>
                            ))}
                        </TextField>
                        <TextField
                            label="Return Amount"
                            type="number"
                            fullWidth
                            value={formData.total_amount}
                            onChange={(e) => setFormData({ ...formData, total_amount: parseFloat(e.target.value) || 0 })}
                            required
                            inputProps={{ min: 0, step: 0.01 }}
                        />
                        <TextField
                            label="Reason"
                            multiline
                            rows={3}
                            fullWidth
                            value={formData.reason}
                            onChange={(e) => setFormData({ ...formData, reason: e.target.value })}
                        />
                        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2, mt: 2 }}>
                            <Button onClick={handleCloseDialog}>Cancel</Button>
                            <Button variant="contained" onClick={handleSubmit} sx={{ bgcolor: '#FF8C00' }}>
                                Create Return
                            </Button>
                        </Box>
                    </Box>
                </DialogContent>
            </Dialog>
        </Box>
    );
};

export default PurchaseReturn;

