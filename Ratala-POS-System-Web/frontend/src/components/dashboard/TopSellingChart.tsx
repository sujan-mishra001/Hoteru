import React, { useMemo } from 'react';
import { Box, Typography, Paper, Chip } from '@mui/material';
import { TrendingUp } from 'lucide-react';
import Chart from 'react-apexcharts';

export const TopSellingItemsChart: React.FC<{
    items: Array<{ name: string; quantity: number; revenue: number }>;
}> = ({ items }) => {
    const hasData = items && items.length > 0;
    const totalRevenue = useMemo(() => items.reduce((sum, item) => sum + item.revenue, 0), [items]);
    const topItem = useMemo(() => items.length > 0 ? items[0] : null, [items]);

    // Color palette for bars
    const colors = ['#10b981', '#22c55e', '#4ade80', '#86efac', '#bbf7d0'];

    return (
        <Paper sx={{
            p: 3,
            borderRadius: '16px',
            bgcolor: '#fff',
            boxShadow: '0 4px 20px rgba(0,0,0,0.02)',
            height: '100%'
        }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Box>
                    <Typography variant="subtitle2" fontWeight={700} color="#64748b">
                        Top 3 Selling Items
                    </Typography>
                    {topItem && (
                        <Typography variant="caption" color="#10b981" sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5 }}>
                            <TrendingUp size={12} />
                            Best: {topItem.name}
                        </Typography>
                    )}
                </Box>
                {hasData && (
                    <Chip
                        label={`NPRs. ${totalRevenue.toLocaleString()}`}
                        size="small"
                        sx={{
                            bgcolor: '#ecfdf5',
                            color: '#10b981',
                            fontWeight: 700,
                            fontSize: '0.65rem',
                            height: '20px'
                        }}
                    />
                )}
            </Box>

            {hasData ? (
                <>
                    {/* Horizontal Bar Chart */}
                    <Box sx={{ mt: 2 }}>
                        <Chart
                            options={{
                                chart: {
                                    type: 'bar',
                                    toolbar: { show: false },
                                    animations: {
                                        enabled: true,
                                        speed: 800
                                    }
                                },
                                plotOptions: {
                                    bar: {
                                        horizontal: true,
                                        borderRadius: 6,
                                        barHeight: '60%',
                                        distributed: true
                                    }
                                },
                                colors: colors.slice(0, items.length),
                                dataLabels: {
                                    enabled: true,
                                    formatter: (val: number) => `NPRs. ${val.toLocaleString()}`,
                                    style: {
                                        fontSize: '10px',
                                        fontWeight: 800,
                                        colors: ['#1e293b']
                                    },
                                    offsetX: 10,
                                    background: {
                                        enabled: true,
                                        foreColor: '#fff',
                                        padding: 4,
                                        borderRadius: 4,
                                        borderWidth: 0,
                                        opacity: 0.9,
                                        dropShadow: { enabled: false }
                                    }
                                },
                                xaxis: {
                                    categories: items.map((item) => item.name),
                                    labels: {
                                        formatter: (val: any) => `₹${(Number(val) / 1000).toFixed(1)}k`,
                                        style: {
                                            fontSize: '9px',
                                            colors: '#94a3b8'
                                        }
                                    }
                                },
                                yaxis: {
                                    labels: {
                                        style: {
                                            fontSize: '11px',
                                            colors: '#1e293b',
                                            fontWeight: 700
                                        }
                                    }
                                },
                                grid: {
                                    borderColor: '#f1f5f9',
                                    xaxis: {
                                        lines: { show: true }
                                    },
                                    yaxis: {
                                        lines: { show: false }
                                    }
                                },
                                tooltip: {
                                    theme: 'light',
                                    y: {
                                        formatter: (val) => `NPRs. ${val.toLocaleString()}`
                                    }
                                },
                                legend: { show: false }
                            }}
                            series={[{
                                name: 'Revenue',
                                data: items.map(item => item.revenue)
                            }]}
                            type="bar"
                            height={160}
                        />
                    </Box>

                    {/* Item Statistics Grid */}
                    <Box sx={{ mt: 3, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 1.5 }}>
                        {items.slice(0, 3).map((item, index) => (
                            <Box key={item.name} sx={{
                                p: 1.5,
                                bgcolor: index === 0 ? '#10b98108' : '#f8fafc',
                                borderRadius: '12px',
                                border: index === 0 ? '1px solid #10b98120' : '1px solid #e2e8f0',
                                textAlign: 'center'
                            }}>
                                <Typography variant="caption" color="#64748b" sx={{ display: 'block', mb: 0.5, fontWeight: 700, fontSize: '0.6rem', textTransform: 'uppercase' }}>
                                    {index === 0 ? 'TOP SELLER' : `Rank #${index + 1}`}
                                </Typography>
                                <Typography variant="body2" fontWeight={800} color="#1e293b" noWrap sx={{ mb: 0.5 }}>
                                    {item.name}
                                </Typography>
                                <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                                    <Typography variant="body2" fontWeight={900} color={index === 0 ? '#10b981' : '#1e293b'}>
                                        NPRs. {item.revenue.toLocaleString()}
                                    </Typography>
                                    <Typography variant="caption" color="#94a3b8" sx={{ fontSize: '0.65rem' }}>
                                        {item.quantity} units
                                    </Typography>
                                </Box>
                            </Box>
                        ))}
                    </Box>
                </>
            ) : (
                <Box sx={{ opacity: 0.2, pointerEvents: 'none' }}>
                    <Chart
                        options={{
                            chart: { type: 'bar', toolbar: { show: false } },
                            plotOptions: { bar: { horizontal: true, borderRadius: 6, barHeight: '60%', distributed: true } },
                            colors: ['#e2e8f0', '#e2e8f0', '#e2e8f0'],
                            xaxis: { categories: ['Item A', 'Item B', 'Item C'], labels: { show: false } },
                            yaxis: { labels: { show: false } },
                            grid: { show: false },
                            dataLabels: { enabled: false }
                        }}
                        series={[{ data: [80, 60, 45] }]}
                        type="bar"
                        height={160}
                    />
                    <Box sx={{ mt: 3, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 1.5 }}>
                        {[1, 2, 3].map((i) => (
                            <Box key={i} sx={{ p: 1.5, bgcolor: '#f1f5f9', borderRadius: '12px', height: 60 }} />
                        ))}
                    </Box>
                </Box>
            )}
        </Paper>
    );
};
