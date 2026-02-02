import React from 'react';
import { Box, Container, Typography, Paper } from '@mui/material';
import { Outlet } from 'react-router-dom';

const BranchSetupLayout: React.FC = () => {
    return (
        <Box sx={{ minHeight: '100vh', bgcolor: '#f8fafc', py: 8 }}>
            <Container maxWidth="md">
                <Box sx={{ textAlign: 'center', mb: 6 }}>
                    <Typography variant="h3" sx={{ fontWeight: 900, color: '#1e293b', mb: 2 }}>Welcome to HOTERU</Typography>
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
