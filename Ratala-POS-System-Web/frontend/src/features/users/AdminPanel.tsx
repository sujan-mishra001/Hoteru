import React, { useState, useEffect } from 'react';
import {
    Box,
    Typography,
    Paper,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Button,
    Chip,
    IconButton,
    Alert,
    CircularProgress,
    Snackbar,
    Avatar,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
    MenuItem,
    Grid
} from '@mui/material';
import { Trash2, RefreshCw, Shield, Calendar, Store, Edit2, UserCheck, X } from 'lucide-react';
import { usersAPI, branchAPI } from '../../services/api';

const AdminPanel: React.FC = () => {
    const [users, setUsers] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [branches, setBranches] = useState<any[]>([]);
    const [processing, setProcessing] = useState(false);
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

    // Edit Dialog State
    const [editDialogOpen, setEditDialogOpen] = useState(false);
    const [selectedUser, setSelectedUser] = useState<any>(null);
    const [editFormData, setEditFormData] = useState({
        full_name: '',
        email: '',
        role: '',
        username: '',
        disabled: false
    });

    const fetchData = async () => {
        try {
            setLoading(true);
            const [usersRes, branchesRes] = await Promise.all([
                usersAPI.getAllOrganizationUsers(),
                branchAPI.getAllSystemBranches() // I'll need to add this to api.ts or just handle it
            ]);
            setUsers(usersRes.data || []);
            setBranches(branchesRes.data || []);
        } catch (err) {
            console.error('Error fetching admin data:', err);
            showSnackbar('Failed to fetch user data', 'error');
            // Fallback for users if the new organization call fails
            try {
                const usersRes = await usersAPI.getAllOrganizationUsers();
                setUsers(usersRes.data || []);
            } catch (e) { }
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();
    }, []);

    const showSnackbar = (message: string, severity: 'success' | 'error' = 'success') => {
        setSnackbar({ open: true, message, severity });
    };

    const handleOpenEdit = (user: any) => {
        setSelectedUser(user);
        setEditFormData({
            full_name: user.full_name || '',
            email: user.email || '',
            role: user.role || '',
            username: user.username || '',
            disabled: user.disabled || false
        });
        setEditDialogOpen(true);
    };

    const handleCloseEdit = () => {
        setEditDialogOpen(false);
        setSelectedUser(null);
    };

    const handleUpdateUser = async () => {
        if (!selectedUser) return;
        setProcessing(true);
        try {
            await usersAPI.update(selectedUser.id, editFormData);
            showSnackbar('User updated successfully');
            handleCloseEdit();
            fetchData();
        } catch (err: any) {
            showSnackbar(err.response?.data?.detail || 'Error updating user', 'error');
        } finally {
            setProcessing(false);
        }
    };

    const handleDeleteUser = async (userId: number, userFullName: string) => {
        if (!window.confirm(`Are you sure you want to delete user "${userFullName}"? This action cannot be undone.`)) return;

        setProcessing(true);
        try {
            await usersAPI.delete(userId);
            showSnackbar('User deleted successfully');
            fetchData();
        } catch (err: any) {
            showSnackbar(err.response?.data?.detail || 'Error deleting user', 'error');
        } finally {
            setProcessing(false);
        }
    };

    const formatDate = (dateString?: string) => {
        if (!dateString) return 'N/A';
        return new Date(dateString).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    };

    return (
        <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
                <Box>
                    <Typography variant="h4" fontWeight={900} sx={{ color: '#1e293b', letterSpacing: '-1px' }}>
                        Platform Control Center
                    </Typography>
                    <Typography variant="body1" color="text.secondary" fontWeight={500}>
                        Manage all registered users and organizations globally
                    </Typography>
                </Box>
                <Button
                    variant="contained"
                    startIcon={<RefreshCw size={18} />}
                    onClick={fetchData}
                    disabled={loading}
                    sx={{
                        borderRadius: '12px',
                        textTransform: 'none',
                        bgcolor: '#FFC107',
                        color: '#000',
                        fontWeight: 700,
                        '&:hover': { bgcolor: '#eab308' },
                        boxShadow: '0 4px 12px rgba(255, 193, 7, 0.2)'
                    }}
                >
                    Refresh Directory
                </Button>
            </Box>

            <Alert
                severity="warning"
                icon={<UserCheck size={20} />}
                sx={{ mb: 4, borderRadius: '16px', fontWeight: 600, border: '1px solid #fef3c7', bgcolor: '#fffbeb', color: '#92400e' }}
            >
                You are currently in the Platform Administration view. Any changes made here will affect users across the entire system. Use with caution.
            </Alert>

            <TableContainer component={Paper} sx={{ borderRadius: '20px', border: '1px solid #e2e8f0', boxShadow: '0 10px 15px -3px rgba(0,0,0,0.05)', overflow: 'hidden' }} elevation={0}>
                <Table>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 800, color: '#475569', fontSize: '0.85rem', textTransform: 'uppercase' }}>User / Registry</TableCell>
                            <TableCell sx={{ fontWeight: 800, color: '#475569', fontSize: '0.85rem', textTransform: 'uppercase' }}>System Role</TableCell>
                            <TableCell sx={{ fontWeight: 800, color: '#475569', fontSize: '0.85rem', textTransform: 'uppercase' }}>Status</TableCell>
                            <TableCell sx={{ fontWeight: 800, color: '#475569', fontSize: '0.85rem', textTransform: 'uppercase' }}>Organization / Branch</TableCell>
                            <TableCell sx={{ fontWeight: 800, color: '#475569', fontSize: '0.85rem', textTransform: 'uppercase' }}>Registration Date</TableCell>
                            <TableCell sx={{ fontWeight: 800, color: '#475569', fontSize: '0.85rem', textTransform: 'uppercase' }} align="right">Actions</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={5} align="center" sx={{ py: 15 }}>
                                    <CircularProgress size={50} sx={{ color: '#FFC107' }} thickness={5} />
                                    <Typography sx={{ mt: 3, color: '#64748b', fontWeight: 600 }}>Syncing with global registry...</Typography>
                                </TableCell>
                            </TableRow>
                        ) : users.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={5} align="center" sx={{ py: 10 }}>
                                    <Typography color="text.secondary" fontWeight={500}>No registered users found in the system</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            users.map((user) => (
                                <TableRow key={user.id} sx={{ '&:hover': { bgcolor: '#f8fafc' }, transition: 'background-color 0.2s' }}>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2.5 }}>
                                            <Avatar
                                                src={user.profile_image_url}
                                                sx={{
                                                    width: 44,
                                                    height: 44,
                                                    bgcolor: '#f1f5f9',
                                                    color: '#FFC107',
                                                    fontWeight: 800,
                                                    border: '2px solid #fff',
                                                    boxShadow: '0 2px 4px rgba(0,0,0,0.05)'
                                                }}
                                            >
                                                {user.full_name?.charAt(0) || user.username?.charAt(0)}
                                            </Avatar>
                                            <Box>
                                                <Typography variant="subtitle1" fontWeight={800} sx={{ color: '#1e293b', lineHeight: 1.2 }}>
                                                    {user.full_name}
                                                </Typography>
                                                <Typography variant="body2" sx={{ color: '#64748b', fontWeight: 500 }}>
                                                    {user.email || user.username}
                                                </Typography>
                                            </Box>
                                        </Box>
                                    </TableCell>
                                    <TableCell>
                                        <Chip
                                            icon={<Shield size={14} />}
                                            label={user.role}
                                            size="small"
                                            sx={{
                                                bgcolor: user.role.toLowerCase() === 'platform_admin' ? '#fef2f2' : (user.role.toLowerCase() === 'admin' ? '#fff7ed' : '#f0fdf4'),
                                                color: user.role.toLowerCase() === 'platform_admin' ? '#ef4444' : (user.role.toLowerCase() === 'admin' ? '#c2410c' : '#15803d'),
                                                fontWeight: 800,
                                                textTransform: 'uppercase',
                                                fontSize: '0.65rem',
                                                borderRadius: '6px',
                                                '& .MuiChip-icon': { color: 'inherit' }
                                            }}
                                        />
                                    </TableCell>
                                    <TableCell>
                                        <Chip
                                            label={user.disabled ? 'Disabled' : 'Enabled'}
                                            size="small"
                                            sx={{
                                                bgcolor: user.disabled ? '#fee2e2' : '#dcfce7',
                                                color: user.disabled ? '#b91c1c' : '#15803d',
                                                fontWeight: 700,
                                                borderRadius: '6px',
                                                fontSize: '0.75rem'
                                            }}
                                        />
                                    </TableCell>
                                    <TableCell>
                                        <Box>
                                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                                                <Store size={14} color="#64748b" />
                                                <Typography variant="body2" sx={{ color: '#1e293b', fontWeight: 600 }}>
                                                    {user.organization?.name || 'Self-Registered'}
                                                </Typography>
                                            </Box>
                                            <Box sx={{ ml: 3.2, display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                                                {user.branch_assignments && user.branch_assignments.length > 0 ? (
                                                    user.branch_assignments.map((assignment: any) => (
                                                        <Chip
                                                            key={assignment.branch_id}
                                                            label={assignment.branch?.name || 'Unknown'}
                                                            size="small"
                                                            variant="outlined"
                                                            sx={{
                                                                fontSize: '0.65rem',
                                                                height: '18px',
                                                                borderColor: assignment.is_primary ? '#fbbf24' : '#e2e8f0',
                                                                bgcolor: assignment.is_primary ? '#fffbeb' : 'transparent',
                                                                fontWeight: assignment.is_primary ? 700 : 500
                                                            }}
                                                        />
                                                    ))
                                                ) : (
                                                    <Typography variant="caption" sx={{ color: '#94a3b8' }}>
                                                        {user.current_branch_id ?
                                                            (branches.find(b => b.id === user.current_branch_id)?.name || 'Branch Member') :
                                                            'No primary branch'
                                                        }
                                                    </Typography>
                                                )}
                                            </Box>
                                        </Box>
                                    </TableCell>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <Calendar size={14} color="#64748b" />
                                            <Typography variant="body2" sx={{ color: '#475569', fontWeight: 500 }}>
                                                {formatDate(user.created_at)}
                                            </Typography>
                                        </Box>
                                    </TableCell>
                                    <TableCell align="right">
                                        <Box sx={{ display: 'flex', gap: 1, justifyContent: 'flex-end' }}>
                                            <IconButton
                                                size="small"
                                                onClick={() => handleOpenEdit(user)}
                                                sx={{
                                                    color: '#6366f1',
                                                    bgcolor: '#eef2ff',
                                                    '&:hover': { bgcolor: '#e0e7ff' }
                                                }}
                                            >
                                                <Edit2 size={18} />
                                            </IconButton>
                                            <IconButton
                                                size="small"
                                                color="error"
                                                onClick={() => handleDeleteUser(user.id, user.full_name)}
                                                disabled={processing || user.role.toLowerCase() === 'platform_admin'}
                                                sx={{
                                                    bgcolor: '#fff1f2',
                                                    '&:hover': { bgcolor: '#ffe4e6' },
                                                    opacity: user.role.toLowerCase() === 'platform_admin' ? 0.3 : 1
                                                }}
                                            >
                                                <Trash2 size={18} />
                                            </IconButton>
                                        </Box>
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            {/* Edit User Dialog */}
            <Dialog
                open={editDialogOpen}
                onClose={handleCloseEdit}
                PaperProps={{
                    sx: { borderRadius: '24px', width: '100%', maxWidth: '500px', p: 1 }
                }}
            >
                <DialogTitle sx={{ fontWeight: 900, fontSize: '1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    Edit System User
                    <IconButton onClick={handleCloseEdit}><X size={24} /></IconButton>
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ mt: 2 }}>
                        <Grid container spacing={3}>
                            <Grid size={12}>
                                <TextField
                                    label="Full Name"
                                    fullWidth
                                    value={editFormData.full_name}
                                    onChange={(e) => setEditFormData({ ...editFormData, full_name: e.target.value })}
                                />
                            </Grid>
                            <Grid size={12}>
                                <TextField
                                    label="Email Address"
                                    fullWidth
                                    value={editFormData.email}
                                    onChange={(e) => setEditFormData({ ...editFormData, email: e.target.value })}
                                />
                            </Grid>
                            <Grid size={12}>
                                <TextField
                                    label="Username"
                                    fullWidth
                                    disabled
                                    value={editFormData.username}
                                />
                            </Grid>
                            <Grid size={12}>
                                <TextField
                                    select
                                    label="System Role"
                                    fullWidth
                                    value={editFormData.role}
                                    onChange={(e) => setEditFormData({ ...editFormData, role: e.target.value })}
                                >
                                    <MenuItem value="admin">Organization Admin</MenuItem>
                                    <MenuItem value="platform_admin">Platform Manager</MenuItem>
                                    <MenuItem value="worker">Standard Staff</MenuItem>
                                    <MenuItem value="waiter">Waiter</MenuItem>
                                    <MenuItem value="bartender">Bartender</MenuItem>
                                </TextField>
                            </Grid>
                            <Grid size={12}>
                                <TextField
                                    select
                                    label="Account Status"
                                    fullWidth
                                    value={editFormData.disabled ? 'true' : 'false'}
                                    onChange={(e) => setEditFormData({ ...editFormData, disabled: e.target.value === 'true' })}
                                >
                                    <MenuItem value="false">Active (Enabled)</MenuItem>
                                    <MenuItem value="true">Inactive (Disabled)</MenuItem>
                                </TextField>
                            </Grid>
                        </Grid>
                    </Box>
                </DialogContent>
                <DialogActions sx={{ p: 3, pt: 1 }}>
                    <Button
                        onClick={handleCloseEdit}
                        variant="text"
                        sx={{ fontWeight: 700, borderRadius: '12px', color: '#64748b' }}
                    >
                        Cancel
                    </Button>
                    <Button
                        onClick={handleUpdateUser}
                        variant="contained"
                        disabled={processing}
                        sx={{
                            fontWeight: 800,
                            borderRadius: '12px',
                            bgcolor: '#FFC107',
                            color: '#000',
                            px: 4,
                            '&:hover': { bgcolor: '#eab308' }
                        }}
                    >
                        {processing ? <CircularProgress size={20} /> : 'Save Changes'}
                    </Button>
                </DialogActions>
            </Dialog>

            <Snackbar
                open={snackbar.open}
                autoHideDuration={4000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            >
                <Alert severity={snackbar.severity} sx={{ width: '100%', borderRadius: '12px', fontWeight: 600, boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)' }}>
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </Box>
    );
};

export default AdminPanel;
