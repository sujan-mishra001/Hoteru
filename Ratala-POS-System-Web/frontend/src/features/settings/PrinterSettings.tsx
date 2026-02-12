import React, { useState, useEffect } from 'react';
import {
    Box,
    Typography,
    Paper,
    Button,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    IconButton,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
    MenuItem,
    Chip,
    CircularProgress,
    FormControl,
    InputLabel,
    Select
} from '@mui/material';
import { Plus, Printer, Edit, Trash2, Wifi, Usb } from 'lucide-react';
import { settingsAPI } from '../../services/api';
import { useNotification } from '../../app/providers/NotificationProvider';

interface Printer {
    id: number;
    name: string;
    brand: string;
    connection_type: string;
    ip_address?: string;
    port?: number;
    usb_path?: string;
    paper_size: number;
    is_active: boolean;
}

const PrinterSettings: React.FC = () => {
    const { showAlert } = useNotification();
    const [printers, setPrinters] = useState<Printer[]>([]);
    const [loading, setLoading] = useState(false);
    const [openDialog, setOpenDialog] = useState(false);
    const [editingPrinter, setEditingPrinter] = useState<Printer | null>(null);
    const [formData, setFormData] = useState({
        name: '',
        brand: 'EPSON',
        connection_type: 'NETWORK',
        ip_address: '',
        port: 9100,
        usb_path: '',
        paper_size: 80,
        is_active: true
    });

    useEffect(() => {
        loadPrinters();
    }, []);

    const loadPrinters = async () => {
        try {
            setLoading(true);
            const response = await settingsAPI.get('/printers');
            setPrinters(response.data || []);
        } catch (error) {
            console.error('Error loading printers:', error);
            showAlert('Failed to load printers', 'error');
        } finally {
            setLoading(false);
        }
    };

    const handleOpenDialog = (printer?: Printer) => {
        if (printer) {
            setEditingPrinter(printer);
            setFormData({
                name: printer.name,
                brand: printer.brand,
                connection_type: printer.connection_type,
                ip_address: printer.ip_address || '',
                port: printer.port || 9100,
                usb_path: printer.usb_path || '',
                paper_size: printer.paper_size,
                is_active: printer.is_active
            });
        } else {
            setEditingPrinter(null);
            setFormData({
                name: '',
                brand: 'EPSON',
                connection_type: 'NETWORK',
                ip_address: '',
                port: 9100,
                usb_path: '',
                paper_size: 80,
                is_active: true
            });
        }
        setOpenDialog(true);
    };

    const handleCloseDialog = () => {
        setOpenDialog(false);
        setEditingPrinter(null);
    };

    const handleSave = async () => {
        try {
            setLoading(true);

            const payload = {
                ...formData,
                port: Number(formData.port),
                paper_size: Number(formData.paper_size)
            };

            if (editingPrinter) {
                await settingsAPI.put(`/printers/${editingPrinter.id}`, payload);
                showAlert('Printer updated successfully', 'success');
            } else {
                await settingsAPI.post('/printers', payload);
                showAlert('Printer added successfully', 'success');
            }
            handleCloseDialog();
            loadPrinters();
        } catch (error: any) {
            console.error('Error saving printer:', error);
            showAlert(error.response?.data?.detail || 'Failed to save printer', 'error');
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id: number) => {
        if (!confirm('Are you sure you want to delete this printer?')) return;

        try {
            setLoading(true);
            await settingsAPI.delete(`/printers/${id}`);
            showAlert('Printer deleted successfully', 'success');
            loadPrinters();
        } catch (error) {
            console.error('Error deleting printer:', error);
            showAlert('Failed to delete printer', 'error');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Typography variant="h6" fontWeight={800}>Printer Management</Typography>
                <Button
                    variant="contained"
                    startIcon={<Plus size={18} />}
                    onClick={() => handleOpenDialog()}
                    sx={{
                        bgcolor: '#FFC107',
                        '&:hover': { bgcolor: '#FF7700' },
                        color: '#000',
                        textTransform: 'none',
                        borderRadius: '8px',
                        fontWeight: 700
                    }}
                >
                    Add Printer
                </Button>
            </Box>

            <TableContainer component={Paper} sx={{ borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: 'none' }}>
                <Table>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 800, fontSize: '0.75rem', color: '#64748b' }}>PRINTER NAME</TableCell>
                            <TableCell sx={{ fontWeight: 800, fontSize: '0.75rem', color: '#64748b' }}>BRAND</TableCell>
                            <TableCell sx={{ fontWeight: 800, fontSize: '0.75rem', color: '#64748b' }}>CONNECTION</TableCell>
                            <TableCell sx={{ fontWeight: 800, fontSize: '0.75rem', color: '#64748b' }}>ADDRESS</TableCell>
                            <TableCell sx={{ fontWeight: 800, fontSize: '0.75rem', color: '#64748b' }}>STATUS</TableCell>
                            <TableCell sx={{ fontWeight: 800, fontSize: '0.75rem', color: '#64748b' }}>ACTIONS</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading && printers.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={6} align="center" sx={{ py: 4 }}>
                                    <CircularProgress size={24} sx={{ color: '#FFC107' }} />
                                </TableCell>
                            </TableRow>
                        ) : printers.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={6} align="center" sx={{ py: 8 }}>
                                    <Printer size={48} color="#cbd5e1" />
                                    <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
                                        No printers configured. Add a printer to get started.
                                    </Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            printers.map((printer) => (
                                <TableRow key={printer.id} hover>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <Printer size={18} color="#64748b" />
                                            <Typography variant="body2" fontWeight={700}>{printer.name}</Typography>
                                        </Box>
                                    </TableCell>
                                    <TableCell>
                                        <Typography variant="body2">{printer.brand}</Typography>
                                    </TableCell>
                                    <TableCell>
                                        <Chip
                                            icon={printer.connection_type.toUpperCase() === 'NETWORK' ? <Wifi size={14} /> : <Usb size={14} />}
                                            label={printer.connection_type}
                                            size="small"
                                            sx={{
                                                bgcolor: printer.connection_type.toUpperCase() === 'NETWORK' ? '#eff6ff' : '#fef3c7',
                                                color: printer.connection_type.toUpperCase() === 'NETWORK' ? '#3b82f6' : '#f59e0b',
                                                fontWeight: 700,
                                                fontSize: '0.7rem'
                                            }}
                                        />
                                    </TableCell>
                                    <TableCell>
                                        <Typography variant="caption" color="text.secondary">
                                            {printer.connection_type.toUpperCase() === 'NETWORK'
                                                ? `${printer.ip_address}:${printer.port}`
                                                : printer.usb_path || 'USB'}
                                        </Typography>
                                    </TableCell>
                                    <TableCell>
                                        <Chip
                                            label={printer.is_active ? 'Active' : 'Inactive'}
                                            size="small"
                                            color={printer.is_active ? 'success' : 'default'}
                                            sx={{ fontSize: '0.7rem', fontWeight: 700 }}
                                        />
                                    </TableCell>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', gap: 0.5 }}>
                                            <IconButton size="small" onClick={() => handleOpenDialog(printer)}>
                                                <Edit size={16} />
                                            </IconButton>
                                            <IconButton size="small" color="error" onClick={() => handleDelete(printer.id)}>
                                                <Trash2 size={16} />
                                            </IconButton>
                                        </Box>
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            {/* Add/Edit Dialog */}
            <Dialog
                open={openDialog}
                onClose={handleCloseDialog}
                maxWidth="sm"
                fullWidth
                PaperProps={{ sx: { borderRadius: '16px' } }}
            >
                <DialogTitle sx={{ fontWeight: 800, pb: 1 }}>
                    {editingPrinter ? 'Edit Printer' : 'Add New Printer'}
                </DialogTitle>
                <DialogContent sx={{ pt: 2 }}>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
                        <TextField
                            fullWidth
                            label="Printer Name"
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            placeholder="e.g., Main Kitchen Printer"
                        />

                        <FormControl fullWidth>
                            <InputLabel>Printer Brand</InputLabel>
                            <Select
                                value={formData.brand}
                                label="Printer Brand"
                                onChange={(e) => setFormData({ ...formData, brand: e.target.value })}
                            >
                                <MenuItem value="EPSON">Epson</MenuItem>
                                <MenuItem value="XPRINTER">XPrinter</MenuItem>
                                <MenuItem value="RONGTA">Rongta</MenuItem>
                                <MenuItem value="TVS">TVS</MenuItem>
                                <MenuItem value="GENERIC">Generic ESC/POS</MenuItem>
                            </Select>
                        </FormControl>

                        <FormControl fullWidth>
                            <InputLabel>Connection Type</InputLabel>
                            <Select
                                value={formData.connection_type}
                                label="Connection Type"
                                onChange={(e) => setFormData({ ...formData, connection_type: e.target.value })}
                            >
                                <MenuItem value="NETWORK">Network (IP Address)</MenuItem>
                                <MenuItem value="USB">USB</MenuItem>
                            </Select>
                        </FormControl>

                        {formData.connection_type.toUpperCase() === 'NETWORK' ? (
                            <Box sx={{ display: 'flex', gap: 2 }}>
                                <TextField
                                    fullWidth
                                    label="IP Address"
                                    value={formData.ip_address}
                                    onChange={(e) => setFormData({ ...formData, ip_address: e.target.value })}
                                    placeholder="192.168.1.100"
                                />
                                <TextField
                                    label="Port"
                                    type="number"
                                    value={formData.port}
                                    onChange={(e) => setFormData({ ...formData, port: parseInt(e.target.value) })}
                                    sx={{ width: 120 }}
                                />
                            </Box>
                        ) : (
                            <TextField
                                fullWidth
                                label="USB Path"
                                value={formData.usb_path}
                                onChange={(e) => setFormData({ ...formData, usb_path: e.target.value })}
                                placeholder="/dev/usb/lp0 or COM3"
                            />
                        )}

                        <FormControl fullWidth>
                            <InputLabel>Paper Size</InputLabel>
                            <Select
                                value={formData.paper_size}
                                label="Paper Size"
                                onChange={(e) => setFormData({ ...formData, paper_size: Number(e.target.value) })}
                            >
                                <MenuItem value={80}>80mm</MenuItem>
                                <MenuItem value={58}>58mm</MenuItem>
                            </Select>
                        </FormControl>

                        <FormControl fullWidth>
                            <InputLabel>Status</InputLabel>
                            <Select
                                value={formData.is_active ? 'active' : 'inactive'}
                                label="Status"
                                onChange={(e) => setFormData({ ...formData, is_active: e.target.value === 'active' })}
                            >
                                <MenuItem value="active">Active</MenuItem>
                                <MenuItem value="inactive">Inactive</MenuItem>
                            </Select>
                        </FormControl>
                    </Box>
                </DialogContent>
                <DialogActions sx={{ p: 3, pt: 2 }}>
                    <Button onClick={handleCloseDialog} sx={{ color: '#64748b' }}>
                        Cancel
                    </Button>
                    <Button
                        variant="contained"
                        onClick={handleSave}
                        disabled={loading || !formData.name}
                        sx={{
                            bgcolor: '#FFC107',
                            '&:hover': { bgcolor: '#FF7700' },
                            color: '#000',
                            fontWeight: 700
                        }}
                    >
                        {loading ? <CircularProgress size={24} /> : (editingPrinter ? 'Update' : 'Add Printer')}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default PrinterSettings;
