import { Box, Typography } from '@mui/material';
import { Outlet } from 'react-router-dom';

const AuthLayout: React.FC = () => {
    return (
        <Box
            sx={{
                minHeight: '100vh',
                display: 'flex',
                bgcolor: '#f8fafc',
                overflow: 'hidden'
            }}
        >
            {/* Left side - Image */}
            <Box
                sx={{
                    width: '60%',
                    height: '100vh',
                    display: { xs: 'none', md: 'block' },
                    backgroundImage: 'url("/Cafe.jpeg")',
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                    position: 'relative',
                    '&::before': {
                        content: '""',
                        position: 'absolute',
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        bgcolor: 'rgba(0,0,0,0.3)', // Subtle overlay
                    }
                }}
            />

            {/* Right side - Content */}
            <Box
                sx={{
                    width: { xs: '100%', md: '40%' },
                    height: '100vh',
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'center',
                    alignItems: 'center',
                    bgcolor: 'white',
                    p: 4
                }}
            >
                <Box sx={{ width: '100%', maxWidth: 400 }}>
                    <Box sx={{ mb: 4, textAlign: 'left' }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                            <Box
                                component="img"
                                src="/dautari-logo.png"
                                alt="Dautari Adda Logo"
                                sx={{
                                    height: 60,
                                    filter: 'drop-shadow(0 4px 6px rgba(0,0,0,0.1))'
                                }}
                            />
                            <Typography
                                variant="h4"
                                sx={{
                                    fontWeight: 900,
                                    color: '#1e293b',
                                    letterSpacing: '-1px',
                                    textTransform: 'uppercase'
                                }}
                            >
                                Dautari Adda
                            </Typography>
                        </Box>
                        <Typography variant="body1" sx={{ color: '#64748b', fontWeight: 500 }}>
                            Digital Business Management Platform
                        </Typography>
                    </Box>
                    <Outlet />
                </Box>
            </Box>
        </Box>
    );
};

export default AuthLayout;

