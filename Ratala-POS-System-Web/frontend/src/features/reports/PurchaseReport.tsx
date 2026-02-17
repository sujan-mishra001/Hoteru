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
    Breadcrumbs,
    Link as MuiLink,
} from '@mui/material';
import { ShoppingCart, RotateCcw, ChevronRight } from 'lucide-react';
import { reportsAPI } from '../../services/api';
import { Link as RouterLink, useParams } from 'react-router-dom';

const PurchaseReport: React.FC = () => {
    const { branchSlug } = useParams();
    const today = new Date().toISOString().split('T')[0];
    const startDate = today;
    const endDate = today;
    const [loading, setLoading] = useState(false);
    const [data, setData] = useState<any[]>([]);
    const [summary, setSummary] = useState<any>(null);

    const loadData = async () => {
        try {
            setLoading(true);
            const response = await reportsAPI.getPurchaseReport({
                start_date: startDate,
                end_date: endDate,
            });
            setData(response.data.items);
            setSummary(response.data.summary);
        } catch (error) {
            console.error('Failed to load purchase report:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadData();
    }, []);

    return (
        <Box>
            <Breadcrumbs separator={<ChevronRight size={14} />} sx={{ mb: 2 }}>
                <MuiLink component={RouterLink} to={`/${branchSlug}/reports`} underline="hover" color="inherit">
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
                        onClick={loadData}
                        sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600 }}
                    >
                        Refresh
                    </Button>
                </Box>
            </Box>

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
