import { Outlet, useNavigate } from 'react-router-dom';
import { Box, AppBar, Toolbar, Typography, Button, Container, Avatar } from '@mui/material';
import { LogOut, ShieldCheck } from 'lucide-react';
import { useAuth } from '../providers/AuthProvider';

const PlatformLayout: React.FC = () => {
    const { user, logout } = useAuth();
    const navigate = useNavigate();

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh', bgcolor: '#f8fafc' }}>
            <AppBar position="sticky" elevation={0} sx={{ bgcolor: '#fff', borderBottom: '1px solid #e2e8f0', color: '#1e293b' }}>
                <Toolbar sx={{ justifyContent: 'space-between' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Box sx={{
                            bgcolor: '#FFC107',
                            p: 1,
                            borderRadius: '10px',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            boxShadow: '0 4px 12px rgba(255, 193, 7, 0.2)'
                        }}>
                            <ShieldCheck size={24} color="#000" />
                        </Box>
                        <Box>
                            <Typography variant="h6" fontWeight={900} sx={{ letterSpacing: '-0.5px', lineHeight: 1.2 }}>
                                Ratala Platform
                            </Typography>
                            <Typography variant="caption" sx={{ color: '#64748b', fontWeight: 600, display: 'block', mt: -0.5 }}>
                                Control Center
                            </Typography>
                        </Box>
                    </Box>

                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 3 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, px: 2, py: 0.8, borderRadius: '12px', bgcolor: '#f1f5f9' }}>
                            <Avatar sx={{ width: 32, height: 32, bgcolor: '#FFC107', color: '#000', fontSize: '0.8rem', fontWeight: 800 }}>
                                {user?.full_name?.charAt(0) || 'P'}
                            </Avatar>
                            <Box>
                                <Typography variant="subtitle2" fontWeight={700} sx={{ fontSize: '0.85rem' }}>
                                    {user?.full_name || 'Platform Admin'}
                                </Typography>
                                <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: -0.5, fontSize: '0.7rem', fontWeight: 600 }}>
                                    Super Administrator
                                </Typography>
                            </Box>
                        </Box>
                        <Button
                            variant="text"
                            startIcon={<LogOut size={18} />}
                            onClick={handleLogout}
                            sx={{
                                color: '#ef4444',
                                fontWeight: 700,
                                textTransform: 'none',
                                borderRadius: '10px',
                                '&:hover': { bgcolor: '#fef2f2' }
                            }}
                        >
                            Sign Out
                        </Button>
                    </Box>
                </Toolbar>
            </AppBar>

            <Container maxWidth="xl" sx={{ mt: 4, pb: 8 }}>
                <Outlet />
            </Container>
        </Box>
    );
};

export default PlatformLayout;
