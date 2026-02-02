import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import axios from 'axios';
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
            const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';
            await axios.post(`${API_BASE_URL}/signup`, {
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
            <Typography variant="h5" sx={{ fontWeight: 800, mb: 1 }}>Create Your Account</Typography>

            {error && <Alert severity="error">{error}</Alert>}
            {success && <Alert severity="success">{success}</Alert>}

            <TextField
                label="Full Name"
                fullWidth
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                required
            />

            <TextField
                label="Email Address"
                type="email"
                fullWidth
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
            />

            <TextField
                label="Password"
                type={showPassword ? 'text' : 'password'}
                fullWidth
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
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
            />

            <Button
                type="submit"
                variant="contained"
                disabled={isLoading}
                fullWidth
                sx={{
                    mt: 2,
                    py: 1.5,
                    bgcolor: '#FF8C00',
                    '&:hover': { bgcolor: '#FF7700' },
                    borderRadius: '12px',
                    fontWeight: 800,
                    textTransform: 'none'
                }}
            >
                {isLoading ? <Loader2 className="animate-spin" /> : 'Get Started'}
            </Button>

            <Box sx={{ textAlign: 'center', mt: 1 }}>
                <Typography variant="body2" color="text.secondary">
                    Already have an account? <Link to="/login" style={{ color: '#FF8C00', fontWeight: 700, textDecoration: 'none' }}>Log in</Link>
                </Typography>
            </Box>
        </Box>
    );
};

export default Signup;
