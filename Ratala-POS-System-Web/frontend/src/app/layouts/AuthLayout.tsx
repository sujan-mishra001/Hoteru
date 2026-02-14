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
                <Box sx={{ width: '100%', maxWidth: 480 }}>
                    <Box sx={{ mb: 5, textAlign: 'center' }}>
                        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3, mb: 3 }}>
                            <Box
                                component="img"
                                src="/Ratala Hospitality Logo.jpg"
                                alt="Ratala Hospitality Logo"
                                sx={{
                                    height: 150,
                                    borderRadius: '20px',
                                    objectFit: 'contain',
                                    boxShadow: '0 p4x 20px rgba(0,0,0,0.08)'
                                }}
                            />
                            <Typography
                                variant="h3"
                                sx={{
                                    fontWeight: 900,
                                    color: '#FFC107',
                                    letterSpacing: '-1px',
                                    textTransform: 'uppercase',
                                    lineHeight: 1.1
                                }}
                            >
                                Ratala Hospitality
                            </Typography>
                        </Box>
                        <Typography variant="body1" sx={{ color: '#64748b', fontWeight: 500, textAlign: 'center' }}>
                            Premium Restaurant Management App
                        </Typography>
                    </Box>
                    <Outlet />
                </Box>
            </Box>
        </Box>
    );
};

export default AuthLayout;

