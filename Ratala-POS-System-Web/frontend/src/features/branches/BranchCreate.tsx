import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useAuth } from '../../app/providers/AuthProvider';
import { useBranch } from '../../app/providers/BranchProvider';
import { Building2, MapPin, Phone, Mail, Loader2, CheckCircle, Save } from 'lucide-react';
import { Box, Typography, TextField, Button, Grid, Alert, InputAdornment } from '@mui/material';

const BranchCreate: React.FC = () => {
    const { token } = useAuth();
    const { refreshBranches } = useBranch();
    const navigate = useNavigate();

    const [formData, setFormData] = useState({
        name: '',
        code: '',
        location: '',
        address: '',
        phone: '',
        email: ''
    });

    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState(false);

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const { name, value } = e.target;
        setFormData(prev => {
            const next = { ...prev, [name]: value };
            // Auto-generate code from name if code is empty or from name
            if (name === 'name' && (!prev.code || prev.code.includes('-001'))) {
                next.code = value.toUpperCase().replace(/[^A-Z0-9]/g, '').substring(0, 8) + '-001';
            }
            return next;
        });
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);

        try {
            const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';
            await axios.post(
                `${API_BASE_URL}/api/v1/branches`,
                formData,
                {
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json'
                    }
                }
            );

            setSuccess(true);
            await refreshBranches();

            // Strict Workflow Rule 2: Redirect to Branch Selection Page
            setTimeout(() => {
                navigate('/select-branch');
            }, 2000);

        } catch (err: any) {
            setError(err.response?.data?.detail || 'Failed to create branch. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    if (success) {
        return (
            <Box sx={{ textAlign: 'center', py: 4 }}>
                <CheckCircle size={64} color="#10b981" />
                <Typography variant="h4" sx={{ fontWeight: 800, mt: 2, mb: 1 }}>Success!</Typography>
                <Typography variant="body1" color="text.secondary">Branch created. Taking you to selection page...</Typography>
            </Box>
        );
    }

    return (
        <Box component="form" onSubmit={handleSubmit}>
            <Typography variant="h5" sx={{ fontWeight: 800, mb: 3 }}>Branch Details</Typography>

            {error && <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>}

            <Grid container spacing={3}>
                <Grid size={12}>
                    <TextField
                        fullWidth
                        label="Branch Name"
                        name="name"
                        value={formData.name}
                        onChange={handleChange}
                        required
                        variant="outlined"
                        InputProps={{
                            startAdornment: (
                                <InputAdornment position="start">
                                    <Building2 size={20} color="#64748b" />
                                </InputAdornment>
                            ),
                        }}
                    />
                </Grid>
                <Grid size={{ xs: 12, sm: 6 }}>
                    <TextField
                        fullWidth
                        label="Branch Code"
                        name="code"
                        value={formData.code}
                        onChange={handleChange}
                        required
                        variant="outlined"
                    />
                </Grid>
                <Grid size={{ xs: 12, sm: 6 }}>
                    <TextField
                        fullWidth
                        label="Location/Area"
                        name="location"
                        value={formData.location}
                        onChange={handleChange}
                        variant="outlined"
                        InputProps={{
                            startAdornment: (
                                <InputAdornment position="start">
                                    <MapPin size={20} color="#64748b" />
                                </InputAdornment>
                            ),
                        }}
                    />
                </Grid>
                <Grid size={12}>
                    <TextField
                        fullWidth
                        label="Full Address"
                        name="address"
                        value={formData.address}
                        onChange={handleChange}
                        multiline
                        rows={2}
                        variant="outlined"
                    />
                </Grid>
                <Grid size={{ xs: 12, sm: 6 }}>
                    <TextField
                        fullWidth
                        label="Phone"
                        name="phone"
                        value={formData.phone}
                        onChange={handleChange}
                        variant="outlined"
                        InputProps={{
                            startAdornment: (
                                <InputAdornment position="start">
                                    <Phone size={20} color="#64748b" />
                                </InputAdornment>
                            ),
                        }}
                    />
                </Grid>
                <Grid size={{ xs: 12, sm: 6 }}>
                    <TextField
                        fullWidth
                        label="Email"
                        type="email"
                        name="email"
                        value={formData.email}
                        onChange={handleChange}
                        variant="outlined"
                        InputProps={{
                            startAdornment: (
                                <InputAdornment position="start">
                                    <Mail size={20} color="#64748b" />
                                </InputAdornment>
                            ),
                        }}
                    />
                </Grid>
            </Grid>

            <Button
                type="submit"
                variant="contained"
                fullWidth
                disabled={isLoading}
                sx={{
                    mt: 4,
                    py: 1.5,
                    bgcolor: '#FFC107',
                    '&:hover': { bgcolor: '#FF7700' },
                    borderRadius: '12px',
                    fontWeight: 800,
                    fontSize: '1.1rem',
                    textTransform: 'none'
                }}
            >
                {isLoading ? <Loader2 className="animate-spin" /> : <><Save size={20} style={{ marginRight: 8 }} /> Create Branch</>}
            </Button>
        </Box>
    );
};

export default BranchCreate;

