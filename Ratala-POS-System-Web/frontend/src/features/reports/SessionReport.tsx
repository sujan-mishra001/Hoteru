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
    Chip,
    CircularProgress,
    IconButton,
    Tooltip,
    Button,
    Snackbar,
    Alert,
    Breadcrumbs,
    Link as MuiLink
} from '@mui/material';
import { Calendar, User, Clock, DollarSign, FileText, ChevronRight } from 'lucide-react';
import { reportsAPI } from '../../services/api';
import { useParams, Link as RouterLink } from 'react-router-dom';

interface Session {
    id: number;
    user_id: number;
    user?: {
        full_name: string;
        role: string;
    };
    start_time: string;
    end_time: string | null;
    status: string;
    opening_cash: number;
    actual_cash: number;
    expected_cash: number;
    total_sales: number;
    total_orders: number;
    notes: string | null;
}

const SessionReport: React.FC = () => {
    const { branchSlug } = useParams();
    const [sessions, setSessions] = useState<Session[]>([]);
    const [loading, setLoading] = useState(true);
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

    const showSnackbar = (message: string, severity: 'success' | 'error' = 'success') => {
        setSnackbar({ open: true, message, severity });
    };

    useEffect(() => {
        loadSessions();
    }, []);

    const loadSessions = async () => {
        try {
            setLoading(true);
            const response = await reportsAPI.getSessions();
            setSessions(response.data);
        } catch (error) {
            console.error('Failed to load sessions:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleExportPDF = async () => {
        try {
            const response = await reportsAPI.exportSessionsPDF();
            const url = window.URL.createObjectURL(new Blob([response.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', 'session_report.pdf');
            document.body.appendChild(link);
            link.click();
            link.remove();
            window.URL.revokeObjectURL(url);
            showSnackbar('Session report exported successfully');
        } catch (error) {
            console.error('Failed to export PDF:', error);
            showSnackbar('Failed to export session report', 'error');
        }
    };

    const handleExportShift = async (sessionId: number) => {
        try {
            const response = await reportsAPI.exportShiftReport(sessionId);
            const url = window.URL.createObjectURL(new Blob([response.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `shift_report_${sessionId}.pdf`);
            document.body.appendChild(link);
            link.click();
            link.remove();
            window.URL.revokeObjectURL(url);
            showSnackbar('Shift report exported successfully');
        } catch (error) {
            console.error('Failed to export shift report:', error);
            showSnackbar('Failed to export shift report', 'error');
        }
    };

    const formatDateTime = (dateString: string | null) => {
        if (!dateString) return '-';
        try {
            const date = new Date(dateString);
            return date.toLocaleDateString('en-US', {
                month: 'short', day: 'numeric', year: 'numeric',
                hour: '2-digit', minute: '2-digit'
            });
        } catch {
            return dateString;
        }
    };

    const calculateDuration = (start: string, end: string | null) => {
        if (!end) return 'Ongoing';
        try {
            const diff = new Date(end).getTime() - new Date(start).getTime();
            const hours = Math.floor(diff / (1000 * 60 * 60));
            const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
            return `${hours}h ${minutes}m`;
        } catch {
            return '-';
        }
    };

    if (loading) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
                <CircularProgress sx={{ color: '#FFC107' }} />
            </Box>
        );
    }

    return (
        <Box>
            <Breadcrumbs separator={<ChevronRight size={14} />} sx={{ mb: 2 }}>
                <MuiLink component={RouterLink} to={`/${branchSlug}/reports`} underline="hover" color="inherit">
                    Reports
                </MuiLink>
                <Typography color="text.primary" sx={{ fontWeight: 600 }}>Session Report</Typography>
            </Breadcrumbs>
            <Box sx={{ display: 'flex', flexDirection: { xs: 'column', sm: 'row' }, justifyContent: 'space-between', alignItems: { xs: 'flex-start', sm: 'center' }, mb: { xs: 2, sm: 3, md: 4 }, gap: 2 }}>
                <Box>
                    <Typography variant="h5" fontWeight={800} sx={{ mb: 1, fontSize: { xs: '1.25rem', sm: '1.5rem' } }}>
                        <Calendar size={24} style={{ verticalAlign: 'middle', marginRight: '8px' }} />
                        Session Report
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ fontSize: { xs: '0.8rem', sm: '0.875rem' } }}>
                        Track all POS sessions, staff activity, and sales performance
                    </Typography>
                </Box>
                <Button
                    variant="contained"
                    startIcon={<FileText size={18} />}
                    onClick={handleExportPDF}
                    sx={{
                        bgcolor: '#FFC107',
                        '&:hover': { bgcolor: '#FF7700' },
                        textTransform: 'none',
                        borderRadius: '10px',
                        fontWeight: 700,
                        width: { xs: '100%', sm: 'auto' },
                        minWidth: { sm: '150px' }
                    }}
                >
                    Export PDF
                </Button>
            </Box>

            {/* Summary Cards */}
            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr', lg: '1fr 1fr 1fr 1fr' }, gap: 2, mb: { xs: 2, sm: 3, md: 4 } }}>
                <Paper sx={{ p: { xs: 2, sm: 2.5 }, borderRadius: '12px', border: '1px solid #f1f5f9' }} elevation={0}>
                    <Typography variant="caption" color="text.secondary" fontWeight={700} sx={{ fontSize: { xs: '0.7rem', sm: '0.75rem' } }}>TOTAL SESSIONS</Typography>
                    <Typography variant="h4" fontWeight={800} color="#FFC107" sx={{ fontSize: { xs: '1.5rem', sm: '2rem', md: '2.125rem' } }}>{sessions.length}</Typography>
                </Paper>
                <Paper sx={{ p: { xs: 2, sm: 2.5 }, borderRadius: '12px', border: '1px solid #f1f5f9' }} elevation={0}>
                    <Typography variant="caption" color="text.secondary" fontWeight={700} sx={{ fontSize: { xs: '0.7rem', sm: '0.75rem' } }}>ACTIVE SESSIONS</Typography>
                    <Typography variant="h4" fontWeight={800} color="#10b981" sx={{ fontSize: { xs: '1.5rem', sm: '2rem', md: '2.125rem' } }}>
                        {sessions.filter(s => s.status === 'Open').length}
                    </Typography>
                </Paper>
                <Paper sx={{ p: { xs: 2, sm: 2.5 }, borderRadius: '12px', border: '1px solid #f1f5f9' }} elevation={0}>
                    <Typography variant="caption" color="text.secondary" fontWeight={700} sx={{ fontSize: { xs: '0.7rem', sm: '0.75rem' } }}>TOTAL SALES</Typography>
                    <Typography variant="h4" fontWeight={800} sx={{ fontSize: { xs: '1.25rem', sm: '1.75rem', md: '2.125rem' } }}>
                        NPRs. {sessions.reduce((sum, s) => sum + (s.total_sales || 0), 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </Typography>
                </Paper>
                <Paper sx={{ p: { xs: 2, sm: 2.5 }, borderRadius: '12px', border: '1px solid #f1f5f9' }} elevation={0}>
                    <Typography variant="caption" color="text.secondary" fontWeight={700} sx={{ fontSize: { xs: '0.7rem', sm: '0.75rem' } }}>TOTAL ORDERS</Typography>
                    <Typography variant="h4" fontWeight={800} sx={{ fontSize: { xs: '1.5rem', sm: '2rem', md: '2.125rem' } }}>
                        {sessions.reduce((sum, s) => sum + (s.total_orders || 0), 0)}
                    </Typography>
                </Paper>
            </Box>

            {/* Sessions Table */}
            <TableContainer component={Paper} sx={{ borderRadius: '16px', border: '1px solid #f1f5f9', overflowX: 'auto' }} elevation={0}>
                <Table sx={{ minWidth: { xs: 600, sm: 750, md: 900 } }}>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>Session ID</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>Staff</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' }, display: { xs: 'none', md: 'table-cell' } }}>Start Time</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' }, display: { xs: 'none', md: 'table-cell' } }}>End Time</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' }, display: { xs: 'none', sm: 'table-cell' } }}>Duration</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>Status</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' }, display: { xs: 'none', lg: 'table-cell' } }} align="right">Opening</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' }, display: { xs: 'none', lg: 'table-cell' } }} align="right">Closing</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' } }} align="right">Sales</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' }, display: { xs: 'none', sm: 'table-cell' } }} align="right">Orders</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' } }} align="center">Actions</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {sessions.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={11} align="center" sx={{ py: 4 }}>
                                    <Typography color="text.secondary">No sessions found</Typography>
                                </TableCell>
                            </TableRow>
                        ) : sessions.map((session) => (
                            <TableRow key={session.id} hover>
                                <TableCell>
                                    <Typography variant="body2" fontWeight={700}>#{session.id}</Typography>
                                </TableCell>
                                <TableCell>
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                        <User size={16} color="#64748b" />
                                        <Typography variant="body2">{session.user?.full_name || 'System'}</Typography>
                                    </Box>
                                </TableCell>
                                <TableCell sx={{ display: { xs: 'none', md: 'table-cell' } }}>
                                    <Typography variant="body2" fontSize="0.8rem">
                                        {formatDateTime(session.start_time)}
                                    </Typography>
                                </TableCell>
                                <TableCell sx={{ display: { xs: 'none', md: 'table-cell' } }}>
                                    <Typography variant="body2" fontSize="0.8rem">
                                        {formatDateTime(session.end_time)}
                                    </Typography>
                                </TableCell>
                                <TableCell sx={{ display: { xs: 'none', sm: 'table-cell' } }}>
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                        <Clock size={14} color="#64748b" />
                                        <Typography variant="body2" fontSize="0.8rem">
                                            {calculateDuration(session.start_time, session.end_time)}
                                        </Typography>
                                    </Box>
                                </TableCell>
                                <TableCell>
                                    <Chip
                                        label={session.status === 'Open' ? 'Active Session' : session.status}
                                        size="small"
                                        sx={{
                                            bgcolor: session.status === 'Open' ? '#dcfce7' : '#f1f5f9',
                                            color: session.status === 'Open' ? '#16a34a' : '#64748b',
                                            fontWeight: 700,
                                            fontSize: '0.7rem'
                                        }}
                                    />
                                </TableCell>
                                <TableCell align="right" sx={{ display: { xs: 'none', lg: 'table-cell' } }}>
                                    <Typography variant="body2" fontWeight={600} sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                                        Rs. {(session.opening_cash || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                                    </Typography>
                                </TableCell>
                                <TableCell align="right" sx={{ display: { xs: 'none', lg: 'table-cell' } }}>
                                    <Typography variant="body2" fontWeight={600} sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                                        Rs. {(session.actual_cash || session.total_sales || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                                    </Typography>
                                </TableCell>
                                <TableCell align="right">
                                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 0.5 }}>
                                        <DollarSign size={14} color="#FFC107" />
                                        <Typography variant="body2" fontWeight={700} color="#FFC107">
                                            Rs. {Number(session.total_sales || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                                        </Typography>
                                    </Box>
                                </TableCell>
                                <TableCell align="right" sx={{ display: { xs: 'none', sm: 'table-cell' } }}>
                                    <Typography variant="body2" fontWeight={600} sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>
                                        {session.total_orders}
                                    </Typography>
                                </TableCell>
                                <TableCell align="center">
                                    <Tooltip title="View Detailed Report">
                                        <IconButton
                                            size="small"
                                            sx={{ color: '#64748b' }}
                                            onClick={() => handleExportShift(session.id)}
                                        >
                                            <FileText size={16} />
                                        </IconButton>
                                    </Tooltip>
                                </TableCell>
                            </TableRow>
                        ))}
                    </TableBody>
                </Table>
            </TableContainer>
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

export default SessionReport;

