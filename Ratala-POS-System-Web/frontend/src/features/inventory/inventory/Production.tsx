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
    MenuItem,
    Chip,
    Card,
    CardContent,
    LinearProgress,
    Alert,
    AlertTitle,
    Snackbar
} from '@mui/material';
import { Plus, X, Play, Info, CheckCircle2, AlertTriangle, History, ArrowRight, Package } from 'lucide-react';
import { inventoryAPI } from '../../../services/api';
import { useInventory } from '../../../app/providers/InventoryProvider';

const Production: React.FC = () => {
    const [productions, setProductions] = useState<any[]>([]);
    const [boms, setBoms] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [openDialog, setOpenDialog] = useState(false);
    const [formData, setFormData] = useState({
        bom_id: '',
        quantity: 1,
        notes: ''
    });
    const [selectedBOM, setSelectedBOM] = useState<any>(null);
    const [availability, setAvailability] = useState<any[]>([]);
    const [canProduce, setCanProduce] = useState(true);
    const { checkLowStock } = useInventory();
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

    const showSnackbar = (message: string, severity: 'success' | 'error' = 'success') => {
        setSnackbar({ open: true, message, severity });
    };

    useEffect(() => {
        loadData();
    }, []);

    useEffect(() => {
        if (formData.bom_id && formData.quantity > 0) {
            const bom = boms.find(b => b.id === formData.bom_id);
            if (bom) {
                setSelectedBOM(bom);
                checkAvailability(bom, formData.quantity);
            }
        } else {
            setSelectedBOM(null);
            setAvailability([]);
        }
    }, [formData.bom_id, formData.quantity, boms]);

    const loadData = async () => {
        try {
            setLoading(true);
            const [productionsRes, bomsRes] = await Promise.all([
                inventoryAPI.getProductions(),
                inventoryAPI.getBOMs()
            ]);
            setProductions(productionsRes.data || []);
            setBoms(bomsRes.data || []);
        } catch (error) {
            console.error('Error loading data:', error);
        } finally {
            setLoading(false);
        }
    };

    const checkAvailability = (bom: any, qty: number) => {
        let possible = true;
        const checks = bom.components.map((comp: any) => {
            // Conversion logic: (qty * from_factor) / to_factor
            // comp.unit is the unit used in BOM, comp.product.unit is the product's base unit
            const fromFactor = comp.unit?.conversion_factor || 1.0;
            const toFactor = comp.product?.unit?.conversion_factor || 1.0;

            const unitQuantity = comp.quantity * qty;
            const requiredInBaseUnit = (unitQuantity * fromFactor) / toFactor;

            const current = comp.product?.current_stock || 0;
            if (current < requiredInBaseUnit) possible = false;

            return {
                name: comp.product?.name,
                required: unitQuantity,
                requiredInBase: requiredInBaseUnit,
                available: current,
                unit: comp.unit?.abbreviation || comp.product?.unit?.abbreviation,
                baseUnit: comp.product?.unit?.abbreviation,
                shortage: Math.max(0, requiredInBaseUnit - current)
            };
        });
        setAvailability(checks);
        setCanProduce(possible);
    };

    const handleOpenDialog = () => {
        setFormData({ bom_id: '', quantity: 1, notes: '' });
        setOpenDialog(true);
    };

    const handleCloseDialog = () => {
        setOpenDialog(false);
        setFormData({ bom_id: '', quantity: 1, notes: '' });
        setSelectedBOM(null);
        setAvailability([]);
    };

    const handleSubmit = async () => {
        try {
            if (!canProduce) {
                showSnackbar('Cannot produce: Insufficient raw materials', 'error');
                return;
            }
            await inventoryAPI.createProduction(formData);
            checkLowStock();
            handleCloseDialog();
            loadData();
            showSnackbar('Production recorded successfully');
        } catch (error: any) {
            console.error('Error creating production:', error);
            showSnackbar(error.response?.data?.detail || 'Error creating production. Please check stock levels.', 'error');
        }
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'Completed': return '#10b981';
            case 'Failed': return '#ef4444';
            default: return '#64748b';
        }
    };

    return (
        <Box sx={{ p: 1 }}>
            <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                    <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b', mb: 0.5 }}>Batch Production</Typography>
                    <Typography variant="body2" color="text.secondary">Convert raw materials into finished goods via atomic transactions.</Typography>
                </Box>
                <Button
                    variant="contained"
                    startIcon={<Plus size={18} />}
                    onClick={handleOpenDialog}
                    sx={{
                        bgcolor: '#FFC107',
                        '&:hover': { bgcolor: '#FF7700' },
                        textTransform: 'none',
                        borderRadius: '12px',
                        px: 3,
                        py: 1,
                        boxShadow: '0 4px 14px 0 rgba(255, 140, 0, 0.39)'
                    }}
                >
                    New Production Run
                </Button>
            </Box>

            <TableContainer component={Paper} sx={{ borderRadius: '20px', boxShadow: '0 4px 20px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
                <Table>
                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>PRODUCTION #</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>RECIPE / BOM</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>PRODUCED</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>STATUS</TableCell>
                            <TableCell sx={{ fontWeight: 700, color: '#64748b' }}>DATE</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={6} align="center" sx={{ py: 8 }}>
                                    <LinearProgress sx={{ width: '200px', mx: 'auto', borderRadius: '5px' }} />
                                    <Typography sx={{ mt: 2 }} color="text.secondary">Loading history...</Typography>
                                </TableCell>
                            </TableRow>
                        ) : productions.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={6} align="center" sx={{ py: 10 }}>
                                    <History size={48} color="#94a3b8" style={{ marginBottom: '16px' }} />
                                    <Typography variant="h6" color="text.secondary">No production cycles found.</Typography>
                                    <Typography variant="body2" color="text.secondary">Start your first production batch to see it here.</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            productions.map((prod) => (
                                <TableRow key={prod.id} hover sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                                    <TableCell sx={{ fontWeight: 700, color: '#1e293b' }}>{prod.production_number}</TableCell>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <Box sx={{ p: 1, bgcolor: '#f1f5f9', borderRadius: '8px' }}>
                                                <ArrowRight size={14} color="#64748b" />
                                            </Box>
                                            <Box>
                                                <Typography variant="body2" sx={{ fontWeight: 700 }}>{prod.bom?.name}</Typography>
                                            </Box>
                                        </Box>
                                    </TableCell>
                                    <TableCell>
                                        <Box>
                                            <Typography variant="body2" sx={{ fontWeight: 700, color: '#1e293b' }}>
                                                {Number(prod.total_produced).toFixed(2)} units
                                            </Typography>
                                            <Typography variant="caption" color="#64748b" sx={{ display: 'block' }}>
                                                from {Number(prod.quantity).toFixed(2)} {prod.quantity === 1 ? 'batch' : 'batches'}
                                            </Typography>
                                        </Box>
                                    </TableCell>
                                    <TableCell>
                                        <Chip
                                            label={prod.status}
                                            icon={prod.status === 'Completed' ? <CheckCircle2 size={14} /> : undefined}
                                            size="small"
                                            sx={{
                                                bgcolor: `${getStatusColor(prod.status)}15`,
                                                color: getStatusColor(prod.status),
                                                fontWeight: 700,
                                                borderRadius: '6px',
                                                '& .MuiChip-icon': { color: 'inherit' }
                                            }}
                                        />
                                    </TableCell>
                                    <TableCell sx={{ color: '#64748b' }}>{new Date(prod.created_at).toLocaleString()}</TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="md" fullWidth sx={{ '& .MuiDialog-paper': { borderRadius: '24px' } }}>
                <DialogTitle sx={{ p: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                        <Box sx={{ p: 1, bgcolor: '#FFF7ED', borderRadius: '12px' }}>
                            <Play size={24} color="#FFC107" />
                        </Box>
                        <Typography variant="h5" sx={{ fontWeight: 800 }}>Start Production Cycle</Typography>
                    </Box>
                    <IconButton onClick={handleCloseDialog} size="small" sx={{ color: '#94a3b8' }}>
                        <X size={24} />
                    </IconButton>
                </DialogTitle>
                <DialogContent sx={{ p: 3 }}>
                    <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 4, mt: 1 }}>
                        {/* Form Section */}
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                            <TextField
                                select
                                label="Select Recipe / BOM"
                                fullWidth
                                variant="outlined"
                                value={formData.bom_id}
                                onChange={(e) => setFormData({ ...formData, bom_id: e.target.value })}
                                required
                            >
                                {boms.map((bom) => (
                                    <MenuItem key={bom.id} value={bom.id}>
                                        {bom.name} (Yield: {Number(bom.output_quantity).toFixed(2)} units/batch)
                                    </MenuItem>
                                ))}
                            </TextField>

                            <TextField
                                label="Number of Batches to Produce"
                                type="number"
                                fullWidth
                                value={formData.quantity}
                                onChange={(e) => setFormData({ ...formData, quantity: parseFloat(e.target.value) || 0 })}
                                required
                                inputProps={{ min: 0.1, step: 0.1 }}
                                helperText="How many times the recipe are you producing?"
                            />

                            <TextField
                                label="Production Notes"
                                multiline
                                rows={3}
                                fullWidth
                                value={formData.notes}
                                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                                placeholder="Enter any specific batch notes..."
                            />

                            {selectedBOM && (
                                <Box sx={{ p: 2, bgcolor: '#f8fafc', borderRadius: '16px', border: '1px solid #f1f5f9' }}>
                                    <Typography variant="caption" sx={{ fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>
                                        {selectedBOM.finished_product_id ? 'Target Output (Stock)' : 'Usage Only (JIT)'}
                                    </Typography>
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mt: 1 }}>
                                        <Package size={24} color={selectedBOM.finished_product_id ? "#FFC107" : "#64748b"} />
                                        <Box>
                                            <Typography variant="body1" sx={{ fontWeight: 700 }}>
                                                {selectedBOM.finished_product?.name || 'No Finished Stock'}
                                            </Typography>
                                            <Typography variant="body2" color="text.secondary">
                                                {selectedBOM.finished_product_id
                                                    ? `Will produce ${Number(selectedBOM.output_quantity * (formData.quantity || 0)).toFixed(2)} ${selectedBOM.finished_product?.unit?.abbreviation || 'units'}`
                                                    : 'Ingredients will be consumed without creating new stock.'}
                                            </Typography>
                                        </Box>
                                    </Box>
                                </Box>
                            )}
                        </Box>

                        {/* Preview / Availability Section */}
                        <Box>
                            <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 2, color: '#1e293b' }}>Consumption Preview</Typography>
                            {!selectedBOM ? (
                                <Box sx={{ p: 4, textAlign: 'center', bgcolor: '#f8fafc', borderRadius: '20px', border: '2px dashed #e2e8f0' }}>
                                    <Info size={32} color="#94a3b8" style={{ marginBottom: '8px' }} />
                                    <Typography variant="body2" color="text.secondary">Select a recipe to see stock availability and consumption preview.</Typography>
                                </Box>
                            ) : (
                                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                                    {availability.map((item, idx) => (
                                        <Card key={idx} variant="outlined" sx={{ borderRadius: '12px', border: item.shortage > 0 ? '1px solid #fee2e2' : '1px solid #f1f5f9' }}>
                                            <CardContent sx={{ p: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                                <Box sx={{ flex: 1 }}>
                                                    <Typography variant="body2" sx={{ fontWeight: 700 }}>{item.name}</Typography>
                                                    <Typography variant="caption" color="text.secondary">
                                                        Required: {Number(item.required).toFixed(2)} {item.unit} | Available: {Number(item.available).toFixed(2)} {item.baseUnit}
                                                    </Typography>
                                                </Box>
                                                {item.shortage > 0 ? (
                                                    <Chip label={`Short: ${Number(item.shortage).toFixed(2)}`} size="small" sx={{ bgcolor: '#fee2e2', color: '#ef4444', fontWeight: 700 }} />
                                                ) : (
                                                    <CheckCircle2 size={20} color="#22c55e" />
                                                )}
                                            </CardContent>
                                        </Card>
                                    ))}

                                    {!canProduce && (
                                        <Alert severity="error" icon={<AlertTriangle size={20} />} sx={{ borderRadius: '12px' }}>
                                            <AlertTitle sx={{ fontWeight: 700 }}>Insufficient Stock</AlertTitle>
                                            Cannot start production. Please adjust inventory levels for components marked in red.
                                        </Alert>
                                    )}

                                    {canProduce && (
                                        <Alert severity="success" icon={<CheckCircle2 size={20} />} sx={{ borderRadius: '12px' }}>
                                            <AlertTitle sx={{ fontWeight: 700 }}>Ready to Produce</AlertTitle>
                                            All raw materials are available. System will automatically deduct consumed quantities.
                                        </Alert>
                                    )}
                                </Box>
                            )}
                        </Box>
                    </Box>

                    <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2, mt: 5 }}>
                        <Button onClick={handleCloseDialog} sx={{ px: 3, borderRadius: '10px' }}>Cancel</Button>
                        <Button
                            variant="contained"
                            disabled={!canProduce || !formData.bom_id}
                            onClick={handleSubmit}
                            sx={{
                                bgcolor: '#FFC107',
                                '&:hover': { bgcolor: '#FF7700' },
                                px: 4,
                                py: 1.2,
                                borderRadius: '12px',
                                textTransform: 'none',
                                fontWeight: 700,
                                boxShadow: '0 4px 14px 0 rgba(255, 140, 0, 0.39)'
                            }}
                        >
                            Start Production
                        </Button>
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
        </Box>
    );
};

export default Production;

