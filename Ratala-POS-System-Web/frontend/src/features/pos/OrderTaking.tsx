import React, { useState, useEffect, useRef } from 'react';
import {
    Box,
    Typography,
    Paper,
    Button,
    Tabs,
    Tab,
    IconButton,
    Chip,
    List,
    ListItem,
    TextField,
    Grid,
    InputAdornment,
    Divider,
    CircularProgress,
    Dialog,
    DialogContent,
    DialogActions
} from '@mui/material';
import {
    ArrowLeft,
    Search,
    Plus,
    Minus,
    X,
    Trash2,
    ShoppingCart,
    ShoppingBasket,
    UserCircle,
    Printer,
    Download
} from 'lucide-react';
import { useNavigate, useParams, useLocation } from 'react-router-dom';
import { menuAPI, tablesAPI, ordersAPI, kotAPI, customersAPI } from '../../services/api';
import { useReactToPrint } from 'react-to-print';
import { useBranch } from '../../app/providers/BranchProvider';
import BillView from './billing/BillView';
import html2canvas from 'html2canvas';
import jsPDF from 'jspdf';
import { useNotification } from '../../app/providers/NotificationProvider';
import { useActivity } from '../../app/providers/ActivityProvider';

interface Category {
    id: number;
    name: string;
    type: string;
    image?: string;
}

interface MenuGroup {
    id: number;
    name: string;
    category_id: number;
    image?: string;
}

interface MenuItem {
    id: number;
    name: string;
    category_id: number;
    group_id?: number;
    price: number;
    image?: string;
    status: string;
}

interface OrderItem {
    id: number;
    name: string;
    price: number;
    quantity: number;
    item_id: number;
}

const OrderTaking: React.FC = () => {
    const navigate = useNavigate();
    const { tableId } = useParams<{ tableId: string }>();
    const location = useLocation();
    const tableInfo = location.state?.table;
    const { currentBranch } = useBranch();
    const { showAlert } = useNotification();
    const { logActivity } = useActivity();

    const [loading, setLoading] = useState(true);
    const [categories, setCategories] = useState<Category[]>([]);
    const [groups, setGroups] = useState<MenuGroup[]>([]);
    const [allItems, setAllItems] = useState<MenuItem[]>([]);

    const [selectedCategoryId, setSelectedCategoryId] = useState<number | null>(null);
    const [selectedGroupId, setSelectedGroupId] = useState<number | null>(null);
    const [searchTerm, setSearchTerm] = useState('');

    const [orderItems, setOrderItems] = useState<OrderItem[]>([]);
    const [table, setTable] = useState<any>(tableInfo);
    const [existingOrder, setExistingOrder] = useState<any>(null);

    const [customers, setCustomers] = useState<any[]>([]);
    const [selectedCustomer, setSelectedCustomer] = useState<any>(null);
    const [customerSearch, setCustomerSearch] = useState('');

    const [billDialogOpen, setBillDialogOpen] = useState(false);
    const billRef = useRef<HTMLDivElement>(null);

    const handlePrint = useReactToPrint({
        contentRef: billRef,
        documentTitle: `Bill_Draft`,
        onAfterPrint: () => setBillDialogOpen(false),
        onPrintError: () => showAlert("Printer not found or error occurred while printing.", "error")
    });

    const handleDownloadPDF = async () => {
        if (!billRef.current) return;
        try {
            const canvas = await html2canvas(billRef.current, { scale: 2 });
            const imgData = canvas.toDataURL('image/png');
            const pdf = new jsPDF({ unit: 'mm', format: [80, 200] });
            const imgProps = pdf.getImageProperties(imgData);
            const pdfWidth = pdf.internal.pageSize.getWidth();
            const pdfHeight = (imgProps.height * pdfWidth) / imgProps.width;
            pdf.addImage(imgData, 'PNG', 0, 0, pdfWidth, pdfHeight);
            pdf.save(`Bill_Draft.pdf`);
        } catch (error) {
            console.error("PDF Export Error:", error);
            showAlert("Failed to generate PDF", "error");
        }
    };

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setLoading(true);
            const [catsRes, groupsRes, itemsRes, custRes] = await Promise.all([
                menuAPI.getCategories(),
                menuAPI.getGroups(),
                menuAPI.getItems(),
                customersAPI.getAll()
            ]);

            setCustomers(custRes.data || []);

            const activeCategories = catsRes.data.filter((c: any) => c.is_active !== false);
            const activeGroups = groupsRes.data.filter((g: any) => g.is_active !== false);
            const activeItems = itemsRes.data.filter((i: any) => i.is_active !== false);

            setCategories(activeCategories);
            setGroups(activeGroups);
            setAllItems(activeItems);

            if (activeCategories.length > 0) {
                setSelectedCategoryId(activeCategories[0].id);
                const firstGroup = groupsRes.data.find((g: MenuGroup) => g.category_id === activeCategories[0].id);
                if (firstGroup) {
                    setSelectedGroupId(firstGroup.id);
                }
            }

            let currentTable = table;
            if (!currentTable && tableId) {
                const tableRes = await tablesAPI.getById(parseInt(tableId));
                currentTable = tableRes.data;
                setTable(currentTable);
            }

            // Check for active order (Pending or Draft) for this table
            if (currentTable) {
                const ordersRes = await ordersAPI.getAll();
                const activeOrder = ordersRes.data.find((o: any) =>
                    o.table_id === currentTable.id &&
                    (o.status === 'Pending' || o.status === 'Draft' || o.status === 'In Progress')
                );

                if (activeOrder) {
                    setExistingOrder(activeOrder);
                    const mappedItems = activeOrder.items.map((item: any) => ({
                        id: item.id,
                        name: item.menu_item?.name || 'Unknown',
                        price: item.price,
                        quantity: item.quantity,
                        item_id: item.menu_item_id
                    }));
                    setOrderItems(mappedItems);
                    if (activeOrder.customer) {
                        setSelectedCustomer(activeOrder.customer);
                    }
                }
            }
        } catch (error) {
            console.error("Error loading menu data:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleCategoryChange = (categoryId: number) => {
        setSelectedCategoryId(categoryId);
        const firstGroup = groups.find(g => g.category_id === categoryId);
        setSelectedGroupId(firstGroup ? firstGroup.id : null);
    };

    const filteredGroups = groups.filter(g => g.category_id === selectedCategoryId && (g as any).is_active !== false);

    const filteredItems = allItems.filter(item => {
        const matchesSearch = item.name.toLowerCase().includes(searchTerm.toLowerCase());
        const matchesGroup = selectedGroupId ? item.group_id === selectedGroupId : item.category_id === selectedCategoryId;
        return matchesSearch && matchesGroup;
    });

    const addToOrder = (item: MenuItem) => {
        setOrderItems(prev => {
            const existing = prev.find(oi => oi.item_id === item.id);
            if (existing) {
                return prev.map(oi => oi.item_id === item.id ? { ...oi, quantity: oi.quantity + 1 } : oi);
            }
            return [...prev, {
                id: Date.now(), // temporary ID
                name: item.name,
                price: item.price,
                quantity: 1,
                item_id: item.id
            }];
        });
    };

    const updateQuantity = (itemId: number, delta: number) => {
        setOrderItems(prev => prev.map(oi => {
            if (oi.item_id === itemId) {
                const newQty = Math.max(0, oi.quantity + delta);
                return { ...oi, quantity: newQty };
            }
            return oi;
        }).filter(oi => oi.quantity > 0));
    };

    const total = orderItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);

    const handleSaveDraft = async () => {
        if (orderItems.length === 0) return;

        try {
            setLoading(true);
            const orderPayload = {
                table_id: table?.id,
                customer_id: selectedCustomer?.id,
                order_type: table?.is_hold_table === 'Yes' ? 'Takeaway' : 'Table',
                status: 'Draft',
                gross_amount: total,
                net_amount: Math.round(total * 1.05),
                discount: 0,
                items: orderItems.map(item => ({
                    menu_item_id: item.item_id,
                    quantity: item.quantity,
                    price: item.price,
                    subtotal: item.price * item.quantity,
                    notes: ''
                }))
            };

            if (existingOrder) {
                await ordersAPI.update(existingOrder.id, orderPayload);
            } else {
                await ordersAPI.create(orderPayload);
            }

            // For Draft, we DON'T create KOTs or change table status to Occupied
            // unless it's already occupied.

            logActivity('Draft Saved', `Order draft saved for ${table?.table_id || 'Table'}`, 'order');
            showAlert("Order saved as draft successfully!", "success");
            navigate('/pos');
        } catch (error: any) {
            console.error("Error saving draft:", error);
            showAlert(error.response?.data?.detail || "Error saving draft", "error");
        } finally {
            setLoading(false);
        }
    };

    const handlePlaceOrder = async () => {
        if (orderItems.length === 0) return;

        try {
            setLoading(true);

            // 1. Create or Update Order
            let orderId;
            const orderPayload = {
                table_id: table?.id,
                customer_id: selectedCustomer?.id,
                order_type: table?.is_hold_table === 'Yes' ? 'Takeaway' : 'Table',
                status: 'Pending',
                gross_amount: total,
                net_amount: Math.round(total * 1.05), // Including 5% SC for now
                discount: 0,
                items: orderItems.map(item => ({
                    menu_item_id: item.item_id,
                    quantity: item.quantity,
                    price: item.price,
                    subtotal: item.price * item.quantity,
                    notes: ''
                }))
            };

            if (existingOrder) {
                await ordersAPI.update(existingOrder.id, orderPayload);
                orderId = existingOrder.id;
            } else {
                const orderRes = await ordersAPI.create(orderPayload);
                orderId = orderRes.data.id;
            }

            // 2. Create KOT/BOT only for NEW items or changed quantities
            const itemsToSentToKot = orderItems.filter(item => {
                const existingItem = existingOrder?.items.find((ei: any) => ei.menu_item_id === item.item_id);
                return !existingItem || item.quantity > existingItem.quantity;
            }).map(item => {
                const existingItem = existingOrder?.items.find((ei: any) => ei.menu_item_id === item.item_id);
                return {
                    ...item,
                    quantity: existingItem ? item.quantity - existingItem.quantity : item.quantity
                };
            });

            if (itemsToSentToKot.length > 0) {
                const kotItems = itemsToSentToKot.filter(item => {
                    const menuItem = allItems.find(i => i.id === item.item_id);
                    const category = categories.find(c => c.id === menuItem?.category_id);
                    return category?.type === 'KOT';
                });

                const botItems = itemsToSentToKot.filter(item => {
                    const menuItem = allItems.find(i => i.id === item.item_id);
                    const category = categories.find(c => c.id === menuItem?.category_id);
                    return category?.type === 'BOT';
                });

                if (kotItems.length > 0) {
                    await kotAPI.create({
                        order_id: orderId,
                        kot_type: 'KOT',
                        items: kotItems.map(item => ({
                            menu_item_id: item.item_id,
                            quantity: item.quantity,
                            notes: ''
                        }))
                    });
                }

                if (botItems.length > 0) {
                    await kotAPI.create({
                        order_id: orderId,
                        kot_type: 'BOT',
                        items: botItems.map(item => ({
                            menu_item_id: item.item_id,
                            quantity: item.quantity,
                            notes: ''
                        }))
                    });
                }
            }

            // 3. Update Table Status to Occupied
            if (table && table.id && !existingOrder) {
                await tablesAPI.update(table.id, {
                    ...table,
                    status: 'Occupied'
                });
            }

            logActivity(existingOrder ? 'Order Updated' : 'New Order',
                `${existingOrder ? 'Updated' : 'Placed'} order for ${table?.table_id || 'Table'} - Rs. ${total}`, 'order');
            showAlert(existingOrder ? "Order updated successfully!" : "Order placed successfully!", "success");
            navigate('/pos');
        } catch (error: any) {
            console.error("Error placing order:", error);
            showAlert(error.response?.data?.detail || "Error placing order", "error");
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
                <CircularProgress sx={{ color: '#FF8C00' }} />
            </Box>
        );
    }

    return (
        <Box sx={{ display: 'flex', height: '100vh', bgcolor: '#f8fafc', overflow: 'hidden' }}>
            {/* Left: Item Selection */}
            <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', bgcolor: 'white', minWidth: 0 }}>
                {/* Header */}
                <Box sx={{ p: 2, borderBottom: '1px solid #f1f5f9', display: 'flex', alignItems: 'center', gap: 2 }}>
                    <IconButton onClick={() => navigate(-1)} sx={{ bgcolor: '#f8fafc' }}>
                        <ArrowLeft size={20} />
                    </IconButton>
                    <Box>
                        <Typography variant="h6" fontWeight={800} sx={{ lineHeight: 1.2 }}>
                            {table?.is_hold_table ? table.hold_table_name : `Table ${table?.table_id || tableId}`}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                            Order Taking
                        </Typography>
                    </Box>

                    <TextField
                        size="small"
                        placeholder="Search items..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        sx={{ ml: 'auto', width: 250, '& .MuiOutlinedInput-root': { borderRadius: '20px', bgcolor: '#f8fafc' } }}
                        InputProps={{
                            startAdornment: (
                                <InputAdornment position="start">
                                    <Search size={18} color="#94a3b8" />
                                </InputAdornment>
                            )
                        }}
                    />
                </Box>

                {/* Categories Tabs */}
                <Box sx={{ borderBottom: '1px solid #f1f5f9', px: 1 }}>
                    <Tabs
                        value={selectedCategoryId}
                        onChange={(_, v) => handleCategoryChange(v)}
                        variant="scrollable"
                        scrollButtons="auto"
                        sx={{
                            minHeight: '48px',
                            '& .MuiTab-root': {
                                textTransform: 'none',
                                fontWeight: 700,
                                fontSize: '14px',
                                color: '#64748b',
                                minHeight: '48px',
                                px: 3,
                                '&.Mui-selected': { color: '#FF8C00' }
                            },
                            '& .MuiTabs-indicator': { bgcolor: '#FF8C00', height: '3px', borderRadius: '3px 3px 0 0' }
                        }}
                    >
                        {categories.map(cat => (
                            <Tab key={cat.id} label={cat.name} value={cat.id} />
                        ))}
                    </Tabs>
                </Box>

                <Box sx={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
                    {/* Subcategories (Groups) */}
                    <Box sx={{
                        width: 180,
                        borderRight: '1px solid #f1f5f9',
                        bgcolor: '#f8fafc',
                        overflowY: 'auto',
                        p: 1
                    }}>
                        <List sx={{ p: 0, display: 'flex', flexDirection: 'column', gap: 1 }}>
                            <ListItem
                                onClick={() => setSelectedGroupId(null)}
                                sx={{
                                    borderRadius: '12px',
                                    cursor: 'pointer',
                                    py: 1.5,
                                    px: 2,
                                    mb: 0.5,
                                    bgcolor: selectedGroupId === null ? 'white' : 'transparent',
                                    boxShadow: selectedGroupId === null ? '0 2px 8px rgba(0,0,0,0.05)' : 'none',
                                    border: selectedGroupId === null ? '1px solid #FF8C00' : '1px solid transparent',
                                    transition: 'all 0.2s',
                                    '&:hover': { bgcolor: selectedGroupId === null ? 'white' : '#f1f5f9' }
                                }}
                            >
                                <Typography
                                    sx={{
                                        fontWeight: 700,
                                        fontSize: '13px',
                                        color: selectedGroupId === null ? '#FF8C00' : '#64748b'
                                    }}
                                >
                                    All Items
                                </Typography>
                            </ListItem>

                            {filteredGroups.map(group => (
                                <ListItem
                                    key={group.id}
                                    onClick={() => setSelectedGroupId(group.id)}
                                    sx={{
                                        borderRadius: '12px',
                                        cursor: 'pointer',
                                        py: 1.5,
                                        px: 2,
                                        mb: 0.5,
                                        bgcolor: selectedGroupId === group.id ? 'white' : 'transparent',
                                        boxShadow: selectedGroupId === group.id ? '0 2px 8px rgba(0,0,0,0.05)' : 'none',
                                        border: selectedGroupId === group.id ? '1px solid #FF8C00' : '1px solid transparent',
                                        transition: 'all 0.2s',
                                        '&:hover': { bgcolor: selectedGroupId === group.id ? 'white' : '#f1f5f9' }
                                    }}
                                >
                                    <Typography
                                        sx={{
                                            fontWeight: 700,
                                            fontSize: '13px',
                                            color: selectedGroupId === group.id ? '#FF8C00' : '#64748b',
                                            overflow: 'hidden',
                                            textOverflow: 'ellipsis',
                                            whiteSpace: 'nowrap'
                                        }}
                                    >
                                        {group.name}
                                    </Typography>
                                </ListItem>
                            ))}
                        </List>
                    </Box>

                    {/* Items Grid */}
                    <Box sx={{ flexGrow: 1, p: 2, overflowY: 'auto' }}>
                        {filteredItems.length > 0 ? (
                            <Grid container spacing={2}>
                                {filteredItems.map(item => (
                                    <Grid key={item.id} size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
                                        <Paper
                                            elevation={0}
                                            onClick={() => addToOrder(item)}
                                            sx={{
                                                p: 2,
                                                height: '100%',
                                                display: 'flex',
                                                flexDirection: 'column',
                                                justifyContent: 'space-between',
                                                borderRadius: '16px',
                                                border: '1px solid #f1f5f9',
                                                cursor: 'pointer',
                                                transition: 'all 0.2s',
                                                '&:hover': {
                                                    borderColor: '#FF8C00',
                                                    boxShadow: '0 4px 12px rgba(255,140,0,0.1)',
                                                    transform: 'translateY(-2px)'
                                                }
                                            }}
                                        >
                                            <Box>
                                                <Box sx={{
                                                    width: '100%',
                                                    height: 100,
                                                    bgcolor: '#f8fafc',
                                                    borderRadius: '12px',
                                                    display: 'flex',
                                                    alignItems: 'center',
                                                    justifyContent: 'center',
                                                    mb: 1.5,
                                                    fontSize: '40px'
                                                }}>
                                                    {item.image || '🍽️'}
                                                </Box>
                                                <Typography fontWeight={700} fontSize="14px" sx={{ mb: 0.5, lineHeight: 1.3 }}>
                                                    {item.name}
                                                </Typography>
                                            </Box>
                                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mt: 1 }}>
                                                <Typography fontWeight={800} color="#FF8C00" fontSize="16px">
                                                    NPRs. {item.price}
                                                </Typography>
                                                <Box sx={{ bgcolor: '#fff7ed', p: 0.5, borderRadius: '8px' }}>
                                                    <Plus size={16} color="#FF8C00" />
                                                </Box>
                                            </Box>
                                        </Paper>
                                    </Grid>
                                ))}
                            </Grid>
                        ) : (
                            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100%', opacity: 0.5 }}>
                                <ShoppingBasket size={48} color="#94a3b8" />
                                <Typography variant="body1" sx={{ mt: 2, fontWeight: 600 }}>No items found</Typography>
                                <Typography variant="body2" color="text.secondary">Try a different group or search term</Typography>
                            </Box>
                        )}
                    </Box>
                </Box>
            </Box>

            {/* Right: Order Summary */}
            <Box sx={{
                width: 380,
                bgcolor: 'white',
                borderLeft: '1px solid #f1f5f9',
                display: 'flex',
                flexDirection: 'column',
                boxShadow: '-4px 0 15px rgba(0,0,0,0.02)'
            }}>
                <Box sx={{ p: 3, borderBottom: '1px solid #f1f5f9' }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                        <Typography variant="h6" fontWeight={800} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            Current Order <Chip label={orderItems.length} size="small" sx={{ bgcolor: '#FF8C00', color: 'white', fontWeight: 800, height: 20 }} />
                        </Typography>
                        <IconButton size="small" onClick={() => setOrderItems([])} disabled={orderItems.length === 0}>
                            <Trash2 size={18} color="#94a3b8" />
                        </IconButton>
                    </Box>

                    {/* Customer Selection */}
                    <Box sx={{ mb: 2, position: 'relative' }}>
                        {selectedCustomer ? (
                            <Box sx={{
                                p: 1.5,
                                borderRadius: '12px',
                                bgcolor: '#fff7ed',
                                border: '1px solid #ffedd5',
                                display: 'flex',
                                alignItems: 'center',
                                gap: 1.5
                            }}>
                                <UserCircle size={20} color="#FF8C00" />
                                <Box sx={{ flex: 1 }}>
                                    <Typography variant="body2" fontWeight={800} color="#9a3412">{selectedCustomer.name}</Typography>
                                    <Typography variant="caption" color="#c2410c">{selectedCustomer.phone || 'No phone'}</Typography>
                                </Box>
                                <IconButton size="small" onClick={() => setSelectedCustomer(null)}>
                                    <X size={16} color="#c2410c" />
                                </IconButton>
                            </Box>
                        ) : (
                            <Box>
                                <TextField
                                    fullWidth
                                    size="small"
                                    placeholder="Add Customer (Name or Phone)"
                                    value={customerSearch}
                                    onChange={(e) => setCustomerSearch(e.target.value)}
                                    InputProps={{
                                        startAdornment: <InputAdornment position="start"><Search size={16} /></InputAdornment>,
                                        sx: { borderRadius: '12px', fontSize: '0.85rem' }
                                    }}
                                />
                                {customerSearch && (
                                    <Paper sx={{
                                        position: 'absolute',
                                        top: '100%',
                                        left: 0,
                                        right: 0,
                                        zIndex: 10,
                                        mt: 0.5,
                                        maxHeight: 200,
                                        overflow: 'auto',
                                        borderRadius: '12px',
                                        boxShadow: '0 10px 25px rgba(0,0,0,0.1)',
                                        border: '1px solid #f1f5f9'
                                    }}>
                                        <List sx={{ p: 0 }}>
                                            {customers
                                                .filter(c =>
                                                    c.name.toLowerCase().includes(customerSearch.toLowerCase()) ||
                                                    (c.phone && c.phone.includes(customerSearch))
                                                )
                                                .map(c => (
                                                    <ListItem
                                                        key={c.id}
                                                        onClick={() => {
                                                            setSelectedCustomer(c);
                                                            setCustomerSearch('');
                                                        }}
                                                        sx={{
                                                            cursor: 'pointer',
                                                            '&:hover': { bgcolor: '#f8fafc' },
                                                            borderBottom: '1px solid #f1f5f9',
                                                            py: 1
                                                        }}
                                                    >
                                                        <Box>
                                                            <Typography variant="body2" fontWeight={700}>{c.name}</Typography>
                                                            <Typography variant="caption" color="text.secondary">{c.phone}</Typography>
                                                        </Box>
                                                    </ListItem>
                                                ))}
                                            <ListItem
                                                onClick={async () => {
                                                    try {
                                                        const res = await customersAPI.create({ name: customerSearch });
                                                        setSelectedCustomer(res.data);
                                                        setCustomers(prev => [...prev, res.data]);
                                                        setCustomerSearch('');
                                                    } catch (error) {
                                                        showAlert("Error adding customer", "error");
                                                    }
                                                }}
                                                sx={{
                                                    cursor: 'pointer',
                                                    '&:hover': { bgcolor: '#fff7ed' },
                                                    py: 1,
                                                    bgcolor: '#f8fafc'
                                                }}
                                            >
                                                <Typography variant="body2" fontWeight={700} color="#FF8C00">
                                                    + Quick Add "{customerSearch}"
                                                </Typography>
                                            </ListItem>
                                        </List>
                                    </Paper>
                                )}
                            </Box>
                        )}
                    </Box>

                    <Box sx={{ display: 'flex', gap: 1 }}>
                        <Button
                            variant="contained"
                            size="small"
                            sx={{
                                bgcolor: '#FF8C00',
                                boxShadow: 'none',
                                borderRadius: '20px',
                                textTransform: 'none',
                                fontWeight: 700,
                                '&:hover': { bgcolor: '#e67e00', boxShadow: 'none' }
                            }}
                        >
                            Dine In
                        </Button>
                        <Button
                            variant="outlined"
                            size="small"
                            sx={{
                                borderRadius: '20px',
                                textTransform: 'none',
                                fontWeight: 700,
                                color: '#64748b',
                                borderColor: '#e2e8f0'
                            }}
                        >
                            Takeaway
                        </Button>
                    </Box>
                </Box>

                <Box sx={{ flex: 1, p: 2, overflowY: 'auto' }}>
                    {orderItems.length > 0 ? (
                        orderItems.map((item) => (
                            <Paper
                                key={item.item_id}
                                elevation={0}
                                sx={{
                                    p: 2,
                                    mb: 1.5,
                                    borderRadius: '16px',
                                    border: '1px solid #f1f5f9',
                                    bgcolor: '#f8fafc',
                                    transition: 'all 0.2s',
                                    '&:hover': { border: '1px solid #FF8C00' }
                                }}
                            >
                                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                    <Typography fontWeight={700} fontSize="14px">{item.name}</Typography>
                                    <Typography fontWeight={800} color="#1e293b">NPRs. {item.price * item.quantity}</Typography>
                                </Box>
                                <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 1.5 }}>
                                    NPRs. {item.price} / item
                                </Typography>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                    <Box sx={{ display: 'flex', alignItems: 'center', bgcolor: 'white', borderRadius: '10px', p: 0.5, border: '1px solid #e2e8f0' }}>
                                        <IconButton
                                            size="small"
                                            onClick={() => updateQuantity(item.item_id, -1)}
                                            sx={{ p: 0.5, color: '#FF8C00' }}
                                        >
                                            <Minus size={16} />
                                        </IconButton>
                                        <Typography sx={{ width: 30, textAlign: 'center', fontWeight: 800, fontSize: '14px' }}>
                                            {item.quantity}
                                        </Typography>
                                        <IconButton
                                            size="small"
                                            onClick={() => updateQuantity(item.item_id, 1)}
                                            sx={{ p: 0.5, color: '#FF8C00' }}
                                        >
                                            <Plus size={16} />
                                        </IconButton>
                                    </Box>
                                    <IconButton
                                        size="small"
                                        onClick={() => updateQuantity(item.item_id, -item.quantity)}
                                        sx={{ ml: 'auto', bgcolor: '#fff1f2', color: '#ef4444', p: 0.8, '&:hover': { bgcolor: '#ffe4e6' } }}
                                    >
                                        <X size={16} />
                                    </IconButton>
                                </Box>
                            </Paper>
                        ))
                    ) : (
                        <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', opacity: 0.3 }}>
                            <ShoppingCart size={64} color="#94a3b8" />
                            <Typography sx={{ mt: 2, fontWeight: 700 }}>Order is empty</Typography>
                        </Box>
                    )}
                </Box>

                <Box sx={{ p: 3, bgcolor: '#f8fafc', borderTop: '1px solid #f1f5f9' }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                        <Typography color="text.secondary" fontWeight={500}>Subtotal</Typography>
                        <Typography fontWeight={700}>NPRs. {total}</Typography>
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                        <Typography color="text.secondary" fontWeight={500}>Service Charge (5%)</Typography>
                        <Typography fontWeight={700}>NPRs. {Math.round(total * 0.05)}</Typography>
                    </Box>
                    <Divider sx={{ mb: 2, borderStyle: 'dashed' }} />
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
                        <Typography variant="h6" fontWeight={800}>Total Payable</Typography>
                        <Typography variant="h6" fontWeight={800} color="#FF8C00">NPRs. {Math.round(total * 1.05)}</Typography>
                    </Box>

                    <Button
                        fullWidth
                        variant="contained"
                        disabled={orderItems.length === 0}
                        onClick={handlePlaceOrder}
                        sx={{
                            bgcolor: '#FF8C00',
                            mb: 1.5,
                            py: 1.8,
                            fontWeight: 800,
                            fontSize: '16px',
                            borderRadius: '16px',
                            boxShadow: '0 8px 20px rgba(255,140,0,0.2)',
                            textTransform: 'none',
                            '&:hover': { bgcolor: '#e67e00', boxShadow: '0 10px 25px rgba(255,140,0,0.3)' }
                        }}
                    >
                        Place Order
                    </Button>
                    <Box sx={{ display: 'flex', gap: 1.5 }}>
                        <Button
                            fullWidth
                            variant="outlined"
                            onClick={handleSaveDraft}
                            disabled={orderItems.length === 0}
                            sx={{
                                borderColor: '#e2e8f0',
                                color: '#64748b',
                                py: 1.2,
                                borderRadius: '12px',
                                textTransform: 'none',
                                fontWeight: 700,
                                '&:hover': { bgcolor: 'white', borderColor: '#FF8C00', color: '#FF8C00' }
                            }}
                        >
                            Draft
                        </Button>
                        <Button
                            fullWidth
                            variant="outlined"
                            onClick={() => setBillDialogOpen(true)}
                            startIcon={<Printer size={16} />}
                            disabled={orderItems.length === 0}
                            sx={{
                                borderColor: '#e2e8f0',
                                color: '#64748b',
                                py: 1.2,
                                borderRadius: '12px',
                                textTransform: 'none',
                                fontWeight: 700,
                                '&:hover': { bgcolor: 'white', borderColor: '#FF8C00', color: '#FF8C00' }
                            }}
                        >
                            Print
                        </Button>
                    </Box>
                </Box>
            </Box>

            {/* Bill Preview Dialog */}
            <Dialog
                open={billDialogOpen}
                onClose={() => setBillDialogOpen(false)}
                maxWidth="xs"
                fullWidth
                PaperProps={{ sx: { borderRadius: '16px' } }}
            >
                <Box sx={{ p: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #f1f5f9' }}>
                    <Typography variant="h6" fontWeight={800}>Bill Preview</Typography>
                    <IconButton onClick={() => setBillDialogOpen(false)} size="small"><X size={20} /></IconButton>
                </Box>
                <DialogContent sx={{ p: 0, bgcolor: '#f8fafc' }}>
                    <Box sx={{ p: 2 }}>
                        <Paper elevation={0} sx={{ p: 0, overflow: 'hidden', border: '1px solid #e2e8f0', borderRadius: '8px' }}>
                            <BillView
                                ref={billRef}
                                branch={currentBranch}
                                order={{
                                    order_number: 'DRAFT',
                                    created_at: new Date().toISOString(),
                                    table: { table_id: tableId || 'N/A' },
                                    order_type: tableId ? 'Dine-in' : 'Takeaway',
                                    customer: selectedCustomer,
                                    items: orderItems.map(item => ({
                                        id: item.item_id,
                                        menu_item: { name: item.name },
                                        quantity: item.quantity,
                                        price: item.price,
                                        subtotal: item.quantity * item.price
                                    })),
                                    gross_amount: total,
                                    net_amount: Math.round(total * 1.05),
                                    discount: 0
                                }}
                            />
                        </Paper>
                    </Box>
                </DialogContent>
                <DialogActions sx={{ p: 2, gap: 1 }}>
                    <Button
                        fullWidth
                        variant="outlined"
                        startIcon={<Download size={18} />}
                        onClick={handleDownloadPDF}
                        sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 700 }}
                    >
                        Save as PDF
                    </Button>
                    <Button
                        fullWidth
                        variant="contained"
                        startIcon={<Printer size={18} />}
                        onClick={() => handlePrint()}
                        sx={{ borderRadius: '10px', bgcolor: '#FF8C00', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', fontWeight: 700 }}
                    >
                        Print Bill
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default OrderTaking;
