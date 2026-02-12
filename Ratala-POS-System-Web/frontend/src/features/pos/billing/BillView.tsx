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
    const scRate = settings?.service_charge_rate !== undefined ? settings.service_charge_rate : (order.service_charge_amount > 0 ? Math.round((order.service_charge_amount * 100) / (subtotal - discount)) : 0);
    const taxRate = settings?.tax_rate !== undefined ? settings.tax_rate : (order.tax_amount > 0 ? Math.round((order.tax_amount * 100) / ((subtotal - discount) + (order.service_charge_amount || 0))) : 0);

    // Use stored values if available, otherwise calculate fallback
    const serviceCharge = order.service_charge_amount !== undefined && order.service_charge_amount !== null
        ? order.service_charge_amount
        : Math.round(subtotal * (scRate / 100));

    const vat = order.tax_amount !== undefined && order.tax_amount !== null
        ? order.tax_amount
        : Math.round((subtotal + serviceCharge) * (taxRate / 100));

    const total = order.net_amount || (subtotal - discount + serviceCharge + vat + (order.delivery_charge || 0));

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
                {order.table?.table_id ? (
                    <Typography sx={{ fontSize: '11px' }}><strong>Table:</strong> {order.table.table_id}</Typography>
                ) : (
                    <Typography sx={{ fontSize: '11px' }}><strong>Type:</strong> {order.order_type || 'Takeaway'}</Typography>
                )}
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
                            <TableCell align="center">{Number(item.quantity).toFixed(2)}</TableCell>
                            <TableCell align="right">{Number(item.subtotal).toFixed(2)}</TableCell>
                        </TableRow>
                    ))}
                </TableBody>
            </Table>

            <Divider sx={{ my: 0.5, borderStyle: 'dashed' }} />

            <Box sx={{ px: 0.5 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography sx={{ fontSize: '11px' }}>Subtotal:</Typography>
                    <Typography sx={{ fontSize: '11px' }}>{Number(subtotal).toFixed(2)}</Typography>
                </Box>
                {(discount > 0 || order.discount > 0) && (
                    <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                        <Typography sx={{ fontSize: '11px' }}>Discount:</Typography>
                        <Typography sx={{ fontSize: '11px' }}>-{Number(discount || order.discount).toFixed(2)}</Typography>
                    </Box>
                )}
                {(serviceCharge > 0 || order.service_charge_amount > 0) && (
                    <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                        <Typography sx={{ fontSize: '11px' }}>Service Charge ({scRate}%):</Typography>
                        <Typography sx={{ fontSize: '11px' }}>{Number(serviceCharge || order.service_charge_amount).toFixed(2)}</Typography>
                    </Box>
                )}
                {(vat > 0 || order.tax_amount > 0 || taxRate > 0) && (
                    <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                        <Typography sx={{ fontSize: '11px' }}>VAT ({taxRate}%):</Typography>
                        <Typography sx={{ fontSize: '11px' }}>{Number(vat || order.tax_amount).toFixed(2)}</Typography>
                    </Box>
                )}
                {order.delivery_charge > 0 && (
                    <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                        <Typography sx={{ fontSize: '11px' }}>Delivery Charge:</Typography>
                        <Typography sx={{ fontSize: '11px' }}>{Number(order.delivery_charge).toFixed(2)}</Typography>
                    </Box>
                )}
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 0.5 }}>
                    <Typography sx={{ fontSize: '14px', fontWeight: 900 }}>TOTAL:</Typography>
                    <Typography sx={{ fontSize: '14px', fontWeight: 900 }}>NPRs. {Number(total).toFixed(2)}</Typography>
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
                            <Typography sx={{ fontSize: '11px', fontWeight: 800 }}>{Number(order.paid_amount || 0).toFixed(2)}</Typography>
                        </Box>
                        {(order.credit_amount > 0 || order.payment_type === 'Credit') && (
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 0.2 }}>
                                <Typography sx={{ fontSize: '11px', color: 'red' }}>Remaining Due:</Typography>
                                <Typography sx={{ fontSize: '11px', fontWeight: 800, color: 'red' }}>{Number(order.credit_amount || 0).toFixed(2)}</Typography>
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

