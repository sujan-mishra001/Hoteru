import { forwardRef } from 'react';
import { Box, Typography, Divider, Table, TableBody, TableCell, TableHead, TableRow } from '@mui/material';

interface BillViewProps {
    order: any;
    branch?: any;
    settings?: any;
}

const BillView = forwardRef<HTMLDivElement, BillViewProps>(({ order, branch, settings }, ref) => {
    if (!order) return null;

    const subtotal = order.gross_amount || 0;
    const discount = order.discount || 0;
    const scRate = settings?.service_charge_rate || 5;
    const taxRate = settings?.tax_rate || 0;

    // Attempt to calculate backward if not clearly stored, but prefer dynamic calculation for preview
    const serviceCharge = Math.round(subtotal * (scRate / 100));
    const vat = Math.round((subtotal + serviceCharge) * (taxRate / 100));
    const total = order.net_amount || (subtotal - discount + serviceCharge + vat);

    return (
        <Box
            ref={ref}
            sx={{
                p: 1, // Compact padding
                width: '80mm',
                margin: '0 auto',
                bgcolor: 'white',
                color: 'black',
                fontFamily: 'monospace',
                '@media print': {
                    p: 0,
                    width: '100%',
                }
            }}
        >
            <Box sx={{ textAlign: 'center', mb: 1 }}>
                <Typography sx={{ fontSize: '18px', fontWeight: 900 }}>
                    {branch?.name?.toUpperCase() || 'TAX INVOICE'}
                </Typography>
                <Typography sx={{ fontSize: '11px' }}>
                    {branch?.address || branch?.location || ''}
                </Typography>
                <Typography sx={{ fontSize: '11px' }}>
                    {branch?.phone ? `Tel: ${branch.phone}` : ''}
                </Typography>
                {branch?.email && (
                    <Typography sx={{ fontSize: '11px' }}>
                        Email: {branch.email}
                    </Typography>
                )}
                <Typography sx={{ fontSize: '11px' }}>{branch?.code ? `Branch: ${branch.code}` : ''}</Typography>
            </Box>

            <Divider sx={{ my: 0.5, borderStyle: 'dashed' }} />

            <Box sx={{ mb: 1 }}>
                <Typography sx={{ fontSize: '11px' }}><strong>Bill No:</strong> {order.order_number}</Typography>
                <Typography sx={{ fontSize: '11px' }}><strong>Date:</strong> {new Date(order.created_at).toLocaleString()}</Typography>
                <Typography sx={{ fontSize: '11px' }}><strong>Table:</strong> {order.table?.table_id || 'Walk-in'}</Typography>
                <Typography sx={{ fontSize: '11px' }}><strong>Order Type:</strong> {order.order_type}</Typography>
                {order.customer && <Typography sx={{ fontSize: '11px' }}><strong>Customer:</strong> {order.customer.name}</Typography>}
            </Box>

            <Divider sx={{ my: 0.5, borderStyle: 'dashed' }} />

            <Table size="small" sx={{ '& .MuiTableCell-root': { borderBottom: 'none', p: 0.2, fontSize: '12px', fontFamily: 'monospace' } }}>
                <TableHead>
                    <TableRow>
                        <TableCell><strong>Item</strong></TableCell>
                        <TableCell align="center"><strong>Qty</strong></TableCell>
                        <TableCell align="right"><strong>Amt</strong></TableCell>
                    </TableRow>
                </TableHead>
                <TableBody>
                    {order.items?.map((item: any) => (
                        <TableRow key={item.id}>
                            <TableCell sx={{ maxWidth: '40mm', overflow: 'hidden' }}>{item.menu_item?.name}</TableCell>
                            <TableCell align="center">{item.quantity}</TableCell>
                            <TableCell align="right">{item.subtotal}</TableCell>
                        </TableRow>
                    ))}
                </TableBody>
            </Table>

            <Divider sx={{ my: 0.5, borderStyle: 'dashed' }} />

            <Box sx={{ px: 0.5 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography sx={{ fontSize: '11px' }}>Subtotal:</Typography>
                    <Typography sx={{ fontSize: '11px' }}>{subtotal}</Typography>
                </Box>
                {discount > 0 && (
                    <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                        <Typography sx={{ fontSize: '11px' }}>Discount:</Typography>
                        <Typography sx={{ fontSize: '11px' }}>-{discount}</Typography>
                    </Box>
                )}
                {serviceCharge > 0 && (
                    <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                        <Typography sx={{ fontSize: '11px' }}>Service Charge ({scRate}%):</Typography>
                        <Typography sx={{ fontSize: '11px' }}>{serviceCharge}</Typography>
                    </Box>
                )}
                {taxRate > 0 && (
                    <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                        <Typography sx={{ fontSize: '11px' }}>VAT ({taxRate}%):</Typography>
                        <Typography sx={{ fontSize: '11px' }}>{vat}</Typography>
                    </Box>
                )}
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 0.5 }}>
                    <Typography sx={{ fontSize: '14px', fontWeight: 900 }}>TOTAL:</Typography>
                    <Typography sx={{ fontSize: '14px', fontWeight: 900 }}>NPRs. {total}</Typography>
                </Box>
            </Box>

            {order.status === 'Paid' && (
                <>
                    <Divider sx={{ my: 0.5, borderStyle: 'dashed' }} />
                    <Box sx={{ px: 0.5 }}>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography sx={{ fontSize: '11px' }}>Payment Mode:</Typography>
                            <Typography sx={{ fontSize: '11px', fontWeight: 800 }}>{order.payment_type || 'Cash'}</Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography sx={{ fontSize: '11px' }}>Paid Amount:</Typography>
                            <Typography sx={{ fontSize: '11px', fontWeight: 800 }}>{order.paid_amount || 0}</Typography>
                        </Box>
                        {(order.credit_amount > 0 || order.payment_type === 'Credit') && (
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 0.2 }}>
                                <Typography sx={{ fontSize: '11px', color: 'red' }}>Remaining Due:</Typography>
                                <Typography sx={{ fontSize: '11px', fontWeight: 800, color: 'red' }}>{order.credit_amount || 0}</Typography>
                            </Box>
                        )}
                    </Box>
                </>
            )}

            <Divider sx={{ my: 1, borderStyle: 'dashed' }} />

            <Box sx={{ textAlign: 'center', mt: 1 }}>
                <Typography sx={{ fontSize: '11px' }}>Thank You for Visiting!</Typography>
                <Typography sx={{ fontSize: '9px' }}>Please visit again</Typography>
            </Box>
        </Box>
    );
});

export default BillView;

