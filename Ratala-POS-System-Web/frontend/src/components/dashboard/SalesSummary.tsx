import React, { useMemo } from 'react';
import { Box, Typography, Paper, Grid, LinearProgress, Avatar, Chip } from '@mui/material';
import Chart from 'react-apexcharts';
import type { ApexOptions } from 'apexcharts';
import { TrendingUp, TrendingDown, DollarSign } from 'lucide-react';

export const SalesSummary: React.FC<{
    totalSales?: number;
    paidSales?: number;
    creditSales?: number;
    discount?: number;
}> = ({ totalSales = 0, paidSales = 0, creditSales = 0, discount = 0 }) => {

    // Calculate percentages safely
    const paidPercent = useMemo(() => {
        return totalSales > 0 ? Math.round((paidSales / totalSales) * 100) : 0;
    }, [totalSales, paidSales]);

    const creditPercent = useMemo(() => {
        return totalSales > 0 ? Math.round((creditSales / totalSales) * 100) : 0;
    }, [totalSales, creditSales]);

    const discountPercent = useMemo(() => {
        const totalWithDiscount = totalSales + discount;
        return totalWithDiscount > 0 ? Math.round((discount / totalWithDiscount) * 100) : 0;
    }, [totalSales, discount]);

    // Expected total including discount
    const grossSales = useMemo(() => totalSales + discount, [totalSales, discount]);

    const options: ApexOptions = {
        chart: {
            id: 'sales-donut',
            animations: {
                enabled: true,
                speed: 800
            }
        },
        labels: ['Paid', 'Credit'],
        colors: ['#22c55e', '#ff9800'],
        legend: { show: false },
        dataLabels: { enabled: false },
        stroke: { width: 0 },
        plotOptions: {
            pie: {
                donut: {
                    size: '70%',
                    labels: {
                        show: true,
                        total: {
                            show: true,
                            label: 'Total',
                            formatter: () => `${paidPercent}%`
                        }
                    }
                }
            }
        },
        tooltip: {
            y: {
                formatter: (value) => `${value}%`
            }
        }
    };

    // Only show chart if there's data
    const series = useMemo(() => {
        if (paidSales === 0 && creditSales === 0) {
            return [100, 0]; // Show full circle if no data
        }
        return [paidPercent, creditPercent];
    }, [paidPercent, creditPercent, paidSales, creditSales]);

    const hasData = totalSales > 0 || paidSales > 0 || creditSales > 0;

    return (
        <Paper sx={{ p: 3, borderRadius: '16px', bgcolor: '#fff', boxShadow: '0 4px 20px rgba(0,0,0,0.02)', height: '100%' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="subtitle1" fontWeight={700}>Sales Summary (24h)</Typography>
                {hasData && (
                    <Chip
                        icon={<TrendingUp size={14} />}
                        label={`${paidPercent}% Paid`}
                        size="small"
                        sx={{
                            bgcolor: '#dcfce7',
                            color: '#16a34a',
                            fontWeight: 700,
                            fontSize: '0.7rem'
                        }}
                    />
                )}
            </Box>

            {hasData ? (
                <Grid container spacing={2} sx={{ alignItems: 'center' }}>
                    <Grid size={{ xs: 7 }}>
                        <Box>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                <DollarSign size={20} color="#FF8C00" />
                                <Typography variant="h4" fontWeight={900}>NPRs. {totalSales.toLocaleString()}</Typography>
                            </Box>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5 }}>
                                <Typography variant="caption" color="#64748b">Net sales today</Typography>
                                {discount > 0 && (
                                    <Typography variant="caption" color="#94a3b8" sx={{ ml: 1 }}>
                                        (Gross: NPRs. {grossSales.toLocaleString()})
                                    </Typography>
                                )}
                            </Box>
                        </Box>
                        <Box sx={{ mt: 3 }}>
                            {[
                                { label: 'Paid Sales', val: `NPRs. ${paidSales.toLocaleString()}`, percent: paidPercent, color: '#22c55e', icon: <TrendingUp size={12} /> },
                                { label: 'Credit Sales', val: `NPRs. ${creditSales.toLocaleString()}`, percent: creditPercent, color: '#ff9800', icon: <TrendingDown size={12} /> },
                                { label: 'Discount Given', val: `NPRs. ${discount.toLocaleString()}`, percent: discountPercent, color: '#ef4444', icon: null },
                            ].map((item) => (
                                <Box key={item.label} sx={{ mb: 2 }}>
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: item.color }} />
                                            <Typography variant="caption" color="#64748b" sx={{ textTransform: 'capitalize' }}>
                                                {item.label}
                                            </Typography>
                                            {item.icon}
                                        </Box>
                                        <Typography variant="caption" fontWeight={700}>{item.val}</Typography>
                                    </Box>
                                    <LinearProgress
                                        variant="determinate"
                                        value={Math.min(item.percent, 100)}
                                        sx={{
                                            height: 4,
                                            borderRadius: 2,
                                            bgcolor: '#f1f5f9',
                                            '& .MuiLinearProgress-bar': { bgcolor: item.color }
                                        }}
                                    />
                                    {item.percent > 0 && (
                                        <Typography variant="caption" color="#94a3b8" fontSize="0.65rem">
                                            {item.percent}% of total
                                        </Typography>
                                    )}
                                </Box>
                            ))}
                        </Box>
                    </Grid>
                    <Grid size={{ xs: 5 }}>
                        <Box sx={{ position: 'relative', display: 'flex', justifyContent: 'center' }}>
                            <Chart options={options} series={series} type="donut" width={180} />
                        </Box>
                    </Grid>
                </Grid>
            ) : (
                <Box sx={{
                    py: 4,
                    textAlign: 'center',
                    color: '#94a3b8',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: 1
                }}>
                    <Avatar sx={{ bgcolor: '#f8fafc', color: '#cbd5e1', width: 60, height: 60 }}>
                        <DollarSign size={30} />
                    </Avatar>
                    <Typography variant="body2" fontWeight={600}>No Sales Data Yet</Typography>
                    <Typography variant="caption">Sales information will appear here once orders are placed</Typography>
                </Box>
            )}
        </Paper>
    );
};

export const OrderDetail: React.FC<{
    totalOrders?: number;
    dineInCount?: number;
    takeawayCount?: number;
    deliveryCount?: number;
}> = ({ totalOrders = 0, dineInCount = 0, takeawayCount = 0, deliveryCount = 0 }) => {

    // Calculate percentages
    const orderTypes = useMemo(() => [
        {
            label: 'Dine In',
            count: dineInCount,
            color: '#22c55e',
            progress: totalOrders > 0 ? Math.round((dineInCount / totalOrders) * 100) : 0,
            icon: '🍽️'
        },
        {
            label: 'Takeaway',
            count: takeawayCount,
            color: '#FF8C00',
            progress: totalOrders > 0 ? Math.round((takeawayCount / totalOrders) * 100) : 0,
            icon: '🛍️'
        },
        {
            label: 'Delivery',
            count: deliveryCount,
            color: '#ef4444',
            progress: totalOrders > 0 ? Math.round((deliveryCount / totalOrders) * 100) : 0,
            icon: '🚗'
        },
    ], [totalOrders, dineInCount, takeawayCount, deliveryCount]);

    // Find most popular order type
    const mostPopular = useMemo(() => {
        if (totalOrders === 0) return null;
        const sorted = [...orderTypes].sort((a, b) => b.count - a.count);
        return sorted[0].count > 0 ? sorted[0] : null;
    }, [orderTypes, totalOrders]);

    const hasOrders = totalOrders > 0;

    return (
        <Paper sx={{ p: 3, borderRadius: '16px', bgcolor: '#fff', boxShadow: '0 4px 20px rgba(0,0,0,0.02)', height: '100%' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Box>
                    <Typography variant="subtitle1" fontWeight={700}>Order Detail (24h)</Typography>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5 }}>
                        <Typography variant="caption" color="#64748b">Order breakdown by type</Typography>
                    </Box>
                </Box>
                <Box sx={{ textAlign: 'right' }}>
                    <Typography variant="h4" fontWeight={900}>{totalOrders}</Typography>
                    <Typography variant="caption" color="#64748b">Total Orders</Typography>
                </Box>
            </Box>

            {mostPopular && (
                <Chip
                    label={`${mostPopular.icon} ${mostPopular.label} is leading`}
                    size="small"
                    sx={{
                        mb: 2,
                        bgcolor: `${mostPopular.color}20`,
                        color: mostPopular.color,
                        fontWeight: 700,
                        fontSize: '0.7rem'
                    }}
                />
            )}

            {hasOrders ? (
                <Box sx={{ mt: 2 }}>
                    {orderTypes.map((item) => (
                        <Box key={item.label} sx={{ mb: 2.5 }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <Box sx={{ width: 12, height: 12, borderRadius: '50%', bgcolor: item.color }} />
                                    <Typography variant="body2" fontWeight={600}>{item.label}</Typography>
                                    <Avatar sx={{
                                        width: 24,
                                        height: 24,
                                        fontSize: 11,
                                        bgcolor: `${item.color}20`,
                                        color: item.color,
                                        fontWeight: 700
                                    }}>
                                        {item.count}
                                    </Avatar>
                                </Box>
                                <Typography variant="caption" color="#64748b" fontWeight={600}>
                                    {item.progress}%
                                </Typography>
                            </Box>
                            <LinearProgress
                                variant="determinate"
                                value={Math.min(item.progress, 100)}
                                sx={{
                                    height: 8,
                                    borderRadius: 4,
                                    bgcolor: '#f1f5f9',
                                    '& .MuiLinearProgress-bar': {
                                        bgcolor: item.color,
                                        borderRadius: 4
                                    }
                                }}
                            />
                        </Box>
                    ))}
                </Box>
            ) : (
                <Box sx={{
                    py: 4,
                    textAlign: 'center',
                    color: '#94a3b8',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    gap: 1,
                    mt: 2
                }}>
                    <Typography fontSize="3rem">📋</Typography>
                    <Typography variant="body2" fontWeight={600}>No Orders Yet</Typography>
                    <Typography variant="caption">Order breakdown will show here once you start processing orders</Typography>
                </Box>
            )}
        </Paper>
    );
};
