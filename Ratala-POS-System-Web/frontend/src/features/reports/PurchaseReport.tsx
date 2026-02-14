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
    CircularProgress,
    Button,
    Grid,
    TextField,
    Breadcrumbs,
    Link as MuiLink,
    FormControl,
    InputLabel,
    Select,
    MenuItem,
} from '@mui/material';
import { ShoppingCart, Download, RotateCcw, ChevronRight } from 'lucide-react';
import { reportsAPI, purchaseAPI } from '../../services/api';
import { Link as RouterLink } from 'react-router-dom';

const PurchaseReport: React.FC = () => {
    const today = new Date().toISOString().split('T')[0];
    const [startDate, setStartDate] = useState(today);
    const [endDate, setEndDate] = useState(today);
    const [supplierId, setSupplierId] = useState<number | string>('');
    const [suppliers, setSuppliers] = useState<any[]>([]);
    const [loading, setLoading] = useState(false);
    const [data, setData] = useState<any[]>([]);
    const [summary, setSummary] = useState<any>(null);

    const loadData = async () => {
        try {
            setLoading(true);
            const response = await reportsAPI.getPurchaseReport({
                start_date: startDate,
                end_date: endDate,
                supplier_id: supplierId || undefined
            });
            setData(response.data.items);
            setSummary(response.data.summary);
        } catch (error) {
            console.error('Failed to load purchase report:', error);
        } finally {
            setLoading(false);
        }
    };

    const loadSuppliers = async () => {
        try {
            const response = await purchaseAPI.getSuppliers();
            setSuppliers(response.data);
        } catch (error) {
            console.error('Failed to load suppliers:', error);
        }
    };

    useEffect(() => {
        loadData();
        loadSuppliers();
    }, []);

    const handleReset = () => {
        setStartDate(today);
        setEndDate(today);
        setSupplierId('');
    };

    const handleExport = async () => {
        try {
            const response = await reportsAPI.exportExcel('purchase', { start_date: startDate, end_date: endDate });
            const url = window.URL.createObjectURL(new Blob([response.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `Purchase_Report_${startDate}.xlsx`);
            document.body.appendChild(link);
            link.click();
            link.remove();
        } catch (error) {
            console.error('Export failed:', error);
        }
    };

    return (
        <Box>
            <Breadcrumbs separator={<ChevronRight size={14} />} sx={{ mb: 2 }}>
                <MuiLink component={RouterLink} to="/reports" underline="hover" color="inherit">
                    Reports
                </MuiLink>
                <Typography color="text.primary" sx={{ fontWeight: 600 }}>Purchase Report</Typography>
            </Breadcrumbs>

            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h5" fontWeight={800} sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                    <ShoppingCart size={28} color="#ef4444" />
                    Purchase Report
                </Typography>
                <Box sx={{ display: 'flex', gap: 2 }}>
                    <Button
                        variant="outlined"
                        startIcon={<RotateCcw size={18} />}
                        onClick={handleReset}
                        sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600 }}
                    >
                        Reset
                    </Button>
                    <Button
                        variant="contained"
                        startIcon={<Download size={18} />}
                        onClick={handleExport}
                        sx={{
                            bgcolor: '#ef4444',
                            '&:hover': { bgcolor: '#dc2626' },
                            borderRadius: '10px',
                            textTransform: 'none',
                            fontWeight: 700,
                            boxShadow: '0 4px 12px rgba(239, 68, 68, 0.2)'
                        }}
                    >
                        Export Excel
                    </Button>
                </Box>
            </Box>

            <Paper sx={{ p: 3, borderRadius: '16px', border: '1px solid #f1f5f9', mb: 4 }} elevation={0}>
                <Grid container spacing={3} alignItems="center">
                    <Grid size={{ xs: 12, sm: 3 }}>
                        <TextField
                            fullWidth
                            label="Start Date"
                            type="date"
                            value={startDate}
                            onChange={(e) => setStartDate(e.target.value)}
                            InputLabelProps={{ shrink: true }}
                            sx={{ '& .MuiOutlinedInput-root': { borderRadius: '10px' } }}
                        />
                    </Grid>
                    <Grid size={{ xs: 12, sm: 3 }}>
                        <TextField
                            fullWidth
                            label="End Date"
                            type="date"
                            value={endDate}
                            onChange={(e) => setEndDate(e.target.value)}
                            InputLabelProps={{ shrink: true }}
                            sx={{ '& .MuiOutlinedInput-root': { borderRadius: '10px' } }}
                        />
                    </Grid>
                    <Grid size={{ xs: 12, sm: 3 }}>
                        <FormControl fullWidth sx={{ '& .MuiOutlinedInput-root': { borderRadius: '10px' } }}>
                            <InputLabel>Supplier</InputLabel>
                            <Select
                                value={supplierId}
                                label="Supplier"
                                onChange={(e) => setSupplierId(e.target.value)}
                            >
                                <MenuItem value="">All Suppliers</MenuItem>
                                {suppliers.map(s => (
                                    <MenuItem key={s.id} value={s.id}>{s.name}</MenuItem>
                                ))}
                            </Select>
                        </FormControl>
                    </Grid>
                    <Grid size={{ xs: 12, sm: 3 }}>
                        <Button
                            fullWidth
                            variant="contained"
                            onClick={loadData}
                            sx={{
                                height: '56px',
                                bgcolor: '#000',
                                '&:hover': { bgcolor: '#333' },
                                borderRadius: '10px',
                                textTransform: 'none',
                                fontWeight: 700
                            }}
                        >
                            Generate Report
                        </Button>
                    </Grid>
                </Grid>
            </Paper>

            {summary && (
                <Grid container spacing={2} sx={{ mb: 3 }}>
                    <Grid size={{ xs: 12, sm: 4 }}>
                        <Paper sx={{ p: 2.5, borderRadius: '12px', border: '1px solid #f1f5f9', bgcolor: '#fff' }} elevation={0}>
                            <Typography variant="caption" fontWeight={700} color="text.secondary" sx={{ display: 'block', mb: 1, textTransform: 'uppercase' }}>Total Bills</Typography>
                            <Typography variant="h4" fontWeight={800} color="#6366f1">{summary.total_bills || 0}</Typography>
                        </Paper>
                    </Grid>
                    <Grid size={{ xs: 12, sm: 4 }}>
                        <Paper sx={{ p: 2.5, borderRadius: '12px', border: '1px solid #f1f5f9', bgcolor: '#fff' }} elevation={0}>
                            <Typography variant="caption" fontWeight={700} color="text.secondary" sx={{ display: 'block', mb: 1, textTransform: 'uppercase' }}>Total Payable</Typography>
                            <Typography variant="h4" fontWeight={800} color="#ef4444">NPR {summary.total_payable.toLocaleString(undefined, { minimumFractionDigits: 2 })}</Typography>
                        </Paper>
                    </Grid>
                    <Grid size={{ xs: 12, sm: 4 }}>
                        <Paper sx={{ p: 2.5, borderRadius: '12px', border: '1px solid #f1f5f9', bgcolor: '#fff' }} elevation={0}>
                            <Typography variant="caption" fontWeight={700} color="text.secondary" sx={{ display: 'block', mb: 1, textTransform: 'uppercase' }}>Total Paid</Typography>
                            <Typography variant="h4" fontWeight={800} color="#10b981">NPR {summary.total_paid.toLocaleString(undefined, { minimumFractionDigits: 2 })}</Typography>
                        </Paper>
                    </Grid>
                </Grid>
            )}

            <TableContainer component={Paper} sx={{ borderRadius: '16px', border: '1px solid #f1f5f9' }} elevation={0}>
                <Table sx={{ minWidth: 1000 }}>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700 }}>BILL #</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>DATE</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>SUPPLIER NAME</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>PAYABLE</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>PAID</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>STATUS</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>PAID BY</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={7} align="center" sx={{ py: 10 }}>
                                    <CircularProgress sx={{ color: '#ef4444' }} />
                                </TableCell>
                            </TableRow>
                        ) : data.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={7} align="center" sx={{ py: 10 }}>
                                    <Typography color="text.secondary">No records found for the selected period</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            data.map((row, idx) => (
                                <TableRow key={idx} hover>
                                    <TableCell sx={{ fontWeight: 700, color: '#1e293b' }}>{row.bill_number}</TableCell>
                                    <TableCell sx={{ fontWeight: 600 }}>{row.date}</TableCell>
                                    <TableCell>{row.supplier_name}</TableCell>
                                    <TableCell sx={{ fontWeight: 700 }}>{row.payable.toLocaleString(undefined, { minimumFractionDigits: 2 })}</TableCell>
                                    <TableCell sx={{ color: '#10b981', fontWeight: 600 }}>{row.paid.toLocaleString(undefined, { minimumFractionDigits: 2 })}</TableCell>
                                    <TableCell>
                                        <Box sx={{
                                            display: 'inline-block',
                                            px: 1.5,
                                            py: 0.5,
                                            borderRadius: '6px',
                                            fontSize: '0.75rem',
                                            fontWeight: 700,
                                            bgcolor: row.status === 'Paid' ? '#ecfdf5' : '#fff7ed',
                                            color: row.status === 'Paid' ? '#059669' : '#c2410c'
                                        }}>
                                            {row.status.toUpperCase()}
                                        </Box>
                                    </TableCell>
                                    <TableCell>{row.paid_by}</TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>
        </Box>
    );
};

export default PurchaseReport;
