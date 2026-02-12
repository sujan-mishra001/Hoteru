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
    TextField,
    Dialog,
    DialogTitle,
    DialogContent,
    IconButton,
    InputAdornment,
    Snackbar,
    Alert
} from '@mui/material';
import { Plus, Search, X, Edit, Trash2 } from 'lucide-react';
import { inventoryAPI } from '../../../services/api';

const Units: React.FC = () => {
    const [units, setUnits] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [openDialog, setOpenDialog] = useState(false);
    const [editingUnit, setEditingUnit] = useState<any>(null);
    const [formData, setFormData] = useState({ name: '', abbreviation: '' });
    const [searchTerm, setSearchTerm] = useState('');
    const [openRulesDialog, setOpenRulesDialog] = useState(false);
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

    const showSnackbar = (message: string, severity: 'success' | 'error' = 'success') => {
        setSnackbar({ open: true, message, severity });
    };

    useEffect(() => {
        loadUnits();
    }, []);

    const loadUnits = async () => {
        try {
            setLoading(true);
            const response = await inventoryAPI.getUnits();
            setUnits(response.data || []);
        } catch (error) {
            console.error('Error loading units:', error);
            setUnits([]);
        } finally {
            setLoading(false);
        }
    };

    const handleOpenDialog = (unit?: any) => {
        if (unit) {
            setEditingUnit(unit);
            setFormData({ name: unit.name || '', abbreviation: unit.abbreviation || '' });
        } else {
            setEditingUnit(null);
            setFormData({ name: '', abbreviation: '' });
        }
        setOpenDialog(true);
    };

    const handleCloseDialog = () => {
        setOpenDialog(false);
        setEditingUnit(null);
        setFormData({ name: '', abbreviation: '' });
    };

    const handleSubmit = async () => {
        try {
            if (editingUnit) {
                await inventoryAPI.updateUnit(editingUnit.id, formData);
            } else {
                const res = await inventoryAPI.createUnit(formData);
                const mainUnitId = res.data.id;

                // Auto-create sub-units for Weight (kg)
                if (formData.abbreviation?.toLowerCase() === 'kg' || formData.name?.toLowerCase() === 'kilogram') {
                    const subUnits = [
                        { name: 'Gram', abbreviation: 'g', base_unit_id: mainUnitId, conversion_factor: 0.001 },
                        { name: 'Milligram', abbreviation: 'mg', base_unit_id: mainUnitId, conversion_factor: 0.000001 }
                    ];
                    for (const sub of subUnits) {
                        const exists = units.find(u => u.abbreviation?.toLowerCase() === sub.abbreviation.toLowerCase());
                        if (!exists) {
                            await inventoryAPI.createUnit(sub);
                        }
                    }
                }

                // Auto-create sub-units for Volume (L)
                if (formData.abbreviation?.toLowerCase() === 'l' || formData.name?.toLowerCase() === 'liter' || formData.name?.toLowerCase() === 'litre') {
                    const subUnits = [
                        { name: 'Milliliter', abbreviation: 'mL', base_unit_id: mainUnitId, conversion_factor: 0.001 }
                    ];
                    for (const sub of subUnits) {
                        const exists = units.find(u => u.abbreviation?.toLowerCase() === sub.abbreviation.toLowerCase());
                        if (!exists) {
                            await inventoryAPI.createUnit(sub);
                        }
                    }
                }
            }
            handleCloseDialog();
            loadUnits();
            showSnackbar(`Unit ${editingUnit ? 'updated' : 'created'} successfully`);
        } catch (error: any) {
            console.error('Error saving unit:', error);
            showSnackbar(error.response?.data?.detail || 'Error saving unit', 'error');
        }
    };

    const handleDelete = async (id: number) => {
        if (!confirm('Are you sure you want to delete this unit?')) return;
        try {
            await inventoryAPI.deleteUnit(id);
            loadUnits();
            showSnackbar('Unit deleted successfully');
        } catch (error: any) {
            console.error('Error deleting unit:', error);
            showSnackbar(error.response?.data?.detail || 'Error deleting unit', 'error');
        }
    };

    const filteredUnits = units.filter(unit =>
        unit.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        unit.abbreviation?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <Box>
            <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b' }}>Units of Measurement</Typography>
                <Button
                    variant="contained"
                    startIcon={<Plus size={18} />}
                    onClick={() => handleOpenDialog()}
                    sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', borderRadius: '10px' }}
                >
                    Add Unit
                </Button>
            </Box>

            <Paper sx={{ p: 2, mb: 3, borderRadius: '12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <TextField
                    size="small"
                    placeholder="Search units..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    InputProps={{
                        startAdornment: (
                            <InputAdornment position="start">
                                <Search size={18} color="#64748b" />
                            </InputAdornment>
                        ),
                    }}
                    sx={{ width: 300 }}
                />
                <Button
                    variant="outlined"
                    onClick={() => setOpenRulesDialog(true)}
                    sx={{ borderRadius: '8px', fontWeight: 600, color: '#FFC107', borderColor: '#FFC107', '&:hover': { borderColor: '#FF7700', bgcolor: '#fff7ed' } }}
                >
                    Rules
                </Button>
            </Paper>

            <TableContainer component={Paper} sx={{ borderRadius: '16px' }}>
                <Table>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700 }}>Name</TableCell>
                            <TableCell sx={{ fontWeight: 700 }}>Abbreviation</TableCell>
                            <TableCell sx={{ fontWeight: 700 }} align="right">Actions</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={3} align="center">Loading...</TableCell>
                            </TableRow>
                        ) : filteredUnits.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={3} align="center">No units found. Add your first unit to get started.</TableCell>
                            </TableRow>
                        ) : (
                            filteredUnits.map((unit) => (
                                <TableRow key={unit.id} hover>
                                    <TableCell sx={{ fontWeight: 600 }}>{unit.name || 'N/A'}</TableCell>
                                    <TableCell>{unit.abbreviation || '-'}</TableCell>
                                    <TableCell align="right">
                                        <IconButton size="small" onClick={() => handleOpenDialog(unit)}>
                                            <Edit size={16} />
                                        </IconButton>
                                        <IconButton size="small" onClick={() => handleDelete(unit.id)}>
                                            <Trash2 size={16} />
                                        </IconButton>
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
                <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography fontWeight={800}>{editingUnit ? 'Edit Unit' : 'Add New Unit'}</Typography>
                    <IconButton onClick={handleCloseDialog} size="small">
                        <X size={20} />
                    </IconButton>
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
                        <TextField
                            label="Unit Name"
                            fullWidth
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            placeholder="e.g., Kilogram"
                            required
                        />
                        <TextField
                            label="Abbreviation"
                            fullWidth
                            value={formData.abbreviation}
                            onChange={(e) => setFormData({ ...formData, abbreviation: e.target.value })}
                            placeholder="e.g., kg"
                        />
                        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2, mt: 2 }}>
                            <Button onClick={handleCloseDialog}>Cancel</Button>
                            <Button variant="contained" onClick={handleSubmit} sx={{ bgcolor: '#FFC107' }}>
                                {editingUnit ? 'Update' : 'Create'}
                            </Button>
                        </Box>
                    </Box>
                </DialogContent>
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

            {/* Rules Dialog */}
            <Dialog open={openRulesDialog} onClose={() => setOpenRulesDialog(false)} maxWidth="xs" fullWidth>
                <DialogTitle sx={{ fontWeight: 800, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    Unit Conversion Rules
                    <IconButton onClick={() => setOpenRulesDialog(false)} size="small">
                        <X size={20} />
                    </IconButton>
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ py: 1 }}>
                        <Typography variant="subtitle1" fontWeight={800} color="#1e293b" gutterBottom>Weight</Typography>
                        <Typography variant="body2" sx={{ mb: 1 }}>1 kilogram (kg) = 1000 gram (g)</Typography>
                        <Typography variant="body2" sx={{ mb: 3 }}>1 gram (g) = 1000 milligram (mg)</Typography>

                        <Typography variant="subtitle1" fontWeight={800} color="#1e293b" gutterBottom>Volume / Capacity</Typography>
                        <Typography variant="body2">1 liter (L) = 1000 milliliter (mL)</Typography>

                        <Box sx={{ mt: 3, p: 2, bgcolor: '#f8fafc', borderRadius: '8px', borderLeft: '4px solid #FFC107' }}>
                            <Typography variant="caption" color="text.secondary" fontWeight={600}>
                                Note: Kilogram (kg) and Liter (L) are the base units.
                                Sub-units are automatically created when base units are added.
                            </Typography>
                        </Box>
                    </Box>
                </DialogContent>
            </Dialog>
        </Box>
    );
};

export default Units;

