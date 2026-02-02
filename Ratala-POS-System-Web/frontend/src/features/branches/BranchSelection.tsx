import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../app/providers/AuthProvider';
import { useBranch } from '../../app/providers/BranchProvider';
import { Building2, MapPin, Check, Loader2, Plus } from 'lucide-react';
import { Box, Typography, Grid, Paper, Button, Avatar, CircularProgress, Alert } from '@mui/material';

const BranchSelection: React.FC = () => {
    const { user } = useAuth();
    const { accessibleBranches, selectBranch, loading: branchesLoading } = useBranch();
    const navigate = useNavigate();
    const [selectedBranchId, setSelectedBranchId] = useState<number | null>(null);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        // Strict Workflow Rule 1: Redirect to Create Branch if no branches
        if (!branchesLoading && (!accessibleBranches || accessibleBranches.length === 0)) {
            navigate('/branches/create');
        }
    }, [accessibleBranches, branchesLoading, navigate]);

    const handleBranchSelect = async (branchId: number) => {
        setIsLoading(true);
        setError('');
        try {
            await selectBranch(branchId);
            // Workflow: "When user selects a branch -> Redirect to Selected Branch Admin Panel"
            // For managers/admins go to dashboard, others go to POS
            const role = user?.role.toLowerCase();
            if (role === 'admin' || role === 'manager') {
                navigate('/dashboard');
            } else {
                navigate('/pos');
            }
        } catch (err: any) {
            setError('Failed to select branch. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    if (branchesLoading) {
        return <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}><CircularProgress /></Box>;
    }

    return (
        <Box>
            {error && <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>}

            <Grid container spacing={3}>
                {accessibleBranches.map((branch) => (
                    <Grid size={{ xs: 12, sm: 6 }} key={branch.id}>
                        <Paper
                            onClick={() => setSelectedBranchId(branch.id)}
                            sx={{
                                p: 3,
                                borderRadius: '16px',
                                cursor: 'pointer',
                                position: 'relative',
                                border: '2px solid',
                                borderColor: selectedBranchId === branch.id ? '#FF8C00' : 'transparent',
                                bgcolor: selectedBranchId === branch.id ? '#fff7ed' : 'white',
                                transition: 'all 0.2s',
                                '&:hover': {
                                    borderColor: '#FF8C00',
                                    transform: 'translateY(-4px)',
                                    boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)'
                                }
                            }}
                        >
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                <Avatar sx={{ bgcolor: '#FF8C00', width: 48, height: 48 }}>
                                    <Building2 size={24} />
                                </Avatar>
                                <Box>
                                    <Typography variant="h6" sx={{ fontWeight: 800 }}>{branch.name}</Typography>
                                    <Typography variant="body2" color="text.secondary">Code: {branch.code}</Typography>
                                    {branch.location && (
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5 }}>
                                            <MapPin size={14} color="#64748b" />
                                            <Typography variant="caption" color="text.secondary">{branch.location}</Typography>
                                        </Box>
                                    )}
                                </Box>
                            </Box>
                            {selectedBranchId === branch.id && (
                                <Box sx={{ position: 'absolute', top: 16, right: 16, color: '#FF8C00' }}>
                                    <Check size={24} />
                                </Box>
                            )}
                        </Paper>
                    </Grid>
                ))}

                {/* Add New Branch Option for Admins */}
                {user?.role.toLowerCase() === 'admin' && (
                    <Grid size={{ xs: 12, sm: 6 }}>
                        <Paper
                            onClick={() => navigate('/branches/create')}
                            sx={{
                                p: 3,
                                borderRadius: '16px',
                                cursor: 'pointer',
                                border: '2px dashed #e2e8f0',
                                bgcolor: 'transparent',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                gap: 2,
                                height: '100%',
                                '&:hover': {
                                    bgcolor: '#f8fafc',
                                    borderColor: '#cbd5e1'
                                }
                            }}
                        >
                            <Plus size={24} color="#64748b" />
                            <Typography variant="subtitle1" sx={{ fontWeight: 700, color: '#64748b' }}>Add New Branch</Typography>
                        </Paper>
                    </Grid>
                )}
            </Grid>

            <Button
                variant="contained"
                fullWidth
                disabled={!selectedBranchId || isLoading}
                onClick={() => selectedBranchId && handleBranchSelect(selectedBranchId)}
                sx={{
                    mt: 4,
                    py: 1.5,
                    bgcolor: '#FF8C00',
                    '&:hover': { bgcolor: '#FF7700' },
                    borderRadius: '12px',
                    fontWeight: 800,
                    fontSize: '1.1rem',
                    textTransform: 'none'
                }}
            >
                {isLoading ? <Loader2 className="animate-spin" /> : 'Enter Selected Branch'}
            </Button>
        </Box>
    );
};

export default BranchSelection;
