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
import { Book, RotateCcw, ChevronRight } from 'lucide-react';
import { reportsAPI } from '../../services/api';
import { Link as RouterLink, useParams } from 'react-router-dom';

const DaybookReport: React.FC = () => {
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
            const response = await reportsAPI.getDayBook({ start_date: startDate, end_date: endDate });
            setData(response.data.items);
            setSummary(response.data.summary);
        } catch (error) {
            console.error('Failed to load daybook:', error);
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
                <Typography color="text.primary" sx={{ fontWeight: 600 }}>Daybook Report</Typography>
            </Breadcrumbs>

            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h5" fontWeight={800} sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                    <Book size={28} color="#10b981" />
                    Daybook Report
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
                    <Grid size={{ xs: 12, sm: 6 }}>
                        <Paper sx={{ p: 3, borderRadius: '12px', border: '1px solid #f1f5f9', bgcolor: '#f0fdf4' }} elevation={0}>
                            <Typography variant="caption" fontWeight={700} color="#16a34a" sx={{ display: 'block', mb: 1 }}>TOTAL PAID</Typography>
                            <Typography variant="h4" fontWeight={800} color="#15803d">{summary.total_paid.toLocaleString(undefined, { minimumFractionDigits: 2 })}</Typography>
                        </Paper>
                    </Grid>
                    <Grid size={{ xs: 12, sm: 6 }}>
                        <Paper sx={{ p: 3, borderRadius: '12px', border: '1px solid #f1f5f9', bgcolor: '#eff6ff' }} elevation={0}>
                            <Typography variant="caption" fontWeight={700} color="#2563eb" sx={{ display: 'block', mb: 1 }}>TOTAL RECEIVED</Typography>
                            <Typography variant="h4" fontWeight={800} color="#1d4ed8">{summary.total_received.toLocaleString(undefined, { minimumFractionDigits: 2 })}</Typography>
                        </Paper>
                    </Grid>
                </Grid>
            )}

            <TableContainer component={Paper} sx={{ borderRadius: '16px', border: '1px solid #f1f5f9' }} elevation={0}>
                <Table sx={{ minWidth: 600 }}>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700 }}>DATE</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>PAID</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>RECEIVED</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>BALANCE</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={4} align="center" sx={{ py: 10 }}>
                                    <CircularProgress sx={{ color: '#10b981' }} />
                                </TableCell>
                            </TableRow>
                        ) : data.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={4} align="center" sx={{ py: 10 }}>
                                    <Typography color="text.secondary">No records found</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            data.map((row, idx) => (
                                <TableRow key={idx} hover>
                                    <TableCell sx={{ fontWeight: 600 }}>{row.date}</TableCell>
                                    <TableCell sx={{ color: '#ef4444' }}>{row.paid.toLocaleString(undefined, { minimumFractionDigits: 2 })}</TableCell>
                                    <TableCell sx={{ color: '#10b981' }}>{row.received.toLocaleString(undefined, { minimumFractionDigits: 2 })}</TableCell>
                                    <TableCell sx={{ fontWeight: 700 }}>{row.balance.toLocaleString(undefined, { minimumFractionDigits: 2 })}</TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>
        </Box>
    );
};

export default DaybookReport;
