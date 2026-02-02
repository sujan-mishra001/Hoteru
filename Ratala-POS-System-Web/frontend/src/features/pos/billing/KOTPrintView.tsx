import { forwardRef } from 'react';
import { Box, Typography, Divider, List, ListItem } from '@mui/material';

interface KOTPrintViewProps {
    kot: any;
    branch?: any;
}

const KOTPrintView = forwardRef<HTMLDivElement, KOTPrintViewProps>(({ kot, branch }, ref) => {
    if (!kot) return null;

    return (
        <Box
            ref={ref}
            sx={{
                p: 1.5,
                width: '80mm',
                margin: '0 auto',
                bgcolor: 'white',
                color: 'black',
                fontFamily: 'monospace',
                '@media print': {
                    p: 1,
                    width: '100%',
                }
            }}
        >
            <Box sx={{ textAlign: 'center', mb: 0.5 }}>
                <Typography sx={{ fontSize: '11px', fontWeight: 700 }}>{branch?.name || ''}</Typography>
                <Typography sx={{ fontSize: '18px', fontWeight: 900 }}>{kot.kot_type || 'KOT'}</Typography>
                <Typography sx={{ fontSize: '14px', fontWeight: 700 }}>#{kot.kot_number}</Typography>
            </Box>

            <Divider sx={{ my: 0.5, borderStyle: 'dashed', borderColor: 'black' }} />

            <Box sx={{ mb: 0.5 }}>
                <Typography sx={{ fontSize: '16px', fontWeight: 900 }}>Table: {kot.order?.table?.table_id || 'N/A'}</Typography>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography sx={{ fontSize: '11px' }}>Type: {kot.order?.order_type || 'N/A'}</Typography>
                    <Typography sx={{ fontSize: '11px' }}>Time: {new Date(kot.created_at).toLocaleTimeString()}</Typography>
                </Box>
                {kot.user && (
                    <Typography sx={{ fontSize: '11px', fontWeight: 700, mt: 0.2 }}>
                        issued by: {kot.user.full_name}
                    </Typography>
                )}
            </Box>

            <Divider sx={{ my: 0.5, borderStyle: 'solid', borderColor: 'black', borderWidth: 1.5 }} />

            <List disablePadding>
                {kot.items?.map((item: any, idx: number) => (
                    <ListItem key={idx} disablePadding sx={{ py: 0.5, alignItems: 'flex-start' }}>
                        <Typography sx={{ fontSize: '16px', fontWeight: 900, mr: 1, minWidth: '30px' }}>
                            {item.quantity}x
                        </Typography>
                        <Box sx={{ flexGrow: 1 }}>
                            <Typography sx={{ fontSize: '16px', fontWeight: 900 }}>{item.menu_item?.name}</Typography>
                            {item.notes && (
                                <Typography sx={{ fontSize: '12px', mt: 0.2, bgcolor: '#eee', p: 0.3, fontWeight: 700 }}>
                                    NOTE: {item.notes}
                                </Typography>
                            )}
                        </Box>
                    </ListItem>
                ))}
            </List>

            <Divider sx={{ mt: 1, mb: 0.5, borderStyle: 'dashed', borderColor: 'black' }} />

            <Box sx={{ textAlign: 'center' }}>
                <Typography sx={{ fontSize: '10px' }}>{new Date().toLocaleString()}</Typography>
            </Box>
        </Box>
    );
});

export default KOTPrintView;
