import React, { useState, useEffect, useRef } from 'react';
import {
    Box,
    Typography,
    Paper,
    Button,
    IconButton,
    Divider,
    Grid,
    CircularProgress,
    TextField,
    Stack,
    Chip,
    Tooltip,
} from '@mui/material';
import {
    ArrowLeft,
    Banknote,
    CreditCard,
    Smartphone,
    Printer,
    CheckCircle2,
    UserCircle,
    Download,
    X,
    History
} from 'lucide-react';
import { useNavigate, useParams, useLocation } from 'react-router-dom';
import { ordersAPI, tablesAPI, settingsAPI } from '../../../services/api';
import { useReactToPrint } from 'react-to-print';
import BillView from './BillView';
import { Dialog, DialogContent, DialogActions } from '@mui/material';
import html2canvas from 'html2canvas';
import jsPDF from 'jspdf';
import { useBranch } from '../../../app/providers/BranchProvider';
import { useNotification } from '../../../app/providers/NotificationProvider';
import { useActivity } from '../../../app/providers/ActivityProvider';

const Billing: React.FC = () => {
    const navigate = useNavigate();
    const { tableId } = useParams<{ tableId: string }>();
    const location = useLocation();
    const tableInfo = location.state?.table;
    const { currentBranch } = useBranch();
    const { showAlert } = useNotification();
    const { logActivity } = useActivity();
    const [loading, setLoading] = useState(true);
    const [table, setTable] = useState<any>(tableInfo);
    const [order, setOrder] = useState<any>(null);
    const [paymentModes, setPaymentModes] = useState<any[]>([]);
    const [selectedPaymentMode, setSelectedPaymentMode] = useState('Cash');
    const [paidAmount, setPaidAmount] = useState<number>(0);
    const [billDialogOpen, setBillDialogOpen] = useState(false);
    const [isPaid, setIsPaid] = useState(false);
    const [companySettings, setCompanySettings] = useState<any>(null);
    const billRef = useRef<HTMLDivElement>(null);

    const handlePrint = useReactToPrint({
        contentRef: billRef,
        documentTitle: `Bill_${order?.order_number}`,
        onPrintError: () => showAlert("Printer not found or error occurred while printing.", 'error')
    });

    const handleDownloadPDF = async () => {
        if (!billRef.current) return;
        try {
            const canvas = await html2canvas(billRef.current, { scale: 2 });
            const imgData = canvas.toDataURL('image/png');
            const pdf = new jsPDF({ unit: 'mm', format: [80, 200] });
            const imgProps = pdf.getImageProperties(imgData);
            const pdfWidth = pdf.internal.pageSize.getWidth();
            const pdfHeight = (imgProps.height * pdfWidth) / imgProps.width;
            pdf.addImage(imgData, 'PNG', 0, 0, pdfWidth, pdfHeight);
            pdf.save(`Bill_${order?.order_number}.pdf`);
        } catch (error) {
            console.error("PDF Export Error:", error);
            showAlert("Failed to generate PDF", 'error');
        }
    };

    useEffect(() => {
        loadData();
    }, [tableId]);

    const loadData = async () => {
        try {
            setLoading(true);

            // 1. Get Table Info
            let currentTable = tableInfo;
            if (!currentTable && tableId) {
                const tableRes = await tablesAPI.getById(parseInt(tableId));
                currentTable = tableRes.data;
                setTable(currentTable);
            }

            // 2. Get Active Order for this table
            const ordersRes = await ordersAPI.getAll();
            const allOrders = ordersRes.data || [];
            const activeOrder = allOrders.find((o: any) =>
                o.table_id === parseInt(tableId!) &&
                o.status !== 'Completed' &&
                o.status !== 'Cancelled' &&
                o.status !== 'Paid'
            );

            if (activeOrder) {
                setOrder(activeOrder);
                setPaidAmount(activeOrder.net_amount);
            }

            // 3. Get Payment Modes & Company Settings
            const [settingsRes, companyRes] = await Promise.all([
                settingsAPI.getPaymentModes(),
                settingsAPI.getCompanySettings()
            ]);
            setPaymentModes(settingsRes.data || []);
            setCompanySettings(companyRes.data);

        } catch (error) {
            console.error("Error loading billing data:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleProcessPayment = async () => {
        if (!order) return;

        try {
            setLoading(true);
            // 1. Validate Credit Orders
            const creditAmount = Math.max(0, (order.net_amount || 0) - (paidAmount || 0));
            if (creditAmount > 0 && !order.customer_id) {
                showAlert("Customer must be assigned for Credit/Due orders.", 'warning');
                setLoading(false);
                return;
            }

            // 2. Update Order Status to Paid
            await ordersAPI.update(order.id, {
                status: 'Paid',
                payment_type: selectedPaymentMode,
                paid_amount: paidAmount,
                credit_amount: creditAmount
            });

            // Update local order state with the response or merge it
            setOrder((prev: any) => ({
                ...prev,
                status: 'Paid',
                payment_type: selectedPaymentMode,
                paid_amount: paidAmount,
                credit_amount: creditAmount
            }));

            setIsPaid(true);

            logActivity('Payment Received', `Payment of Rs. ${paidAmount} received for ${table?.hold_table_name || `Table ${table?.table_id}`} via ${selectedPaymentMode}`, 'order');
            showAlert("Payment successful!", 'success');

            // We don't navigate immediately anymore to allow printing the bill
        } catch (error) {
            console.error("Error processing payment:", error);
            showAlert("Failed to process payment", 'error');
        } finally {
            setLoading(false);
        }
    };


    if (loading && !table) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
                <CircularProgress sx={{ color: '#FFC107' }} />
            </Box>
        );
    }

    if (!order && !loading) {
        return (
            <Box sx={{ p: 4, textAlign: 'center' }}>
                <Typography variant="h6" color="text.secondary">No active order found for this table.</Typography>
                <Button variant="outlined" sx={{ mt: 2 }} onClick={() => navigate('/pos')}>Go Back</Button>
            </Box>
        );
    }

    return (
        <Box sx={{ minHeight: '100vh', bgcolor: '#f1f5f9', p: { xs: 2, md: 4 } }}>
            {/* Minimal Header */}
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 4 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <IconButton
                        onClick={() => navigate(-1)}
                        sx={{
                            bgcolor: 'white',
                            boxShadow: '0 2px 8px rgba(0,0,0,0.05)',
                            '&:hover': { bgcolor: '#f8fafc' }
                        }}
                    >
                        <ArrowLeft size={20} />
                    </IconButton>
                    <Box>
                        <Typography variant="h5" fontWeight={900} color="#1e293b">
                            Order Checkout
                        </Typography>
                        <Typography variant="caption" sx={{ color: '#64748b', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 1 }}>
                            {table?.hold_table_name || `Table ${table?.table_id}`}
                            <Box sx={{ width: 4, height: 4, borderRadius: '50%', bgcolor: '#cbd5e1' }} />
                            #{order?.order_number}
                        </Typography>
                    </Box>
                </Box>

                <Box sx={{ textAlign: 'right', display: { xs: 'none', sm: 'block' } }}>
                    <Typography variant="h4" fontWeight={900} color={isPaid ? "#16a34a" : "#FFC107"} sx={{ lineHeight: 1 }}>
                        Rs. {isPaid ? order?.paid_amount : (order?.net_amount || 0)}
                    </Typography>
                    <Typography variant="caption" fontWeight={700} color="#94a3b8">{isPaid ? 'TOTAL PAID' : 'TOTAL PAYABLE'}</Typography>
                </Box>
            </Box>

            <Grid container spacing={4}>
                {/* Left Side: Order Summary */}
                <Grid size={{ xs: 12, lg: 7 }}>
                    <Paper elevation={0} sx={{ p: 3, borderRadius: '24px', bgcolor: 'white', border: '1px solid #e2e8f0' }}>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                            <Typography variant="h6" fontWeight={800} color="#1e293b">Order Summary</Typography>
                            {isPaid && (
                                <Chip
                                    label="PAID"
                                    sx={{ bgcolor: '#dcfce7', color: '#16a34a', fontWeight: 900, borderRadius: '8px' }}
                                />
                            )}
                            {order?.customer && (
                                <Chip
                                    icon={<UserCircle size={16} />}
                                    label={order.customer.name}
                                    variant="outlined"
                                    sx={{ borderRadius: '8px', fontWeight: 700, borderColor: '#FFC107', color: '#FFC107' }}
                                />
                            )}
                        </Box>

                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5, mb: 4 }}>
                            {order?.items?.map((item: any) => (
                                <Box key={item.id} sx={{
                                    display: 'flex',
                                    justifyContent: 'space-between',
                                    alignItems: 'center',
                                    p: 2,
                                    bgcolor: '#f8fafc',
                                    borderRadius: '16px',
                                }}>
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                        <Box sx={{
                                            width: 40, height: 40, borderRadius: '12px', bgcolor: '#fff',
                                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                                            border: '1px solid #e2e8f0', fontWeight: 800, color: '#FFC107'
                                        }}>
                                            {item.quantity}
                                        </Box>
                                        <Box>
                                            <Typography variant="subtitle2" fontWeight={800} color="#1e293b">{item.menu_item?.name}</Typography>
                                            <Typography variant="caption" fontWeight={600} color="#94a3b8">Rs. {item.price} each</Typography>
                                        </Box>
                                    </Box>
                                    <Typography variant="subtitle1" fontWeight={900} color="#1e293b">
                                        Rs. {item.subtotal}
                                    </Typography>
                                </Box>
                            ))}
                        </Box>

                        <Divider sx={{ borderStyle: 'dashed', mb: 3 }} />

                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                                <Typography variant="body2" fontWeight={600} color="#64748b">Subtotal</Typography>
                                <Typography variant="body2" fontWeight={800} color="#1e293b">Rs. {order?.gross_amount || 0}</Typography>
                            </Box>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                                <Typography variant="body2" fontWeight={600} color="#64748b">Discount</Typography>
                                <Typography variant="body2" fontWeight={800} color="#ef4444">- Rs. {order?.discount || 0}</Typography>
                            </Box>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                                <Typography variant="body2" fontWeight={600} color="#64748b">Service Charge ({companySettings?.service_charge_rate || 0}%)</Typography>
                                <Typography variant="body2" fontWeight={800} color="#1e293b">Rs. {order ? Math.round(order.gross_amount * (companySettings?.service_charge_rate || 0) / 100) : 0}</Typography>
                            </Box>
                            {companySettings?.tax_rate > 0 && (
                                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                                    <Typography variant="body2" fontWeight={600} color="#64748b">VAT ({companySettings?.tax_rate || 0}%)</Typography>
                                    <Typography variant="body2" fontWeight={800} color="#1e293b">Rs. {order ? Math.round((order.gross_amount + (order.gross_amount * (companySettings?.service_charge_rate || 0) / 100)) * (companySettings?.tax_rate || 0) / 100) : 0}</Typography>
                                </Box>
                            )}
                            <Box sx={{
                                display: 'flex', justifyContent: 'space-between', mt: 2, p: 2.5,
                                bgcolor: '#1e293b', borderRadius: '16px', color: 'white'
                            }}>
                                <Typography variant="h6" fontWeight={800}>Total Amount</Typography>
                                <Typography variant="h5" fontWeight={900} color="#FFC107">Rs. {order?.net_amount || 0}</Typography>
                            </Box>
                        </Box>
                    </Paper>
                </Grid>

                {/* Right Side: Payment Methods */}
                <Grid size={{ xs: 12, lg: 5 }}>
                    <Stack spacing={3}>
                        <Paper elevation={0} sx={{ p: 3, borderRadius: '24px', bgcolor: 'white', border: '1px solid #e2e8f0' }}>
                            <Typography variant="h6" fontWeight={800} color="#1e293b" sx={{ mb: 3 }}>Payment Method</Typography>

                            <Grid container spacing={2}>
                                <Grid size={{ xs: 6 }}>
                                    <Box
                                        onClick={() => setSelectedPaymentMode('Cash')}
                                        sx={{
                                            p: 2.5, borderRadius: '20px', border: '2px solid',
                                            borderColor: selectedPaymentMode === 'Cash' ? '#FFC107' : '#f1f5f9',
                                            bgcolor: selectedPaymentMode === 'Cash' ? '#fff7ed' : 'white',
                                            cursor: 'pointer', textAlign: 'center', transition: 'all 0.2s',
                                            '&:hover': { borderColor: '#FFC107' }
                                        }}
                                    >
                                        <Banknote size={24} color={selectedPaymentMode === 'Cash' ? '#FFC107' : '#64748b'} style={{ marginBottom: 8 }} />
                                        <Typography variant="body2" fontWeight={800} color={selectedPaymentMode === 'Cash' ? '#FFC107' : '#64748b'}>Cash</Typography>
                                    </Box>
                                </Grid>
                                {paymentModes.filter(m => m.name !== 'Cash').map((mode) => (
                                    <Grid size={{ xs: 6 }} key={mode.id}>
                                        <Box
                                            onClick={() => setSelectedPaymentMode(mode.name)}
                                            sx={{
                                                p: 2.5, borderRadius: '20px', border: '2px solid',
                                                borderColor: selectedPaymentMode === mode.name ? '#FFC107' : '#f1f5f9',
                                                bgcolor: selectedPaymentMode === mode.name ? '#fff7ed' : 'white',
                                                cursor: 'pointer', textAlign: 'center', transition: 'all 0.2s',
                                                '&:hover': { borderColor: '#FFC107' }
                                            }}
                                        >
                                            {mode.name.toLowerCase().includes('card') ? <CreditCard size={24} color={selectedPaymentMode === mode.name ? '#FFC107' : '#64748b'} style={{ marginBottom: 8 }} /> : <Smartphone size={24} color={selectedPaymentMode === mode.name ? '#FFC107' : '#64748b'} style={{ marginBottom: 8 }} />}
                                            <Typography variant="body2" fontWeight={800} color={selectedPaymentMode === mode.name ? '#FFC107' : '#64748b'}>{mode.name}</Typography>
                                        </Box>
                                    </Grid>
                                ))}
                                <Grid size={{ xs: 12 }}>
                                    <Tooltip title={!order?.customer_id ? "Assign a customer to enable Credit payment" : ""}>
                                        <Box
                                            onClick={() => order?.customer_id && setSelectedPaymentMode('Credit')}
                                            sx={{
                                                p: 2.5, borderRadius: '20px', border: '2px solid',
                                                borderColor: selectedPaymentMode === 'Credit' ? '#ef4444' : '#f1f5f9',
                                                bgcolor: selectedPaymentMode === 'Credit' ? '#fef2f2' : 'white',
                                                cursor: order?.customer_id ? 'pointer' : 'not-allowed',
                                                textAlign: 'center', transition: 'all 0.2s',
                                                opacity: order?.customer_id ? 1 : 0.5,
                                                '&:hover': { borderColor: order?.customer_id ? '#ef4444' : '#f1f5f9' },
                                                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 2
                                            }}
                                        >
                                            <History size={20} color={selectedPaymentMode === 'Credit' ? '#ef4444' : '#64748b'} />
                                            <Typography variant="body2" fontWeight={800} color={selectedPaymentMode === 'Credit' ? '#ef4444' : '#64748b'}>Credit / Due Order</Typography>
                                        </Box>
                                    </Tooltip>
                                </Grid>
                            </Grid>
                        </Paper>

                        <Paper elevation={0} sx={{ p: 3, borderRadius: '24px', bgcolor: 'white', border: '1px solid #e2e8f0' }}>
                            <Typography variant="h6" fontWeight={800} color="#1e293b" sx={{ mb: 3 }}>Settlement</Typography>

                            <TextField
                                fullWidth
                                label="Received Amount"
                                type="number"
                                value={paidAmount}
                                onChange={(e) => setPaidAmount(Number(e.target.value))}
                                InputProps={{
                                    startAdornment: <Typography sx={{ mr: 1, fontWeight: 700, color: '#94a3b8' }}>NPRs.</Typography>,
                                    sx: {
                                        borderRadius: '16px',
                                        bgcolor: '#f8fafc',
                                        fontWeight: 900,
                                        fontSize: '24px',
                                        py: 1,
                                        '& fieldset': { borderColor: 'transparent' },
                                        '&:hover fieldset': { borderColor: '#FFC107' },
                                        '&.Mui-focused fieldset': { borderColor: '#FFC107', borderWidth: 2 }
                                    }
                                }}
                            />

                            <Box sx={{ mt: 3, display: 'flex', flexDirection: 'column', gap: 2 }}>
                                {paidAmount > (order?.net_amount || 0) && (
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', p: 2, bgcolor: '#dcfce7', borderRadius: '16px' }}>
                                        <Typography variant="body2" fontWeight={800} color="#16a34a">Change Return</Typography>
                                        <Typography variant="subtitle1" fontWeight={900} color="#16a34a">Rs. {paidAmount - (order?.net_amount || 0)}</Typography>
                                    </Box>
                                )}
                                {paidAmount < (order?.net_amount || 0) && (
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', p: 2, bgcolor: '#fee2e2', borderRadius: '16px' }}>
                                        <Typography variant="body2" fontWeight={800} color="#dc2626">Balance Due</Typography>
                                        <Typography variant="subtitle1" fontWeight={900} color="#dc2626">Rs. {(order?.net_amount || 0) - paidAmount}</Typography>
                                    </Box>
                                )}

                                <Button
                                    fullWidth
                                    variant={isPaid ? 'contained' : 'contained'}
                                    size="large"
                                    onClick={isPaid ? () => navigate('/pos') : handleProcessPayment}
                                    disabled={loading}
                                    startIcon={loading ? <CircularProgress size={24} sx={{ color: 'white' }} /> : (isPaid ? <CheckCircle2 size={24} /> : <CheckCircle2 size={24} />)}
                                    sx={{
                                        py: 2.5, borderRadius: '18px',
                                        bgcolor: isPaid ? '#16a34a' : '#FFC107',
                                        fontWeight: 900, fontSize: '1.2rem', textTransform: 'none',
                                        boxShadow: isPaid ? '0 8px 30px rgba(22, 163, 74, 0.3)' : '0 8px 30px rgba(255, 140, 0, 0.3)',
                                        '&:hover': { bgcolor: isPaid ? '#15803d' : '#e67e00', transform: 'translateY(-2px)' },
                                        '&:disabled': { bgcolor: '#cbd5e1' },
                                        transition: 'all 0.2s'
                                    }}
                                >
                                    {loading ? 'Processing...' : (isPaid ? 'Payment Completed - Done' : 'Complete Payment')}
                                </Button>

                                <Button
                                    fullWidth
                                    variant={isPaid ? 'contained' : 'outlined'}
                                    startIcon={<Printer size={20} />}
                                    onClick={() => setBillDialogOpen(true)}
                                    sx={{
                                        py: 2, borderRadius: '16px',
                                        borderColor: isPaid ? 'transparent' : '#e2e8f0',
                                        bgcolor: isPaid ? '#FFC107' : 'transparent',
                                        color: isPaid ? 'white' : '#64748b',
                                        fontWeight: 800, textTransform: 'none',
                                        boxShadow: isPaid ? '0 8px 25px rgba(255, 140, 0, 0.3)' : 'none',
                                        '&:hover': {
                                            borderColor: '#FFC107',
                                            bgcolor: isPaid ? '#e67e00' : '#fff7ed',
                                            transform: isPaid ? 'scale(1.02)' : 'none'
                                        },
                                        transition: 'all 0.2s'
                                    }}
                                >
                                    Print Receipt
                                </Button>
                                {isPaid && (
                                    <Typography variant="caption" align="center" sx={{ color: '#16a34a', fontWeight: 700 }}>
                                        Payment successful! You can now print the updated receipt.
                                    </Typography>
                                )}
                            </Box>
                        </Paper>
                    </Stack>
                </Grid>
            </Grid>

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
                            <BillView ref={billRef} order={order} branch={currentBranch} settings={companySettings} />
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
                        sx={{ borderRadius: '10px', bgcolor: '#FFC107', '&:hover': { bgcolor: '#e67e00' }, textTransform: 'none', fontWeight: 700 }}
                    >
                        Print Bill
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default Billing;

