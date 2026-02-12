import React, { useState, useEffect } from 'react';
import { Box, Grid, Typography, CircularProgress, Dialog, DialogTitle, DialogContent, DialogActions, TextField, Button, InputAdornment } from '@mui/material';
import { WelcomeCard } from '../../components/dashboard/OverviewCards';
import { SalesSummary, OrderDetail } from '../../components/dashboard/SalesSummary';
import { SalesByArea } from '../../components/dashboard/RevenueAndArea';
import { TopSellingItemsChart } from '../../components/dashboard/TopSellingChart';
import { useAuth } from '../../app/providers/AuthProvider';
import { reportsAPI, sessionsAPI } from '../../services/api';
import { useNotification } from '../../app/providers/NotificationProvider';

import { useNavigate } from 'react-router-dom';

interface DashboardData {
    occupancy: number;
    total_tables: number;
    occupied_tables: number;
    sales_24h: number;
    paid_sales: number;
    credit_sales: number;
    discount: number;
    orders_24h: number;
    dine_in_count: number;
    takeaway_count: number;
    delivery_count: number;
    outstanding_revenue: number;
    top_outstanding_items: Array<{ name: string; amount: number }>;
    top_selling_items: Array<{ name: string; quantity: number; revenue: number }>;
    sales_by_area: Array<{ area: string; amount: number }>;
    peak_time_data: number[];
    hourly_sales: number[];
    period: string;
}

interface Session {
    id: number;
    user_id: number;
    start_time: string;
    end_time: string | null;
    status: string;
    opening_cash: number;
    actual_cash: number;
    expected_cash: number;
    total_sales: number;
    user?: {
        full_name: string;
        username: string;
    };
}

const Dashboard: React.FC = () => {
    const { user } = useAuth();
    const navigate = useNavigate();
    const [data, setData] = useState<DashboardData | null>(null);
    const [loading, setLoading] = useState(true);

    // Session State
    // Session State
    const [activeSession, setActiveSession] = useState<Session | null>(null);
    const [globalActiveSession, setGlobalActiveSession] = useState<Session | null>(null);
    const [sessionDuration, setSessionDuration] = useState<string>('00:00:00');
    const { showAlert } = useNotification();

    // Dialog States
    const [openingDialog, setOpeningDialog] = useState(false);
    const [closingDialog, setClosingDialog] = useState(false);
    const [openingCash, setOpeningCash] = useState('0');
    const [actualCash, setActualCash] = useState('0');

    useEffect(() => {
        const fetchDashboardData = async () => {
            try {
                setLoading(true);
                const [dashboardRes, sessionsRes] = await Promise.all([
                    reportsAPI.getDashboardSummary(),
                    sessionsAPI.getAll()
                ]);
                setData(dashboardRes.data);

                // Find active session for current user
                if (user?.id) {
                    const sessions = sessionsRes.data || [];

                    // Check for current user's session
                    const currentSession = sessions.find((s: any) =>
                        s.user_id === user.id && s.status === 'Open'
                    );
                    setActiveSession(currentSession || null);

                    // Check for ANY active session (to show Admin/others)
                    const anyActiveSession = sessions.find((s: any) => s.status === 'Open');
                    setGlobalActiveSession(anyActiveSession || null);
                }
            } catch (error) {
                console.error('Error fetching dashboard data:', error);
            } finally {
                setLoading(false);
            }
        };

        if (user?.id) {
            fetchDashboardData();
        }
    }, [user?.id]);

    // Timer effect for active session
    // Timer effect for active session (personal or global)
    useEffect(() => {
        let interval: ReturnType<typeof setInterval>;

        // Use either personal session or global session for the timer
        const sessionToTrack = activeSession || globalActiveSession;

        if (sessionToTrack) {
            const updateTimer = () => {
                const start = new Date(sessionToTrack.start_time).getTime();
                const now = new Date().getTime();
                const diff = now - start;

                const hours = Math.floor(diff / (1000 * 60 * 60));
                const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
                const seconds = Math.floor((diff % (1000 * 60)) / 1000);

                setSessionDuration(
                    `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
                );
            };

            updateTimer(); // Initial call
            interval = setInterval(updateTimer, 1000);
        }

        return () => {
            if (interval) clearInterval(interval);
        };
    }, [activeSession, globalActiveSession]);

    const handleStartSession = async () => {
        setOpeningDialog(true);
    };

    const confirmStartSession = async () => {
        try {
            const response = await sessionsAPI.create({
                opening_cash: parseFloat(openingCash) || 0,
                notes: 'Session started from Dashboard'
            });
            setActiveSession(response.data);
            showAlert('Session started successfully', 'success');
            setOpeningDialog(false);
            setOpeningCash('0');
            // Refresh dashboard
            window.location.reload();
        } catch (error: any) {
            console.error('Error starting session:', error);
            showAlert(error.response?.data?.detail || 'Failed to start session', 'error');
        }
    };

    const handleEndSession = async () => {
        const sessionToEnd = activeSession || globalActiveSession;
        if (!sessionToEnd) return;

        // Default closing balance = opening + sales
        const suggestBalance = (sessionToEnd.opening_cash || 0) + (sessionToEnd.total_sales || 0);
        setActualCash(suggestBalance.toString());
        setClosingDialog(true);
    };

    const confirmEndSession = async () => {
        const sessionToEnd = activeSession || globalActiveSession;
        if (!sessionToEnd) return;

        try {
            await sessionsAPI.update(sessionToEnd.id, {
                actual_cash: parseFloat(actualCash) || 0,
                status: 'Closed'
            });
            setActiveSession(null);
            setGlobalActiveSession(null);
            setSessionDuration('00:00:00');
            setClosingDialog(false);
            setActualCash('0');
            showAlert('Session ended successfully', 'success');

            // Redirect smoothly to dashboard
            navigate('/dashboard');
        } catch (error: any) {
            console.error('Error ending session:', error);
            showAlert(error.response?.data?.detail || 'Failed to end session', 'error');
        }
    };

    if (loading) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '80vh' }}>
                <CircularProgress sx={{ color: '#FFC107' }} />
            </Box>
        );
    }

    return (
        <Box>
            <Typography variant="h4" sx={{ fontWeight: 800, mb: { xs: 2, sm: 3, md: 4 }, color: '#1e293b', fontSize: { xs: '1.5rem', sm: '2rem', md: '2.125rem' } }}>
                Dashboard Overview
            </Typography>
            <Grid container spacing={{ xs: 2, sm: 2.5, md: 3 }}>
                <Grid size={{ xs: 12, md: 7 }}>
                    <WelcomeCard
                        username={user?.full_name || user?.username || 'Admin'}
                        onGoToPOS={() => navigate('/pos')}
                        isSessionActive={!!activeSession}
                        activeSessionUser={globalActiveSession?.user?.full_name || globalActiveSession?.user?.username}
                        sessionDuration={sessionDuration}
                        sessionStartDate={(activeSession || globalActiveSession) ? new Date((activeSession || globalActiveSession)!.start_time).toLocaleDateString() + ' ' + new Date((activeSession || globalActiveSession)!.start_time).toLocaleTimeString() : undefined}
                        onStartSession={handleStartSession}
                        onEndSession={handleEndSession}
                    />
                </Grid>

                <Grid size={{ xs: 12, md: 5 }}>
                    <SalesSummary
                        totalSales={data?.sales_24h}
                        paidSales={data?.paid_sales}
                        creditSales={data?.credit_sales}
                        discount={data?.discount}
                    />
                </Grid>

                <Grid size={{ xs: 12 }}>
                    <SalesByArea
                        data={data?.sales_by_area || []}
                        occupancy={{
                            percentage: data?.occupancy || 0,
                            occupied: data?.occupied_tables || 0,
                            total: data?.total_tables || 0
                        }}
                    />
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                    <OrderDetail
                        totalOrders={data?.orders_24h}
                        dineInCount={data?.dine_in_count}
                        takeawayCount={data?.takeaway_count}
                        deliveryCount={data?.delivery_count}
                    />
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                    <TopSellingItemsChart
                        items={data?.top_selling_items || []}
                    />
                </Grid>
            </Grid>

            {/* Opening Balance Dialog */}
            <Dialog open={openingDialog} onClose={() => setOpeningDialog(false)} maxWidth="xs" fullWidth>
                <DialogTitle sx={{ fontWeight: 800 }}>Start POS Session</DialogTitle>
                <DialogContent>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                        Please enter the starting cash amount in your drawer.
                    </Typography>
                    <TextField
                        autoFocus
                        label="Opening Balance"
                        type="number"
                        fullWidth
                        value={openingCash}
                        onChange={(e) => setOpeningCash(e.target.value)}
                        InputProps={{
                            startAdornment: <InputAdornment position="start">Rs.</InputAdornment>,
                        }}
                        sx={{
                            '& .MuiOutlinedInput-root': {
                                borderRadius: '12px',
                            }
                        }}
                    />
                </DialogContent>
                <DialogActions sx={{ p: 3 }}>
                    <Button onClick={() => setOpeningDialog(false)} sx={{ color: '#64748b', fontWeight: 700 }}>
                        Cancel
                    </Button>
                    <Button
                        onClick={confirmStartSession}
                        variant="contained"
                        sx={{
                            bgcolor: '#22c55e',
                            '&:hover': { bgcolor: '#16a34a' },
                            fontWeight: 800,
                            borderRadius: '12px',
                            px: 3
                        }}
                    >
                        Start Session
                    </Button>
                </DialogActions>
            </Dialog>

            {/* Closing Balance Dialog */}
            <Dialog open={closingDialog} onClose={() => setClosingDialog(false)} maxWidth="xs" fullWidth>
                <DialogTitle sx={{ fontWeight: 800 }}>End POS Session</DialogTitle>
                <DialogContent>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                        Enter the actual cash amount currently in the drawer to close the session.
                    </Typography>
                    <TextField
                        autoFocus
                        label="Actual Cash Reported"
                        type="number"
                        fullWidth
                        value={actualCash}
                        onChange={(e) => setActualCash(e.target.value)}
                        InputProps={{
                            startAdornment: <InputAdornment position="start">Rs.</InputAdornment>,
                        }}
                        sx={{
                            '& .MuiOutlinedInput-root': {
                                borderRadius: '12px',
                            }
                        }}
                    />
                    {(activeSession || globalActiveSession) && (
                        <Box sx={{ mt: 3, p: 2, bgcolor: '#f8fafc', borderRadius: '12px' }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                <Typography variant="body2" color="text.secondary">Total Sales:</Typography>
                                <Typography variant="body2" fontWeight={700}>Rs. {Number((activeSession || globalActiveSession)!.total_sales).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                            </Box>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                                <Typography variant="body2" color="text.secondary">Opening Balance:</Typography>
                                <Typography variant="body2" fontWeight={700}>Rs. {Number((activeSession || globalActiveSession)!.opening_cash).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                            </Box>
                        </Box>
                    )}
                </DialogContent>
                <DialogActions sx={{ p: 3 }}>
                    <Button onClick={() => setClosingDialog(false)} sx={{ color: '#64748b', fontWeight: 700 }}>
                        Cancel
                    </Button>
                    <Button
                        onClick={confirmEndSession}
                        variant="contained"
                        sx={{
                            bgcolor: '#ef4444',
                            '&:hover': { bgcolor: '#dc2626' },
                            fontWeight: 800,
                            borderRadius: '12px',
                            px: 3
                        }}
                    >
                        End Session
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default Dashboard;

