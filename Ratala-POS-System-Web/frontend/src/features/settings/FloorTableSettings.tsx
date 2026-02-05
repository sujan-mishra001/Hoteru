import React, { useState, useEffect } from 'react';
import {
    Box,
    Typography,
    Paper,
    Button,
    Grid,
    TextField,
    IconButton,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    Select,
    MenuItem,
    FormControl,
    InputLabel,
    Card,
    CardContent,
    Chip,
    Divider
} from '@mui/material';
import { Plus, Edit2, Trash2, Armchair, Move } from 'lucide-react';
import { floorsAPI, tablesAPI } from '../../services/api';
import { useNotification } from '../../app/providers/NotificationProvider';

const FloorTableSettings: React.FC = () => {
    const { showAlert, showConfirm } = useNotification();
    const [floors, setFloors] = useState<any[]>([]);
    const [tables, setTables] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);

    // Dialog states
    const [openFloorDialog, setOpenFloorDialog] = useState(false);
    const [openTableDialog, setOpenTableDialog] = useState(false);
    const [currentFloor, setCurrentFloor] = useState<any>(null);
    const [currentTable, setCurrentTable] = useState<any>(null);

    // Form states
    const [floorForm, setFloorForm] = useState({ name: '', display_order: 0 });
    const [tableForm, setTableForm] = useState({ table_id: '', floor_id: '', capacity: 4, table_type: 'Square' });

    const loadData = async () => {
        try {
            const [fRes, tRes] = await Promise.all([floorsAPI.getAll(), tablesAPI.getAll()]);
            setFloors(fRes.data || []);
            setTables(tRes.data || []);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        loadData();
    }, []);

    const handleSaveFloor = async () => {
        try {
            if (currentFloor) {
                await floorsAPI.update(currentFloor.id, floorForm);
                showAlert('Floor updated', 'success');
            } else {
                await floorsAPI.create(floorForm);
                showAlert('Floor created', 'success');
            }
            setOpenFloorDialog(false);
            loadData();
        } catch (err: any) {
            showAlert(err.response?.data?.detail || 'Failed to save floor', 'error');
        }
    };

    const handleDeleteFloor = (id: number) => {
        showConfirm({
            title: 'Delete Floor?',
            message: 'This will delete all tables associated with this floor. Continue?',
            onConfirm: async () => {
                try {
                    await floorsAPI.delete(id);
                    showAlert('Floor deleted', 'success');
                    loadData();
                } catch (err: any) {
                    showAlert(err.response?.data?.detail || 'Failed to delete floor', 'error');
                }
            }
        });
    };

    const handleSaveTable = async () => {
        try {
            if (currentTable) {
                await tablesAPI.update(currentTable.id, tableForm);
                showAlert('Table updated', 'success');
            } else {
                await tablesAPI.create(tableForm);
                showAlert('Table created', 'success');
            }
            setOpenTableDialog(false);
            loadData();
        } catch (err: any) {
            showAlert(err.response?.data?.detail || 'Failed to save table', 'error');
        }
    };

    const handleDeleteTable = (id: number) => {
        showConfirm({
            title: 'Delete Table?',
            message: 'Are you sure you want to delete this table?',
            onConfirm: async () => {
                try {
                    await tablesAPI.delete(id);
                    showAlert('Table deleted', 'success');
                    loadData();
                } catch (err: any) {
                    showAlert(err.response?.data?.detail || 'Failed to delete table', 'error');
                }
            }
        });
    };

    return (
        <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
                <Typography variant="h5" fontWeight={800} color="#2C1810">Manage Floors & Tables</Typography>
                <Box sx={{ display: 'flex', gap: 2 }}>
                    <Button
                        variant="outlined"
                        startIcon={<Plus size={18} />}
                        onClick={() => { setCurrentFloor(null); setFloorForm({ name: '', display_order: floors.length }); setOpenFloorDialog(true); }}
                        sx={{ borderRadius: '8px', textTransform: 'none', fontWeight: 700, borderColor: '#FFC107', color: '#2C1810' }}
                    >
                        Add Floor
                    </Button>
                    <Button
                        variant="contained"
                        startIcon={<Plus size={18} />}
                        onClick={() => { setCurrentTable(null); setTableForm({ table_id: '', floor_id: floors[0]?.id || '', capacity: 4, table_type: 'Square' }); setOpenTableDialog(true); }}
                        sx={{ borderRadius: '8px', textTransform: 'none', fontWeight: 700, bgcolor: '#FFC107', '&:hover': { bgcolor: '#e67e00' } }}
                    >
                        Add Table
                    </Button>
                </Box>
            </Box>

            <Grid container spacing={4}>
                {floors.map(floor => (
                    <Grid size={12} key={floor.id}>
                        <Paper sx={{ p: 3, borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: 'none' }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <Move size={20} color="#94a3b8" />
                                    <Typography variant="h6" fontWeight={800}>{floor.name}</Typography>
                                    <Chip label={`Order: ${floor.display_order}`} size="small" sx={{ ml: 1, fontWeight: 700 }} />
                                </Box>
                                <Box>
                                    <IconButton size="small" onClick={() => { setCurrentFloor(floor); setFloorForm({ name: floor.name, display_order: floor.display_order }); setOpenFloorDialog(true); }}>
                                        <Edit2 size={16} />
                                    </IconButton>
                                    <IconButton size="small" color="error" onClick={() => handleDeleteFloor(floor.id)}>
                                        <Trash2 size={16} />
                                    </IconButton>
                                </Box>
                            </Box>
                            <Divider sx={{ mb: 2 }} />
                            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
                                {tables.filter(t => t.floor_id === floor.id).map(table => (
                                    <Card key={table.id} sx={{ minWidth: 140, borderRadius: '12px', border: '1px solid #f1f5f9', position: 'relative' }}>
                                        <CardContent sx={{ p: '16px !important', textAlign: 'center' }}>
                                            <Armchair size={24} color="#FFC107" style={{ marginBottom: 8 }} />
                                            <Typography variant="subtitle1" fontWeight={800}>{table.table_id}</Typography>
                                            <Typography variant="caption" color="text.secondary">Capacity: {table.capacity}</Typography>
                                            <Box sx={{ mt: 1, display: 'flex', justifyContent: 'center', gap: 1 }}>
                                                <IconButton size="small" onClick={() => { setCurrentTable(table); setTableForm({ table_id: table.table_id, floor_id: table.floor_id, capacity: table.capacity, table_type: table.table_type }); setOpenTableDialog(true); }}>
                                                    <Edit2 size={14} />
                                                </IconButton>
                                                <IconButton size="small" color="error" onClick={() => handleDeleteTable(table.id)}>
                                                    <Trash2 size={14} />
                                                </IconButton>
                                            </Box>
                                        </CardContent>
                                    </Card>
                                ))}
                                {tables.filter(t => t.floor_id === floor.id).length === 0 && (
                                    <Typography variant="body2" color="text.secondary" sx={{ py: 2, px: 1 }}>No tables on this floor.</Typography>
                                )}
                            </Box>
                        </Paper>
                    </Grid>
                ))}
            </Grid>

            {/* Floor Dialog */}
            <Dialog open={openFloorDialog} onClose={() => setOpenFloorDialog(false)}>
                <DialogTitle>{currentFloor ? 'Edit Floor' : 'Add Floor'}</DialogTitle>
                <DialogContent>
                    <Box sx={{ pt: 1, display: 'flex', flexDirection: 'column', gap: 2, minWidth: 300 }}>
                        <TextField
                            label="Floor Name"
                            fullWidth
                            value={floorForm.name}
                            onChange={(e) => setFloorForm({ ...floorForm, name: e.target.value })}
                        />
                        <TextField
                            label="Display Order"
                            type="number"
                            fullWidth
                            value={floorForm.display_order}
                            onChange={(e) => setFloorForm({ ...floorForm, display_order: parseInt(e.target.value) })}
                        />
                    </Box>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpenFloorDialog(false)}>Cancel</Button>
                    <Button onClick={handleSaveFloor} variant="contained" sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#e67e00' } }}>Save</Button>
                </DialogActions>
            </Dialog>

            {/* Table Dialog */}
            <Dialog open={openTableDialog} onClose={() => setOpenTableDialog(false)}>
                <DialogTitle>{currentTable ? 'Edit Table' : 'Add Table'}</DialogTitle>
                <DialogContent>
                    <Box sx={{ pt: 1, display: 'flex', flexDirection: 'column', gap: 2, minWidth: 300 }}>
                        <TextField
                            label="Table ID (e.g. T1)"
                            fullWidth
                            value={tableForm.table_id}
                            onChange={(e) => setTableForm({ ...tableForm, table_id: e.target.value })}
                        />
                        <FormControl fullWidth>
                            <InputLabel>Floor</InputLabel>
                            <Select
                                value={tableForm.floor_id}
                                label="Floor"
                                onChange={(e) => setTableForm({ ...tableForm, floor_id: e.target.value as any })}
                            >
                                {floors.map(f => <MenuItem key={f.id} value={f.id}>{f.name}</MenuItem>)}
                            </Select>
                        </FormControl>
                        <TextField
                            label="Capacity"
                            type="number"
                            fullWidth
                            value={tableForm.capacity}
                            onChange={(e) => setTableForm({ ...tableForm, capacity: parseInt(e.target.value) })}
                        />
                        <FormControl fullWidth>
                            <InputLabel>Type</InputLabel>
                            <Select
                                value={tableForm.table_type}
                                label="Type"
                                onChange={(e) => setTableForm({ ...tableForm, table_type: e.target.value as any })}
                            >
                                <MenuItem value="Square">Square</MenuItem>
                                <MenuItem value="Round">Round</MenuItem>
                                <MenuItem value="Rectangle">Rectangle</MenuItem>
                            </Select>
                        </FormControl>
                    </Box>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setOpenTableDialog(false)}>Cancel</Button>
                    <Button onClick={handleSaveTable} variant="contained" sx={{ bgcolor: '#FFC107', '&:hover': { bgcolor: '#e67e00' } }}>Save</Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default FloorTableSettings;
