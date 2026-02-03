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
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
    Checkbox,
    FormControlLabel,
    CircularProgress,
    Snackbar,
    Alert,
    Grid
} from '@mui/material';
import { Shield, Edit, Trash2, RefreshCw } from 'lucide-react';
import { rolesAPI } from '../../services/api';

const Roles: React.FC = () => {
    const [roles, setRoles] = useState<any[]>([]);
    const [availablePermissions, setAvailablePermissions] = useState<string[]>([]);
    const [loading, setLoading] = useState(true);
    const [open, setOpen] = useState(false);
    const [editingRole, setEditingRole] = useState<any>(null);
    const [formData, setFormData] = useState({ name: '', description: '', permissions: [] as string[] });
    const [processing, setProcessing] = useState(false);
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

    const fetchRolesAndPermissions = async () => {
        try {
            setLoading(true);
            const [rolesRes, permsRes] = await Promise.all([
                rolesAPI.getAll(),
                rolesAPI.getPermissions()
            ]);
            setRoles(rolesRes.data || []);
            setAvailablePermissions(permsRes.data || []);
        } catch (err) {
            console.error('Error fetching roles:', err);
            showSnackbar('Failed to fetch data', 'error');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchRolesAndPermissions();
    }, []);

    const showSnackbar = (message: string, severity: 'success' | 'error' = 'success') => {
        setSnackbar({ open: true, message, severity });
    };

    const handleOpenDialog = (role?: any) => {
        if (role) {
            setEditingRole(role);
            setFormData({
                name: role.name,
                description: role.description || '',
                permissions: role.permissions || []
            });
        } else {
            setEditingRole(null);
            setFormData({ name: '', description: '', permissions: [] });
        }
        setOpen(true);
    };

    const handlePermissionToggle = (perm: string) => {
        const newPerms = formData.permissions.includes(perm)
            ? formData.permissions.filter(p => p !== perm)
            : [...formData.permissions, perm];
        setFormData({ ...formData, permissions: newPerms });
    };

    const handleSaveRole = async () => {
        if (!formData.name) return showSnackbar('Role name is required', 'error');

        setProcessing(true);
        try {
            if (editingRole) {
                await rolesAPI.update(editingRole.id, formData);
                showSnackbar('Role updated successfully');
            } else {
                await rolesAPI.create(formData);
                showSnackbar('Role created successfully');
            }
            setOpen(false);
            fetchRolesAndPermissions();
        } catch (err: any) {
            showSnackbar(err.response?.data?.detail || 'Error saving role', 'error');
        } finally {
            setProcessing(false);
        }
    };

    const handleDeleteRole = async (roleId: number) => {
        if (!window.confirm('Are you sure you want to delete this role? This may affect users assigned to it.')) return;

        setProcessing(true);
        try {
            await rolesAPI.delete(roleId);
            showSnackbar('Role deleted successfully');
            fetchRolesAndPermissions();
        } catch (err: any) {
            showSnackbar(err.response?.data?.detail || 'Error deleting role', 'error');
        } finally {
            setProcessing(false);
        }
    };

    return (
        <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
                <Box>
                    <Typography variant="h5" fontWeight={800}>Dynamic Role Management</Typography>
                    <Typography variant="body2" color="text.secondary">Create custom roles and assign granular permissions</Typography>
                </Box>
                <Box sx={{ display: 'flex', gap: 2 }}>
                    <Button
                        variant="outlined"
                        startIcon={<RefreshCw size={18} />}
                        onClick={fetchRolesAndPermissions}
                        disabled={loading}
                        sx={{ borderRadius: '10px', textTransform: 'none' }}
                    >
                        Refresh
                    </Button>
                    <Button
                        variant="contained"
                        startIcon={<Shield size={18} />}
                        onClick={() => handleOpenDialog()}
                        sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', borderRadius: '10px' }}
                    >
                        Create New Role
                    </Button>
                </Box>
            </Box>

            <TableContainer component={Paper} sx={{ borderRadius: '16px', border: '1px solid #f1f5f9' }} elevation={0}>
                <Table>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700 }}>Role Name</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Description</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Permissions</TableCell>
                            <TableCell sx={{ fontWeight: 700 }} align="right">Actions</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={4} align="center" sx={{ py: 8 }}>
                                    <CircularProgress />
                                </TableCell>
                            </TableRow>
                        ) : roles.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={4} align="center" sx={{ py: 8 }}>
                                    <Typography color="text.secondary">No roles found</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            roles.map((role) => (
                                <TableRow key={role.id} sx={{ '&:hover': { bgcolor: '#fdfdfd' } }}>
                                    <TableCell sx={{ fontWeight: 700, color: '#1e293b' }}>{role.name}</TableCell>
                                    <TableCell sx={{ maxWidth: 300 }}>{role.description}</TableCell>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                                            {role.permissions?.map((p: string) => (
                                                <Chip key={p} label={p} size="small" sx={{ bgcolor: '#fff7ed', color: '#FFC107', fontWeight: 800, fontSize: '0.7rem' }} />
                                            ))}
                                            {(!role.permissions || role.permissions.length === 0) && (
                                                <Typography variant="caption" color="text.secondary">No explicitly assigned permissions</Typography>
                                            )}
                                        </Box>
                                    </TableCell>
                                    <TableCell align="right">
                                        <IconButton size="small" onClick={() => handleOpenDialog(role)} sx={{ color: '#FFC107' }}>
                                            <Edit size={16} />
                                        </IconButton>
                                        <IconButton
                                            size="small"
                                            color="error"
                                            onClick={() => handleDeleteRole(role.id)}
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

            <Dialog open={open} onClose={() => !processing && setOpen(false)} maxWidth="md" fullWidth>
                <DialogTitle sx={{ fontWeight: 800 }}>{editingRole ? 'Edit Role' : 'Create New Role'}</DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, pt: 1 }}>
                        <TextField
                            label="Role Name"
                            fullWidth
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            disabled={processing}
                        />
                        <TextField
                            label="Description"
                            fullWidth
                            multiline
                            rows={2}
                            value={formData.description}
                            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                            disabled={processing}
                        />

                        <Box>
                            <Typography variant="subtitle2" fontWeight={800} gutterBottom>Permissions</Typography>
                            <Paper variant="outlined" sx={{ p: 2, bgcolor: '#f8fafc', borderRadius: '12px' }}>
                                <Grid container spacing={1}>
                                    {availablePermissions.map(perm => (
                                        <Grid size={{ xs: 12, sm: 6, md: 4 }} key={perm}>
                                            <FormControlLabel
                                                control={
                                                    <Checkbox
                                                        size="small"
                                                        checked={formData.permissions.includes(perm)}
                                                        onChange={() => handlePermissionToggle(perm)}
                                                        disabled={processing}
                                                        sx={{ color: '#FFC107', '&.Mui-checked': { color: '#FFC107' } }}
                                                    />
                                                }
                                                label={<Typography variant="body2">{perm}</Typography>}
                                            />
                                        </Grid>
                                    ))}
                                </Grid>
                            </Paper>
                        </Box>
                    </Box>
                </DialogContent>
                <DialogActions sx={{ p: 3 }}>
                    <Button onClick={() => setOpen(false)} disabled={processing}>Cancel</Button>
                    <Button
                        onClick={handleSaveRole}
                        variant="contained"
                        disabled={processing}
                        sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, fontWeight: 700 }}
                    >
                        {processing ? <CircularProgress size={24} color="inherit" /> : editingRole ? 'Update Role' : 'Create Role'}
                    </Button>
                </DialogActions>
            </Dialog>

            <Snackbar
                open={snackbar.open}
                autoHideDuration={4000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
            >
                <Alert severity={snackbar.severity} sx={{ width: '100%', borderRadius: '12px', fontWeight: 600 }}>
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </Box>
    );
};

export default Roles;

