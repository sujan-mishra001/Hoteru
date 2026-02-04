import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { otpAPI } from '../../services/api';
import { Loader2, ArrowLeft } from 'lucide-react';
import { Box, TextField, Button, Typography, Alert, IconButton } from '@mui/material';

const OTPVerification: React.FC = () => {
    const [code, setCode] = useState('');
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [isResending, setIsResending] = useState(false);

    const navigate = useNavigate();
    const location = useLocation();
    const email = location.state?.email;
    const type = location.state?.type || 'signup';

    useEffect(() => {
        if (!email) {
            navigate('/forgot-password');
        }
    }, [email, navigate]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);

        try {
            await otpAPI.verifyOTP(email, code, type !== 'reset');
            if (type === 'reset') {
                navigate('/reset-password', { state: { email, code } });
            } else {
                // If it was signup, usually we redirect to login or dashboard
                navigate('/login', { state: { message: 'Email verified successfully! Please login.' } });
            }
        } catch (err: any) {
            setError(err.response?.data?.detail || 'Invalid OTP. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    const handleResend = async () => {
        setError('');
        setIsResending(true);
        try {
            await otpAPI.sendOTP(email, type);
            // Show success message
        } catch (err: any) {
            setError('Failed to resend OTP. Please try again.');
        } finally {
            setIsResending(false);
        }
    };

    return (
        <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <IconButton onClick={() => navigate(-1)} sx={{ mr: 1, p: 0 }}>
                    <ArrowLeft size={24} />
                </IconButton>
                <Typography variant="h5" sx={{ fontWeight: 800, color: '#1e293b' }}>Verify OTP</Typography>
            </Box>

            <Typography variant="body2" color="text.secondary">
                We've sent a code to <strong>{email}</strong>. Enter it below to continue.
            </Typography>

            {error && <Alert severity="error">{error}</Alert>}

            <TextField
                label="6-Digit Code"
                fullWidth
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, '').substring(0, 6))}
                required
                variant="outlined"
                inputProps={{
                    style: { textAlign: 'center', letterSpacing: '8px', fontSize: '1.5rem', fontWeight: 700 }
                }}
            />

            <Button
                type="submit"
                variant="contained"
                disabled={isLoading}
                fullWidth
                sx={{
                    py: 1.5,
                    bgcolor: '#FFC107',
                    '&:hover': { bgcolor: '#FF7700' },
                    borderRadius: '12px',
                    fontWeight: 700,
                    fontSize: '1rem',
                    textTransform: 'none'
                }}
            >
                {isLoading ? <Loader2 className="animate-spin" size={24} /> : 'Verify'}
            </Button>

            <Box sx={{ textAlign: 'center', mt: 1 }}>
                <Typography variant="body2" color="text.secondary">
                    Didn't receive the code?{' '}
                    <Button
                        onClick={handleResend}
                        disabled={isResending}
                        sx={{ color: '#FFC107', textTransform: 'none', fontWeight: 700, p: 0, minWidth: 0, verticalAlign: 'baseline' }}
                    >
                        {isResending ? 'Resending...' : 'Resend'}
                    </Button>
                </Typography>
            </Box>
        </Box>
    );
};

export default OTPVerification;
