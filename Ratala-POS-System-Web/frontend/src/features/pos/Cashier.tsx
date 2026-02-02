import React, { useState, useEffect, useRef } from 'react';
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
    Button,
    Chip,
    TextField,
    InputAdornment,
    Dialog,
    DialogContent,
    DialogActions,
    IconButton
} from '@mui/material';
import { Search, Receipt, Download, Printer, X } from 'lucide-react';
import { ordersAPI } from '../../services/api';
import { useReactToPrint } from 'react-to-print';
import { useBranch } from '../../app/providers/BranchProvider';
import BillView from './billing/BillView';
import html2canvas from 'html2canvas';
import jsPDF from 'jspdf';

const Cashier: React.FC = () => {
    const [orders, setOrders] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const { currentBranch } = useBranch();
    const [searchTerm, setSearchTerm] = useState('');
    const [selectedOrder, setSelectedOrder] = useState<any>(null);
    const [billDialogOpen, setBillDialogOpen] = useState(false);

    const billRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        loadOrders();
    }, []);

    const loadOrders = async () => {
        try {
            setLoading(true);
            const response = await ordersAPI.getAll();
            // Show only unsettled orders: Pending, In Progress, or Completed (served but not yet paid)
            const runningStatuses = ['Pending', 'In Progress', 'Completed'];
            const cashierOrders = (response.data || []).filter((order: any) =>
                runningStatuses.includes(order.status)
            );
            setOrders(cashierOrders);
        } catch (error) {
            console.error('Error loading orders:', error);
            setOrders([]);
        } finally {
            setLoading(false);
        }
    };

    const handlePrintBill = (order: any) => {
        setSelectedOrder(order);
        setBillDialogOpen(true);
    };

    const handlePrint = useReactToPrint({
        contentRef: billRef,
        documentTitle: `Bill_${selectedOrder?.order_number}`,
        onAfterPrint: () => console.log("Print Success"),
        onPrintError: () => alert("Printer not found or error occurred while printing.")
    });

    const handleDownloadPDF = async () => {
        if (!billRef.current) return;

        try {
            const canvas = await html2canvas(billRef.current, {
                scale: 2,
                logging: false,
                useCORS: true
            });
            const imgData = canvas.toDataURL('image/png');
            const pdf = new jsPDF({
                unit: 'mm',
                format: [80, 200] // Thermal roll format
            });

            const imgProps = pdf.getImageProperties(imgData);
            const pdfWidth = pdf.internal.pageSize.getWidth();
            const pdfHeight = (imgProps.height * pdfWidth) / imgProps.width;

            pdf.addImage(imgData, 'PNG', 0, 0, pdfWidth, pdfHeight);
            pdf.save(`Bill_${selectedOrder?.order_number}.pdf`);
        } catch (error) {
            console.error("PDF Export Error:", error);
            alert("Failed to generate PDF");
        }
    };

    const filteredOrders = orders.filter(order =>
        order.order_number?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        order.customer?.name?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <Box>
            <Box sx={{ mb: 4 }}>
                <Typography variant="h5" fontWeight={800} sx={{ mb: 1 }}>Cashier</Typography>
                <Typography variant="body2" color="text.secondary">Manage payments and bills</Typography>
            </Box>

            <Paper sx={{ p: 2, mb: 3, borderRadius: '12px' }}>
                <TextField
                    size="small"
                    placeholder="Search orders..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    InputProps={{
                        startAdornment: (
                            <InputAdornment position="start">
                                <Search size={18} color="#64748b" />
                            </InputAdornment>
                        ),
                    }}
                    sx={{ width: 300 }}
                />
            </Paper>

            <TableContainer component={Paper} sx={{ borderRadius: '16px' }}>
                <Table>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700 }}>Order ID</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Table/Customer</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Order Type</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Order Time</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Total Amount</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Status</TableCell>
                            <TableCell sx={{ fontWeight: 700 }} align="right">Actions</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={7} align="center">Loading...</TableCell>
                            </TableRow>
                        ) : filteredOrders.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={7} align="center">No orders found for cashier.</TableCell>
                            </TableRow>
                        ) : (
                            filteredOrders.map((order) => (
                                <TableRow key={order.id} hover>
                                    <TableCell sx={{ fontWeight: 600 }}>{order.order_number || 'N/A'}</TableCell>
                                    <TableCell>
                                        <Box>
                                            <Typography variant="body2" fontWeight={700}>
                                                {order.table?.table_id ? `Table ${order.table.table_id}` : (order.customer?.name || 'Walk-in')}
                                            </Typography>
                                            {order.table?.table_id && order.customer?.name && (
                                                <Typography variant="caption" color="text.secondary">
                                                    {order.customer.name}
                                                </Typography>
                                            )}
                                        </Box>
                                    </TableCell>
                                    <TableCell>{order.order_type || 'N/A'}</TableCell>
                                    <TableCell>
                                        {new Date(order.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                    </TableCell>
                                    <TableCell sx={{ fontWeight: 700 }}>NPRs. {order.net_amount?.toLocaleString() || 0}</TableCell>
                                    <TableCell>
                                        <Chip
                                            label={order.status || 'Pending'}
                                            size="small"
                                            sx={{
                                                bgcolor: order.status === 'Paid' || order.status === 'Completed' ? '#22c55e15' : '#f59e0b15',
                                                color: order.status === 'Paid' || order.status === 'Completed' ? '#22c55e' : '#f59e0b',
                                                fontWeight: 700
                                            }}
                                        />
                                    </TableCell>
                                    <TableCell align="right">
                                        <Button
                                            size="small"
                                            startIcon={<Receipt size={14} />}
                                            onClick={() => handlePrintBill(order)}
                                            sx={{ color: '#FF8C00', textTransform: 'none', mr: 1 }}
                                        >
                                            Bill
                                        </Button>
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            {/* Bill Preview Dialog */}
            <Dialog
                open={billDialogOpen}
                onClose={() => setBillDialogOpen(false)}
                maxWidth="xs"
                fullWidth
                PaperProps={{ sx: { borderRadius: '16px' } }}
            >
                <Box sx={{ p: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #f1f5f9' }}>
                    <Typography variant="h6" fontWeight={800}>Bill Preview</Typography>
                    <IconButton onClick={() => setBillDialogOpen(false)} size="small"><X size={20} /></IconButton>
                </Box>
                <DialogContent sx={{ p: 0, bgcolor: '#f8fafc' }}>
                    <Box sx={{ p: 2 }}>
                        <Paper elevation={0} sx={{ p: 0, overflow: 'hidden', border: '1px solid #e2e8f0', borderRadius: '8px' }}>
                            <BillView ref={billRef} order={selectedOrder} branch={currentBranch} />
                        </Paper>
                    </Box>
                </DialogContent>
                <DialogActions sx={{ p: 2, gap: 1 }}>
                    <Button
                        fullWidth
                        variant="outlined"
                        startIcon={<Download size={18} />}
                        onClick={handleDownloadPDF}
                        sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 700 }}
                    >
                        Save as PDF
                    </Button>
                    <Button
                        fullWidth
                        variant="contained"
                        startIcon={<Printer size={18} />}
                        onClick={() => handlePrint()}
                        sx={{ borderRadius: '10px', bgcolor: '#FF8C00', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', fontWeight: 700 }}
                    >
                        Print Bill
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default Cashier;
