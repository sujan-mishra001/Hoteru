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
    Button,
    Avatar,
    CircularProgress,
    Snackbar,
    Alert,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField
} from '@mui/material';
import { Clock, Play, Square } from 'lucide-react';
import { sessionsAPI, authAPI } from '../../services/api';

interface Session {
    id: number;
    user_id: number;
    start_time: string;
    end_time: string | null;
    status: string;
    opening_cash: number;
    actual_cash: number;
    total_sales: number;
    total_orders: number;
    user?: {
        full_name: string;
        role: string;
    };
}

const Sessions: React.FC = () => {
    const [sessions, setSessions] = useState<Session[]>([]);
    const [loading, setLoading] = useState(true);
    const [currentUser, setCurrentUser] = useState<any>(null);
    const [activeSessionId, setActiveSessionId] = useState<number | null>(null);
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

    // Dialog states
    const [openingDialog, setOpeningDialog] = useState(false);
    const [closingDialog, setClosingDialog] = useState(false);
    const [openingCash, setOpeningCash] = useState('0');
    const [actualCash, setActualCash] = useState('0');
    const [sessionToClose, setSessionToClose] = useState<number | null>(null);

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setLoading(true);
            const [sessionsRes, userRes] = await Promise.all([
                sessionsAPI.getAll(),
                authAPI.getCurrentUser()
            ]);

            const sessionData = sessionsRes.data || [];
            // Sort by start_time decending
            sessionData.sort((a: Session, b: Session) => new Date(b.start_time).getTime() - new Date(a.start_time).getTime());

            setSessions(sessionData);
            setCurrentUser(userRes.data);

            // Check if current user has an active session
            const userActiveSession = sessionData.find((s: Session) => s.user_id === userRes.data.id && !s.end_time);
            if (userActiveSession) {
                setActiveSessionId(userActiveSession.id);
            }
        } catch (error) {
            console.error('Error loading sessions:', error);
            setSnackbar({ open: true, message: 'Failed to load sessions', severity: 'error' });
        } finally {
            setLoading(false);
        }
    };

    const handleStartSessionClick = () => {
        // Always ask for opening balance regardless of role
        setOpeningDialog(true);
    };

    const handleStartSession = async (openingBalance: number) => {
        try {
            const payload = {
                opening_cash: openingBalance,
                notes: 'Session started via POS'
            };
            const response = await sessionsAPI.create(payload);
            setActiveSessionId(response.data.id);
            setSnackbar({ open: true, message: 'Session started successfully', severity: 'success' });
            setOpeningDialog(false);
            setOpeningCash('0');
            loadData();
        } catch (error: any) {
            console.error('Error starting session:', error);
            setSnackbar({ open: true, message: error.response?.data?.detail || 'Failed to start session', severity: 'error' });
        }
    };

    const handleEndSessionClick = (sessionId: number) => {
        const session = sessions.find(s => s.id === sessionId);
        if (session) {
            // Set default closing balance to sum of opening balance and total sales
            setActualCash(((session.opening_cash || 0) + (session.total_sales || 0)).toString());
        }
        setSessionToClose(sessionId);
        setClosingDialog(true);
    };

    const handleEndSession = async () => {
        if (!sessionToClose) return;

        try {
            const payload = {
                actual_cash: parseFloat(actualCash) || 0,
                status: 'Closed'
            };
            await sessionsAPI.update(sessionToClose, payload);
            if (sessionToClose === activeSessionId) setActiveSessionId(null);
            setClosingDialog(false);
            setActualCash('0');
            setSessionToClose(null);
            loadData();
        } catch (error: any) {
            console.error('Error ending session:', error);
            setSnackbar({ open: true, message: error.response?.data?.detail || 'Failed to end session', severity: 'error' });
        }
    };

    const formatTime = (dateString: string) => {
        return new Date(dateString).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    };

    const getDuration = (start: string, end: string | null) => {
        if (!end) return 'Ongoing';
        const diff = new Date(end).getTime() - new Date(start).getTime();
        const hours = Math.floor(diff / (1000 * 60 * 60));
        const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
        return `${hours}h ${minutes}m`;
    };

    return (
        <Box>
            <Box sx={{ mb: { xs: 2, sm: 3, md: 4 }, display: 'flex', flexDirection: { xs: 'column', sm: 'row' }, justifyContent: 'space-between', alignItems: { xs: 'flex-start', sm: 'center' }, gap: 2 }}>
                <Box>
                    <Typography variant="h5" fontWeight={800} sx={{ fontSize: { xs: '1.25rem', sm: '1.5rem' } }}>Staff Sessions</Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ fontSize: { xs: '0.8rem', sm: '0.875rem' } }}>Monitor active and past worker sessions</Typography>
                </Box>
                {!activeSessionId && (
                    <Button
                        variant="contained"
                        startIcon={<Play size={18} />}
                        onClick={handleStartSessionClick}
                        sx={{
                            bgcolor: '#FFC107',
                            '&:hover': { bgcolor: '#FF7700' },
                            textTransform: 'none',
                            borderRadius: '10px',
                            width: { xs: '100%', sm: 'auto' },
                            minWidth: { sm: '180px' }
                        }}
                    >
                        Start My Session
                    </Button>
                )}
            </Box>

            <TableContainer component={Paper} sx={{ borderRadius: '16px', boxShadow: '0 4px 20px rgba(0,0,0,0.02)', overflowX: 'auto' }}>
                <Table sx={{ minWidth: { xs: 500, sm: 650 } }}>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>Staff Member</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>Time</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>Status</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' }, display: { xs: 'none', sm: 'table-cell' } }}>Orders</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>Opening</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>Actual</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>Sales</TableCell>
                            <TableCell sx={{ fontWeight: 700, fontSize: { xs: '0.75rem', sm: '0.875rem' } }} align="right">Actions</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow><TableCell colSpan={6} align="center"><CircularProgress size={24} sx={{ color: '#FFC107' }} /></TableCell></TableRow>
                        ) : sessions.length === 0 ? (
                            <TableRow><TableCell colSpan={6} align="center">No sessions found</TableCell></TableRow>
                        ) : (
                            sessions.map((session) => (
                                <TableRow key={session.id} hover>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                            <Avatar sx={{ bgcolor: '#fff7ed', color: '#FFC107', fontSize: '14px', fontWeight: 700 }}>
                                                {session.user?.full_name?.charAt(0) || 'U'}
                                            </Avatar>
                                            <Box>
                                                <Typography variant="subtitle2" fontWeight={700}>{session.user?.full_name || 'Unknown'}</Typography>
                                                <Typography variant="caption" color="text.secondary">{session.user?.role || 'Staff'}</Typography>
                                            </Box>
                                        </Box>
                                    </TableCell>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', flexDirection: 'column' }}>
                                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                                                <Clock size={14} color="#64748b" />
                                                <Typography variant="body2" fontWeight={600}>{formatTime(session.start_time)}</Typography>
                                            </Box>
                                            <Typography variant="caption" color="text.secondary">
                                                {getDuration(session.start_time, session.end_time)}
                                            </Typography>
                                        </Box>
                                    </TableCell>
                                    <TableCell>
                                        <Chip
                                            label={!session.end_time ? 'Active' : 'Closed'}
                                            size="small"
                                            sx={{
                                                bgcolor: !session.end_time ? '#22c55e15' : '#64748b15',
                                                color: !session.end_time ? '#22c55e' : '#64748b',
                                                fontWeight: 700
                                            }}
                                        />
                                    </TableCell>
                                    <TableCell sx={{ display: { xs: 'none', sm: 'table-cell' } }}>
                                        <Typography fontWeight={600} sx={{ fontSize: { xs: '0.8rem', sm: '0.875rem' } }}>{session.total_orders || 0}</Typography>
                                    </TableCell>
                                    <TableCell>
                                        <Typography fontWeight={600} sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>Rs. {(session.opening_cash || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                                    </TableCell>
                                    <TableCell>
                                        <Typography fontWeight={600} sx={{ fontSize: { xs: '0.75rem', sm: '0.875rem' } }}>Rs. {(session.actual_cash || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                                    </TableCell>
                                    <TableCell>
                                        <Typography fontWeight={700} sx={{ fontSize: { xs: '0.8rem', sm: '0.875rem' } }}>NPRs. {(session.total_sales || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                                    </TableCell>
                                    <TableCell align="right">
                                        {!session.end_time && session.user_id === currentUser?.id ? (
                                            <Button
                                                size="small"
                                                color="error"
                                                startIcon={<Square size={14} />}
                                                onClick={() => handleEndSessionClick(session.id)}
                                                sx={{
                                                    textTransform: 'none',
                                                    fontSize: { xs: '0.75rem', sm: '0.875rem' },
                                                    px: { xs: 1, sm: 2 }
                                                }}
                                            >
                                                <Box component="span" sx={{ display: { xs: 'none', sm: 'inline' } }}>End Session</Box>
                                                <Box component="span" sx={{ display: { xs: 'inline', sm: 'none' } }}>End</Box>
                                            </Button>
                                        ) : (
                                            <Button
                                                size="small"
                                                sx={{
                                                    textTransform: 'none',
                                                    color: '#64748b',
                                                    fontSize: { xs: '0.75rem', sm: '0.875rem' },
                                                    display: { xs: 'none', sm: 'inline-flex' }
                                                }}
                                            >
                                                View Logs
                                            </Button>
                                        )}
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            {/* Opening Balance Dialog (for Cashiers) */}
            <Dialog open={openingDialog} onClose={() => setOpeningDialog(false)} maxWidth="xs" fullWidth>
                <DialogTitle>Start Session</DialogTitle>
                <DialogContent>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                        Enter the opening cash amount for your shift
                    </Typography>
                    <TextField
                        autoFocus
                        label="Opening Cash"
                        type="number"
                        fullWidth
                        value={openingCash}
                        onChange={(e) => setOpeningCash(e.target.value)}
                        InputProps={{
                            startAdornment: <Typography sx={{ mr: 1, color: 'text.secondary' }}>Rs.</Typography>
                        }}
                    />
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpeningDialog(false)} sx={{ textTransform: 'none' }}>
                        Cancel
                    </Button>
                    <Button
                        onClick={() => handleStartSession(parseFloat(openingCash) || 0)}
                        variant="contained"
                        sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none' }}
                    >
                        Start Session
                    </Button>
                </DialogActions>
            </Dialog>

            {/* Closing Balance Dialog */}
            <Dialog open={closingDialog} onClose={() => setClosingDialog(false)} maxWidth="xs" fullWidth>
                <DialogTitle>Close Session</DialogTitle>
                <DialogContent>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                        Enter the actual cash amount in the drawer
                    </Typography>
                    <TextField
                        autoFocus
                        label="Actual Cash"
                        type="number"
                        fullWidth
                        value={actualCash}
                        onChange={(e) => setActualCash(e.target.value)}
                        InputProps={{
                            startAdornment: <Typography sx={{ mr: 1, color: 'text.secondary' }}>Rs.</Typography>
                        }}
                    />
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setClosingDialog(false)} sx={{ textTransform: 'none' }}>
                        Cancel
                    </Button>
                    <Button
                        onClick={handleEndSession}
                        variant="contained"
                        color="error"
                        sx={{ textTransform: 'none' }}
                    >
                        Close Session
                    </Button>
                </DialogActions>
            </Dialog>

            <Snackbar
                open={snackbar.open}
                autoHideDuration={6000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            >
                <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} sx={{ width: '100%' }}>
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </Box>
    );
};

export default Sessions;

