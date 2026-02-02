import React, { useState, useEffect } from 'react';
import {
    Box,
    Typography,
    Paper,
    Grid,
    Button,
    Card,
    CardContent,
    CircularProgress,
    Divider
} from '@mui/material';
import {
    Download,
    TrendingUp,
    DollarSign,
    ShoppingCart,
    FileText,
    BarChart3,
    Calendar,
    ChevronRight,
    FileSpreadsheet,
    Wallet,
    CreditCard
} from 'lucide-react';
import { reportsAPI } from '../../services/api';
import { useNavigate } from 'react-router-dom';
import { PeakTimeChart } from '../../components/dashboard/OverviewCards';
import { useBranch } from '../../app/providers/BranchProvider';

const Reports: React.FC = () => {
    const [loading, setLoading] = useState(false);
    const [summary, setSummary] = useState<any>(null);
    const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
    const navigate = useNavigate();
    const { currentBranch } = useBranch();

    const fetchSummary = async (date?: string) => {
        try {
            setLoading(true);
            const res = await reportsAPI.getDashboardSummary({
                start_date: date || selectedDate,
                end_date: date || selectedDate
            });
            setSummary(res.data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchSummary();
    }, [selectedDate]);

    const reportTypes = [
        { name: 'Daily Sales Report', icon: <DollarSign />, description: 'Summary of sales, tax, and discounts for today', type: 'sales' },
        { name: 'Inventory Consumption', icon: <ShoppingCart />, description: 'Track stock usage and low inventory items', type: 'inventory' },
        { name: 'Customer Analytics', icon: <BarChart3 />, description: 'Visit frequency and total spending by customer', type: 'customers' },
        { name: 'Staff Performance', icon: <FileText />, description: 'Orders processed and items served per staff', type: 'staff' },
        { name: 'Session Report', icon: <Calendar />, description: 'View all POS sessions, sales, and staff activity', type: 'sessions', navigateTo: '/reports/sessions' },
    ];

    const handleExport = async (type: string, format: 'pdf' | 'excel') => {
        try {
            const report = reportTypes.find(r => r.type === type);
            const reportName = report ? report.name.replace(/\s+/g, '_') : type;
            const dateStr = selectedDate === new Date().toISOString().split('T')[0] ? 'Today' : selectedDate;
            const filename = `${reportName}_${dateStr}`;

            // Special handling for sessions PDF export
            if (type === 'sessions' && format === 'pdf') {
                const res = await reportsAPI.exportSessionsPDF();
                const url = window.URL.createObjectURL(new Blob([res.data]));
                const link = document.createElement('a');
                link.href = url;
                link.setAttribute('download', `${filename}.pdf`);
                document.body.appendChild(link);
                link.click();
                link.remove();
                return;
            }

            const params = type === 'sales' ? { start_date: selectedDate, end_date: selectedDate } : {};

            const res = format === 'pdf'
                ? await reportsAPI.exportPDF(type, params)
                : await reportsAPI.exportExcel(type, params);

            const url = window.URL.createObjectURL(new Blob([res.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `${filename}.${format === 'pdf' ? 'pdf' : 'xlsx'}`);
            document.body.appendChild(link);
            link.click();
            link.remove();
        } catch (err) {
            alert('Failed to export report');
        }
    };

    const handleExportAll = async () => {
        try {
            const res = await reportsAPI.exportAllExcel();
            const url = window.URL.createObjectURL(new Blob([res.data]));
            const link = document.createElement('a');
            link.href = url;
            const prefix = currentBranch?.name?.replace(/\s+/g, '_') || 'Business';
            const filename = `${prefix}_Full_Business_Report_${new Date().toISOString().split('T')[0]}`;
            link.setAttribute('download', `${filename}.xlsx`);
            document.body.appendChild(link);
            link.click();
            link.remove();
        } catch (err) {
            alert('Failed to export all reports');
        }
    };

    if (loading && !summary) return (
        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '60vh' }}>
            <CircularProgress sx={{ color: '#FF8C00' }} />
            <Typography sx={{ mt: 2, color: 'text.secondary' }}>Preparing your business reports...</Typography>
        </Box>
    );

    return (
        <Box sx={{ p: { xs: 1, md: 0 } }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 4, flexDirection: { xs: 'column', sm: 'row' }, gap: 2 }}>
                <Box>
                    <Typography variant="h4" fontWeight={900} color="#2C1810">Intelligence <span style={{ color: '#FF8C00' }}>Center</span></Typography>
                    <Typography variant="body1" color="text.secondary">Comprehensive analytics and data exports for your restaurant</Typography>
                </Box>
                <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', flexWrap: 'wrap' }}>
                    <Box sx={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 2,
                        bgcolor: 'white',
                        p: 1.5,
                        px: 3,
                        borderRadius: '16px',
                        border: '1px solid #e2e8f0',
                        boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
                        transition: 'all 0.2s',
                        '&:hover': {
                            borderColor: '#FF8C00',
                            boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)'
                        }
                    }}>
                        <Calendar size={20} color="#FF8C00" />
                        <Box sx={{ display: 'flex', flexDirection: 'column' }}>
                            <Typography variant="caption" sx={{ color: '#64748b', fontWeight: 700, textTransform: 'uppercase', fontSize: '0.65rem', mb: -0.5 }}>Reporting Date</Typography>
                            <input
                                type="date"
                                value={selectedDate}
                                onChange={(e) => setSelectedDate(e.target.value)}
                                style={{
                                    border: 'none',
                                    background: 'transparent',
                                    fontSize: '1rem',
                                    fontWeight: 700,
                                    color: '#1e293b',
                                    outline: 'none',
                                    cursor: 'pointer',
                                    fontFamily: 'inherit',
                                    padding: '4px 0'
                                }}
                            />
                        </Box>
                    </Box>
                    <Button
                        variant="contained"
                        startIcon={<FileSpreadsheet size={18} />}
                        onClick={handleExportAll}
                        sx={{
                            borderRadius: '12px',
                            textTransform: 'none',
                            bgcolor: '#10b981',
                            fontWeight: 700,
                            '&:hover': { bgcolor: '#059669' }
                        }}
                    >
                        Export Master Excel
                    </Button>
                </Box>
            </Box>

            <Grid container spacing={3} sx={{ mb: 4 }}>
                <Grid size={{ xs: 12, sm: 6, md: 3 }}>
                    <SummaryCard
                        title="Gross Sales"
                        value={`NPRs. ${summary?.sales_24h?.toLocaleString() || '0'}`}
                        icon={<TrendingUp size={20} />}
                        color="#FF8C00"
                        subtitle={`On ${selectedDate === new Date().toISOString().split('T')[0] ? 'Today' : selectedDate}`}
                    />
                </Grid>
                <Grid size={{ xs: 12, sm: 6, md: 3 }}>
                    <SummaryCard
                        title="Cash Collection"
                        value={`NPRs. ${summary?.paid_sales?.toLocaleString() || '0'}`}
                        icon={<Wallet size={20} />}
                        color="#10b981"
                        subtitle={`From ${summary?.orders_24h || 0} Orders on ${selectedDate === new Date().toISOString().split('T')[0] ? 'Today' : selectedDate}`}
                    />
                </Grid>
                <Grid size={{ xs: 12, sm: 6, md: 3 }}>
                    <SummaryCard
                        title="Credit Sales"
                        value={`NPRs. ${summary?.credit_sales?.toLocaleString() || '0'}`}
                        icon={<CreditCard size={20} />}
                        color="#ef4444"
                        subtitle={`Dues as of ${selectedDate === new Date().toISOString().split('T')[0] ? 'Today' : selectedDate}`}
                    />
                </Grid>
                <Grid size={{ xs: 12, sm: 6, md: 3 }}>
                    <SummaryCard
                        title="Avg. Order Value"
                        value={`NPRs. ${summary?.orders_24h > 0 ? Math.round(summary.sales_24h / summary.orders_24h).toLocaleString() : '0'}`}
                        icon={<BarChart3 size={20} />}
                        color="#3b82f6"
                        subtitle={`Efficiency on ${selectedDate === new Date().toISOString().split('T')[0] ? 'Today' : selectedDate}`}
                    />
                </Grid>
            </Grid>

            <Grid container spacing={3} sx={{ mb: 4 }}>
                <Grid size={{ xs: 12, lg: 8 }}>
                    <PeakTimeChart
                        data={summary?.peak_time_data || []}
                        salesData={summary?.hourly_sales || []}
                    />
                </Grid>
                <Grid size={{ xs: 12, lg: 4 }}>
                    <Paper sx={{ p: 3, borderRadius: '16px', border: '1px solid #f1f5f9', height: '100%' }} elevation={0}>
                        <Typography variant="h6" fontWeight={800} sx={{ mb: 2 }}>Quick Actions</Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                            <ActionItem
                                title="View Live Sessions"
                                description="Real-time staff activity"
                                onClick={() => navigate('/reports/sessions')}
                            />
                            <ActionItem
                                title="Sales History"
                                description="Search previous orders"
                                onClick={() => navigate('/orders')}
                            />
                            <ActionItem
                                title="Settings"
                                description="Adjust report parameters"
                                onClick={() => navigate('/settings')}
                            />
                        </Box>
                    </Paper>
                </Grid>
            </Grid>

            <Typography variant="h5" fontWeight={900} sx={{ mb: 3 }}>Available Data Exports</Typography>
            <Grid container spacing={3}>
                {reportTypes.map((report) => (
                    <Grid size={{ xs: 12, md: 6, lg: 4 }} key={report.name}>
                        <Paper
                            sx={{
                                p: 3,
                                borderRadius: '20px',
                                border: '1px solid #f1f5f9',
                                transition: 'all 0.2s',
                                '&:hover': {
                                    borderColor: '#FF8C00',
                                    bgcolor: '#fffbf5',
                                    transform: 'translateY(-2px)',
                                    boxShadow: '0 10px 15px -3px rgba(0,0,0,0.04)'
                                }
                            }}
                            elevation={0}
                        >
                            <Box sx={{ display: 'flex', gap: 2, mb: 2 }}>
                                <Box sx={{ p: 1.5, bgcolor: '#fff', borderRadius: '12px', color: '#FF8C00', boxShadow: '0 2px 8px rgba(0,0,0,0.05)', display: 'flex' }}>
                                    {report.icon}
                                </Box>
                                <Box>
                                    <Typography fontWeight={800} color="#2C1810">{report.name}</Typography>
                                    <Typography variant="caption" color="text.secondary">{report.description}</Typography>
                                </Box>
                            </Box>

                            <Divider sx={{ my: 2, opacity: 0.5 }} />

                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <Box sx={{ display: 'flex', gap: 1 }}>
                                    <Button
                                        size="small"
                                        startIcon={<Download size={14} />}
                                        sx={{
                                            textTransform: 'none',
                                            color: '#64748b',
                                            fontWeight: 600,
                                            borderRadius: '8px',
                                            '&:hover': { bgcolor: '#fff', color: '#FF8C00' }
                                        }}
                                        onClick={() => handleExport(report.type, 'pdf')}
                                    >
                                        PDF
                                    </Button>
                                    <Button
                                        size="small"
                                        startIcon={<FileSpreadsheet size={14} />}
                                        sx={{
                                            textTransform: 'none',
                                            color: '#64748b',
                                            fontWeight: 600,
                                            borderRadius: '8px',
                                            '&:hover': { bgcolor: '#fff', color: '#10b981' }
                                        }}
                                        onClick={() => handleExport(report.type, 'excel')}
                                    >
                                        Excel
                                    </Button>
                                </Box>
                                {report.navigateTo && (
                                    <Button
                                        size="small"
                                        endIcon={<ChevronRight size={14} />}
                                        onClick={() => navigate(report.navigateTo!)}
                                        sx={{ textTransform: 'none', fontWeight: 700, borderRadius: '8px', color: '#FF8C00' }}
                                    >
                                        View
                                    </Button>
                                )}
                            </Box>
                        </Paper>
                    </Grid>
                ))}
            </Grid>
        </Box>
    );
};

const SummaryCard = ({ title, value, icon, color, subtitle }: any) => (
    <Card sx={{ borderRadius: '20px', border: '1px solid #f1f5f9', bgcolor: '#fff', overflow: 'hidden' }} elevation={0}>
        <CardContent sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                <Typography variant="body2" fontWeight={700} color="text.secondary">{title}</Typography>
                <Box sx={{ p: 1, borderRadius: '10px', bgcolor: `${color}10`, color: color }}>
                    {icon}
                </Box>
            </Box>
            <Typography variant="h5" fontWeight={900} color="#2C1810">{value}</Typography>
            <Typography variant="caption" color="text.secondary" sx={{ mt: 0.5, display: 'block' }}>{subtitle}</Typography>
        </CardContent>
    </Card>
);

const ActionItem = ({ title, description, onClick }: any) => (
    <Box
        onClick={onClick}
        sx={{
            p: 2,
            borderRadius: '12px',
            bgcolor: '#f8fafc',
            cursor: 'pointer',
            transition: 'all 0.2s',
            border: '1px solid transparent',
            '&:hover': { bgcolor: '#fff', borderColor: '#FF8C00', transform: 'translateX(4px)' }
        }}
    >
        <Typography variant="subtitle2" fontWeight={800}>{title}</Typography>
        <Typography variant="caption" color="text.secondary">{description}</Typography>
    </Box>
);



export default Reports;
