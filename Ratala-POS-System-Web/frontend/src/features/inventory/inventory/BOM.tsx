import React, { useState, useEffect } from 'react';
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
    Card,
    CardContent,
    Alert,
    Snackbar,
} from '@mui/material';
import { Plus, X, Edit, Trash2, Save, Package, Utensils } from 'lucide-react';
import { inventoryAPI, menuAPI } from '../../../services/api';

const BOM: React.FC = () => {
    const [boms, setBoms] = useState<any[]>([]);
    const [products, setProducts] = useState<any[]>([]);
    const [units, setUnits] = useState<any[]>([]);
    const [menuItems, setMenuItems] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [openDialog, setOpenDialog] = useState(false);
    const [editingBOM, setEditingBOM] = useState<any>(null);

    // We strictly use Menu Items now as per requirements
    const [formData, setFormData] = useState<any>({
        name: '',
        output_quantity: 1,
        finished_product_id: '',
        menu_item_ids: [],
        components: []
    });
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

    const showSnackbar = (message: string, severity: 'success' | 'error' = 'success') => {
        setSnackbar({ open: true, message, severity });
    };

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setLoading(true);
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
        } finally {
            setLoading(false);
        }
    };

    const handleOpenDialog = (bom?: any) => {
        if (bom) {
            setEditingBOM(bom);
            setFormData({
                name: bom.name || '',
                output_quantity: bom.output_quantity || 1,
                // We clear finished_product_id as we are moving away from it for now, or keep it if it exists but don't show UI
                finished_product_id: bom.finished_product_id || '',
                menu_item_ids: bom.menu_items ? bom.menu_items.map((m: any) => m.id) : [],
                components: bom.components.map((c: any) => ({
                    product_id: c.product_id,
                    unit_id: c.unit_id || '',
                    quantity: c.quantity
                }))
            });
        } else {
            setEditingBOM(null);
            setFormData({
                name: '',
                output_quantity: 1,
                finished_product_id: '',
                menu_item_ids: [],
                components: []
            });
        }
        setOpenDialog(true);
    };

    const handleCloseDialog = () => {
        setOpenDialog(false);
        setEditingBOM(null);
    };

    const handleAddComponent = () => {
        setFormData({
            ...formData,
            components: [...formData.components, { product_id: '', unit_id: '', quantity: 1 }]
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
            if (!formData.name) return;

            // Filter out empty components
            const filteredComponents = formData.components.filter((c: any) => c.product_id !== '');

            const payload = {
                ...formData,
                components: filteredComponents,
                // Ensure we prioritize menu items
                finished_product_id: null,
                menu_item_ids: formData.menu_item_ids
            };

            if (editingBOM) {
                await inventoryAPI.updateBOM(editingBOM.id, payload);
            } else {
                await inventoryAPI.createBOM(payload);
            }
            handleCloseDialog();
            loadData();
            showSnackbar(`Recipe ${editingBOM ? 'updated' : 'created'} successfully`);
        } catch (error: any) {
            console.error('Error saving BOM:', error);
            showSnackbar(error.response?.data?.detail || 'Error saving BOM. Ensure all components have a product selected.', 'error');
        }
    };

    const handleDeleteBOM = async (id: number) => {
        if (!window.confirm('Are you sure you want to delete this recipe?')) return;
        try {
            await inventoryAPI.deleteBOM(id);
            loadData();
            showSnackbar('Recipe deleted successfully');
        } catch (error: any) {
            console.error('Error deleting BOM:', error);
            showSnackbar(error.response?.data?.detail || 'Failed to delete recipe', 'error');
        }
    };

    return (
        <Box sx={{ p: 1 }}>
            <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                    <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b', mb: 0.5 }}>Bill of Materials</Typography>
                    <Typography variant="body2" color="text.secondary">Define recipes and component requirements for Menu Items.</Typography>
                </Box>
                <Button
                    variant="contained"
                    startIcon={<Plus size={18} />}
                    onClick={() => handleOpenDialog()}
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
                    Create New Recipe
                </Button>
            </Box>

            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(auto-fill, minmax(350px, 1fr))' }, gap: 3 }}>
                {loading ? (
                    [1, 2, 3].map((i) => (
                        <Card key={i} sx={{ borderRadius: '16px', border: '1px solid #f1f5f9', bgcolor: '#fff' }}>
                            <CardContent sx={{ p: 3, height: 200, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Typography color="text.secondary">Loading...</Typography>
                            </CardContent>
                        </Card>
                    ))
                ) : boms.length === 0 ? (
                    <Box sx={{ gridColumn: '1/-1', textAlign: 'center', py: 8 }}>
                        <Typography variant="h6" color="text.secondary">No recipes defined yet.</Typography>
                        <Button variant="text" onClick={() => handleOpenDialog()} sx={{ mt: 1, color: '#FFC107' }}>Create your first BOM</Button>
                    </Box>
                ) : (
                    boms.map((bom) => (
                        <Card
                            key={bom.id}
                            sx={{
                                borderRadius: '16px',
                                border: '1px solid #f1f5f9',
                                transition: 'all 0.3s ease',
                                '&:hover': {
                                    transform: 'translateY(-4px)',
                                    boxShadow: '0 12px 24px -10px rgba(0,0,0,0.1)',
                                    borderColor: '#FFC107'
                                }
                            }}
                        >
                            <CardContent sx={{ p: 0 }}>
                                <Box sx={{ p: 2.5, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', bgcolor: '#f8fafc', borderBottom: '1px solid #f1f5f9' }}>
                                    <Box>
                                        <Typography variant="h6" sx={{ fontWeight: 700, color: '#1e293b' }}>{bom.name}</Typography>
                                    </Box>
                                    <Box sx={{ display: 'flex', gap: 1 }}>
                                        <IconButton size="small" onClick={() => handleOpenDialog(bom)} sx={{ color: '#64748b' }}>
                                            <Edit size={16} />
                                        </IconButton>
                                        <IconButton size="small" onClick={() => handleDeleteBOM(bom.id)} sx={{ color: '#ef4444' }}>
                                            <Trash2 size={16} />
                                        </IconButton>
                                    </Box>
                                </Box>
                                <Box sx={{ p: 2.5 }}>
                                    <Box sx={{ mb: 2 }}>
                                        <Typography variant="caption" sx={{ fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Batch Yield</Typography>
                                        <Typography variant="body2" sx={{ mt: 0.5, display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <Package size={16} color="#FFC107" />
                                            {bom.name}
                                            <Typography variant="caption" sx={{ ml: 1, bgcolor: '#f1f5f9', px: 1, py: 0.5, borderRadius: '4px', fontWeight: 700 }}>
                                                {Number(bom.output_quantity).toFixed(2)} units
                                            </Typography>
                                        </Typography>
                                    </Box>

                                    {/* Show Linked Product or Menu Items */}
                                    <Box sx={{ mb: 2 }}>
                                        <Typography variant="caption" sx={{ fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Usage</Typography>
                                        <Typography variant="body2" sx={{ mt: 0.5, fontWeight: 600 }}>
                                            {bom.menu_items && bom.menu_items.length > 0 ? (
                                                <span style={{ color: '#3b82f6' }}>{bom.menu_items.map((m: any) => m.name).join(', ')} (Menu)</span>
                                            ) : bom.finished_product ? (
                                                <span style={{ color: '#10b981' }}>{bom.finished_product.name} (Stock)</span>
                                            ) : (
                                                <span style={{ color: '#94a3b8' }}>Unlinked Recipe</span>
                                            )}
                                        </Typography>
                                    </Box>

                                    <Divider sx={{ my: 1.5, borderStyle: 'dashed' }} />
                                    <Typography variant="caption" sx={{ fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', mb: 1 }}>Ingredients ({bom.components?.length || 0})</Typography>
                                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                                        {bom.components?.slice(0, 3).map((comp: any, idx: number) => (
                                            <Box key={idx} sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                                <Typography variant="body2" color="text.secondary">{comp.product?.name}</Typography>
                                                <Typography variant="body2" sx={{ fontWeight: 600 }}>{Number(comp.quantity).toFixed(2)} {comp.unit?.abbreviation || comp.product?.unit?.abbreviation}</Typography>
                                            </Box>
                                        ))}
                                        {bom.components?.length > 3 && (
                                            <Typography variant="caption" color="primary" sx={{ mt: 0.5, cursor: 'pointer' }}>+ {bom.components.length - 3} more ingredients</Typography>
                                        )}
                                    </Box>
                                </Box>
                            </CardContent>
                        </Card>
                    ))
                )}
            </Box>

            <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="md" fullWidth sx={{ '& .MuiDialog-paper': { borderRadius: '20px' } }}>
                <DialogTitle sx={{ px: 3, pt: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography variant="h5" sx={{ fontWeight: 800 }}>{editingBOM ? 'Edit Recipe' : 'New Recipe'}</Typography>
                    <IconButton onClick={handleCloseDialog} size="small" sx={{ color: '#94a3b8' }}>
                        <X size={24} />
                    </IconButton>
                </DialogTitle>
                <DialogContent sx={{ px: 3, pb: 3 }}>
                    <Box sx={{ mt: 2, display: 'flex', flexDirection: 'column', gap: 3 }}>
                        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '2fr 1fr' }, gap: 3 }}>
                            <TextField
                                label="Recipe Name"
                                fullWidth
                                variant="outlined"
                                value={formData.name}
                                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                placeholder="e.g., Signature Burger"
                                required
                            />
                            <TextField
                                label="Output Quantity (Yield)"
                                type="number"
                                fullWidth
                                value={formData.output_quantity}
                                onChange={(e) => setFormData({ ...formData, output_quantity: parseFloat(e.target.value) || 1 })}
                                required
                                helperText="How many units does this recipe produce?"
                            />
                        </Box>

                        <TextField
                            select
                            label="Linked Menu Item(s) (Sales)"
                            fullWidth
                            variant="outlined"
                            SelectProps={{
                                multiple: true,
                                renderValue: (selected: any) => {
                                    return menuItems
                                        .filter(item => selected.includes(item.id))
                                        .map(item => item.name)
                                        .join(', ');
                                }
                            }}
                            value={formData.menu_item_ids}
                            onChange={(e) => setFormData({ ...formData, menu_item_ids: e.target.value })}
                            helperText="Select Menu Items (Dishes) that are made using this recipe. Ingredients will be deducted upon sale/production."
                        >
                            {menuItems.map((item) => (
                                <MenuItem key={item.id} value={item.id}>
                                    {item.name}
                                </MenuItem>
                            ))}
                        </TextField>

                        <Box>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                                <Typography variant="subtitle2" sx={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <Utensils size={18} color="#FFC107" />
                                    Recipe Ingredients
                                </Typography>
                                <Button
                                    size="small"
                                    startIcon={<Plus size={16} />}
                                    onClick={handleAddComponent}
                                    sx={{ color: '#FFC107' }}
                                >
                                    Add Ingredient
                                </Button>
                            </Box>

                            {formData.components.length === 0 ? (
                                <Alert severity="info" sx={{ borderRadius: '12px' }}>Click "Add Ingredient" to start defining your recipe components.</Alert>
                            ) : (
                                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                                    {formData.components.map((comp: any, index: number) => (
                                        <Box key={index} sx={{ display: 'grid', gridTemplateColumns: '3fr 1.5fr 1.5fr 40px', gap: 2, alignItems: 'center' }}>
                                            <TextField
                                                select
                                                size="small"
                                                label="Ingredient"
                                                value={comp.product_id}
                                                onChange={(e) => handleComponentChange(index, 'product_id', e.target.value)}
                                            >
                                                {products.map((p) => (
                                                    <MenuItem key={p.id} value={p.id}>{p.name}</MenuItem>
                                                ))}
                                            </TextField>
                                            <TextField
                                                size="small"
                                                label="Quantity"
                                                type="number"
                                                value={comp.quantity}
                                                onChange={(e) => handleComponentChange(index, 'quantity', parseFloat(e.target.value) || 0)}
                                            />
                                            <TextField
                                                select
                                                size="small"
                                                label="Unit"
                                                value={comp.unit_id}
                                                onChange={(e) => handleComponentChange(index, 'unit_id', e.target.value)}
                                            >
                                                <MenuItem value=""><em>Base Unit</em></MenuItem>
                                                {units.map((u) => (
                                                    <MenuItem key={u.id} value={u.id}>{u.abbreviation}</MenuItem>
                                                ))}
                                            </TextField>
                                            <IconButton size="small" onClick={() => handleRemoveComponent(index)} sx={{ color: '#ef4444' }}>
                                                <Trash2 size={16} />
                                            </IconButton>
                                        </Box>
                                    ))}
                                </Box>
                            )}
                        </Box>

                        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2, mt: 2 }}>
                            <Button onClick={handleCloseDialog} sx={{ px: 3, borderRadius: '10px' }}>Cancel</Button>
                            <Button
                                variant="contained"
                                startIcon={<Save size={18} />}
                                onClick={handleSubmit}
                                sx={{
                                    bgcolor: '#FFC107',
                                    '&:hover': { bgcolor: '#FF7700' },
                                    px: 4,
                                    borderRadius: '10px'
                                }}
                            >
                                {editingBOM ? 'Update Recipe' : 'Save Recipe'}
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
        </Box>
    );
};

export default BOM;
