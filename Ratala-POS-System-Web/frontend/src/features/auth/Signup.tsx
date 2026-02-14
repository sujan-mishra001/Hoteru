import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { authAPI } from '../../services/api';
import { Eye, EyeOff, Loader2 } from 'lucide-react';
import { Box, TextField, Button, IconButton, InputAdornment, Typography, Alert } from '@mui/material';

const Signup: React.FC = () => {
    const [fullName, setFullName] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const navigate = useNavigate();

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setSuccess('');

        if (password !== confirmPassword) {
            setError('Passwords do not match');
            return;
        }

        setIsLoading(true);

        try {
            await authAPI.signup({
                email,
                full_name: fullName,
                password,
                role: 'admin'
            });

            setSuccess('Account created successfully! Redirecting to login...');
            setTimeout(() => {
                navigate('/login');
            }, 2000);

        } catch (err: any) {
            setError(err.response?.data?.detail || 'Failed to create account. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 2.5 }}>
            <Box sx={{ mb: 1 }}>
                <Typography variant="h4" sx={{ fontWeight: 900, color: '#1e293b', mb: 0.5, letterSpacing: '-0.5px' }}>
                    Create Account
                </Typography>
                <Typography variant="body1" sx={{ color: '#64748b', fontWeight: 500 }}>
                    Join us and start managing your restaurant
                </Typography>
            </Box>

            {error && <Alert severity="error" sx={{ borderRadius: '12px' }}>{error}</Alert>}
            {success && <Alert severity="success" sx={{ borderRadius: '12px' }}>{success}</Alert>}

            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <TextField
                    label="Full Name"
                    fullWidth
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    required
                    sx={{ '& .MuiOutlinedInput-root': { borderRadius: '12px', backgroundColor: '#f8fafc' } }}
                />

                <TextField
                    label="Email Address"
                    type="email"
                    fullWidth
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    sx={{ '& .MuiOutlinedInput-root': { borderRadius: '12px', backgroundColor: '#f8fafc' } }}
                />

                <TextField
                    label="Password"
                    type={showPassword ? 'text' : 'password'}
                    fullWidth
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    sx={{ '& .MuiOutlinedInput-root': { borderRadius: '12px', backgroundColor: '#f8fafc' } }}
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
                    sx={{ '& .MuiOutlinedInput-root': { borderRadius: '12px', backgroundColor: '#f8fafc' } }}
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
            </Box>

            <Button
                type="submit"
                variant="contained"
                disabled={isLoading}
                fullWidth
                sx={{
                    mt: 1,
                    py: 1.8,
                    bgcolor: '#FFC107',
                    color: '#000',
                    '&:hover': { bgcolor: '#eab308' },
                    borderRadius: '12px',
                    fontWeight: 900,
                    fontSize: '1rem',
                    textTransform: 'none',
                    boxShadow: '0 4px 12px rgba(255, 193, 7, 0.3)',
                }}
            >
                {isLoading ? <Loader2 className="animate-spin" /> : 'Create Account'}
            </Button>

            <Box sx={{ textAlign: 'center', mt: 1 }}>
                <Typography variant="body2" sx={{ color: '#64748b', fontWeight: 500 }}>
                    Already have an account? <Link to="/login" style={{ color: '#FFC107', fontWeight: 800, textDecoration: 'none', marginLeft: '4px' }}>Sign In</Link>
                </Typography>
            </Box>
        </Box>
    );
};

export default Signup;

