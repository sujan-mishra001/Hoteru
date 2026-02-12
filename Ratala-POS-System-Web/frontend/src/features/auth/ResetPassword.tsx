import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { otpAPI } from '../../services/api';
import { Loader2, Eye, EyeOff } from 'lucide-react';
import { Box, TextField, Button, Typography, Alert, IconButton, InputAdornment } from '@mui/material';

const ResetPassword: React.FC = () => {
    const [newPassword, setNewPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);

    const navigate = useNavigate();
    const location = useLocation();
    const email = location.state?.email;
    const code = location.state?.code;

    useEffect(() => {
        if (!email || !code) {
            navigate('/forgot-password');
        }
    }, [email, code, navigate]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');

        if (newPassword !== confirmPassword) {
            setError('Passwords do not match');
            return;
        }

        if (newPassword.length < 6) {
            setError('Password must be at least 6 characters long');
            return;
        }

        setIsLoading(true);

        try {
            await otpAPI.completePasswordReset({
                email,
                code,
                new_password: newPassword
            });

            // Navigate to login with success message
            navigate('/login', { state: { message: 'Password reset successful! Please login with your new password.' } });
        } catch (err: any) {
            setError(err.response?.data?.detail || 'Failed to reset password. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <Typography variant="h5" sx={{ fontWeight: 800, color: '#1e293b' }}>Set New Password</Typography>

            <Typography variant="body2" color="text.secondary">
                Please enter a new password for your account.
            </Typography>

            {error && <Alert severity="error">{error}</Alert>}

            <TextField
                label="New Password"
                type={showPassword ? 'text' : 'password'}
                fullWidth
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                required
                variant="outlined"
                InputProps={{
                    endAdornment: (
                        <InputAdornment position="end">
                            <IconButton onClick={() => setShowPassword(!showPassword)} edge="end">
                                {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                            </IconButton>
                        </InputAdornment>
                    ),
                }}
            />

            <TextField
                label="Confirm Password"
                type={showPassword ? 'text' : 'password'}
                fullWidth
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
                variant="outlined"
                InputProps={{
                    endAdornment: (
                        <InputAdornment position="end">
                            <IconButton onClick={() => setShowPassword(!showPassword)} edge="end">
                                {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                            </IconButton>
                        </InputAdornment>
                    ),
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
                {isLoading ? <Loader2 className="animate-spin" size={24} /> : 'Update Password'}
            </Button>
        </Box>
    );
};

export default ResetPassword;
