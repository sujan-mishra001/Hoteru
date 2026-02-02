import React, { useMemo } from 'react';
import { Box, Typography, Paper, Grid, Avatar, Chip, LinearProgress } from '@mui/material';
import { InfoOutlined } from '@mui/icons-material';
import { TrendingUp, MapPin, AlertCircle } from 'lucide-react';

export const OutstandingRevenue: React.FC<{ amount: number }> = ({ amount }) => {
    // Determine urgency level based on amount
    const urgencyLevel = useMemo(() => {
        if (amount >= 50000) return { level: 'high', color: '#ef4444', label: 'High Priority' };
        if (amount >= 20000) return { level: 'medium', color: '#ff9800', label: 'Medium Priority' };
        if (amount > 0) return { level: 'low', color: '#22c55e', label: 'Low Priority' };
        return { level: 'none', color: '#64748b', label: 'All Clear' };
    }, [amount]);

    const hasOutstanding = amount > 0;

    return (
        <Paper sx={{
            p: 3,
            borderRadius: '16px',
            bgcolor: '#fff',
            boxShadow: '0 4px 20px rgba(0,0,0,0.02)',
            height: '100%',
            border: urgencyLevel.level === 'high' ? '2px solid #fecaca' : '1px solid transparent'
        }}>
            <Box sx={{ display: 'flex', gap: 2, alignItems: 'flex-start' }}>
                <Avatar
                    src="/logo.png"
                    sx={{
                        width: 50,
                        height: 50,
                        bgcolor: `${urgencyLevel.color}20`,
                        border: `2px solid ${urgencyLevel.color}40`
                    }}
                />
                <Box sx={{ flexGrow: 1 }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                            <Typography variant="subtitle2" fontWeight={700} color="#64748b">
                                Outstanding Revenue
                            </Typography>
                            <InfoOutlined sx={{ fontSize: 14, color: '#94a3b8' }} />
                        </Box>
                        {hasOutstanding && (
                            <Chip
                                icon={<AlertCircle size={12} />}
                                label={urgencyLevel.label}
                                size="small"
                                sx={{
                                    bgcolor: `${urgencyLevel.color}20`,
                                    color: urgencyLevel.color,
                                    fontWeight: 700,
                                    fontSize: '0.65rem',
                                    height: '20px'
                                }}
                            />
                        )}
                    </Box>
                    <Box sx={{ display: 'flex', alignItems: 'baseline', gap: 1 }}>
                        <Typography variant="h5" fontWeight={900} color={urgencyLevel.color}>
                            NPRs. {amount.toLocaleString()}
                        </Typography>
                        {hasOutstanding && (
                            <Typography variant="caption" color="#94a3b8">
                                to collect
                            </Typography>
                        )}
                    </Box>
                </Box>
            </Box>
            <Box sx={{ mt: 3, p: 2, bgcolor: hasOutstanding ? '#fef3f2' : '#f8fafc', borderRadius: '10px' }}>
                <Typography variant="caption" color="#64748b" sx={{ display: 'block', lineHeight: 1.5 }}>
                    {hasOutstanding ? (
                        <>
                            💡 <strong>Action Required:</strong> This shows the total credit amount from orders that need to be collected.
                            {urgencyLevel.level === 'high' && ' Consider following up with customers for payment.'}
                        </>
                    ) : (
                        <>
                            ✅ <strong>Great!</strong> No pending credit sales. All orders have been fully paid.
                        </>
                    )}
                </Typography>
            </Box>
        </Paper>
    );
};

export const SalesByArea: React.FC<{
    data: Array<{ area: string; amount: number }>;
    occupancy?: { percentage: number; occupied: number; total: number };
}> = ({ data, occupancy }) => {

    // Calculate totals
    const totalFloorSales = useMemo(() => {
        return data.reduce((sum, item) => sum + item.amount, 0);
    }, [data]);

    // Find top performing floor
    const topFloor = useMemo(() => {
        if (data.length === 0) return null;
        return [...data].sort((a, b) => b.amount - a.amount)[0];
    }, [data]);

    // Calculate percentages for each floor
    const floorsWithPercentage = useMemo(() => {
        return data.map(floor => ({
            ...floor,
            percentage: totalFloorSales > 0 ? Math.round((floor.amount / totalFloorSales) * 100) : 0
        }));
    }, [data, totalFloorSales]);

    // Status color for occupancy
    const statusColor = useMemo(() => {
        if (!occupancy) return '#22c55e';
        if (occupancy.percentage >= 80) return '#ef4444';
        if (occupancy.percentage >= 50) return '#FF8C00';
        return '#22c55e';
    }, [occupancy]);

    // Base UI
    return (
        <Paper sx={{ p: 3, borderRadius: '16px', bgcolor: '#fff', boxShadow: '0 4px 20px rgba(0,0,0,0.02)', height: '100%' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Box>
                    <Typography variant="subtitle1" fontWeight={700}>Floor Performance</Typography>
                    {topFloor && (
                        <Typography variant="caption" color="#64748b" sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5 }}>
                            <TrendingUp size={12} />
                            {topFloor.area} is leading in sales
                        </Typography>
                    )}
                </Box>
            </Box>
            <Grid container spacing={3} sx={data.length === 0 ? { opacity: 0.2, pointerEvents: 'none' } : {}}>
                <Grid size={{ xs: 12, md: 8.5 }}>
                    <Box sx={{ display: 'flex', gap: 4, flexDirection: { xs: 'column', sm: 'row' } }}>
                        <Box sx={{ minWidth: '140px' }}>
                            <Typography variant="h4" fontWeight={900}>NPRs. {totalFloorSales.toLocaleString()}</Typography>
                            <Typography variant="caption" color="#64748b" sx={{ fontWeight: 600 }}>Total Floor Sales</Typography>
                            <Typography variant="caption" color="#94a3b8" sx={{ display: 'block', mt: 0.5 }}>
                                Across {data.length || 3} areas
                            </Typography>
                        </Box>
                        <Box sx={{ flexGrow: 1 }}>
                            {(data.length > 0 ? floorsWithPercentage : [
                                { area: 'Main Hall', amount: 0, percentage: 60 },
                                { area: 'Terrace', amount: 0, percentage: 40 },
                                { area: 'Private Room', amount: 0, percentage: 20 }
                            ]).map((item) => (
                                <Box key={item.area} sx={{ mb: 2 }}>
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 0.5 }}>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <MapPin size={12} color="#64748b" />
                                            <Typography variant="caption" color="#64748b" fontWeight={600}>
                                                {item.area}
                                            </Typography>
                                        </Box>
                                        <Typography variant="caption" fontWeight={700}>
                                            NPRs. {item.amount.toLocaleString()}
                                        </Typography>
                                    </Box>
                                    <LinearProgress
                                        variant="determinate"
                                        value={item.percentage}
                                        sx={{
                                            height: 6,
                                            borderRadius: 3,
                                            bgcolor: '#f1f5f9',
                                            '& .MuiLinearProgress-bar': {
                                                bgcolor: '#64748b',
                                                borderRadius: 3
                                            }
                                        }}
                                    />
                                </Box>
                            ))}
                        </Box>
                    </Box>
                </Grid>
                <Grid size={{ xs: 12, md: 3.5 }} sx={{ borderLeft: { md: '1px solid #f1f5f9' }, pl: { md: 3 } }}>
                    <Typography variant="caption" color="#64748b" fontWeight={800} sx={{ display: 'block', mb: 2, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                        Live Occupancy
                    </Typography>

                    {occupancy ? (
                        <Box sx={{ p: 2, bgcolor: `${statusColor}08`, borderRadius: '12px', border: `1px solid ${statusColor}20` }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
                                <Typography variant="h5" fontWeight={900} color={statusColor}>
                                    {Math.round(occupancy.percentage)}%
                                </Typography>
                                <Chip
                                    label={occupancy.percentage >= 80 ? 'Busy' : occupancy.percentage >= 50 ? 'Moderate' : 'Smooth'}
                                    size="small"
                                    sx={{
                                        height: '18px',
                                        fontSize: '0.65rem',
                                        fontWeight: 800,
                                        bgcolor: `${statusColor}20`,
                                        color: statusColor
                                    }}
                                />
                            </Box>
                            <Typography variant="caption" color="text.secondary" fontWeight={600} sx={{ display: 'block', mb: 1 }}>
                                {occupancy.occupied} / {occupancy.total} Tables Active
                            </Typography>
                            <LinearProgress
                                variant="determinate"
                                value={occupancy.percentage}
                                sx={{
                                    height: 4,
                                    borderRadius: 2,
                                    bgcolor: `${statusColor}15`,
                                    '& .MuiLinearProgress-bar': {
                                        bgcolor: statusColor,
                                        borderRadius: 2
                                    }
                                }}
                            />
                        </Box>
                    ) : (
                        <Box sx={{ p: 2, bgcolor: '#f8fafc', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                            <Typography variant="h5" fontWeight={900} color="#cbd5e1">0%</Typography>
                            <Typography variant="caption" color="#cbd5e1">0/0 Tables Active</Typography>
                        </Box>
                    )}

                    <Box sx={{ mt: 3 }}>
                        <Typography variant="caption" color="#94a3b8" fontWeight={700} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: '#FF8C00' }} />
                            High Performing Zone
                        </Typography>
                        <Typography variant="body2" fontWeight={800} sx={{ mt: 0.5, ml: 2, color: '#2C1810' }}>
                            {topFloor?.area || 'N/A'}
                        </Typography>
                    </Box>
                </Grid>
            </Grid>
        </Paper>
    );
};

