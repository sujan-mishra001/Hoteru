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
    Button,

    Breadcrumbs,
    Link as MuiLink,
} from '@mui/material';
import { BarChart3, RotateCcw, ChevronRight } from 'lucide-react';
import { reportsAPI } from '../../services/api';
import { Link as RouterLink, useParams } from 'react-router-dom';

const MonthlySalesReport: React.FC = () => {
    const { branchSlug } = useParams();
    const currentYear = new Date().getFullYear();
    const [year] = useState(currentYear);
    const [loading, setLoading] = useState(false);
    const [data, setData] = useState<any[]>([]);

    const months = [
        "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
        "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
    ];

    const loadData = async () => {
        try {
            setLoading(true);
            const response = await reportsAPI.getMonthlySales({ year });
            setData(response.data);
        } catch (error) {
            console.error('Failed to load monthly sales:', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadData();
    }, [year]);



    return (
        <Box>
            <Breadcrumbs separator={<ChevronRight size={14} />} sx={{ mb: 2 }}>
                <MuiLink component={RouterLink} to={`/${branchSlug}/reports`} underline="hover" color="inherit">
                    Reports
                </MuiLink>
                <Typography color="text.primary" sx={{ fontWeight: 600 }}>Monthly Sales Summary</Typography>
            </Breadcrumbs>

            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h5" fontWeight={800} sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                    <BarChart3 size={28} color="#3b82f6" />
                    Monthly Sales Summary
                </Typography>
                <Box sx={{ display: 'flex', gap: 2 }}>
                    <Button
                        variant="outlined"
                        startIcon={<RotateCcw size={18} />}
                        onClick={loadData}
                        sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600 }}
                    >
                        Refresh
                    </Button>
                </Box>
            </Box>



            <Box sx={{ mb: 2, textAlign: 'center' }}>
                <Typography variant="h6" fontWeight={700}>For the period {year}/{year + 1}</Typography>
            </Box>

            <TableContainer component={Paper} sx={{ borderRadius: '16px', border: '1px solid #f1f5f9' }} elevation={0}>
                <Table sx={{ minWidth: 1500 }}>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700, width: 200 }}>PARTICULARS</TableCell>
                            {months.map((month, idx) => (
                                <TableCell key={idx} align="right" sx={{ fontWeight: 700 }}>
                                    {month} {year}
                                </TableCell>
                            ))}
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={13} align="center" sx={{ py: 10 }}>
                                    <CircularProgress sx={{ color: '#3b82f6' }} />
                                </TableCell>
                            </TableRow>
                        ) : data.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={13} align="center" sx={{ py: 10 }}>
                                    <Typography color="text.secondary">No records found for the selected year</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            data.map((row, idx) => (
                                <TableRow key={idx} hover>
                                    <TableCell sx={{ fontWeight: 700, bgcolor: '#f8fafc' }}>{row.particular}</TableCell>
                                    {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].map(m => (
                                        <TableCell key={m} align="right">
                                            {row[`month_${m}`].toLocaleString(undefined, { minimumFractionDigits: 2 })}
                                        </TableCell>
                                    ))}
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>
        </Box>
    );
};

export default MonthlySalesReport;
