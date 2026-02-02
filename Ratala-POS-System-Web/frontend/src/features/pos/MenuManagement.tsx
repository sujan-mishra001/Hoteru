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
    Tabs,
    Tab,
    TextField,
    Dialog,
    DialogTitle,
    DialogContent,
    IconButton,
    Avatar,
    InputAdornment,
    MenuItem,
    CircularProgress
} from '@mui/material';
import { Plus, Search, X, Edit, Trash2 } from 'lucide-react';
import { menuAPI } from '../../services/api';

const MenuManagement: React.FC = () => {
    const [tab, setTab] = useState(0);
    const [loading, setLoading] = useState(true);

    // Data states
    const [menuItems, setMenuItems] = useState<any[]>([]);
    const [categories, setCategories] = useState<any[]>([]);
    const [groups, setGroups] = useState<any[]>([]);

    // UI states
    const [openAddItem, setOpenAddItem] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const [editingItem, setEditingItem] = useState<any>(null);

    // Form states
    const [itemForm, setItemForm] = useState({
        name: '',
        price: '',
        category_id: '',
        group_id: '',
        description: '',
        is_active: true
    });

    const [categoryForm, setCategoryForm] = useState({ name: '', description: '', is_active: true });
    const [groupForm, setGroupForm] = useState({ name: '', description: '', is_active: true });

    useEffect(() => {
        loadData();
    }, [tab]);

    const loadData = async () => {
        try {
            setLoading(true);
            const [itemsRes, catRes, groupsRes] = await Promise.all([
                menuAPI.getItems(),
                menuAPI.getCategories(),
                menuAPI.getGroups()
            ]);
            setMenuItems(itemsRes.data || []);
            setCategories(catRes.data || []);
            setGroups(groupsRes.data || []);
        } catch (error) {
            console.error('Error loading menu data:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleOpenDialog = (item?: any) => {
        setEditingItem(item || null);
        if (tab === 0) { // Items
            if (item) {
                setItemForm({
                    name: item.name,
                    price: item.price,
                    category_id: item.category_id || '',
                    group_id: item.group_id || '',
                    description: item.description || '',
                    is_active: !!item.is_active
                });
            } else {
                setItemForm({ name: '', price: '', category_id: '', group_id: '', description: '', is_active: true });
            }
        } else if (tab === 1) { // Categories
            if (item) {
                setCategoryForm({ name: item.name, description: item.description || '', is_active: !!item.is_active });
            } else {
                setCategoryForm({ name: '', description: '', is_active: true });
            }
        } else { // Groups
            if (item) {
                setGroupForm({ name: item.name, description: item.description || '', is_active: !!item.is_active });
            } else {
                setGroupForm({ name: '', description: '', is_active: true });
            }
        }
        setOpenAddItem(true);
    };

    const handleSave = async () => {
        try {
            if (tab === 0) { // Items
                const payload = {
                    name: itemForm.name,
                    price: parseFloat(itemForm.price as any),
                    category_id: Number(itemForm.category_id),
                    group_id: itemForm.group_id ? Number(itemForm.group_id) : null,
                    description: itemForm.description,
                    is_active: itemForm.is_active
                };
                if (editingItem) await menuAPI.updateItem(editingItem.id, payload);
                else await menuAPI.createItem(payload);
            } else if (tab === 1) { // Categories
                const payload = {
                    name: categoryForm.name,
                    description: categoryForm.description,
                    is_active: categoryForm.is_active,
                    type: 'KOT' // Default type if not in form
                };
                if (editingItem) await menuAPI.updateCategory(editingItem.id, payload);
                else await menuAPI.createCategory(payload);
            } else { // Groups
                const payload = {
                    name: groupForm.name,
                    description: groupForm.description,
                    is_active: groupForm.is_active,
                    category_id: Number(categories[0]?.id) // Defaulting to first category if not specified
                };
                if (editingItem) await menuAPI.updateGroup(editingItem.id, payload);
                else await menuAPI.createGroup(payload);
            }
            setOpenAddItem(false);
            loadData();
        } catch (error: any) {
            console.error('Error saving:', error);
            alert(error.response?.data?.detail || 'Failed to save');
        }
    };

    const handleDelete = async (id: number) => {
        if (!confirm('Are you sure?')) return;
        try {
            if (tab === 0) await menuAPI.deleteItem(id);
            else if (tab === 1) await menuAPI.deleteCategory(id);
            else await menuAPI.deleteGroup(id);
            loadData();
        } catch (error) {
            console.error('Error deleting:', error);
        }
    };

    const filteredContent = () => {
        const lowerSearch = searchTerm.toLowerCase();
        if (tab === 0) return menuItems.filter(i => i.name.toLowerCase().includes(lowerSearch));
        if (tab === 1) return categories.filter(c => c.name.toLowerCase().includes(lowerSearch));
        return groups.filter(g => g.name.toLowerCase().includes(lowerSearch));
    };

    const getDialogTitle = () => {
        const action = editingItem ? 'EDIT' : 'ADD NEW';
        if (tab === 0) return `${action} MENU ITEM`;
        if (tab === 1) return `${action} CATEGORY`;
        return `${action} GROUP`;
    };

    return (
        <Box>
            <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Typography variant="h5" fontWeight={800}>Menu Management</Typography>
                <Button variant="contained" startIcon={<Plus size={18} />} onClick={() => handleOpenDialog()} sx={{ bgcolor: '#FF8C00', '&:hover': { bgcolor: '#FF7700' } }}>
                    Add {tab === 0 ? 'Item' : tab === 1 ? 'Category' : 'Group'}
                </Button>
            </Box>

            <Paper sx={{ borderRadius: '16px', border: '1px solid #f1f5f9', overflow: 'hidden' }}>
                <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ px: 2, borderBottom: '1px solid #f1f5f9' }}>
                    <Tab label="MENU ITEMS" />
                    <Tab label="CATEGORIES" />
                    <Tab label="GROUPS" />
                </Tabs>

                <Box sx={{ p: 3 }}>
                    <TextField
                        size="small"
                        placeholder="Search..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        fullWidth
                        sx={{ mb: 3 }}
                        InputProps={{ startAdornment: <InputAdornment position="start"><Search size={18} /></InputAdornment> }}
                    />

                    <TableContainer>
                        <Table>
                            <TableHead sx={{ bgcolor: '#f8fafc' }}>
                                <TableRow>
                                    {tab === 0 && <TableCell sx={{ fontWeight: 700 }}>IMAGE</TableCell>}
                                    <TableCell sx={{ fontWeight: 700 }}>NAME</TableCell>
                                    {tab === 0 && <TableCell sx={{ fontWeight: 700 }}>CATEGORY</TableCell>}
                                    {tab === 0 && <TableCell sx={{ fontWeight: 700 }}>PRICE</TableCell>}
                                    <TableCell sx={{ fontWeight: 700 }}>STATUS</TableCell>
                                    <TableCell sx={{ fontWeight: 700 }}>ACTIONS</TableCell>
                                </TableRow>
                            </TableHead>
                            <TableBody>
                                {loading ? (
                                    <TableRow><TableCell colSpan={6} align="center"><CircularProgress size={24} sx={{ color: '#FF8C00' }} /></TableCell></TableRow>
                                ) : filteredContent().length === 0 ? (
                                    <TableRow><TableCell colSpan={6} align="center">No records found</TableCell></TableRow>
                                ) : (
                                    filteredContent().map((item: any) => (
                                        <TableRow key={item.id} hover>
                                            {tab === 0 && (
                                                <TableCell>
                                                    <Avatar src={item.image_url} variant="rounded" sx={{ width: 40, height: 40, bgcolor: '#f1f5f9', color: '#64748b' }}>{item.name.charAt(0)}</Avatar>
                                                </TableCell>
                                            )}
                                            <TableCell sx={{ fontWeight: 600 }}>{item.name}</TableCell>
                                            {tab === 0 && <TableCell>{item.category?.name || '-'}</TableCell>}
                                            {tab === 0 && <TableCell sx={{ fontWeight: 700 }}>NPRs. {item.price}</TableCell>}
                                            <TableCell>
                                                <Box sx={{
                                                    display: 'inline-block', px: 1, py: 0.5, borderRadius: '4px',
                                                    bgcolor: item.is_active ? '#ecfdf5' : '#fef2f2',
                                                    color: item.is_active ? '#10b981' : '#ef4444',
                                                    fontSize: '0.75rem', fontWeight: 700
                                                }}>
                                                    {item.is_active ? 'Active' : 'Inactive'}
                                                </Box>
                                            </TableCell>
                                            <TableCell>
                                                <IconButton size="small" onClick={() => handleOpenDialog(item)} sx={{ color: '#64748b', '&:hover': { color: '#FF8C00' } }}><Edit size={16} /></IconButton>
                                                <IconButton size="small" onClick={() => handleDelete(item.id)} sx={{ color: '#64748b', '&:hover': { color: '#ef4444' } }}><Trash2 size={16} /></IconButton>
                                            </TableCell>
                                        </TableRow>
                                    ))
                                )}
                            </TableBody>
                        </Table>
                    </TableContainer>
                </Box>
            </Paper>

            <Dialog open={openAddItem} onClose={() => setOpenAddItem(false)} maxWidth="sm" fullWidth>
                <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography fontWeight={800}>{getDialogTitle()}</Typography>
                    <IconButton onClick={() => setOpenAddItem(false)} size="small"><X size={20} /></IconButton>
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
                        {tab === 0 ? (
                            <>
                                <TextField label="Item Name" fullWidth required value={itemForm.name} onChange={(e) => setItemForm({ ...itemForm, name: e.target.value })} />
                                <Box sx={{ display: 'flex', gap: 2 }}>
                                    <TextField select label="Category" fullWidth value={itemForm.category_id} onChange={(e) => setItemForm({ ...itemForm, category_id: e.target.value })}>
                                        {categories.map(cat => <MenuItem key={cat.id} value={cat.id}>{cat.name}</MenuItem>)}
                                    </TextField>
                                    <TextField select label="Group" fullWidth value={itemForm.group_id} onChange={(e) => setItemForm({ ...itemForm, group_id: e.target.value })}>
                                        {groups.map(grp => <MenuItem key={grp.id} value={grp.id}>{grp.name}</MenuItem>)}
                                    </TextField>
                                </Box>
                                <TextField label="Price" type="number" fullWidth required value={itemForm.price} onChange={(e) => setItemForm({ ...itemForm, price: e.target.value })} InputProps={{ startAdornment: <InputAdornment position="start">NPRs.</InputAdornment> }} />
                                <TextField label="Description" fullWidth multiline rows={3} value={itemForm.description} onChange={(e) => setItemForm({ ...itemForm, description: e.target.value })} />
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <input type="checkbox" id="is_active_item" checked={itemForm.is_active} onChange={(e) => setItemForm({ ...itemForm, is_active: e.target.checked })} style={{ width: 20, height: 20, accentColor: '#FF8C00', cursor: 'pointer' }} />
                                    <label htmlFor="is_active_item" style={{ cursor: 'pointer', fontWeight: 600 }}>Active Status</label>
                                </Box>
                            </>
                        ) : (
                            <>
                                <TextField label="Name" fullWidth required value={tab === 1 ? categoryForm.name : groupForm.name} onChange={(e) => tab === 1 ? setCategoryForm({ ...categoryForm, name: e.target.value }) : setGroupForm({ ...groupForm, name: e.target.value })} />
                                <TextField label="Description" fullWidth multiline rows={3} value={tab === 1 ? categoryForm.description : groupForm.description} onChange={(e) => tab === 1 ? setCategoryForm({ ...categoryForm, description: e.target.value }) : setGroupForm({ ...groupForm, description: e.target.value })} />
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <input type="checkbox" id="is_active_toggle" checked={tab === 1 ? categoryForm.is_active : groupForm.is_active} onChange={(e) => tab === 1 ? setCategoryForm({ ...categoryForm, is_active: e.target.checked }) : setGroupForm({ ...groupForm, is_active: e.target.checked })} style={{ width: 20, height: 20, accentColor: '#FF8C00', cursor: 'pointer' }} />
                                    <label htmlFor="is_active_toggle" style={{ cursor: 'pointer', fontWeight: 600 }}>Active Status</label>
                                </Box>
                            </>
                        )}
                        <Button variant="contained" sx={{ bgcolor: '#FF8C00', '&:hover': { bgcolor: '#FF7700' }, mt: 2 }} onClick={handleSave}>
                            {editingItem ? 'Update' : 'Save'}
                        </Button>
                    </Box>
                </DialogContent>
            </Dialog>
        </Box>
    );
};

export default MenuManagement;
