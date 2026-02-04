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
            if (user.role === 'Admin') {
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
            await login(access_token);
            logActivity('User Login', `Logged in as ${username}`, 'auth');

            // Workflow: Always go to select-branch, it will decide if redirection to create-branch is needed
            navigate('/select-branch');

        } catch (err: any) {
            setError(err.response?.data?.detail || 'Invalid credentials. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <Box component="form" onSubmit={handleSubmit} sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <Typography variant="h5" sx={{ fontWeight: 800, mb: 1, color: '#1e293b' }}>Welcome Back</Typography>

            {error && <Alert severity="error">{error}</Alert>}
            {successMessage && <Alert severity="success">{successMessage}</Alert>}

            <TextField
                label="Username or Email"
                fullWidth
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
                variant="outlined"
            />

            <TextField
                label="Password"
                type={showPassword ? 'text' : 'password'}
                fullWidth
                value={password}
                onChange={(e) => setPassword(e.target.value)}
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

            <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
                <Link to="/forgot-password" style={{ color: '#FFC107', fontWeight: 600, textDecoration: 'none', fontSize: '0.875rem' }}>
                    Forgot password?
                </Link>
            </Box>

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
                {isLoading ? <Loader2 className="animate-spin" size={24} /> : 'Login'}
            </Button>

            <Box sx={{ textAlign: 'center', mt: 2 }}>
                <Typography variant="body2" color="text.secondary">
                    Don't have an account? <Link to="/signup" style={{ color: '#FFC107', fontWeight: 700, textDecoration: 'none' }}>Sign up</Link>
                </Typography>
            </Box>
        </Box>
    );
};

export default Login;

