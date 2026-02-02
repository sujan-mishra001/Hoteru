import React from 'react';
import { Box, Typography, Slide } from '@mui/material';
import { CheckCircle2, AlertCircle, Info, AlertTriangle, X } from 'lucide-react';

interface BeautifulAlertProps {
    open: boolean;
    message: string;
    severity: 'success' | 'error' | 'warning' | 'info';
    onClose: () => void;
}

const BeautifulAlert: React.FC<BeautifulAlertProps> = ({ open, message, severity, onClose }) => {
    const getIcon = () => {
        switch (severity) {
            case 'success':
                return <CheckCircle2 size={24} />;
            case 'error':
                return <AlertCircle size={24} />;
            case 'warning':
                return <AlertTriangle size={24} />;
            case 'info':
                return <Info size={24} />;
        }
    };

    const getColors = () => {
        switch (severity) {
            case 'success':
                return {
                    bg: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                    iconBg: 'rgba(255, 255, 255, 0.2)',
                };
            case 'error':
                return {
                    bg: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
                    iconBg: 'rgba(255, 255, 255, 0.2)',
                };
            case 'warning':
                return {
                    bg: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
                    iconBg: 'rgba(255, 255, 255, 0.2)',
                };
            case 'info':
                return {
                    bg: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)',
                    iconBg: 'rgba(255, 255, 255, 0.2)',
                };
        }
    };

    const colors = getColors();

    if (!open) return null;

    return (
        <Slide direction="left" in={open} mountOnEnter unmountOnExit>
            <Box
                sx={{
                    position: 'fixed',
                    top: 24,
                    right: 24,
                    zIndex: 9999,
                    minWidth: 320,
                    maxWidth: 400,
                    background: colors.bg,
                    borderRadius: '16px',
                    boxShadow: '0 20px 40px rgba(0, 0, 0, 0.2)',
                    overflow: 'hidden',
                    animation: 'slideIn 0.3s ease-out',
                    '@keyframes slideIn': {
                        from: {
                            transform: 'translateX(100%)',
                            opacity: 0,
                        },
                        to: {
                            transform: 'translateX(0)',
                            opacity: 1,
                        },
                    },
                }}
            >
                <Box sx={{ p: 2.5, display: 'flex', alignItems: 'flex-start', gap: 2 }}>
                    <Box
                        sx={{
                            bgcolor: colors.iconBg,
                            borderRadius: '12px',
                            p: 1,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color: 'white',
                        }}
                    >
                        {getIcon()}
                    </Box>
                    <Box sx={{ flex: 1 }}>
                        <Typography
                            variant="body1"
                            sx={{
                                color: 'white',
                                fontWeight: 700,
                                lineHeight: 1.5,
                                pr: 1,
                            }}
                        >
                            {message}
                        </Typography>
                    </Box>
                    <Box
                        onClick={onClose}
                        sx={{
                            cursor: 'pointer',
                            color: 'white',
                            opacity: 0.8,
                            '&:hover': { opacity: 1 },
                            transition: 'opacity 0.2s',
                        }}
                    >
                        <X size={20} />
                    </Box>
                </Box>
                <Box
                    sx={{
                        height: 4,
                        bgcolor: 'rgba(255, 255, 255, 0.3)',
                        animation: 'shrink 4s linear forwards',
                        '@keyframes shrink': {
                            from: { width: '100%' },
                            to: { width: '0%' },
                        },
                    }}
                />
            </Box>
        </Slide>
    );
};

export default BeautifulAlert;
