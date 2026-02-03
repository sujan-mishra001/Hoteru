import React, { useState, useEffect } from 'react';
import {
    Box,
    Typography,
    Paper,
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
    Alert
} from '@mui/material';
import { Plus, X, Edit, Trash2, Save, Package, Utensils } from 'lucide-react';
import { inventoryAPI, menuAPI } from '../../../services/api';

const BOM: React.FC = () => {
    const [boms, setBoms] = useState<any[]>([]);
    const [menuItems, setMenuItems] = useState<any[]>([]);
    const [products, setProducts] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [openDialog, setOpenDialog] = useState(false);
    const [editingBOM, setEditingBOM] = useState<any>(null);
    const [formData, setFormData] = useState<any>({
        name: '',
        finished_product_id: '',
        output_quantity: 1,
        menu_item_id: '',
        components: []
    });

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setLoading(true);
            const [bomsRes, menuRes, productsRes] = await Promise.all([
                inventoryAPI.getBOMs(),
                menuAPI.getItems(),
                inventoryAPI.getProducts()
            ]);
            setBoms(bomsRes.data || []);
            setMenuItems(menuRes.data || []);
            setProducts(productsRes.data || []);
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
                finished_product_id: bom.finished_product_id || '',
                output_quantity: bom.output_quantity || 1,
                menu_item_id: bom.menu_item_id || '',
                components: bom.components.map((c: any) => ({
                    product_id: c.product_id,
                    quantity: c.quantity
                }))
            });
        } else {
            setEditingBOM(null);
            setFormData({
                name: '',
                finished_product_id: '',
                output_quantity: 1,
                menu_item_id: '',
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
            components: [...formData.components, { product_id: '', quantity: 1 }]
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
            const filteredData = {
                ...formData,
                components: formData.components.filter((c: any) => c.product_id !== ''),
                // Convert empty strings to null for the backend
                menu_item_id: formData.menu_item_id === '' ? null : formData.menu_item_id,
                finished_product_id: formData.finished_product_id === '' ? null : formData.finished_product_id
            };

            if (editingBOM) {
                await inventoryAPI.updateBOM(editingBOM.id, filteredData);
            } else {
                await inventoryAPI.createBOM(filteredData);
            }
            handleCloseDialog();
            loadData();
        } catch (error) {
            console.error('Error saving BOM:', error);
            alert('Error saving BOM. Ensure all components have a product selected.');
        }
    };

    return (
        <Box sx={{ p: 1 }}>
            <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                    <Typography variant="h4" sx={{ fontWeight: 800, color: '#1e293b', mb: 0.5 }}>Bill of Materials</Typography>
                    <Typography variant="body2" color="text.secondary">Define recipes and component requirements for finished products.</Typography>
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
                                        {bom.menu_item && (
                                            <Box sx={{ display: 'flex', alignItems: 'center', mt: 0.5, gap: 0.5 }}>
                                                <Utensils size={14} color="#64748b" />
                                                <Typography variant="caption" color="text.secondary">{bom.menu_item.name}</Typography>
                                            </Box>
                                        )}
                                    </Box>
                                    <Box sx={{ display: 'flex', gap: 1 }}>
                                        <IconButton size="small" onClick={() => handleOpenDialog(bom)} sx={{ color: '#64748b' }}>
                                            <Edit size={16} />
                                        </IconButton>
                                    </Box>
                                </Box>
                                <Box sx={{ p: 2.5 }}>
                                    <Box sx={{ mb: 2 }}>
                                        <Typography variant="caption" sx={{ fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Finished Product</Typography>
                                        <Typography variant="body2" sx={{ mt: 0.5, display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <Package size={16} color="#FFC107" />
                                            {bom.finished_product?.name || 'Manual Selection'}
                                            <Typography variant="caption" sx={{ ml: 1, bgcolor: '#f1f5f9', px: 1, py: 0.5, borderRadius: '4px' }}>
                                                Yield: {bom.output_quantity} {bom.finished_product?.unit?.abbreviation || 'pcs'}
                                            </Typography>
                                        </Typography>
                                    </Box>
                                    <Divider sx={{ my: 1.5, borderStyle: 'dashed' }} />
                                    <Typography variant="caption" sx={{ fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block', mb: 1 }}>Ingredients ({bom.components?.length || 0})</Typography>
                                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                                        {bom.components?.slice(0, 3).map((comp: any, idx: number) => (
                                            <Box key={idx} sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                                <Typography variant="body2" color="text.secondary">{comp.product?.name}</Typography>
                                                <Typography variant="body2" sx={{ fontWeight: 600 }}>{comp.quantity} {comp.product?.unit?.abbreviation}</Typography>
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
                        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '2fr 1.5fr' }, gap: 2 }}>
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
                                select
                                label="Linked Menu Item (Optional)"
                                fullWidth
                                value={formData.menu_item_id}
                                onChange={(e) => setFormData({ ...formData, menu_item_id: e.target.value })}
                            >
                                <MenuItem value=""><em>None</em></MenuItem>
                                {menuItems.map((item) => (
                                    <MenuItem key={item.id} value={item.id}>{item.name}</MenuItem>
                                ))}
                            </TextField>
                        </Box>

                        <Paper variant="outlined" sx={{ p: 2, borderRadius: '12px', bgcolor: '#f8fafc' }}>
                            <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
                                <Package size={18} color="#FFC107" />
                                Resulting Product
                            </Typography>
                            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '2fr 1fr' }, gap: 2 }}>
                                <TextField
                                    select
                                    label="Finished Product"
                                    fullWidth
                                    value={formData.finished_product_id}
                                    onChange={(e) => setFormData({ ...formData, finished_product_id: e.target.value })}
                                    required
                                >
                                    {products.map((p) => (
                                        <MenuItem key={p.id} value={p.id}>{p.name}</MenuItem>
                                    ))}
                                </TextField>
                                <TextField
                                    label="Output Quantity"
                                    type="number"
                                    fullWidth
                                    value={formData.output_quantity}
                                    onChange={(e) => setFormData({ ...formData, output_quantity: parseFloat(e.target.value) || 1 })}
                                    required
                                />
                            </Box>
                        </Paper>

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
                                        <Box key={index} sx={{ display: 'grid', gridTemplateColumns: '3fr 1.5fr 40px', gap: 2, alignItems: 'center' }}>
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
        </Box>
    );
};

export default BOM;

