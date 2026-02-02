import React, { useState, useEffect } from 'react';
import { Box, Grid, Typography, CircularProgress } from '@mui/material';
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
    const { showAlert, showConfirm } = useNotification();

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
        try {
            const response = await sessionsAPI.create({
                opening_cash: 0,
                notes: 'Session started from Dashboard'
            });
            setActiveSession(response.data);
            showAlert('Session started successfully', 'success');
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

        showConfirm({
            title: 'End Session?',
            message: activeSession
                ? 'Are you sure you want to end your current session?'
                : `Are you sure you want to end ${sessionToEnd.user?.full_name || 'the user'}'s session?`,
            confirmText: 'End Session',
            isDestructive: true,
            onConfirm: async () => {
                try {
                    await sessionsAPI.update(sessionToEnd.id, {
                        status: 'Closed'
                    });
                    setActiveSession(null);
                    setGlobalActiveSession(null);
                    setSessionDuration('00:00:00');
                    showAlert('Session ended successfully', 'success');

                    // Redirect smoothly to dashboard
                    navigate('/dashboard');
                } catch (error: any) {
                    console.error('Error ending session:', error);
                    showAlert(error.response?.data?.detail || 'Failed to end session', 'error');
                }
            }
        });
    };

    if (loading) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '80vh' }}>
                <CircularProgress sx={{ color: '#FF8C00' }} />
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

        </Box>
    );
};

export default Dashboard;
