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
            {/* Left side - Image with Branding Overlay */}
            <Box
                sx={{
                    width: '60%',
                    height: '100vh',
                    display: { xs: 'none', md: 'flex' },
                    backgroundImage: 'url("/Cafe.jpeg")',
                    backgroundSize: 'cover',
                    backgroundPosition: 'center',
                    position: 'relative',
                    flexDirection: 'column',
                    justifyContent: 'center',
                    px: 8,
                    '&::before': {
                        content: '""',
                        position: 'absolute',
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        background: 'linear-gradient(135deg, rgba(0,0,0,0.7) 0%, rgba(0,0,0,0.3) 100%)',
                        zIndex: 1
                    }
                }}
            >
                <Box sx={{ position: 'relative', zIndex: 2, color: 'white' }}>
                    <Typography variant="h2" sx={{ fontWeight: 900, mb: 2, letterSpacing: '-1px' }}>
                        Manage Your <span style={{ color: '#FFC107' }}>Restaurant</span> <br /> With Our Services.
                    </Typography>
                    <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 400, maxWidth: 500, lineHeight: 1.6 }}>
                        Streamline your operations, manage orders, and grow your business with Ratala Hospitality's POS solution.
                    </Typography>
                </Box>
            </Box>

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
                    p: { xs: 2, md: 4 },
                    overflowY: 'auto' // Ensure scrolling on small vertical screens
                }}
            >
                <Box sx={{ width: '100%', maxWidth: { xs: 400, md: 600 } }}>
                    <Box sx={{ mb: 4, textAlign: { xs: 'center', sm: 'left' } }}>
                        <Box sx={{
                            display: 'flex',
                            flexDirection: { xs: 'column', sm: 'row' },
                            alignItems: 'center',
                            justifyContent: { xs: 'center', sm: 'flex-start' },
                            gap: { xs: 2, md: 3 },
                            mb: 2
                        }}>
                            <Box
                                component="img"
                                src="/Ratala Hospitality Logo.jpg"
                                alt="Ratala Hospitality Logo"
                                sx={{
                                    height: { xs: 120, md: 180 }, // Responsive logo size
                                    borderRadius: '12px',
                                    objectFit: 'contain'
                                }}
                            />
                            <Typography
                                variant="h4"
                                sx={{
                                    fontWeight: 900,
                                    color: '#FFC107',
                                    letterSpacing: '-0.5px',
                                    textTransform: 'uppercase'
                                }}
                            >
                                Ratala Hospitality
                            </Typography>
                        </Box>
                        <Typography variant="body1" sx={{ color: '#64748b', fontWeight: 500, textAlign: { xs: 'center', sm: 'left' }, ml: { sm: 1 , xs: 'center' } }}>
                            Restaurant Management App
                        </Typography>
                    </Box>
                    <Outlet />
                </Box>
            </Box>
        </Box>
    );
};

export default AuthLayout;

