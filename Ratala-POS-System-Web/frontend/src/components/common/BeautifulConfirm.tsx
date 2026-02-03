import React from 'react';
import {
    Dialog,
    Box,
    Typography,
    IconButton,
    Button
} from '@mui/material';
import { AlertTriangle, X } from 'lucide-react';

interface BeautifulConfirmProps {
    open: boolean;
    title: string;
    message: string;
    onConfirm: () => void;
    onCancel: () => void;
    confirmText?: string;
    cancelText?: string;
    isDestructive?: boolean;
}

const BeautifulConfirm: React.FC<BeautifulConfirmProps> = ({
    open,
    title,
    message,
    onConfirm,
    onCancel,
    confirmText = 'Confirm',
    cancelText = 'Cancel',
    isDestructive = false
}) => {
    return (
        <Dialog
            open={open}
            onClose={onCancel}
            PaperProps={{
                sx: {
                    borderRadius: '20px',
                    p: 1,
                    maxWidth: '400px',
                    width: '100%'
                }
            }}
        >
            <Box sx={{ display: 'flex', justifyContent: 'flex-end', p: 1 }}>
                <IconButton onClick={onCancel} size="small">
                    <X size={20} />
                </IconButton>
            </Box>

            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', px: 3, pb: 3 }}>
                <Box
                    sx={{
                        width: 64,
                        height: 64,
                        borderRadius: '50%',
                        bgcolor: isDestructive ? '#fee2e2' : '#fff7ed',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        mb: 2,
                        color: isDestructive ? '#ef4444' : '#f59e0b'
                    }}
                >
                    <AlertTriangle size={32} />
                </Box>

                <Typography variant="h6" fontWeight={800} sx={{ mb: 1, color: '#1e293b' }}>
                    {title}
                </Typography>

                <Typography variant="body1" sx={{ color: '#64748b', mb: 3, lineHeight: 1.5 }}>
                    {message}
                </Typography>

                <Box sx={{ display: 'flex', gap: 2, width: '100%' }}>
                    <Button
                        fullWidth
                        onClick={onCancel}
                        sx={{
                            py: 1.5,
                            borderRadius: '12px',
                            textTransform: 'none',
                            fontWeight: 700,
                            color: '#64748b',
                            bgcolor: '#f1f5f9',
                            '&:hover': { bgcolor: '#e2e8f0' }
                        }}
                    >
                        {cancelText}
                    </Button>
                    <Button
                        fullWidth
                        variant="contained"
                        onClick={onConfirm}
                        sx={{
                            py: 1.5,
                            borderRadius: '12px',
                            textTransform: 'none',
                            fontWeight: 800,
                            bgcolor: isDestructive ? '#ef4444' : '#FFC107',
                            '&:hover': {
                                bgcolor: isDestructive ? '#dc2626' : '#e67e00'
                            },
                            boxShadow: isDestructive
                                ? '0 8px 20px rgba(239, 68, 68, 0.2)'
                                : '0 8px 20px rgba(255, 140, 0, 0.2)'
                        }}
                    >
                        {confirmText}
                    </Button>
                </Box>
            </Box>
        </Dialog>
    );
};

export default BeautifulConfirm;

