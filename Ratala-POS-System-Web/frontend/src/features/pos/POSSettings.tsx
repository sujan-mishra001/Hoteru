import React, { useState, useEffect } from 'react';
import {
    Box,
    Typography,
    Paper,
    Tabs,
    Tab,
    TextField,
    Button,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    IconButton,
    Chip,
    CircularProgress,
    Select,
    MenuItem,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    Menu,
    FormControl,
    InputLabel
} from '@mui/material';
import {
    User,
    LayoutGrid,
    BookOpen,
    MoreVertical,
    Plus
} from 'lucide-react';
import { menuAPI, authAPI, usersAPI } from '../../services/api';
import { useNotification } from '../../app/providers/NotificationProvider';
import { useActivity } from '../../app/providers/ActivityProvider';

const POSSettings: React.FC = () => {
    const { showAlert, showConfirm } = useNotification();
    const { logActivity } = useActivity();
    const [sidebarTab, setSidebarTab] = useState(0);
    const [subTab, setSubTab] = useState(0); // 0 for Categories, 1 for Groups
    const [items, setItems] = useState<any[]>([]);
    const [categories, setCategories] = useState<any[]>([]);
    const [groups, setGroups] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [currentUser, setCurrentUser] = useState<any>(null);
    const [categoryDialog, setCategoryDialog] = useState(false);
    const [groupDialog, setGroupDialog] = useState(false);
    const [itemDialog, setItemDialog] = useState(false);
    const [currentCategory, setCurrentCategory] = useState<any>({ name: '', type: 'KOT', status: 'Active' });
    const [currentGroup, setCurrentGroup] = useState<any>({ name: '', category_id: '', status: 'Active' });
    const [currentItem, setCurrentItem] = useState<any>({ name: '', category_id: '', group_id: '', price: 0, kot_bot: 'KOT', inventory_tracking: false, status: 'Active' });
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
    const [selectedId, setSelectedId] = useState<number | null>(null);
    const [menuType, setMenuType] = useState<'item' | 'category' | 'group' | null>(null);
    const [isEditingProfile, setIsEditingProfile] = useState(false);
    const [editProfileData, setEditProfileData] = useState<any>({});

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setLoading(true);
            const [userRes, itemsRes, catsRes, groupsRes] = await Promise.all([
                authAPI.getCurrentUser(),
                menuAPI.getItems(),
                menuAPI.getCategories(),
                menuAPI.getGroups()
            ]);
            setCurrentUser(userRes.data);
            setEditProfileData(userRes.data);
            setItems(itemsRes.data || []);
            setCategories(catsRes.data || []);
            setGroups(groupsRes.data || []);
        } catch (error) {
            console.error("Error loading settings data:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleUpdateProfile = async () => {
        try {
            if (!currentUser?.id) return;
            await usersAPI.update(currentUser.id, editProfileData);
            setIsEditingProfile(false);
            loadData();
            logActivity('Profile Updated', 'User profile details were updated', 'update');
            showAlert('Profile updated successfully', 'success');
        } catch (error) {
            console.error('Error updating profile:', error);
            showAlert('Failed to update profile', 'error');
        }
    };

    const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, id: number, type: 'item' | 'category' | 'group') => {
        setAnchorEl(event.currentTarget);
        setSelectedId(id);
        setMenuType(type);
    };

    const handleMenuClose = () => {
        setAnchorEl(null);
        setSelectedId(null);
        setMenuType(null);
    };

    const handleDelete = async () => {
        if (!selectedId || !menuType) return;

        showConfirm({
            title: `Delete ${menuType.charAt(0).toUpperCase() + menuType.slice(1)}?`,
            message: `Are you sure you want to delete this ${menuType}? This action cannot be undone.`,
            isDestructive: true,
            onConfirm: async () => {
                try {
                    if (menuType === 'item') await menuAPI.deleteItem(selectedId);
                    else if (menuType === 'category') await menuAPI.deleteCategory(selectedId);
                    else if (menuType === 'group') await menuAPI.deleteGroup(selectedId);
                    loadData();
                    handleMenuClose();
                    logActivity(`${menuType.charAt(0).toUpperCase() + menuType.slice(1)} Deleted`, `${menuType} with ID ${selectedId} was removed`, 'update');
                    showAlert(`${menuType.charAt(0).toUpperCase() + menuType.slice(1)} deleted successfully`, 'success');
                } catch (error) {
                    showAlert(`Error deleting ${menuType}`, 'error');
                }
            }
        });
    };

    const handleSaveCategory = async () => {
        try {
            const payload = {
                name: currentCategory.name,
                type: currentCategory.type,
                description: currentCategory.description || '',
                is_active: currentCategory.status === 'Active'
            };
            if (currentCategory.id) await menuAPI.updateCategory(currentCategory.id, payload);
            else await menuAPI.createCategory(payload);
            setCategoryDialog(false);
            setCurrentCategory({ name: '', type: 'KOT', status: 'Active' });
            loadData();
            logActivity(`Category ${currentCategory.id ? 'Updated' : 'Created'}`, `Category "${currentCategory.name}" was ${currentCategory.id ? 'updated' : 'created'}`, 'update');
            showAlert(`Category ${currentCategory.id ? 'updated' : 'created'} successfully`, 'success');
        } catch (error) { showAlert("Error saving category", "error"); }
    };

    const handleSaveGroup = async () => {
        try {
            const payload = {
                name: currentGroup.name,
                category_id: Number(currentGroup.category_id),
                description: currentGroup.description || '',
                is_active: currentGroup.status === 'Active'
            };
            if (currentGroup.id) await menuAPI.updateGroup(currentGroup.id, payload);
            else await menuAPI.createGroup(payload);
            setGroupDialog(false);
            setCurrentGroup({ name: '', category_id: '', status: 'Active' });
            loadData();
            logActivity(`Group ${currentGroup.id ? 'Updated' : 'Created'}`, `Group "${currentGroup.name}" was ${currentGroup.id ? 'updated' : 'created'}`, 'update');
            showAlert(`Group ${currentGroup.id ? 'updated' : 'created'} successfully`, 'success');
        } catch (error) { showAlert("Error saving group", "error"); }
    };

    const handleSaveItem = async () => {
        try {
            const payload = {
                name: currentItem.name,
                category_id: Number(currentItem.category_id),
                group_id: currentItem.group_id ? Number(currentItem.group_id) : null,
                price: Number(currentItem.price),
                kot_bot: currentItem.kot_bot,
                inventory_tracking: currentItem.inventory_tracking,
                description: currentItem.description || '',
                is_active: currentItem.status === 'Active'
            };
            if (currentItem.id) await menuAPI.updateItem(currentItem.id, payload);
            else await menuAPI.createItem(payload);
            setItemDialog(false);
            setCurrentItem({ name: '', category_id: '', group_id: '', price: 0, kot_bot: 'KOT', inventory_tracking: false, status: 'Active' });
            loadData();
            logActivity(`Item ${currentItem.id ? 'Updated' : 'Created'}`, `Menu item "${currentItem.name}" was ${currentItem.id ? 'updated' : 'created'}`, 'update');
            showAlert(`Item ${currentItem.id ? 'updated' : 'created'} successfully`, 'success');
        } catch (error) { showAlert("Error saving menu item", "error"); }
    };

    const sidebarItems = [
        { label: 'Profile', icon: <User size={18} /> },
        { label: 'Category', icon: <LayoutGrid size={18} /> },
        { label: 'Menu Items', icon: <BookOpen size={18} /> },
    ];

    if (loading && !currentUser) {
        return <Box sx={{ display: 'flex', justifyContent: 'center', p: 5 }}><CircularProgress /></Box>;
    }

    return (
        <Box sx={{ p: 3 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
                <Typography variant="h5" fontWeight={800}>POS Settings</Typography>
            </Box>

            <Box sx={{ display: 'flex', gap: 4 }}>
                {/* Sidebar */}
                <Paper sx={{ width: 240, borderRadius: '16px', overflow: 'hidden' }} elevation={0}>
                    <Tabs
                        orientation="vertical"
                        value={sidebarTab}
                        onChange={(_, v) => setSidebarTab(v)}
                        sx={{
                            borderRight: 1, borderColor: 'divider',
                            '& .MuiTab-root': { alignItems: 'flex-start', textAlign: 'left', textTransform: 'none', fontWeight: 600, py: 2 }
                        }}
                    >
                        {sidebarItems.map((item, index) => (
                            <Tab key={index} label={item.label} icon={item.icon} iconPosition="start" />
                        ))}
                    </Tabs>
                </Paper>

                {/* Content */}
                <Box sx={{ flexGrow: 1 }}>
                    {sidebarTab === 0 && currentUser && (
                        <Paper sx={{ p: 4, borderRadius: '20px', border: '1px solid #f1f5f9', bgcolor: 'white' }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
                                <Box>
                                    <Typography variant="h5" fontWeight={900} color="#1e293b">Account Profile</Typography>
                                    <Typography variant="body2" color="text.secondary">Review and manage your personal details</Typography>
                                </Box>
                                <Button
                                    variant={isEditingProfile ? "outlined" : "contained"}
                                    onClick={() => setIsEditingProfile(!isEditingProfile)}
                                    sx={{
                                        borderRadius: '12px',
                                        textTransform: 'none',
                                        fontWeight: 700,
                                        bgcolor: isEditingProfile ? 'transparent' : '#FF8C00',
                                        '&:hover': { bgcolor: isEditingProfile ? '#fff7ed' : '#e67e00' }
                                    }}
                                >
                                    {isEditingProfile ? 'Cancel Editing' : 'Edit Profile'}
                                </Button>
                            </Box>

                            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 3 }}>
                                <TextField
                                    label="Username"
                                    value={currentUser.username}
                                    disabled
                                    fullWidth
                                    variant="filled"
                                    helperText="Username cannot be changed"
                                />
                                <TextField
                                    label="Staff Role"
                                    value={currentUser.role}
                                    disabled
                                    fullWidth
                                    variant="filled"
                                    helperText="Role is managed by administrator"
                                />
                                <TextField
                                    label="Full Name"
                                    value={isEditingProfile ? (editProfileData.full_name ?? currentUser.full_name) : currentUser.full_name}
                                    disabled={!isEditingProfile}
                                    onChange={(e) => setEditProfileData({ ...editProfileData, full_name: e.target.value })}
                                    fullWidth
                                />
                                <TextField
                                    label="Email Address"
                                    value={isEditingProfile ? (editProfileData.email ?? currentUser.email) : currentUser.email}
                                    disabled={!isEditingProfile}
                                    onChange={(e) => setEditProfileData({ ...editProfileData, email: e.target.value })}
                                    fullWidth
                                />
                                <TextField
                                    label="Phone Number"
                                    value={isEditingProfile ? (editProfileData.phone ?? currentUser.phone ?? '') : (currentUser.phone ?? 'Not provided')}
                                    disabled={!isEditingProfile}
                                    onChange={(e) => setEditProfileData({ ...editProfileData, phone: e.target.value })}
                                    fullWidth
                                />
                                <TextField
                                    label="Organization / Branch"
                                    value={currentUser.branch_name || 'Main Branch'}
                                    disabled
                                    fullWidth
                                    variant="filled"
                                />
                                <TextField
                                    label="Address"
                                    value={isEditingProfile ? (editProfileData.address ?? currentUser.address ?? '') : (currentUser.address ?? 'Not provided')}
                                    disabled={!isEditingProfile}
                                    onChange={(e) => setEditProfileData({ ...editProfileData, address: e.target.value })}
                                    fullWidth
                                    multiline
                                    rows={2}
                                    sx={{ gridColumn: { md: '1 / span 2' } }}
                                />
                            </Box>

                            {isEditingProfile && (
                                <Box sx={{ mt: 4, display: 'flex', justifyContent: 'flex-end', gap: 2 }}>
                                    <Button
                                        variant="contained"
                                        onClick={handleUpdateProfile}
                                        sx={{
                                            px: 4,
                                            py: 1.5,
                                            borderRadius: '12px',
                                            bgcolor: '#FF8C00',
                                            fontWeight: 800,
                                            '&:hover': { bgcolor: '#e67e00' }
                                        }}
                                    >
                                        Save Changes
                                    </Button>
                                </Box>
                            )}
                        </Paper>
                    )}

                    {sidebarTab === 1 && (
                        <Box>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                                <Tabs value={subTab} onChange={(_, v) => setSubTab(v)}>
                                    <Tab label="Categories" sx={{ fontWeight: 700 }} />
                                    <Tab label="Groups" sx={{ fontWeight: 700 }} />
                                </Tabs>
                                <Button
                                    variant="contained"
                                    startIcon={<Plus size={18} />}
                                    onClick={() => subTab === 0 ? setCategoryDialog(true) : setGroupDialog(true)}
                                    sx={{ bgcolor: '#FF8C00', '&:hover': { bgcolor: '#e67e00' } }}
                                >
                                    Add {subTab === 0 ? 'Category' : 'Group'}
                                </Button>
                            </Box>

                            <TableContainer component={Paper} sx={{ borderRadius: '16px', border: '1px solid #e2e8f0' }} elevation={0}>
                                <Table>
                                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                                        <TableRow>
                                            <TableCell sx={{ fontWeight: 800 }}>{subTab === 0 ? 'Category Name' : 'Group Name'}</TableCell>
                                            <TableCell sx={{ fontWeight: 800 }}>{subTab === 0 ? 'Type' : 'Category'}</TableCell>
                                            <TableCell sx={{ fontWeight: 800 }}>Status</TableCell>
                                            <TableCell align="right" sx={{ fontWeight: 800 }}>Actions</TableCell>
                                        </TableRow>
                                    </TableHead>
                                    <TableBody>
                                        {subTab === 0 ? (
                                            categories.map((cat) => (
                                                <TableRow key={cat.id}>
                                                    <TableCell sx={{ fontWeight: 600 }}>{cat.name}</TableCell>
                                                    <TableCell><Chip label={cat.type} size="small" variant="outlined" /></TableCell>
                                                    <TableCell><Chip label={cat.status || 'Active'} size="small" color={(cat.status === 'Active' || cat.is_active) ? 'success' : 'default'} /></TableCell>
                                                    <TableCell align="right">
                                                        <IconButton onClick={(e) => handleMenuOpen(e, cat.id, 'category')}><MoreVertical size={18} /></IconButton>
                                                    </TableCell>
                                                </TableRow>
                                            ))
                                        ) : (
                                            groups.map((grp) => (
                                                <TableRow key={grp.id}>
                                                    <TableCell sx={{ fontWeight: 600 }}>{grp.name}</TableCell>
                                                    <TableCell>{categories.find(c => c.id === grp.category_id)?.name || '-'}</TableCell>
                                                    <TableCell><Chip label={grp.status || 'Active'} size="small" color={(grp.status === 'Active' || grp.is_active) ? 'success' : 'default'} /></TableCell>
                                                    <TableCell align="right">
                                                        <IconButton onClick={(e) => handleMenuOpen(e, grp.id, 'group')}><MoreVertical size={18} /></IconButton>
                                                    </TableCell>
                                                </TableRow>
                                            ))
                                        )}
                                    </TableBody>
                                </Table>
                            </TableContainer>
                        </Box>
                    )}

                    {sidebarTab === 2 && (
                        <Box>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                                <Typography variant="h6" fontWeight={800}>Menu Items</Typography>
                                <Button variant="contained" startIcon={<Plus size={18} />} onClick={() => setItemDialog(true)} sx={{ bgcolor: '#FF8C00' }}>Add Item</Button>
                            </Box>
                            <TableContainer component={Paper} sx={{ borderRadius: '16px' }}>
                                <Table>
                                    <TableHead sx={{ bgcolor: '#f8fafc' }}>
                                        <TableRow>
                                            <TableCell sx={{ fontWeight: 800 }}>Item Name</TableCell>
                                            <TableCell sx={{ fontWeight: 800 }}>Category</TableCell>
                                            <TableCell sx={{ fontWeight: 800 }}>Price</TableCell>
                                            <TableCell sx={{ fontWeight: 800 }}>Status</TableCell>
                                            <TableCell align="right" sx={{ fontWeight: 800 }}>Actions</TableCell>
                                        </TableRow>
                                    </TableHead>
                                    <TableBody>
                                        {items.map((item) => (
                                            <TableRow key={item.id}>
                                                <TableCell sx={{ fontWeight: 600 }}>{item.name}</TableCell>
                                                <TableCell>{item.category?.name}</TableCell>
                                                <TableCell>NPRs. {item.price}</TableCell>
                                                <TableCell><Chip label={item.status || (item.is_active === false ? 'Inactive' : 'Active')} size="small" color={(item.status === 'Active' || item.is_active !== false) ? 'success' : 'default'} /></TableCell>
                                                <TableCell align="right">
                                                    <IconButton onClick={(e) => handleMenuOpen(e, item.id, 'item')}><MoreVertical size={18} /></IconButton>
                                                </TableCell>
                                            </TableRow>
                                        ))}
                                    </TableBody>
                                </Table>
                            </TableContainer>
                        </Box>
                    )}

                </Box>
            </Box>

            {/* Common Action Menu */}
            <Menu anchorEl={anchorEl} open={Boolean(anchorEl)} onClose={handleMenuClose}>
                <MenuItem onClick={() => {
                    if (menuType === 'item') {
                        const item = items.find(i => i.id === selectedId);
                        setCurrentItem(item);
                        setItemDialog(true);
                    } else if (menuType === 'category') {
                        const cat = categories.find(c => c.id === selectedId);
                        setCurrentCategory(cat);
                        setCategoryDialog(true);
                    } else if (menuType === 'group') {
                        const grp = groups.find(g => g.id === selectedId);
                        setCurrentGroup(grp);
                        setGroupDialog(true);
                    }
                    handleMenuClose();
                }}>Edit</MenuItem>
                <MenuItem onClick={handleDelete} sx={{ color: 'error.main' }}>Delete</MenuItem>
            </Menu>

            {/* Dialogs */}
            <Dialog open={categoryDialog} onClose={() => setCategoryDialog(false)}>
                <DialogTitle>{currentCategory.id ? 'Edit Category' : 'Add Category'}</DialogTitle>
                <DialogContent sx={{ pt: 2, display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <TextField label="Category Name" fullWidth value={currentCategory.name} onChange={(e) => setCurrentCategory({ ...currentCategory, name: e.target.value })} />
                    <FormControl fullWidth>
                        <InputLabel>Type</InputLabel>
                        <Select label="Type" value={currentCategory.type} onChange={(e: any) => setCurrentCategory({ ...currentCategory, type: e.target.value })}>
                            <MenuItem value="KOT">KOT</MenuItem>
                            <MenuItem value="BOT">BOT</MenuItem>
                        </Select>
                    </FormControl>
                    <FormControl fullWidth>
                        <InputLabel>Status</InputLabel>
                        <Select label="Status" value={currentCategory.status || (currentCategory.is_active === false ? 'Inactive' : 'Active')} onChange={(e: any) => setCurrentCategory({ ...currentCategory, status: e.target.value })}>
                            <MenuItem value="Active">Active</MenuItem>
                            <MenuItem value="Inactive">Inactive</MenuItem>
                        </Select>
                    </FormControl>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setCategoryDialog(false)}>Cancel</Button>
                    <Button onClick={handleSaveCategory} variant="contained">Save</Button>
                </DialogActions>
            </Dialog>

            <Dialog open={groupDialog} onClose={() => setGroupDialog(false)}>
                <DialogTitle>{currentGroup.id ? 'Edit Group' : 'Add Group'}</DialogTitle>
                <DialogContent sx={{ pt: 2, display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <TextField label="Group Name" fullWidth value={currentGroup.name} onChange={(e) => setCurrentGroup({ ...currentGroup, name: e.target.value })} />
                    <FormControl fullWidth>
                        <InputLabel>Category</InputLabel>
                        <Select label="Category" value={currentGroup.category_id} onChange={(e: any) => setCurrentGroup({ ...currentGroup, category_id: e.target.value })}>
                            {categories.map(cat => <MenuItem key={cat.id} value={cat.id}>{cat.name}</MenuItem>)}
                        </Select>
                    </FormControl>
                    <FormControl fullWidth>
                        <InputLabel>Status</InputLabel>
                        <Select label="Status" value={currentGroup.status || (currentGroup.is_active === false ? 'Inactive' : 'Active')} onChange={(e: any) => setCurrentGroup({ ...currentGroup, status: e.target.value })}>
                            <MenuItem value="Active">Active</MenuItem>
                            <MenuItem value="Inactive">Inactive</MenuItem>
                        </Select>
                    </FormControl>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setGroupDialog(false)}>Cancel</Button>
                    <Button onClick={handleSaveGroup} variant="contained">Save</Button>
                </DialogActions>
            </Dialog>

            <Dialog open={itemDialog} onClose={() => setItemDialog(false)}>
                <DialogTitle>{currentItem.id ? 'Edit Item' : 'Add Item'}</DialogTitle>
                <DialogContent sx={{ pt: 2, display: 'flex', flexDirection: 'column', gap: 2, minWidth: 400 }}>
                    <TextField label="Item Name" fullWidth value={currentItem.name} onChange={(e) => setCurrentItem({ ...currentItem, name: e.target.value })} />
                    <TextField label="Price" type="number" fullWidth value={currentItem.price} onChange={(e) => setCurrentItem({ ...currentItem, price: e.target.value })} />
                    <FormControl fullWidth>
                        <InputLabel>Category</InputLabel>
                        <Select label="Category" value={currentItem.category_id} onChange={(e: any) => setCurrentItem({ ...currentItem, category_id: e.target.value })}>
                            {categories.map(cat => <MenuItem key={cat.id} value={cat.id}>{cat.name}</MenuItem>)}
                        </Select>
                    </FormControl>
                    <FormControl fullWidth>
                        <InputLabel>Group</InputLabel>
                        <Select label="Group" value={currentItem.group_id} onChange={(e: any) => setCurrentItem({ ...currentItem, group_id: e.target.value })}>
                            {groups.filter(g => g.category_id === currentItem.category_id).map(g => <MenuItem key={g.id} value={g.id}>{g.name}</MenuItem>)}
                        </Select>
                    </FormControl>
                    <FormControl fullWidth>
                        <InputLabel>Status</InputLabel>
                        <Select label="Status" value={currentItem.status || (currentItem.is_active === false ? 'Inactive' : 'Active')} onChange={(e: any) => setCurrentItem({ ...currentItem, status: e.target.value })}>
                            <MenuItem value="Active">Active</MenuItem>
                            <MenuItem value="Inactive">Inactive</MenuItem>
                        </Select>
                    </FormControl>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setItemDialog(false)}>Cancel</Button>
                    <Button onClick={handleSaveItem} variant="contained">Save</Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default POSSettings;
