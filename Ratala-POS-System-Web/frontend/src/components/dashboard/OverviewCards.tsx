import React, { useMemo } from 'react';
import { Box, Typography, Paper, Button, Avatar, Chip } from '@mui/material';
import Chart from 'react-apexcharts';
import type { ApexOptions } from 'apexcharts';
import { Clock, TrendingUp } from 'lucide-react';

export const WelcomeCard: React.FC<{
    username: string;
    isSessionActive: boolean;
    sessionDuration?: string;
    sessionStartDate?: string;
    activeSessionUser?: string;
    onStartSession: () => void;
    onEndSession: () => void;
    onGoToPOS?: () => void;
}> = ({
    username,
    isSessionActive,
    sessionDuration,
    sessionStartDate,
    activeSessionUser,
    onStartSession,
    onEndSession,
    onGoToPOS
}) => {
        const greeting = useMemo(() => {
            const hour = new Date().getHours();
            if (hour < 12) return 'Good Morning';
            if (hour < 17) return 'Good Afternoon';
            return 'Good Evening';
        }, []);

        return (
            <Paper sx={{
                p: { xs: 3, md: 4 },
                borderRadius: '24px',
                bgcolor: '#fff',
                boxShadow: '0 10px 30px rgba(0,0,0,0.03)',
                display: 'flex',
                flexDirection: 'column',
                position: 'relative',
                overflow: 'hidden',
                height: '100%',
                border: '1px solid #f1f5f9',
                background: 'linear-gradient(135deg, #ffffff 0%, #fafafa 100%)'
            }}>
                {/* Decorative element */}
                <Box sx={{
                    position: 'absolute',
                    top: -20,
                    right: -20,
                    width: 140,
                    height: 140,
                    borderRadius: '50%',
                    bgcolor: '#FFC10708',
                    zIndex: 1
                }} />

                <Box sx={{ zIndex: 2 }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                        <Box>
                            <Typography variant="h4" fontWeight={900} color="#2C1810" sx={{ letterSpacing: '-0.02em' }}>
                                {greeting}, <span style={{ color: '#FFC107' }}>{username}</span>
                            </Typography>
                            <Typography variant="body1" color="#64748b" sx={{ mt: 1, fontWeight: 500 }}>
                                {isSessionActive
                                    ? "Your POS terminal is ready for service."
                                    : activeSessionUser
                                        ? `An active session is currently running by ${activeSessionUser}.`
                                        : "Welcome back! Please start a session to begin taking orders."
                                }
                            </Typography>
                        </Box>
                        <Avatar sx={{ bgcolor: '#FFC10715', color: '#FFC107', width: 56, height: 56, fontSize: '1.5rem', border: '2px solid #FFC10720' }}>
                            {username.charAt(0).toUpperCase()}
                        </Avatar>
                    </Box>

                    <Box sx={{ mt: 4, display: 'flex', gap: 2, alignItems: 'center' }}>
                        {isSessionActive ? (
                            <>
                                <Button
                                    variant="contained"
                                    onClick={onGoToPOS}
                                    sx={{
                                        bgcolor: '#FFC107',
                                        color: 'white',
                                        boxShadow: '0 8px 20px -4px rgba(255, 140, 0, 0.4)',
                                        '&:hover': { bgcolor: '#FF7700', transform: 'translateY(-2px)' },
                                        textTransform: 'none',
                                        fontWeight: 800,
                                        px: 4,
                                        py: 1.5,
                                        borderRadius: '14px',
                                        transition: 'all 0.2s'
                                    }}
                                >
                                    Launch POS Terminal
                                </Button>
                                <Button
                                    variant="contained"
                                    onClick={onEndSession}
                                    sx={{
                                        bgcolor: '#ef4444',
                                        color: 'white',
                                        fontWeight: 800,
                                        textTransform: 'none',
                                        borderRadius: '12px',
                                        px: 3,
                                        py: 1,
                                        boxShadow: '0 4px 12px rgba(239, 68, 68, 0.2)',
                                        '&:hover': {
                                            bgcolor: '#dc2626',
                                            transform: 'translateY(-2px)',
                                            boxShadow: '0 6px 15px rgba(239, 68, 68, 0.3)'
                                        },
                                        transition: 'all 0.2s'
                                    }}
                                >
                                    End Session
                                </Button>
                            </>
                        ) : activeSessionUser ? (
                            <>
                                <Button
                                    variant="contained"
                                    onClick={onGoToPOS}
                                    sx={{
                                        bgcolor: '#FFC107',
                                        color: 'white',
                                        boxShadow: '0 8px 20px -4px rgba(255, 140, 0, 0.4)',
                                        '&:hover': { bgcolor: '#FF7700', transform: 'translateY(-2px)' },
                                        textTransform: 'none',
                                        fontWeight: 800,
                                        px: 4,
                                        py: 1.5,
                                        borderRadius: '14px',
                                        transition: 'all 0.2s'
                                    }}
                                >
                                    Enter POS
                                </Button>
                                <Button
                                    variant="contained"
                                    onClick={onEndSession}
                                    sx={{
                                        bgcolor: '#ef4444',
                                        color: 'white',
                                        fontWeight: 800,
                                        textTransform: 'none',
                                        borderRadius: '12px',
                                        px: 3,
                                        py: 1,
                                        boxShadow: '0 4px 12px rgba(239, 68, 68, 0.2)',
                                        '&:hover': {
                                            bgcolor: '#dc2626',
                                            transform: 'translateY(-2px)',
                                            boxShadow: '0 6px 15px rgba(239, 68, 68, 0.3)'
                                        },
                                        transition: 'all 0.2s'
                                    }}
                                >
                                    End Session
                                </Button>
                            </>
                        ) : (
                            <Button
                                variant="contained"
                                onClick={onStartSession}
                                sx={{
                                    bgcolor: '#22c55e',
                                    color: 'white',
                                    boxShadow: '0 8px 20px -4px rgba(34, 197, 94, 0.3)',
                                    '&:hover': { bgcolor: '#16a34a', transform: 'translateY(-2px)' },
                                    textTransform: 'none',
                                    fontWeight: 800,
                                    px: 4,
                                    py: 1.5,
                                    borderRadius: '14px',
                                    transition: 'all 0.2s'
                                }}
                            >
                                Start New Session
                            </Button>
                        )}
                    </Box>

                    {(isSessionActive || activeSessionUser) && (
                        <Box sx={{
                            mt: 4,
                            p: 2.5,
                            bgcolor: activeSessionUser ? '#fff7ed' : '#f8fafc',
                            borderRadius: '16px',
                            border: activeSessionUser ? '1px solid #fed7aa' : '1px solid #e2e8f0',
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'center'
                        }}>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                <Box sx={{
                                    p: 1.5,
                                    bgcolor: '#fff',
                                    borderRadius: '12px',
                                    boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)',
                                    display: 'flex',
                                    color: '#FFC107'
                                }}>
                                    <Clock size={20} />
                                </Box>
                                <Box>
                                    <Typography variant="caption" color="text.secondary" fontWeight={700} sx={{ textTransform: 'uppercase' }}>
                                        {activeSessionUser ? `Session by ${activeSessionUser}` : 'Current Session'}
                                    </Typography>
                                    <Typography variant="body2" fontWeight={800} color="#334155">
                                        {sessionDuration || "00:00:00"} elapsed
                                    </Typography>
                                </Box>
                            </Box>
                            <Box sx={{ textAlign: 'right' }}>
                                <Typography variant="caption" color="text.secondary" fontWeight={600}>
                                    Started at
                                </Typography>
                                <Typography variant="body2" fontWeight={700} color="#64748b">
                                    {sessionStartDate?.split(' ')[1] || "N/A"}
                                </Typography>
                            </Box>
                        </Box>
                    )}
                </Box>
            </Paper >
        );
    };

export const OccupancyCard: React.FC<{ percentage: number; occupied: number; total: number }> = ({ percentage, occupied, total }) => {
    // Determine status color based on occupancy
    const statusColor = useMemo(() => {
        if (percentage >= 80) return '#ef4444'; // High occupancy - red
        if (percentage >= 50) return '#FFC107'; // Medium occupancy - orange
        return '#22c55e'; // Low occupancy - green
    }, [percentage]);

    const statusText = useMemo(() => {
        if (percentage >= 80) return 'High';
        if (percentage >= 50) return 'Medium';
        return 'Low';
    }, [percentage]);

    // Safe percentage calculation
    const safePercentage = useMemo(() => {
        if (total === 0) return 0;
        return Math.min(100, Math.max(0, Math.round(percentage)));
    }, [percentage, total]);

    return (
        <Paper sx={{
            p: 3,
            borderRadius: '16px',
            bgcolor: '#fff',
            boxShadow: '0 4px 20px rgba(0,0,0,0.02)',
            textAlign: 'center',
            height: '100%',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'space-between'
        }}>
            <Box>
                <Typography variant="subtitle2" fontWeight={700} color="#64748b">Current Occupancy</Typography>
                <Typography variant="h3" fontWeight={900} color={statusColor} sx={{ my: 1 }}>
                    {safePercentage}%
                </Typography>
                <Typography variant="body2" color="#94a3b8">
                    {occupied}/{total} Table{total !== 1 ? 's' : ''}
                </Typography>
                {total > 0 && (
                    <Chip
                        label={statusText}
                        size="small"
                        sx={{
                            mt: 1,
                            bgcolor: `${statusColor}20`,
                            color: statusColor,
                            fontWeight: 700,
                            fontSize: '0.7rem'
                        }}
                    />
                )}
            </Box>
            <Box sx={{ mt: 2, display: 'flex', justifyContent: 'center' }}>
                <Avatar sx={{ bgcolor: `${statusColor}20`, color: statusColor, width: 50, height: 50 }}>
                    🍴
                </Avatar>
            </Box>
            {total === 0 && (
                <Typography variant="caption" color="#94a3b8" sx={{ mt: 2 }}>
                    No tables configured
                </Typography>
            )}
        </Paper>
    );
};

export const PeakTimeChart: React.FC<{ data: number[]; salesData?: number[] }> = ({ data, salesData }) => {
    // Calculate current hour labels dynamically  
    const labels = useMemo(() => {
        const currentHour = new Date().getHours();
        const hours = [];
        for (let i = 23; i >= 0; i--) {
            const hour = (currentHour - i + 24) % 24;
            const period = hour >= 12 ? 'pm' : 'am';
            const displayHour = hour === 0 ? 12 : hour > 12 ? hour - 12 : hour;
            hours.push(`${displayHour}${period}`);
        }
        return hours;
    }, []);

    // Use sales data if available, otherwise fall back to order count
    const chartData = useMemo(() => {
        if (salesData && salesData.length === 24) {
            return salesData.map(v => Math.max(0, v));
        }
        if (!data || data.length !== 24) {
            return new Array(24).fill(0);
        }
        return data.map(v => Math.max(0, v));
    }, [data, salesData]);

    const maxValue = useMemo(() => Math.max(...chartData, 1), [chartData]);
    const totalSales = useMemo(() => chartData.reduce((a, b) => a + b, 0), [chartData]);
    const peakHour = useMemo(() => {
        if (totalSales === 0) return null;
        const maxIndex = chartData.indexOf(Math.max(...chartData));
        return labels[maxIndex];
    }, [chartData, labels, totalSales]);

    const isSalesData = salesData && salesData.length === 24;

    const options: ApexOptions = {
        chart: {
            id: 'peak-time-bar',
            toolbar: { show: false },
            sparkline: { enabled: false },
            animations: {
                enabled: true,
                speed: 800
            }
        },
        plotOptions: {
            bar: {
                borderRadius: 4,
                columnWidth: '70%',
                distributed: false,
                colors: {
                    ranges: [{
                        from: 0,
                        to: maxValue,
                        color: '#FFC107'
                    }]
                }
            }
        },
        dataLabels: { enabled: false },
        tooltip: {
            theme: 'light',
            y: {
                formatter: (value) => isSalesData
                    ? `NPRs. ${value.toLocaleString()}`
                    : `${value} order${value !== 1 ? 's' : ''}`
            }
        },
        xaxis: {
            categories: labels,
            labels: {
                show: true,
                rotate: -45,
                rotateAlways: false,
                style: {
                    fontSize: '9px',
                    colors: '#94a3b8'
                }
            },
            axisBorder: { show: false },
            axisTicks: { show: false }
        },
        yaxis: {
            show: true,
            labels: {
                style: {
                    fontSize: '10px',
                    colors: '#94a3b8'
                },
                formatter: (value) => isSalesData
                    ? `₹${(value / 1000).toFixed(0)}k`
                    : value.toFixed(0)
            }
        },
        grid: {
            show: true,
            borderColor: '#f1f5f9',
            strokeDashArray: 3,
            yaxis: {
                lines: { show: true }
            },
            xaxis: {
                lines: { show: false }
            }
        },
        colors: ['#FFC107']
    };

    const series = [{
        name: isSalesData ? 'Sales' : 'Orders',
        data: chartData
    }];

    return (
        <Paper sx={{ p: 3, borderRadius: '16px', bgcolor: '#fff', boxShadow: '0 4px 20px rgba(0,0,0,0.02)', height: '100%' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Box>
                    <Typography variant="subtitle1" fontWeight={700}>
                        {isSalesData ? 'Sales Revenue (24h)' : 'Peak Time Analysis'}
                    </Typography>
                    {peakHour && (
                        <Typography variant="caption" color="#64748b" sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5 }}>
                            <TrendingUp size={12} />
                            Peak at {peakHour}
                        </Typography>
                    )}
                </Box>
                <Chip
                    label={isSalesData
                        ? `NPRs. ${totalSales.toLocaleString()}`
                        : `${totalSales} orders`
                    }
                    size="small"
                    sx={{
                        bgcolor: '#fff7ed',
                        color: '#FFC107',
                        fontWeight: 700,
                        fontSize: '0.7rem'
                    }}
                />
            </Box>
            {(totalSales > 0 || !isSalesData) ? (
                <Chart options={options} series={series} type="bar" height={180} />
            ) : (
                <Box sx={{ opacity: 0.3, pointerEvents: 'none' }}>
                    <Chart
                        options={options}
                        series={[{
                            name: 'Empty',
                            data: [30, 40, 35, 50, 49, 60, 70, 91, 125, 40, 35, 50, 49, 60, 70, 91, 125, 40, 35, 50, 49, 60, 70, 91]
                        }]}
                        type="bar"
                        height={180}
                    />
                </Box>
            )}
        </Paper>
    );
};

