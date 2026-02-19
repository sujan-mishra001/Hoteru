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
    IconButton,
    TextField,
    InputAdornment
} from '@mui/material';
import { RefreshCw, Search, Calculator, TrendingUp, ShoppingCart, Database } from 'lucide-react';
import { inventoryAPI } from '../../../services/api';

const ProductionCount: React.FC = () => {
    const [productions, setProductions] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setLoading(true);
            console.log('Fetching productions...');
            const response = await inventoryAPI.getProductions();
            console.log('Productions data:', response.data);
            // Filter only for BOMs of type "menu"
            const data = (response.data || []).filter((p: any) => p.bom?.bom_type === 'menu');
            setProductions(data);
        } catch (error) {
            console.error('Error loading production data:', error);
        } finally {
            setLoading(false);
        }
    };

    // Aggregate productions by menu item name
    const aggregatedProductions = React.useMemo(() => {
        const groups: { [key: string]: any } = {};

        productions.forEach(p => {
            const name = p.bom?.menu_items?.[0]?.name || p.bom?.name || 'Unknown Item';
            if (!groups[name]) {
                groups[name] = {
                    name,
                    total_produced: 0,
                    consumed_quantity: 0,
                    remaining_quantity: 0
                };
            }
            groups[name].total_produced += Number(p.total_produced || 0);
            groups[name].consumed_quantity += Number(p.consumed_quantity || 0);
            groups[name].remaining_quantity += Number(p.remaining_quantity || 0);
        });

        return Object.values(groups);
    }, [productions]);

    const filteredProductions = aggregatedProductions.filter(p => {
        return p.name.toLowerCase().includes(searchTerm.toLowerCase());
    });

    return (
        <Box>
            <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Box sx={{ p: 1.5, bgcolor: '#f0f9ff', borderRadius: '12px', color: '#0ea5e9' }}>
                        <Calculator size={28} />
                    </Box>
                    <Box>
                        <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b' }}>Production Count</Typography>
                        <Typography variant="body2" color="text.secondary">Cumulative tracking of menu item yields and sales</Typography>
                    </Box>
                </Box>
                <IconButton onClick={loadData} disabled={loading} sx={{ bgcolor: '#fff', border: '1px solid #e2e8f0' }}>
                    <RefreshCw size={20} className={loading ? 'animate-spin' : ''} />
                </IconButton>
            </Box>

            <Paper sx={{ p: 2, mb: 3, borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: 'none' }}>
                <TextField
                    size="small"
                    placeholder="Search by menu item..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    InputProps={{
                        startAdornment: (
                            <InputAdornment position="start">
                                <Search size={18} color="#94a3b8" />
                            </InputAdornment>
                        ),
                    }}
                    sx={{
                        width: 350,
                        '& .MuiOutlinedInput-root': {
                            bgcolor: '#f8fafc',
                            borderRadius: '10px'
                        }
                    }}
                />
            </Paper>

            <TableContainer component={Paper} sx={{ borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: 'none' }}>
                <Table stickyHeader>
                    <TableHead>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 800, bgcolor: '#f8fafc', color: '#475569' }}>Menu Item</TableCell>
                            <TableCell sx={{ fontWeight: 800, bgcolor: '#f8fafc', color: '#475569' }}>Total Produced</TableCell>
                            <TableCell sx={{ fontWeight: 800, bgcolor: '#f8fafc', color: '#475569' }}>Total Sold</TableCell>
                            <TableCell sx={{ fontWeight: 800, bgcolor: '#f8fafc', color: '#475569' }}>Available Stock</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={4} align="center" sx={{ py: 8 }}>
                                    <CircularProgress size={32} thickness={5} sx={{ color: '#0ea5e9' }} />
                                    <Typography sx={{ mt: 2, color: '#64748b', fontWeight: 600 }}>Calculating balances...</Typography>
                                </TableCell>
                            </TableRow>
                        ) : filteredProductions.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={4} align="center" sx={{ py: 8 }}>
                                    <Typography color="text.secondary" fontWeight={600}>No menu item production records found.</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            filteredProductions.map((p, index) => (
                                <TableRow key={index} hover sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                                    <TableCell>
                                        <Typography fontWeight={700} color="#1e293b">
                                            {p.name}
                                        </Typography>
                                    </TableCell>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <TrendingUp size={14} color="#16a34a" />
                                            <Typography fontWeight={800} color="#16a34a">{p.total_produced.toLocaleString()}</Typography>
                                        </Box>
                                    </TableCell>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <ShoppingCart size={14} color="#f59e0b" />
                                            <Typography fontWeight={700} color="#f59e0b">{p.consumed_quantity.toLocaleString()}</Typography>
                                        </Box>
                                    </TableCell>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <Database size={14} color="#0ea5e9" />
                                            <Typography fontWeight={800} color="#0ea5e9">{p.remaining_quantity.toLocaleString()}</Typography>
                                        </Box>
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>
        </Box>
    );
};

export default ProductionCount;
