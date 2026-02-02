import React, { useState, useEffect, useCallback } from 'react';
import {
    Box,
    Typography,
    Paper,
    Button,
    IconButton,
    TextField,
    Select,
    MenuItem,
    FormControl,
    InputLabel,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Chip,
    Switch,
    FormControlLabel,
    Alert,
    Snackbar,
    Tabs,
    Tab,
    Divider
} from '@mui/material';
import {
    Plus,
    Edit2,
    Trash2,
    Building2,
    LayoutGrid,
    ArrowUp,
    ArrowDown,
    Check,
    X
} from 'lucide-react';
import { floorsAPI, tablesAPI } from '../../services/api';

// Types
interface Floor {
    id: number;
    name: string;
    display_order: number;
    is_active: boolean;
}

interface TableData {
    id: number;
    table_id: string;
    floor: string;
    floor_id: number;
    table_type: string;
    capacity: number;
    status: string;
    is_active: boolean;
    display_order: number;
    is_hold_table: string;
    hold_table_name: string | null;
}

const FloorTableSettings: React.FC = () => {
    const [activeTab, setActiveTab] = useState(0);
    const [floors, setFloors] = useState<Floor[]>([]);
    const [tables, setTables] = useState<TableData[]>([]);
    const [loading, setLoading] = useState(true);

    // Floor Dialog
    const [floorDialogOpen, setFloorDialogOpen] = useState(false);
    const [editingFloor, setEditingFloor] = useState<Floor | null>(null);
    const [floorForm, setFloorForm] = useState({ name: '' });

    // Table Dialog
    const [tableDialogOpen, setTableDialogOpen] = useState(false);
    const [editingTable, setEditingTable] = useState<TableData | null>(null);
    const [tableForm, setTableForm] = useState({
        table_id: '',
        floor_id: 0,
        table_type: 'Regular',
        capacity: 4,
        status: 'Available',
        is_active: true,
        is_hold_table: 'No',
        hold_table_name: ''
    });

    // Notifications
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

    // Load data
    const loadFloors = useCallback(async () => {
        try {
            const response = await floorsAPI.getAll();
            setFloors(response.data || []);
        } catch (error) {
            setSnackbar({ open: true, message: 'Failed to load floors', severity: 'error' });
        }
    }, []);

    const loadTables = useCallback(async () => {
        try {
            const response = await tablesAPI.getAll({ include_inactive: true } as any);
            setTables(response.data || []);
        } catch (error) {
            setSnackbar({ open: true, message: 'Failed to load tables', severity: 'error' });
        }
    }, []);

    const loadData = useCallback(async () => {
        setLoading(true);
        await Promise.all([loadFloors(), loadTables()]);
        setLoading(false);
    }, [loadFloors, loadTables]);

    useEffect(() => {
        loadData();
    }, [loadData]);

    // Floor handlers
    const handleOpenFloorDialog = (floor?: Floor) => {
        if (floor) {
            setEditingFloor(floor);
            setFloorForm({ name: floor.name });
        } else {
            setEditingFloor(null);
            setFloorForm({ name: '' });
        }
        setFloorDialogOpen(true);
    };

    const handleSaveFloor = async () => {
        try {
            if (editingFloor) {
                await floorsAPI.update(editingFloor.id, floorForm);
                setSnackbar({ open: true, message: 'Floor updated successfully', severity: 'success' });
            } else {
                await floorsAPI.create(floorForm);
                setSnackbar({ open: true, message: 'Floor created successfully', severity: 'success' });
            }
            setFloorDialogOpen(false);
            loadFloors();
        } catch (error: any) {
            setSnackbar({ open: true, message: error.response?.data?.detail || 'Failed to save floor', severity: 'error' });
        }
    };

    const handleDeleteFloor = async (floorId: number) => {
        if (!window.confirm('Are you sure you want to delete this floor?')) return;
        try {
            await floorsAPI.delete(floorId);
            setSnackbar({ open: true, message: 'Floor deleted successfully', severity: 'success' });
            loadFloors();
        } catch (error: any) {
            setSnackbar({ open: true, message: error.response?.data?.detail || 'Failed to delete floor', severity: 'error' });
        }
    };

    const handleReorderFloor = async (floorId: number, direction: 'up' | 'down') => {
        const floor = floors.find(f => f.id === floorId);
        if (!floor) return;

        const newOrder = direction === 'up' ? floor.display_order - 1 : floor.display_order + 1;
        if (newOrder < 0) return;

        try {
            await floorsAPI.reorder(floorId, newOrder);
            loadFloors();
        } catch (error) {
            setSnackbar({ open: true, message: 'Failed to reorder floor', severity: 'error' });
        }
    };

    // Table handlers
    const handleOpenTableDialog = (table?: TableData) => {
        if (table) {
            setEditingTable(table);
            setTableForm({
                table_id: table.table_id,
                floor_id: table.floor_id,
                table_type: table.table_type,
                capacity: table.capacity,
                status: table.status,
                is_active: table.is_active,
                is_hold_table: table.is_hold_table || 'No',
                hold_table_name: table.hold_table_name || ''
            });
        } else {
            setEditingTable(null);
            setTableForm({
                table_id: '',
                floor_id: floors[0]?.id || 0,
                table_type: 'Regular',
                capacity: 4,
                status: 'Available',
                is_active: true,
                is_hold_table: 'No',
                hold_table_name: ''
            });
        }
        setTableDialogOpen(true);
    };

    const handleSaveTable = async () => {
        try {
            if (editingTable) {
                await tablesAPI.update(editingTable.id, tableForm);
                setSnackbar({ open: true, message: 'Table updated successfully', severity: 'success' });
            } else {
                await tablesAPI.create(tableForm);
                setSnackbar({ open: true, message: 'Table created successfully', severity: 'success' });
            }
            setTableDialogOpen(false);
            loadTables();
        } catch (error: any) {
            setSnackbar({ open: true, message: error.response?.data?.detail || 'Failed to save table', severity: 'error' });
        }
    };

    const handleDeleteTable = async (tableId: number) => {
        if (!window.confirm('Are you sure you want to delete this table?')) return;
        try {
            await tablesAPI.delete(tableId);
            setSnackbar({ open: true, message: 'Table deleted successfully', severity: 'success' });
            loadTables();
        } catch (error: any) {
            setSnackbar({ open: true, message: error.response?.data?.detail || 'Failed to delete table', severity: 'error' });
        }
    };

    const handleToggleTableActive = async (table: TableData) => {
        try {
            await tablesAPI.update(table.id, { is_active: !table.is_active });
            loadTables();
        } catch (error) {
            setSnackbar({ open: true, message: 'Failed to update table', severity: 'error' });
        }
    };

    const getTableTypeColor = (type: string) => {
        switch (type) {
            case 'VIP': return '#fbbf24';
            case 'Outdoor': return '#10b981';
            default: return '#3b82f6';
        }
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'Available': return '#10b981';
            case 'Occupied': return '#f59e0b';
            case 'Reserved': return '#8b5cf6';
            case 'BillRequested': return '#ef4444';
            default: return '#64748b';
        }
    };

    return (
        <Box sx={{ p: 3 }}>
            <Typography variant="h5" fontWeight={800} sx={{ mb: 3 }}>
                Floor & Table Management
            </Typography>

            <Paper sx={{ borderRadius: '16px', overflow: 'hidden' }}>
                <Tabs
                    value={activeTab}
                    onChange={(_, v) => setActiveTab(v)}
                    sx={{
                        borderBottom: '1px solid #e2e8f0',
                        px: 2,
                        '& .MuiTab-root': { textTransform: 'none', fontWeight: 600 }
                    }}
                >
                    <Tab icon={<Building2 size={18} />} iconPosition="start" label="Floors" />
                    <Tab icon={<LayoutGrid size={18} />} iconPosition="start" label="Tables" />
                </Tabs>

                <Box sx={{ p: 3 }}>
                    {/* Floors Tab */}
                    {activeTab === 0 && (
                        <>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                                <Typography variant="h6" fontWeight={700}>
                                    Floor List
                                </Typography>
                                <Button
                                    variant="contained"
                                    startIcon={<Plus size={18} />}
                                    onClick={() => handleOpenFloorDialog()}
                                    sx={{
                                        bgcolor: '#FF8C00',
                                        '&:hover': { bgcolor: '#e67e00' },
                                        borderRadius: '12px',
                                        textTransform: 'none'
                                    }}
                                >
                                    Add Floor
                                </Button>
                            </Box>

                            <TableContainer>
                                <Table>
                                    <TableHead>
                                        <TableRow>
                                            <TableCell sx={{ fontWeight: 700 }}>Order</TableCell>
                                            <TableCell sx={{ fontWeight: 700 }}>Floor Name</TableCell>
                                            <TableCell sx={{ fontWeight: 700 }}>Tables</TableCell>
                                            <TableCell sx={{ fontWeight: 700 }}>Status</TableCell>
                                            <TableCell sx={{ fontWeight: 700 }}>Actions</TableCell>
                                        </TableRow>
                                    </TableHead>
                                    <TableBody>
                                        {floors.map((floor, index) => (
                                            <TableRow key={floor.id} hover>
                                                <TableCell>
                                                    <Box sx={{ display: 'flex', gap: 0.5 }}>
                                                        <IconButton
                                                            size="small"
                                                            disabled={index === 0}
                                                            onClick={() => handleReorderFloor(floor.id, 'up')}
                                                        >
                                                            <ArrowUp size={16} />
                                                        </IconButton>
                                                        <IconButton
                                                            size="small"
                                                            disabled={index === floors.length - 1}
                                                            onClick={() => handleReorderFloor(floor.id, 'down')}
                                                        >
                                                            <ArrowDown size={16} />
                                                        </IconButton>
                                                    </Box>
                                                </TableCell>
                                                <TableCell sx={{ fontWeight: 600 }}>{floor.name}</TableCell>
                                                <TableCell>
                                                    {tables.filter(t => t.floor_id === floor.id).length} tables
                                                </TableCell>
                                                <TableCell>
                                                    <Chip
                                                        label={floor.is_active ? 'Active' : 'Inactive'}
                                                        size="small"
                                                        sx={{
                                                            bgcolor: floor.is_active ? '#dcfce7' : '#fee2e2',
                                                            color: floor.is_active ? '#16a34a' : '#dc2626'
                                                        }}
                                                    />
                                                </TableCell>
                                                <TableCell>
                                                    <IconButton
                                                        size="small"
                                                        onClick={() => handleOpenFloorDialog(floor)}
                                                    >
                                                        <Edit2 size={16} />
                                                    </IconButton>
                                                    <IconButton
                                                        size="small"
                                                        color="error"
                                                        onClick={() => handleDeleteFloor(floor.id)}
                                                    >
                                                        <Trash2 size={16} />
                                                    </IconButton>
                                                </TableCell>
                                            </TableRow>
                                        ))}
                                    </TableBody>
                                </Table>
                            </TableContainer>
                        </>
                    )}

                    {/* Tables Tab */}
                    {activeTab === 1 && (
                        <>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                                <Typography variant="h6" fontWeight={700}>
                                    Table List
                                </Typography>
                                <Button
                                    variant="contained"
                                    startIcon={<Plus size={18} />}
                                    onClick={() => handleOpenTableDialog()}
                                    sx={{
                                        bgcolor: '#FF8C00',
                                        '&:hover': { bgcolor: '#e67e00' },
                                        borderRadius: '12px',
                                        textTransform: 'none'
                                    }}
                                >
                                    Add Table
                                </Button>
                            </Box>

                            <TableContainer>
                                <Table>
                                    <TableHead>
                                        <TableRow>
                                            <TableCell sx={{ fontWeight: 700 }}>Table ID</TableCell>
                                            <TableCell sx={{ fontWeight: 700 }}>Floor</TableCell>
                                            <TableCell sx={{ fontWeight: 700 }}>Type</TableCell>
                                            <TableCell sx={{ fontWeight: 700 }}>Capacity</TableCell>
                                            <TableCell sx={{ fontWeight: 700 }}>Status</TableCell>
                                            <TableCell sx={{ fontWeight: 700 }}>Active</TableCell>
                                            <TableCell sx={{ fontWeight: 700 }}>Actions</TableCell>
                                        </TableRow>
                                    </TableHead>
                                    <TableBody>
                                        {tables.map((table) => (
                                            <TableRow key={table.id} hover sx={{ opacity: table.is_active ? 1 : 0.5 }}>
                                                <TableCell sx={{ fontWeight: 600 }}>{table.table_id}</TableCell>
                                                <TableCell>{table.floor}</TableCell>
                                                <TableCell>
                                                    <Chip
                                                        label={table.table_type}
                                                        size="small"
                                                        sx={{
                                                            bgcolor: `${getTableTypeColor(table.table_type)}20`,
                                                            color: getTableTypeColor(table.table_type),
                                                            fontWeight: 600
                                                        }}
                                                    />
                                                </TableCell>
                                                <TableCell>
                                                    <Chip
                                                        label={table.is_hold_table === 'Yes' ? 'Hold' : 'Regular'}
                                                        size="small"
                                                        sx={{
                                                            bgcolor: table.is_hold_table === 'Yes' ? '#fee2e2' : '#f1f5f9',
                                                            color: table.is_hold_table === 'Yes' ? '#ef4444' : '#64748b',
                                                            fontWeight: 600
                                                        }}
                                                    />
                                                </TableCell>
                                                <TableCell>{table.capacity}</TableCell>
                                                <TableCell>
                                                    <Chip
                                                        label={table.status}
                                                        size="small"
                                                        sx={{
                                                            bgcolor: `${getStatusColor(table.status)}20`,
                                                            color: getStatusColor(table.status),
                                                            fontWeight: 600
                                                        }}
                                                    />
                                                </TableCell>
                                                <TableCell>
                                                    <Switch
                                                        size="small"
                                                        checked={table.is_active}
                                                        onChange={() => handleToggleTableActive(table)}
                                                        color="success"
                                                    />
                                                </TableCell>
                                                <TableCell>
                                                    <IconButton
                                                        size="small"
                                                        onClick={() => handleOpenTableDialog(table)}
                                                    >
                                                        <Edit2 size={16} />
                                                    </IconButton>
                                                    <IconButton
                                                        size="small"
                                                        color="error"
                                                        onClick={() => handleDeleteTable(table.id)}
                                                    >
                                                        <Trash2 size={16} />
                                                    </IconButton>
                                                </TableCell>
                                            </TableRow>
                                        ))}
                                    </TableBody>
                                </Table>
                            </TableContainer>
                        </>
                    )}
                </Box>
            </Paper>

            {/* Floor Dialog */}
            <Dialog open={floorDialogOpen} onClose={() => setFloorDialogOpen(false)} maxWidth="sm" fullWidth>
                <DialogTitle sx={{ fontWeight: 700 }}>
                    {editingFloor ? 'Edit Floor' : 'Add Floor'}
                </DialogTitle>
                <DialogContent>
                    <TextField
                        autoFocus
                        fullWidth
                        label="Floor Name"
                        value={floorForm.name}
                        onChange={(e) => setFloorForm({ ...floorForm, name: e.target.value })}
                        sx={{ mt: 2 }}
                        placeholder="e.g., Ground Floor, Rooftop, VIP Hall"
                    />
                </DialogContent>
                <DialogActions sx={{ p: 3 }}>
                    <Button onClick={() => setFloorDialogOpen(false)}>Cancel</Button>
                    <Button
                        variant="contained"
                        onClick={handleSaveFloor}
                        disabled={!floorForm.name.trim()}
                        sx={{ bgcolor: '#FF8C00', '&:hover': { bgcolor: '#e67e00' } }}
                    >
                        {editingFloor ? 'Update' : 'Create'}
                    </Button>
                </DialogActions>
            </Dialog>

            {/* Table Dialog */}
            <Dialog open={tableDialogOpen} onClose={() => setTableDialogOpen(false)} maxWidth="sm" fullWidth>
                <DialogTitle sx={{ fontWeight: 700 }}>
                    {editingTable ? 'Edit Table' : 'Add Table'}
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 2 }}>
                        <TextField
                            fullWidth
                            label="Table ID / Name"
                            value={tableForm.table_id}
                            onChange={(e) => setTableForm({ ...tableForm, table_id: e.target.value })}
                            placeholder="e.g., T1, VIP2, Outdoor A"
                        />

                        <FormControl fullWidth>
                            <InputLabel>Floor</InputLabel>
                            <Select
                                value={tableForm.floor_id}
                                label="Floor"
                                onChange={(e) => setTableForm({ ...tableForm, floor_id: Number(e.target.value) })}
                            >
                                {floors.map((floor) => (
                                    <MenuItem key={floor.id} value={floor.id}>
                                        {floor.name}
                                    </MenuItem>
                                ))}
                            </Select>
                        </FormControl>

                        <FormControl fullWidth>
                            <InputLabel>Table Type</InputLabel>
                            <Select
                                value={tableForm.table_type}
                                label="Table Type"
                                onChange={(e) => setTableForm({ ...tableForm, table_type: e.target.value })}
                            >
                                <MenuItem value="Regular">Regular</MenuItem>
                                <MenuItem value="VIP">VIP</MenuItem>
                                <MenuItem value="Outdoor">Outdoor</MenuItem>
                            </Select>
                        </FormControl>

                        <TextField
                            fullWidth
                            type="number"
                            label="Capacity"
                            value={tableForm.capacity}
                            onChange={(e) => setTableForm({ ...tableForm, capacity: Number(e.target.value) })}
                            inputProps={{ min: 1, max: 20 }}
                        />

                        <FormControl fullWidth>
                            <InputLabel>Status</InputLabel>
                            <Select
                                value={tableForm.status}
                                label="Status"
                                onChange={(e) => setTableForm({ ...tableForm, status: e.target.value })}
                            >
                                <MenuItem value="Available">Available</MenuItem>
                                <MenuItem value="Occupied">Occupied</MenuItem>
                                <MenuItem value="Reserved">Reserved</MenuItem>
                                <MenuItem value="BillRequested">Bill Requested</MenuItem>
                            </Select>
                        </FormControl>

                        <FormControlLabel
                            control={
                                <Switch
                                    checked={tableForm.is_active}
                                    onChange={(e) => setTableForm({ ...tableForm, is_active: e.target.checked })}
                                    color="success"
                                />
                            }
                            label="Active"
                        />

                        <FormControlLabel
                            control={
                                <Switch
                                    checked={tableForm.is_hold_table === 'Yes'}
                                    onChange={(e) => setTableForm({ ...tableForm, is_hold_table: e.target.checked ? 'Yes' : 'No' })}
                                    color="error"
                                />
                            }
                            label="Set as Hold Table"
                        />

                        {tableForm.is_hold_table === 'Yes' && (
                            <TextField
                                fullWidth
                                label="Hold Table Name"
                                value={tableForm.hold_table_name}
                                onChange={(e) => setTableForm({ ...tableForm, hold_table_name: e.target.value })}
                                placeholder="e.g., Takeaway 1, Delivery A"
                            />
                        )}
                    </Box>
                </DialogContent>
                <DialogActions sx={{ p: 3 }}>
                    <Button onClick={() => setTableDialogOpen(false)}>Cancel</Button>
                    <Button
                        variant="contained"
                        onClick={handleSaveTable}
                        disabled={!tableForm.table_id.trim() || !tableForm.floor_id}
                        sx={{ bgcolor: '#FF8C00', '&:hover': { bgcolor: '#e67e00' } }}
                    >
                        {editingTable ? 'Update' : 'Create'}
                    </Button>
                </DialogActions>
            </Dialog>

            {/* Snackbar */}
            <Snackbar
                open={snackbar.open}
                autoHideDuration={4000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            >
                <Alert
                    onClose={() => setSnackbar({ ...snackbar, open: false })}
                    severity={snackbar.severity}
                    sx={{ width: '100%' }}
                >
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </Box>
    );
};

export default FloorTableSettings;
