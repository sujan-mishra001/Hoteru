
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
    LinearProgress,
    TextField,
    InputAdornment
} from '@mui/material';
import { History, Search, Package } from 'lucide-react';
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
            const res = await inventoryAPI.getProductions();
            setProductions(res.data || []);
        } catch (error) {
            console.error('Error loading production data:', error);
        } finally {
            setLoading(false);
        }
    };

    const filteredProductions = productions.filter(prod =>
        prod.production_number?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        prod.bom?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        prod.bom?.menu_items?.some((mi: any) => mi.name.toLowerCase().includes(searchTerm.toLowerCase())) ||
        prod.bom?.finished_product?.name?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <Box sx={{ p: 1 }}>
            <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                    <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b', mb: 0.5 }}>Production Count</Typography>
                    <Typography variant="body2" color="text.secondary">Detailed tracking of produced batches, sales, and remaining stock.</Typography>
                </Box>
                <Box>
                    <TextField
                        placeholder="Search production..."
                        size="small"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        InputProps={{
                            startAdornment: <InputAdornment position="start"><Search size={18} color="#94a3b8" /></InputAdornment>
                        }}
                        sx={{ bgcolor: 'white', borderRadius: '8px' }}
                    />
                </Box>
            </Box>

            <TableContainer component={Paper} sx={{ borderRadius: '20px', boxShadow: '0 4px 20px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
                <Table>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>PROD #</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>ITEM NAME</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>RECIPE</TableCell>
                            <TableCell align="right" sx={{ fontWeight: 700, color: '#64748b' }}>PRODUCED</TableCell>
                            <TableCell align="right" sx={{ fontWeight: 700, color: '#64748b' }}>SOLD</TableCell>
                            <TableCell align="right" sx={{ fontWeight: 700, color: '#64748b' }}>REMAINING</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={8} align="center" sx={{ py: 8 }}>
                                    <LinearProgress sx={{ width: '200px', mx: 'auto', borderRadius: '5px' }} />
                                    <Typography sx={{ mt: 2 }} color="text.secondary">Loading data...</Typography>
                                </TableCell>
                            </TableRow>
                        ) : filteredProductions.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={6} align="center" sx={{ py: 10 }}>
                                    <History size={48} color="#94a3b8" style={{ marginBottom: '16px' }} />
                                    <Typography variant="h6" color="text.secondary">No production records found.</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            filteredProductions.map((prod) => (
                                <TableRow key={prod.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                                    <TableCell sx={{ fontWeight: 700, color: '#1e293b' }}>
                                        {prod.production_number}
                                    </TableCell>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <Package size={16} color="#FFC107" />
                                            <Typography variant="body2" sx={{ fontWeight: 700 }}>
                                                {prod.bom?.menu_items?.length > 0
                                                    ? prod.bom.menu_items.map((mi: any) => mi.name).join(', ')
                                                    : (prod.bom?.finished_product?.name || 'Batch Item')}
                                            </Typography>
                                        </Box>
                                    </TableCell>
                                    <TableCell>
                                        <Typography variant="body2" color="text.secondary">{prod.bom?.name}</Typography>
                                    </TableCell>
                                    <TableCell align="right" sx={{ fontWeight: 700 }}>
                                        {prod.total_produced}
                                    </TableCell>
                                    <TableCell align="right" sx={{ fontWeight: 700, color: '#ef4444' }}>
                                        {prod.consumed_quantity}
                                    </TableCell>
                                    <TableCell align="right">
                                        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end' }}>
                                            <Typography variant="body2" sx={{ fontWeight: 800, color: prod.remaining_quantity <= 0 ? '#ef4444' : '#10b981' }}>
                                                {prod.remaining_quantity.toFixed(1)}
                                            </Typography>
                                            <Box sx={{ width: 60, height: 4, bgcolor: '#f1f5f9', borderRadius: 2, mt: 0.5, overflow: 'hidden' }}>
                                                <Box sx={{
                                                    width: `${Math.max(0, Math.min(100, (prod.remaining_quantity / prod.total_produced) * 100))}%`,
                                                    height: '100%',
                                                    bgcolor: prod.remaining_quantity <= 0 ? '#ef4444' : '#10b981'
                                                }} />
                                            </Box>
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
