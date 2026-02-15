import React from 'react';
import { Box, Container, Typography, Paper, Button, Toolbar, AppBar } from '@mui/material';
import { Outlet, useNavigate } from 'react-router-dom';
import { LogOut } from 'lucide-react';
import { useAuth } from '../providers/AuthProvider';

const BranchSetupLayout: React.FC = () => {
    const { logout, user } = useAuth();
    const navigate = useNavigate();

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    return (
        <Box sx={{ minHeight: '100vh', bgcolor: '#f8fafc' }}>
            <AppBar position="static" elevation={0} sx={{ bgcolor: 'transparent', color: '#1e293b', borderBottom: '1px solid #e2e8f0' }}>
                <Toolbar sx={{ justifyContent: 'space-between' }}>
                    <Typography variant="h6" fontWeight={900}>Ratala Hospitality</Typography>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Typography variant="body2" color="text.secondary" fontWeight={600}>
                            Logged in as: <span style={{ color: '#1e293b', fontWeight: 800 }}>{user?.username}</span>
                        </Typography>
                        <Button
                            startIcon={<LogOut size={18} />}
                            onClick={handleLogout}
                            sx={{
                                color: '#ef4444',
                                fontWeight: 800,
                                textTransform: 'none',
                                '&:hover': { bgcolor: '#fef2f2' }
                            }}
                        >
                            Logout
                        </Button>
                    </Box>
                </Toolbar>
            </AppBar>

            <Container maxWidth="md" sx={{ py: 8 }}>
                <Box sx={{ textAlign: 'center', mb: 6 }}>
                    <Typography variant="h3" sx={{ fontWeight: 900, color: '#1e293b', mb: 2 }}>Welcome to Ratala Hospitality</Typography>
                    <Typography variant="h6" color="text.secondary">Let's get your restaurant branch set up</Typography>
                </Box>
                <Paper sx={{ p: 4, borderRadius: '24px', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
                    <Outlet />
                </Paper>
            </Container>
        </Box>
    );
};

export default BranchSetupLayout;

