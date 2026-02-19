import React, { useState, useEffect, useMemo } from 'react';
import {
    Box,
    Typography,
    Button,
    TextField,
    Dialog,
    DialogTitle,
    DialogContent,
    IconButton,
    MenuItem,
    Divider,
    Alert,
    Snackbar,
    Chip,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Paper,
    InputAdornment,
    Switch,
    Tooltip,
} from '@mui/material';
import {
    Plus, X, Edit, Trash2, Save, Package, Utensils, Zap, Clock, Search,
    ArrowRight, ChevronRight, Layers, Info, RotateCcw, TrendingDown
} from 'lucide-react';
import { inventoryAPI, menuAPI } from '../../../services/api';
import BeautifulConfirm from '../../../components/common/BeautifulConfirm';

const BOM: React.FC = () => {
    const [boms, setBoms] = useState<any[]>([]);
    const [products, setProducts] = useState<any[]>([]);
    const [units, setUnits] = useState<any[]>([]);
    const [menuItems, setMenuItems] = useState<any[]>([]);
    const [openDialog, setOpenDialog] = useState(false);
    const [editingBOM, setEditingBOM] = useState<any>(null);
    const [dialogType, setDialogType] = useState<'production' | 'menu'>('production');
    const [menuSelectOpen, setMenuSelectOpen] = useState(false);

    // Filter states
    const [prodSearch, setProdSearch] = useState('');
    const [menuSearch, setMenuSearch] = useState('');

    const [formData, setFormData] = useState<any>({
        name: '',
        bom_type: 'production',
        production_mode: 'manual',
        menu_item_ids: [],
        output_quantity: 1, // Added back for single-output/batch yield
        components: [] // We'll manage inputs and outputs here with item_type
    });
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });
    const [confirmDelete, setConfirmDelete] = useState<{ open: boolean, id: number | null }>({ open: false, id: null });

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            const [bomsRes, productsRes, unitsRes, menuRes] = await Promise.all([
                inventoryAPI.getBOMs(),
                inventoryAPI.getProducts(),
                inventoryAPI.getUnits(),
                menuAPI.getItems()
            ]);
            setBoms(bomsRes.data || []);
            setProducts(productsRes.data || []);
            setUnits(unitsRes.data || []);
            setMenuItems(menuRes.data || []);
        } catch (error) {
            console.error('Error loading data:', error);
        }
    };

    const handleOpenDialog = (type: 'production' | 'menu', bom?: any) => {
        setDialogType(type);
        if (bom) {
            setEditingBOM(bom);
            setFormData({
                name: bom.name || '',
                bom_type: bom.bom_type || type,
                production_mode: bom.production_mode || 'manual',
                is_active: bom.is_active !== undefined ? bom.is_active : true,
                output_quantity: bom.output_quantity || 1,
                menu_item_ids: bom.menu_items ? bom.menu_items.map((m: any) => m.id) : [],
                components: bom.components.map((c: any) => ({
                    product_id: c.product_id,
                    unit_id: c.unit_id || '',
                    quantity: c.quantity,
                    item_type: c.item_type || 'input'
                }))
            });
        } else {
            setEditingBOM(null);
            setFormData({
                name: '',
                bom_type: type,
                production_mode: 'manual',
                is_active: true,
                output_quantity: 1,
                menu_item_ids: [],
                components: []
            });
        }
        setOpenDialog(true);
    };

    const handleAddComponent = (itemType: 'input' | 'output') => {
        setFormData({
            ...formData,
            components: [...formData.components, { product_id: '', unit_id: '', quantity: 1, item_type: itemType }]
        });
    };

    const handleRemoveComponent = (index: number) => {
        const newComponents = [...formData.components];
        newComponents.splice(index, 1);
        setFormData({ ...formData, components: newComponents });
    };

    const handleComponentChange = (index: number, field: string, value: any) => {
        const newComponents = [...formData.components];
        newComponents[index][field] = value;
        setFormData({ ...formData, components: newComponents });
    };

    const handleSubmit = async () => {
        try {
            if (!formData.name && dialogType === 'production') {
                showSnackbar('Recipe name is required', 'error');
                return;
            }

            const payload = {
                ...formData,
                components: formData.components.filter((c: any) => c.product_id !== '')
            };

            if (editingBOM) {
                await inventoryAPI.updateBOM(editingBOM.id, payload);
            } else {
                await inventoryAPI.createBOM(payload);
            }
            setOpenDialog(false);
            loadData();
            showSnackbar(`Recipe ${editingBOM ? 'updated' : 'created'} successfully`);
        } catch (error: any) {
            showSnackbar(error.response?.data?.detail || 'Error saving recipe', 'error');
        }
    };

    const handleDeleteBOM = async (id: number) => {
        setConfirmDelete({ open: true, id });
    };

    const confirmDeleteBOMAction = async () => {
        if (!confirmDelete.id) return;
        try {
            await inventoryAPI.deleteBOM(confirmDelete.id);
            setConfirmDelete({ open: false, id: null });
            loadData();
            showSnackbar('Recipe deleted');
        } catch (error: any) {
            const errorMsg = error.response?.data?.detail || 'Failed to delete';
            showSnackbar(errorMsg, 'error');
        }
    };

    const showSnackbar = (message: string, severity: 'success' | 'error' = 'success') => {
        setSnackbar({ open: true, message, severity });
    };

    const productionBoms = useMemo(() =>
        boms.filter(b => b.bom_type === 'production' &&
            b.name.toLowerCase().includes(prodSearch.toLowerCase())),
        [boms, prodSearch]);

    const menuBoms = useMemo(() =>
        boms.filter(b => b.bom_type === 'menu' &&
            (b.name.toLowerCase().includes(menuSearch.toLowerCase()) ||
                b.menu_items?.some((m: any) => m.name.toLowerCase().includes(menuSearch.toLowerCase())))),
        [boms, menuSearch]);

    const renderStockImpactPreview = () => {
        const inputs = formData.components.filter((c: any) => c.item_type === 'input' && c.product_id);
        const outputs = formData.components.filter((c: any) => c.item_type === 'output' && c.product_id);

        if (inputs.length === 0 && outputs.length === 0) return null;

        return (
            <Paper sx={{ p: 2, bgcolor: '#f0f9ff', border: '1px solid #bae6fd', borderRadius: '12px', mt: 2 }}>
                <Typography variant="subtitle2" sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1, color: '#0369a1' }}>
                    <Info size={16} /> Simulation: Stock Impact per {dialogType === 'production' ? 'Production Run' : 'Sale'}
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                    {inputs.map((c: any, i: number) => {
                        const product = products.find(p => p.id === c.product_id);
                        return (
                            <Box key={i} sx={{ display: 'flex', justifyContent: 'space-between' }}>
                                <Typography variant="caption">{product?.name}</Typography>
                                <Typography variant="caption" sx={{ color: '#ef4444', fontWeight: 700 }}>
                                    -{c.quantity} {units.find(u => u.id === c.unit_id)?.abbreviation || product?.unit?.abbreviation}
                                </Typography>
                            </Box>
                        );
                    })}
                    {outputs.length > 0 && <Divider sx={{ my: 0.5, borderStyle: 'dashed' }} />}
                    {outputs.map((c: any, i: number) => {
                        const product = products.find(p => p.id === c.product_id);
                        return (
                            <Box key={i} sx={{ display: 'flex', justifyContent: 'space-between' }}>
                                <Typography variant="caption">{product?.name}</Typography>
                                <Typography variant="caption" sx={{ color: '#22c55e', fontWeight: 700 }}>
                                    +{c.quantity} {units.find(u => u.id === c.unit_id)?.abbreviation || product?.unit?.abbreviation}
                                </Typography>
                            </Box>
                        );
                    })}
                </Box>
            </Paper>
        );
    };

    return (
        <Box sx={{ height: 'calc(100vh - 120px)', display: 'flex', gap: 2, p: 1 }}>
            {/* LEFT SECTION: PRODUCTION RECIPE */}
            <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', bgcolor: '#fff', borderRadius: '24px', border: '1px solid #f1f5f9', overflow: 'hidden', boxShadow: '0 4px 20px rgba(0,0,0,0.03)' }}>
                <Box sx={{ p: 3, borderBottom: '1px solid #f1f5f9', bgcolor: '#f8fafc' }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                            <Box sx={{ p: 1, bgcolor: '#e0f2fe', color: '#0ea5e9', borderRadius: '12px' }}><Layers size={20} /></Box>
                            <Typography variant="h5" sx={{ fontWeight: 800, color: '#1e293b' }}>Production Recipe</Typography>
                        </Box>
                        <Button
                            variant="contained"
                            startIcon={<Plus size={18} />}
                            onClick={() => handleOpenDialog('production')}
                            sx={{ bgcolor: '#0ea5e9', '&:hover': { bgcolor: '#0284c7' }, borderRadius: '12px', textTransform: 'none', px: 3 }}
                        >
                            Create Recipe
                        </Button>
                    </Box>
                    <TextField
                        fullWidth
                        size="small"
                        placeholder="Search production recipes..."
                        value={prodSearch}
                        onChange={(e) => setProdSearch(e.target.value)}
                        InputProps={{ startAdornment: <InputAdornment position="start"><Search size={18} color="#94a3b8" /></InputAdornment> }}
                    />
                </Box>
                <TableContainer sx={{ flex: 1, overflowY: 'auto', p: 2 }}>
                    <Table stickyHeader>
                        <TableHead>
                            <TableRow>
                                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem', color: '#64748b' }}>RECIPE / INPUTS</TableCell>
                                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem', color: '#64748b' }}>OUTPUT ITEMS</TableCell>
                                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem', color: '#64748b' }} align="center">AUTO</TableCell>
                                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem', color: '#64748b' }} align="right">ACTIONS</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {productionBoms.map((bom) => (
                                <TableRow key={bom.id} hover sx={{ '& td': { py: 2 }, opacity: bom.is_active ? 1 : 0.6, bgcolor: bom.is_active ? 'transparent' : '#f8fafc' }}>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                                            <Typography variant="body2" sx={{ fontWeight: 700 }}>{bom.name}</Typography>
                                            {!bom.is_active && <Chip label="Inactive" size="small" variant="outlined" color="error" sx={{ height: 18, fontSize: '0.6rem', fontWeight: 700 }} />}
                                        </Box>
                                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                                            {bom.components.filter((c: any) => c.item_type === 'input').map((c: any) => (
                                                <Chip key={c.id} label={`${c.quantity} ${c.unit?.abbreviation || ''} ${c.product.name}`} size="small" variant="outlined" sx={{ fontSize: '0.65rem', height: 20 }} />
                                            ))}
                                        </Box>
                                    </TableCell>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                                            {bom.components.filter((c: any) => c.item_type === 'output').map((c: any) => (
                                                <Typography key={c.id} variant="caption" sx={{ color: '#16a34a', fontWeight: 700, display: 'flex', alignItems: 'center', gap: 0.5 }}>
                                                    <ChevronRight size={12} /> {c.quantity} {c.unit?.abbreviation || ''} {c.product.name}
                                                </Typography>
                                            ))}
                                            {/* Legacy Single Output */}
                                            {bom.finished_product && (
                                                <Typography variant="caption" sx={{ color: '#16a34a', fontWeight: 700, display: 'flex', alignItems: 'center', gap: 0.5 }}>
                                                    <ChevronRight size={12} /> {bom.output_quantity} {bom.finished_product.unit?.abbreviation} {bom.finished_product.name}
                                                </Typography>
                                            )}
                                        </Box>
                                    </TableCell>
                                    <TableCell align="center">
                                        {bom.production_mode === 'automatic' ? (
                                            <Tooltip title="Auto-triggers on ingredient update"><Zap size={18} color="#f59e0b" /></Tooltip>
                                        ) : (
                                            <Tooltip title="Manual production trigger only"><Clock size={16} color="#94a3b8" /></Tooltip>
                                        )}
                                    </TableCell>
                                    <TableCell align="right">
                                        <IconButton size="small" onClick={() => handleOpenDialog('production', bom)}><Edit size={16} /></IconButton>
                                        <IconButton size="small" onClick={() => handleDeleteBOM(bom.id)} color="error"><Trash2 size={16} /></IconButton>
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                </TableContainer>
            </Box>

            {/* RIGHT SECTION: MENU RECIPE */}
            <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', bgcolor: '#fff', borderRadius: '24px', border: '1px solid #f1f5f9', overflow: 'hidden', boxShadow: '0 4px 20px rgba(0,0,0,0.03)' }}>
                <Box sx={{ p: 3, borderBottom: '1px solid #f1f5f9', bgcolor: '#fdf4ff' }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                            <Box sx={{ p: 1, bgcolor: '#fae8ff', color: '#d946ef', borderRadius: '12px' }}><Utensils size={20} /></Box>
                            <Typography variant="h5" sx={{ fontWeight: 800, color: '#1e293b' }}>Menu Recipe</Typography>
                        </Box>
                        <Button
                            variant="contained"
                            startIcon={<Plus size={18} />}
                            onClick={() => handleOpenDialog('menu')}
                            sx={{ bgcolor: '#d946ef', '&:hover': { bgcolor: '#c026d3' }, borderRadius: '12px', textTransform: 'none', px: 3 }}
                        >
                            Create Mapping
                        </Button>
                    </Box>
                    <TextField
                        fullWidth
                        size="small"
                        placeholder="Search menu mappings..."
                        value={menuSearch}
                        onChange={(e) => setMenuSearch(e.target.value)}
                        InputProps={{ startAdornment: <InputAdornment position="start"><Search size={18} color="#94a3b8" /></InputAdornment> }}
                    />
                </Box>
                <TableContainer sx={{ flex: 1, overflowY: 'auto', p: 2 }}>
                    <Table stickyHeader>
                        <TableHead>
                            <TableRow>
                                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem', color: '#64748b' }}>MENU ITEM</TableCell>
                                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem', color: '#64748b' }}>LINKED INVENTORY ITEMS</TableCell>
                                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem', color: '#64748b' }} align="center">INDICATOR</TableCell>
                                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem', color: '#64748b' }} align="right">ACTIONS</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {menuBoms.map((bom) => (
                                <TableRow key={bom.id} hover sx={{ '& td': { py: 2 }, opacity: bom.is_active ? 1 : 0.6, bgcolor: bom.is_active ? 'transparent' : '#f8fafc' }}>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                                            <Typography variant="body2" sx={{ fontWeight: 700 }}>{bom.menu_items?.map((m: any) => m.name).join(', ') || bom.name}</Typography>
                                            {!bom.is_active && <Chip label="Inactive" size="small" variant="outlined" color="error" sx={{ height: 18, fontSize: '0.6rem', fontWeight: 700 }} />}
                                        </Box>
                                    </TableCell>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                                            {bom.components.map((c: any) => (
                                                <Chip
                                                    key={c.id}
                                                    label={`${c.quantity} ${c.unit?.abbreviation || ''} ${c.product.name}`}
                                                    size="small"
                                                    variant="outlined"
                                                    sx={{ fontSize: '0.65rem' }}
                                                />
                                            ))}
                                        </Box>
                                    </TableCell>
                                    <TableCell align="center">
                                        {bom.production_mode === 'automatic' ? (
                                            <Tooltip title="Recursive auto-production enabled"><RotateCcw size={18} color="#d946ef" /></Tooltip>
                                        ) : (
                                            <Tooltip title="Deducts only available stock"><TrendingDown size={18} color="#94a3b8" /></Tooltip>
                                        )}
                                    </TableCell>
                                    <TableCell align="right">
                                        <IconButton size="small" onClick={() => handleOpenDialog('menu', bom)}><Edit size={16} /></IconButton>
                                        <IconButton size="small" onClick={() => handleDeleteBOM(bom.id)} color="error"><Trash2 size={16} /></IconButton>
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                </TableContainer>
            </Box>

            {/* CREATION DIALOG */}
            <Dialog
                open={openDialog}
                onClose={() => setOpenDialog(false)}
                maxWidth="md"
                fullWidth
                sx={{ '& .MuiDialog-paper': { borderRadius: '24px', boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)' } }}
            >
                <DialogTitle sx={{ p: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #f1f5f9' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Box sx={{ p: 1, bgcolor: dialogType === 'production' ? '#e0f2fe' : '#fae8ff', color: dialogType === 'production' ? '#0ea5e9' : '#d946ef', borderRadius: '12px' }}>
                            {dialogType === 'production' ? <Layers size={24} /> : <Utensils size={24} />}
                        </Box>
                        <Box>
                            <Typography variant="h5" sx={{ fontWeight: 800, color: '#1e293b' }}>
                                {editingBOM ? 'Update' : 'Create'} {dialogType === 'production' ? 'Production Recipe' : 'Menu Mapping'}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">ERP-Grade Recipe Management System</Typography>
                        </Box>
                    </Box>
                    <IconButton onClick={() => setOpenDialog(false)} size="small" sx={{ bgcolor: '#f1f5f9' }}><X size={20} /></IconButton>
                </DialogTitle>
                <DialogContent sx={{ p: 4 }}>
                    <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: '3fr 2fr' }, gap: 4 }}>
                        {/* FORM PART */}
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, pt: 2 }}>
                            <Box sx={{ display: 'grid', gridTemplateColumns: dialogType === 'production' ? '1fr' : '2fr 1fr', gap: 2 }}>
                                <TextField
                                    label="Recipe / Mapping Name"
                                    fullWidth
                                    variant="outlined"
                                    value={formData.name}
                                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                    placeholder={dialogType === 'production' ? "e.g., Kima Processing" : "e.g., Momo Mapping"}
                                />
                                {dialogType !== 'production' && (
                                    <TextField
                                        label="Batch Yield"
                                        type="number"
                                        fullWidth
                                        variant="outlined"
                                        value={formData.output_quantity}
                                        helperText="Units produced per run"
                                        onChange={(e) => setFormData({ ...formData, output_quantity: parseFloat(e.target.value) || 1 })}
                                    />
                                )}
                            </Box>

                            {dialogType === 'menu' && (
                                <TextField
                                    select
                                    label="Linked Menu Item(s)"
                                    fullWidth
                                    SelectProps={{
                                        multiple: true,
                                        open: menuSelectOpen,
                                        onOpen: () => setMenuSelectOpen(true),
                                        onClose: () => setMenuSelectOpen(false),
                                        renderValue: (selected: any) => menuItems.filter(i => selected.includes(i.id)).map(i => i.name).join(', ')
                                    }}
                                    value={formData.menu_item_ids}
                                    onChange={(e) => {
                                        setFormData({ ...formData, menu_item_ids: e.target.value as any });
                                        setMenuSelectOpen(false);
                                    }}
                                >
                                    {menuItems.map((item) => <MenuItem key={item.id} value={item.id}>{item.name}</MenuItem>)}
                                </TextField>
                            )}

                            <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2 }}>
                                <Box sx={{ p: 2, bgcolor: '#f8fafc', borderRadius: '16px', border: '1px solid #f1f5f9' }}>
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                        <Box>
                                            <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>Enable Auto-Production</Typography>
                                            <Typography variant="caption" color="text.secondary">
                                                {dialogType === 'production' ? 'Auto-triggers if stock is low' : 'Recursive check on sale'}
                                            </Typography>
                                        </Box>
                                        <Switch
                                            checked={formData.production_mode === 'automatic'}
                                            onChange={(e) => setFormData({ ...formData, production_mode: e.target.checked ? 'automatic' : 'manual' })}
                                        />
                                    </Box>
                                </Box>

                                <Box sx={{ p: 2, bgcolor: formData.is_active ? '#f0fdf4' : '#fef2f2', borderRadius: '16px', border: '1px solid', borderColor: formData.is_active ? '#bbf7d0' : '#fecaca' }}>
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                        <Box>
                                            <Typography variant="subtitle2" sx={{ fontWeight: 700, color: formData.is_active ? '#166534' : '#991b1b' }}>Active Status</Typography>
                                            <Typography variant="caption" color="text.secondary">
                                                {formData.is_active ? 'Recipe is active' : 'Recipe is deactivated'}
                                            </Typography>
                                        </Box>
                                        <Switch
                                            color="success"
                                            checked={formData.is_active}
                                            onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
                                        />
                                    </Box>
                                </Box>
                            </Box>

                            {/* INPUTS SECTION */}
                            <Box>
                                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
                                    <Typography variant="subtitle2" sx={{ fontWeight: 700, color: '#64748b' }}>INPUT MATERIALS</Typography>
                                    <Button size="small" startIcon={<Plus size={14} />} onClick={() => handleAddComponent('input')} sx={{ textTransform: 'none' }}>Add Input</Button>
                                </Box>
                                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                                    {formData.components.filter((c: any) => c.item_type === 'input').map((comp: any, idx: number) => {
                                        const globalIdx = formData.components.indexOf(comp);
                                        return (
                                            <Box key={idx} sx={{ display: 'grid', gridTemplateColumns: 'minmax(150px, 1fr) 100px 100px 40px', gap: 1 }}>
                                                <TextField select size="small" label="Item" value={comp.product_id} onChange={(e) => handleComponentChange(globalIdx, 'product_id', e.target.value)}>
                                                    {products
                                                        .filter(p => dialogType === 'production' ? p.product_type === 'Raw' : true)
                                                        .map(p => <MenuItem key={p.id} value={p.id}>{p.name}</MenuItem>)}
                                                </TextField>
                                                <TextField size="small" label="Qty" type="number" value={comp.quantity} onChange={(e) => handleComponentChange(globalIdx, 'quantity', parseFloat(e.target.value) || 0)} />
                                                <TextField select size="small" label="Unit" value={comp.unit_id} onChange={(e) => handleComponentChange(globalIdx, 'unit_id', e.target.value)}>
                                                    <MenuItem value=""><em>Base</em></MenuItem>
                                                    {units.map(u => <MenuItem key={u.id} value={u.id}>{u.abbreviation}</MenuItem>)}
                                                </TextField>
                                                <IconButton size="small" color="error" onClick={() => handleRemoveComponent(globalIdx)}><X size={14} /></IconButton>
                                            </Box>
                                        );
                                    })}
                                </Box>
                            </Box>

                            {/* OUTPUTS SECTION (Only for Production) */}
                            {dialogType === 'production' && (
                                <Box sx={{ mt: 1 }}>
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
                                        <Typography variant="subtitle2" sx={{ fontWeight: 700, color: '#16a34a' }}>OUTPUT PRODUCTS (Yield)</Typography>
                                        <Button size="small" startIcon={<Plus size={14} />} onClick={() => handleAddComponent('output')} color="success" sx={{ textTransform: 'none' }}>Add Output</Button>
                                    </Box>
                                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                                        {formData.components.filter((c: any) => c.item_type === 'output').map((comp: any, idx: number) => {
                                            const globalIdx = formData.components.indexOf(comp);
                                            return (
                                                <Box key={idx} sx={{ display: 'grid', gridTemplateColumns: 'minmax(150px, 1fr) 100px 100px 40px', gap: 1 }}>
                                                    <TextField select size="small" color="success" label="Yield Item" value={comp.product_id} onChange={(e) => handleComponentChange(globalIdx, 'product_id', e.target.value)}>
                                                        {products
                                                            .filter(p => p.product_type === 'Semi-Finished')
                                                            .map(p => <MenuItem key={p.id} value={p.id}>{p.name}</MenuItem>)}
                                                    </TextField>
                                                    <TextField size="small" color="success" label="Qty" type="number" value={comp.quantity} onChange={(e) => handleComponentChange(globalIdx, 'quantity', parseFloat(e.target.value) || 0)} />
                                                    <TextField select size="small" color="success" label="Unit" value={comp.unit_id} onChange={(e) => handleComponentChange(globalIdx, 'unit_id', e.target.value)}>
                                                        <MenuItem value=""><em>Base</em></MenuItem>
                                                        {units.map(u => <MenuItem key={u.id} value={u.id}>{u.abbreviation}</MenuItem>)}
                                                    </TextField>
                                                    <IconButton size="small" color="error" onClick={() => handleRemoveComponent(globalIdx)}><X size={14} /></IconButton>
                                                </Box>
                                            );
                                        })}
                                    </Box>
                                </Box>
                            )}
                        </Box>

                        {/* PREVIEW PART */}
                        <Box sx={{ borderLeft: { lg: '1px solid #f1f5f9' }, pl: { lg: 4 } }}>
                            <Typography variant="subtitle2" sx={{ fontWeight: 800, mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
                                <ArrowRight size={18} color="#FFC107" /> Stock Impact Preview
                            </Typography>
                            {renderStockImpactPreview() || (
                                <Box sx={{ p: 4, textAlign: 'center', border: '2px dashed #f1f5f9', borderRadius: '16px' }}>
                                    <Package size={40} color="#f1f5f9" style={{ marginBottom: '12px' }} />
                                    <Typography variant="caption" color="text.secondary" display="block">Add items to see stock simulation</Typography>
                                </Box>
                            )}

                            <Box sx={{ mt: 4, p: 2, bgcolor: '#f8fafc', borderRadius: '16px' }}>
                                <Typography variant="caption" sx={{ fontWeight: 800, display: 'block', mb: 1 }}>ERP LOGIC RULES:</Typography>
                                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                                    <Typography variant="caption" color="text.secondary">• Inputs are ALWAYS deducted from stock.</Typography>
                                    <Typography variant="caption" color="text.secondary">• Outputs are ALWAYS added to stock.</Typography>
                                    <Typography variant="caption" color="text.secondary">• Auto-Production triggers recursively.</Typography>
                                    <Typography variant="caption" color="text.secondary">• Multi-output BOMs update all child stock.</Typography>
                                </Box>
                            </Box>
                        </Box>
                    </Box>
                </DialogContent>
                <Divider />
                <Box sx={{ p: 3, display: 'flex', justifyContent: 'flex-end', gap: 2 }}>
                    <Button onClick={() => setOpenDialog(false)} sx={{ px: 4, borderRadius: '12px', textTransform: 'none', fontWeight: 700 }}>Cancel</Button>
                    <Button
                        variant="contained"
                        startIcon={<Save size={18} />}
                        onClick={handleSubmit}
                        sx={{
                            bgcolor: dialogType === 'production' ? '#0ea5e9' : '#d946ef',
                            '&:hover': { bgcolor: dialogType === 'production' ? '#0284c7' : '#c026d3' },
                            px: 6,
                            borderRadius: '12px',
                            textTransform: 'none',
                            fontWeight: 700,
                            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)'
                        }}
                    >
                        {editingBOM ? 'Update' : 'Save'} Recipe
                    </Button>
                </Box>
            </Dialog>

            <Snackbar
                open={snackbar.open}
                autoHideDuration={4000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
            >
                <Alert severity={snackbar.severity} sx={{ borderRadius: '12px', fontWeight: 600 }}>{snackbar.message}</Alert>
            </Snackbar>
            <BeautifulConfirm
                open={confirmDelete.open}
                title="Delete Recipe"
                message="Are you sure you want to delete this recipe/BOM? This action cannot be undone and might affect historical production data."
                onConfirm={confirmDeleteBOMAction}
                onCancel={() => setConfirmDelete({ open: false, id: null })}
                confirmText="Yes, Delete Recipe"
                isDestructive
            />
        </Box>
    );
};

export default BOM;
