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
} from '@mui/material';
import { Calendar, Download, RotateCcw, ChevronRight } from 'lucide-react';
import { reportsAPI } from '../../services/api';
import { Link as RouterLink } from 'react-router-dom';

interface DailySaleItem {
    date: string;
    gross_total: number;
    discount: number;
    complementary: number;
    delivery_commission: number;
    net_total: number;
    paid: number;
    credit_sales: number;
    net_delivery: number;
    credit_service: number;
    cash: number;
    fonepay: number;
    esewa: number;
}

interface SummaryData {
    gross_sales: number;
    discount: number;
    complementary: number;
    delivery_commission: number;
    net_sales: number;
    paid_sales: number;
    credit_sales: number;
    net_delivery: number;
}

const DailySalesReport: React.FC = () => {
    const today = new Date().toISOString().split('T')[0];
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

    const [startDate, setStartDate] = useState(thirtyDaysAgo);
    const [endDate, setEndDate] = useState(today);
    const [loading, setLoading] = useState(false);
    const [data, setData] = useState<DailySaleItem[]>([]);
    const [summary, setSummary] = useState<SummaryData | null>(null);

    const loadData = async () => {
        try {
            setLoading(true);
            const response = await reportsAPI.getDailySales({ start_date: startDate, end_date: endDate });
            setData(response.data.items);
            setSummary(response.data.summary);
        } catch (error) {
            console.error('Failed to load daily sales:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadData();
    }, []);

    const handleReset = () => {
        setStartDate(thirtyDaysAgo);
        setEndDate(today);
    };

    const handleExport = async () => {
        try {
            const response = await reportsAPI.exportExcel('sales', { start_date: startDate, end_date: endDate });
            const url = window.URL.createObjectURL(new Blob([response.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `Daily_Sales_Report_${startDate}_to_${endDate}.xlsx`);
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
                <Typography color="text.primary" sx={{ fontWeight: 600 }}>Daily Sales Report</Typography>
            </Breadcrumbs>

            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h5" fontWeight={800} sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                    <Calendar size={28} color="#FFC107" />
                    Daily Sales Report
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
                            bgcolor: '#FFC107',
                            '&:hover': { bgcolor: '#FF9800' },
                            borderRadius: '10px',
                            textTransform: 'none',
                            fontWeight: 700,
                            boxShadow: '0 4px 12px rgba(255, 193, 7, 0.2)'
                        }}
                    >
                        Export Excel
                    </Button>
                </Box>
            </Box>

            <Paper sx={{ p: 3, borderRadius: '16px', border: '1px solid #f1f5f9', mb: 4 }} elevation={0}>
                <Grid container spacing={3} alignItems="center">
                    <Grid size={{ xs: 12, sm: 4 }}>
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
                    <Grid size={{ xs: 12, sm: 4 }}>
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
                    <Grid size={{ xs: 12, sm: 4 }}>
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
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: 'repeat(2, 1fr)', sm: 'repeat(4, 1fr)', lg: 'repeat(8, 1fr)' }, gap: 1.5, mb: 3 }}>
                    {[
                        { label: 'GROSS SALES', value: summary.gross_sales, color: '#64748b' },
                        { label: 'DISCOUNT', value: summary.discount, color: '#ef4444' },
                        { label: 'COMPLEMENTARY', value: summary.complementary, color: '#3b82f6' },
                        { label: 'DEL. COMMISSION', value: summary.delivery_commission, color: '#f59e0b' },
                        { label: 'NET SALES', value: summary.net_sales, color: '#10b981' },
                        { label: 'PAID SALES', value: summary.paid_sales, color: '#22c55e' },
                        { label: 'CREDIT SALES', value: summary.credit_sales, color: '#6366f1' },
                        { label: 'NET DELIVERY', value: summary.net_delivery, color: '#8b5cf6' },
                    ].map((card, idx) => (
                        <Paper key={idx} sx={{ p: 1.5, borderRadius: '12px', border: '1px solid #f1f5f9', textAlign: 'center' }} elevation={0}>
                            <Typography variant="caption" fontWeight={700} color="text.secondary" sx={{ display: 'block', mb: 0.5, fontSize: '0.65rem' }}>
                                {card.label}
                            </Typography>
                            <Typography variant="body1" fontWeight={800} color={card.color}>
                                {card.value.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 })}
                            </Typography>
                        </Paper>
                    ))}
                </Box>
            )}

            <TableContainer component={Paper} sx={{ borderRadius: '16px', border: '1px solid #f1f5f9' }} elevation={0}>
                <Table sx={{ minWidth: 1200 }}>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700 }}>DATE</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>GROSS TOTAL</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>DISCOUNT</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>COMPLEMENTARY</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>DEL. COMMISSION</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>NET TOTAL</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>PAID</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>CREDIT SALES</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>NET DELIVERY</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>CASH</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>FONEPAY</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>ESEWA</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={12} align="center" sx={{ py: 10 }}>
                                    <CircularProgress sx={{ color: '#FFC107' }} />
                                </TableCell>
                            </TableRow>
                        ) : data.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={12} align="center" sx={{ py: 10 }}>
                                    <Typography color="text.secondary">No records found for the selected period</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            data.map((row, idx) => (
                                <TableRow key={idx} hover>
                                    <TableCell sx={{ fontWeight: 600 }}>{row.date}</TableCell>
                                    <TableCell>{row.gross_total.toLocaleString()}</TableCell>
                                    <TableCell color="error.main">{row.discount.toLocaleString()}</TableCell>
                                    <TableCell>{row.complementary.toLocaleString()}</TableCell>
                                    <TableCell>{row.delivery_commission.toLocaleString()}</TableCell>
                                    <TableCell sx={{ fontWeight: 700 }}>{row.net_total.toLocaleString()}</TableCell>
                                    <TableCell sx={{ color: '#22c55e', fontWeight: 600 }}>{row.paid.toLocaleString()}</TableCell>
                                    <TableCell sx={{ color: '#ef4444' }}>{row.credit_sales.toLocaleString()}</TableCell>
                                    <TableCell>{row.net_delivery.toLocaleString()}</TableCell>
                                    <TableCell>{row.cash.toLocaleString()}</TableCell>
                                    <TableCell>{row.fonepay.toLocaleString()}</TableCell>
                                    <TableCell>{row.esewa.toLocaleString()}</TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>
        </Box>
    );
};

export default DailySalesReport;
