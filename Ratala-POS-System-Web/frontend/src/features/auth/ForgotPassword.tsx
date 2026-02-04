import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { otpAPI } from '../../services/api';
import { Loader2, ArrowLeft } from 'lucide-react';
import { Box, TextField, Button, Typography, Alert, IconButton } from '@mui/material';

const ForgotPassword: React.FC = () => {
    const [email, setEmail] = useState('');
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const navigate = useNavigate();

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);

        try {
            await otpAPI.sendOTP(email, 'reset');
            // Navigate to OTP verification with email in state
            navigate('/verify-otp', { state: { email, type: 'reset' } });
        } catch (err: any) {
            setError(err.response?.data?.detail || 'Failed to send OTP. Please check your email and try again.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <IconButton onClick={() => navigate('/login')} sx={{ mr: 1, p: 0 }}>
                    <ArrowLeft size={24} />
                </IconButton>
                <Typography variant="h5" sx={{ fontWeight: 800, color: '#1e293b' }}>Reset Password</Typography>
            </Box>

            <Typography variant="body2" color="text.secondary">
                Enter your email address and we'll send you an OTP to reset your password.
            </Typography>

            {error && <Alert severity="error">{error}</Alert>}

            <TextField
                label="Email Address"
                type="email"
                fullWidth
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                variant="outlined"
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
                {isLoading ? <Loader2 className="animate-spin" size={24} /> : 'Send OTP'}
            </Button>

            <Box sx={{ textAlign: 'center', mt: 2 }}>
                <Typography variant="body2" color="text.secondary">
                    Remember your password? <Link to="/login" style={{ color: '#FFC107', fontWeight: 700, textDecoration: 'none' }}>Back to login</Link>
                </Typography>
            </Box>
        </Box>
    );
};

export default ForgotPassword;
