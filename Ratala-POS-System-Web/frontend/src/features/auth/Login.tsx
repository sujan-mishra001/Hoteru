import React, { useState, useEffect } from 'react';
import { useNavigate, Link, useLocation } from 'react-router-dom';
import { useAuth } from '../../app/providers/AuthProvider';
import { authAPI } from '../../services/api';
import { Eye, EyeOff, Loader2 } from 'lucide-react';
import { Box, TextField, Button, IconButton, InputAdornment, Typography, Alert } from '@mui/material';
import { useActivity } from '../../app/providers/ActivityProvider';

const Login: React.FC = () => {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const { login, user, isAuthenticated } = useAuth();
    const { logActivity } = useActivity();
    const navigate = useNavigate();
    const location = useLocation();
    const successMessage = location.state?.message;

    // Redirect if already logged in
    useEffect(() => {
        if (isAuthenticated && user) {
            // Admin goes to dashboard, others go to POS tables
            if (user.role.toLowerCase() === 'platform_admin') {
                navigate('/admin', { replace: true });
            } else if (user.role.toLowerCase() === 'admin') {
                navigate('/dashboard', { replace: true });
            } else {
                navigate('/pos/tables', { replace: true });
            }
        }
    }, [isAuthenticated, user, navigate]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);

        try {
            const response = await authAPI.login(username, password);
            const { access_token } = response.data;
            const userData = await login(access_token);
            logActivity('User Login', `Logged in as ${username}`, 'auth');

            // Redirect based on role
            if (userData.role.toLowerCase() === 'platform_admin') {
                navigate('/admin', { replace: true });
            } else {
                // Workflow: Always go to select-branch, it will decide if redirection to create-branch is needed
                navigate('/select-branch');
            }

        } catch (err: any) {
            setError(err.response?.data?.detail || 'Invalid credentials. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <Box sx={{ mb: 1 }}>
                <Typography variant="h4" sx={{ fontWeight: 900, color: '#1e293b', mb: 0.5, letterSpacing: '-0.5px' }}>
                    Welcome Back
                </Typography>
                <Typography variant="body1" sx={{ color: '#64748b', fontWeight: 500 }}>
                    Log in to your account to continue
                </Typography>
            </Box>

            {error && <Alert severity="error" sx={{ borderRadius: '12px' }}>{error}</Alert>}
            {successMessage && <Alert severity="success" sx={{ borderRadius: '12px' }}>{successMessage}</Alert>}

            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <TextField
                    label="Username or Email"
                    fullWidth
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    required
                    variant="outlined"
                    sx={{
                        '& .MuiOutlinedInput-root': {
                            borderRadius: '12px',
                            backgroundColor: '#f8fafc',
                            '&:hover backgroundColor': '#f1f5f9',
                        }
                    }}
                />

                <TextField
                    label="Password"
                    type={showPassword ? 'text' : 'password'}
                    fullWidth
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    variant="outlined"
                    sx={{
                        '& .MuiOutlinedInput-root': {
                            borderRadius: '12px',
                            backgroundColor: '#f8fafc',
                        }
                    }}
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

            <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
                <Link to="/forgot-password" style={{ color: '#FFC107', fontWeight: 700, textDecoration: 'none', fontSize: '0.9rem' }}>
                    Forgot password?
                </Link>
            </Box>

            <Button
                type="submit"
                variant="contained"
                disabled={isLoading}
                fullWidth
                sx={{
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
                {isLoading ? <Loader2 className="animate-spin" size={24} /> : 'Sign In'}
            </Button>

            <Box sx={{ textAlign: 'center', mt: 1 }}>
                <Typography variant="body2" sx={{ color: '#64748b', fontWeight: 500 }}>
                    Don't have an account? <Link to="/signup" style={{ color: '#FFC107', fontWeight: 800, textDecoration: 'none', marginLeft: '4px' }}>Create Account</Link>
                </Typography>
            </Box>
        </Box>
    );
};

export default Login;

