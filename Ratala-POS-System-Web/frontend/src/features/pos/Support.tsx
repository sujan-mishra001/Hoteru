import React from 'react';
import { Box, Typography, Paper, Container } from '@mui/material';
import { HelpCircle, MessageCircle, Mail, Phone } from 'lucide-react';

const Support: React.FC = () => {

    return (
        <Box sx={{ py: 4 }}>
            <Container maxWidth="lg">
                <Box sx={{ mb: 4 }}>
                    <Typography variant="h4" fontWeight={800} sx={{ mb: 1 }}>
                        HOTERU Support Center
                    </Typography>
                    <Typography variant="body1" color="text.secondary">
                        Need help? We're here to assist you.
                    </Typography>
                </Box>

                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 3 }}>
                    <Paper
                        sx={{
                            p: 4,
                            borderRadius: '16px',
                            border: '1px solid #e2e8f0',
                            transition: 'all 0.3s',
                            '&:hover': {
                                boxShadow: '0 8px 24px rgba(0,0,0,0.08)',
                                transform: 'translateY(-4px)'
                            }
                        }}
                    >
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                            <Box sx={{
                                p: 2,
                                bgcolor: '#fff7ed',
                                borderRadius: '12px',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center'
                            }}>
                                <MessageCircle size={24} color="#FFC107" />
                            </Box>
                            <Typography variant="h6" fontWeight={700}>
                                Live Chat
                            </Typography>
                        </Box>
                        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                            Chat with our support team in real-time for immediate assistance.
                        </Typography>
                        <Typography variant="caption" color="#FFC107" fontWeight={600}>
                            Available: Mon-Fri, 9:00 AM - 6:00 PM
                        </Typography>
                    </Paper>

                    <Paper
                        sx={{
                            p: 4,
                            borderRadius: '16px',
                            border: '1px solid #e2e8f0',
                            transition: 'all 0.3s',
                            '&:hover': {
                                boxShadow: '0 8px 24px rgba(0,0,0,0.08)',
                                transform: 'translateY(-4px)'
                            }
                        }}
                    >
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                            <Box sx={{
                                p: 2,
                                bgcolor: '#fff7ed',
                                borderRadius: '12px',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center'
                            }}>
                                <Mail size={24} color="#FFC107" />
                            </Box>
                            <Typography variant="h6" fontWeight={700}>
                                Email Support
                            </Typography>
                        </Box>
                        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                            Send us an email and we'll get back to you within 24 hours.
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                            support@hoteru.com
                        </Typography>
                    </Paper>

                    <Paper
                        sx={{
                            p: 4,
                            borderRadius: '16px',
                            border: '1px solid #e2e8f0',
                            transition: 'all 0.3s',
                            '&:hover': {
                                boxShadow: '0 8px 24px rgba(0,0,0,0.08)',
                                transform: 'translateY(-4px)'
                            }
                        }}
                    >
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                            <Box sx={{
                                p: 2,
                                bgcolor: '#fff7ed',
                                borderRadius: '12px',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center'
                            }}>
                                <Phone size={24} color="#FFC107" />
                            </Box>
                            <Typography variant="h6" fontWeight={700}>
                                Phone Support
                            </Typography>
                        </Box>
                        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                            Call us directly for urgent matters and technical support.
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                            +977 1-591-2345
                        </Typography>
                    </Paper>

                    <Paper
                        sx={{
                            p: 4,
                            borderRadius: '16px',
                            border: '1px solid #e2e8f0',
                            transition: 'all 0.3s',
                            '&:hover': {
                                boxShadow: '0 8px 24px rgba(0,0,0,0.08)',
                                transform: 'translateY(-4px)'
                            }
                        }}
                    >
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                            <Box sx={{
                                p: 2,
                                bgcolor: '#fff7ed',
                                borderRadius: '12px',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center'
                            }}>
                                <HelpCircle size={24} color="#FFC107" />
                            </Box>
                            <Typography variant="h6" fontWeight={700}>
                                Help Center
                            </Typography>
                        </Box>
                        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                            Browse our knowledge base and frequently asked questions.
                        </Typography>
                        <Typography variant="caption" color="#FFC107" fontWeight={600}>
                            Coming Soon
                        </Typography>
                    </Paper>
                </Box>
            </Container>
        </Box>
    );
};

export default Support;

