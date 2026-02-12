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
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
    Chip,
    IconButton,
    MenuItem,
    Alert,
    CircularProgress,
    Snackbar,
    InputAdornment
} from '@mui/material';
import { UserPlus, Trash2, Edit, RefreshCw, Eye, EyeOff } from 'lucide-react';
import { usersAPI, rolesAPI, branchAPI } from '../../services/api';

const UserManagement: React.FC = () => {
    const [users, setUsers] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [open, setOpen] = useState(false);
    const [editingUser, setEditingUser] = useState<any>(null);
    const [newUser, setNewUser] = useState<any>({ username: '', full_name: '', email: '', password: '', role: '', branch_id: '' });
    const [roles, setRoles] = useState<any[]>([]);
    const [branches, setBranches] = useState<any[]>([]);
    const [processing, setProcessing] = useState(false);
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });
    const [showPassword, setShowPassword] = useState(false);

    const fetchUsers = async () => {
        try {
            setLoading(true);
            const response = await usersAPI.getAll();
            setUsers(response.data || []);
        } catch (err) {
            setUsers([]);
            showSnackbar('Failed to fetch users', 'error');
        } finally {
            setLoading(false);
        }
    };

    const fetchRoles = async () => {
        try {
            const response = await rolesAPI.getAll();
            const fetchedRoles = response.data || [];
            setRoles(fetchedRoles);
            if (!editingUser && fetchedRoles.length > 0 && !newUser.role) {
                setNewUser((prev: any) => ({ ...prev, role: fetchedRoles[0].name }));
            }
        } catch (err) {
            console.error('Error fetching roles:', err);
        }
    };

    const fetchBranches = async () => {
        try {
            const response = await branchAPI.getAll();
            setBranches(response.data || []);
        } catch (err) {
            console.error('Error fetching branches:', err);
        }
    };

    useEffect(() => {
        fetchUsers();
        fetchRoles();
        fetchBranches();
    }, []);

    const showSnackbar = (message: string, severity: 'success' | 'error' = 'success') => {
        setSnackbar({ open: true, message, severity });
    };

    const handleOpenDialog = (user?: any) => {
        if (user) {
            setEditingUser(user);
            setNewUser({
                username: user.username || '',
                full_name: user.full_name || '',
                email: user.email || '',
                password: '',
                role: user.role || '',
                branch_id: user.current_branch_id || ''
            });
        } else {
            setEditingUser(null);
            setNewUser({
                username: '',
                full_name: '',
                email: '',
                password: '',
                role: roles.length > 0 ? roles[0].name : '',
                branch_id: branches.length > 0 ? branches[0].id : ''
            });
        }
        setShowPassword(false);
        setOpen(true);
    };

    const handleSaveUser = async () => {
        setProcessing(true);
        try {
            if (editingUser) {
                await usersAPI.update(editingUser.id, newUser);
                showSnackbar('User updated successfully');
            } else {
                await usersAPI.create(newUser);
                showSnackbar('User created successfully');
            }
            setOpen(false);
            fetchUsers();
        } catch (err: any) {
            showSnackbar(err.response?.data?.detail || 'Error saving user', 'error');
        } finally {
            setProcessing(false);
        }
    };

    const handleDeleteUser = async (userId: number) => {
        if (!window.confirm('Are you sure you want to delete this user?')) return;

        setProcessing(true);
        try {
            await usersAPI.delete(userId);
            showSnackbar('User deleted successfully');
            fetchUsers();
        } catch (err: any) {
            showSnackbar(err.response?.data?.detail || 'Error deleting user', 'error');
        } finally {
            setProcessing(false);
        }
    };

    return (
        <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
                <Box>
                    <Typography variant="h5" fontWeight={800}>User Management</Typography>
                    <Typography variant="body2" color="text.secondary">Manage business staff and their access roles</Typography>
                </Box>
                <Box sx={{ display: 'flex', gap: 2 }}>
                    <Button
                        variant="outlined"
                        startIcon={<RefreshCw size={18} />}
                        onClick={fetchUsers}
                        disabled={loading}
                        sx={{ borderRadius: '10px', textTransform: 'none' }}
                    >
                        Refresh
                    </Button>
                    <Button
                        variant="contained"
                        startIcon={<UserPlus size={18} />}
                        onClick={() => handleOpenDialog()}
                        sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', borderRadius: '10px' }}
                    >
                        Add Staff Member
                    </Button>
                </Box>
            </Box>

            <TableContainer component={Paper} sx={{ borderRadius: '16px', border: '1px solid #f1f5f9' }} elevation={0}>
                <Table>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700 }}>Full Name</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Username / Email</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Role</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Assigned Branch</TableCell>
                            <TableCell sx={{ fontWeight: 700 }} align="right">Actions</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={5} align="center" sx={{ py: 8 }}>
                                    <CircularProgress />
                                </TableCell>
                            </TableRow>
                        ) : users.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={5} align="center" sx={{ py: 8 }}>
                                    <Typography color="text.secondary">No users found</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            users.map((user) => (
                                <TableRow key={user.id} sx={{ '&:hover': { bgcolor: '#fdfdfd' } }}>
                                    <TableCell sx={{ fontWeight: 600 }}>{user.full_name}</TableCell>
                                    <TableCell>{user.username || user.email}</TableCell>
                                    <TableCell>
                                        <Chip
                                            label={user.role}
                                            size="small"
                                            sx={{
                                                bgcolor: '#fff7ed',
                                                color: '#FFC107',
                                                fontWeight: 800,
                                                textTransform: 'capitalize'
                                            }}
                                        />
                                    </TableCell>
                                    <TableCell>
                                        {user.current_branch_id ? (
                                            <Chip
                                                label={branches.find(b => b.id === user.current_branch_id)?.name || `ID: ${user.current_branch_id}`}
                                                size="small"
                                                variant="outlined"
                                            />
                                        ) : (
                                            <Typography variant="caption" color="text.secondary">None</Typography>
                                        )}
                                    </TableCell>
                                    <TableCell align="right">
                                        <IconButton size="small" onClick={() => handleOpenDialog(user)} sx={{ color: '#64748b' }}>
                                            <Edit size={16} />
                                        </IconButton>
                                        <IconButton
                                            size="small"
                                            color="error"
                                            onClick={() => handleDeleteUser(user.id)}
                                            disabled={processing}
                                        >
                                            <Trash2 size={16} />
                                        </IconButton>
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            <Dialog open={open} onClose={() => !processing && setOpen(false)} maxWidth="sm" fullWidth>
                <DialogTitle sx={{ fontWeight: 800 }}>{editingUser ? 'Edit Staff Member' : 'Add Staff Member'}</DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
                        <TextField
                            label="Full Name"
                            fullWidth
                            value={newUser.full_name}
                            onChange={(e) => setNewUser({ ...newUser, full_name: e.target.value })}
                            disabled={processing}
                        />
                        <TextField
                            label="Username / Email"
                            fullWidth
                            value={newUser.email}
                            onChange={(e) => setNewUser({ ...newUser, email: e.target.value, username: e.target.value })}
                            disabled={processing}
                        />
                        {!editingUser && (
                            <TextField
                                label="Password"
                                type={showPassword ? 'text' : 'password'}
                                fullWidth
                                value={newUser.password}
                                onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
                                disabled={processing}
                                InputProps={{
                                    endAdornment: (
                                        <InputAdornment position="end">
                                            <IconButton
                                                aria-label="toggle password visibility"
                                                onClick={() => setShowPassword(!showPassword)}
                                                onMouseDown={(e) => e.preventDefault()}
                                                edge="end"
                                                size="small"
                                            >
                                                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                                            </IconButton>
                                        </InputAdornment>
                                    ),
                                }}
                            />
                        )}
                        <TextField
                            select
                            label="Role"
                            fullWidth
                            value={newUser.role}
                            onChange={(e) => setNewUser({ ...newUser, role: e.target.value })}
                            disabled={processing}
                            error={roles.length === 0}
                            helperText={roles.length === 0 ? "Please create roles first in Roles & Permissions" : ""}
                        >
                            {roles.map((role) => (
                                <MenuItem key={role.id} value={role.name}>
                                    {role.name}
                                </MenuItem>
                            ))}
                        </TextField>
                        <TextField
                            select
                            label="Default Branch"
                            fullWidth
                            value={newUser.branch_id}
                            onChange={(e) => setNewUser({ ...newUser, branch_id: e.target.value })}
                            disabled={processing}
                            error={branches.length === 0}
                            helperText={branches.length === 0 ? "Please create a branch first" : "The branch this staff member is assigned to"}
                        >
                            {branches.map((branch) => (
                                <MenuItem key={branch.id} value={branch.id}>
                                    {branch.name} ({branch.code})
                                </MenuItem>
                            ))}
                        </TextField>
                    </Box>
                </DialogContent>
                <DialogActions sx={{ p: 3 }}>
                    <Button onClick={() => setOpen(false)} disabled={processing}>Cancel</Button>
                    <Button
                        onClick={handleSaveUser}
                        variant="contained"
                        disabled={processing}
                        sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, fontWeight: 700 }}
                    >
                        {processing ? <CircularProgress size={24} color="inherit" /> : editingUser ? 'Update User' : 'Create User'}
                    </Button>
                </DialogActions>
            </Dialog>

            <Snackbar
                open={snackbar.open}
                autoHideDuration={4000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            >
                <Alert severity={snackbar.severity} sx={{ width: '100%', borderRadius: '12px', fontWeight: 600 }}>
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </Box>
    );
};

export default UserManagement;

