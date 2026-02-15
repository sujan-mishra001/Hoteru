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
    DialogTitle,
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
    Download,
    Armchair,
    ShoppingBag,
    Bike,
    ArrowRightLeft
} from 'lucide-react';
import { useNavigate, useParams, useLocation } from 'react-router-dom';
import { menuAPI, tablesAPI, ordersAPI, kotAPI, customersAPI, settingsAPI, API_BASE_URL } from '../../services/api';
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
    const { customOrderType, deliveryPartnerId, orderId, preSelectedCustomer } = location.state || {};

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
    const [selectedCustomer, setSelectedCustomer] = useState<any>(preSelectedCustomer || null);
    const [customerSearch, setCustomerSearch] = useState('');
    const [orderType, setOrderType] = useState<string>(customOrderType || (tableInfo?.is_hold_table === 'Yes' ? 'Takeaway' : 'Table'));
    const [deliveryCharge, setDeliveryCharge] = useState<number>(0);
    const [discountPercent, setDiscountPercent] = useState<number>(0);

    const [billDialogOpen, setBillDialogOpen] = useState(false);
    const [changeTableDialogOpen, setChangeTableDialogOpen] = useState(false);
    const [allTables, setAllTables] = useState<any[]>([]);
    const [companySettings, setCompanySettings] = useState<any>(null);
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
            const [catsRes, groupsRes, itemsRes, custRes, settingsRes] = await Promise.all([
                menuAPI.getCategories(),
                menuAPI.getGroups(),
                menuAPI.getItems(),
                customersAPI.getAll(),
                settingsAPI.getCompanySettings()
            ]);

            setCompanySettings(settingsRes.data);
            setCustomers(custRes.data || []);

            const activeCategories = catsRes.data.filter((c: any) => c.is_active !== false);
            const activeGroups = groupsRes.data.filter((g: any) => g.is_active !== false);
            const activeItems = itemsRes.data.filter((i: any) => i.is_active !== false);

            setCategories(activeCategories);
            setGroups(activeGroups);
            setAllItems(activeItems);

            if (activeCategories.length > 0) {
                setSelectedCategoryId(activeCategories[0].id);
                // Default to "All Items" (null) instead of auto-selecting the first group
                setSelectedGroupId(null);
            }

            let currentTable = table;
            if (!currentTable && tableId) {
                const tableRes = await tablesAPI.getById(parseInt(tableId));
                currentTable = tableRes.data;
                setTable(currentTable);
            }

            // Find active order (Pending or Draft) 
            let activeOrder = null;
            if (orderId) {
                const orderRes = await ordersAPI.getById(orderId);
                activeOrder = orderRes.data;
            } else if (currentTable) {
                const ordersRes = await ordersAPI.getAll();
                activeOrder = ordersRes.data.find((o: any) =>
                    o.table_id === currentTable.id &&
                    (o.status === 'Pending' || o.status === 'Draft' || o.status === 'In Progress')
                );
            }

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
                if (activeOrder.order_type) {
                    setOrderType(activeOrder.order_type);
                }
                if (activeOrder.discount > 0 && activeOrder.gross_amount > 0) {
                    setDiscountPercent(Math.round((activeOrder.discount * 100) / activeOrder.gross_amount));
                }
                if (activeOrder.delivery_charge) {
                    setDeliveryCharge(activeOrder.delivery_charge);
                }
            }
        } catch (error) {
            console.error("Error loading menu data:", error);
        } finally {
            setLoading(false);
        }
    };

    const loadTables = async () => {
        try {
            const res = await tablesAPI.getAll();
            setAllTables(res.data || []);
        } catch (error) {
            console.error("Error loading tables:", error);
        }
    };

    const handleChangeTable = async (newTable: any) => {
        if (!existingOrder || !newTable) return;
        try {
            setLoading(true);
            await ordersAPI.changeTable(existingOrder.id, newTable.id);
            setTable(newTable);
            setChangeTableDialogOpen(false);
            showAlert(`Moved order to Table ${newTable.table_id}`, "success");
            logActivity('Table Changed', `Order ${existingOrder.order_number} moved from Table ${table?.table_id} to Table ${newTable.table_id}`, 'order');
        } catch (error: any) {
            showAlert(error.response?.data?.detail || "Error changing table", "error");
        } finally {
            setLoading(false);
        }
    };

    const handleCategoryChange = (categoryId: number) => {
        setSelectedCategoryId(categoryId);
        // Default to "All Items" (null) when changing category
        setSelectedGroupId(null);
    };

    const filteredGroups = groups.filter(g => g.category_id === selectedCategoryId && (g as any).is_active !== false);

    const filteredItems = allItems.filter(item => {
        const matchesSearch = item.name.toLowerCase().includes(searchTerm.toLowerCase());

        // If user is searching, filter globally across all items
        if (searchTerm.trim() !== '') {
            return matchesSearch;
        }

        // Otherwise, filter by selected category/group
        const matchesGroup = selectedGroupId ? item.group_id === selectedGroupId : item.category_id === selectedCategoryId;
        return matchesGroup;
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
                order_type: orderType,
                status: 'Draft',
                gross_amount: total,
                service_charge_amount: Math.round((total - (Math.round(total * discountPercent / 100))) * (companySettings?.service_charge_rate || 0) / 100 * 100) / 100,
                tax_amount: Math.round(((total - (Math.round(total * discountPercent / 100))) + ((total - (Math.round(total * discountPercent / 100))) * (companySettings?.service_charge_rate || 0) / 100)) * (companySettings?.tax_rate || 0) / 100 * 100) / 100,
                net_amount: Math.round((total - (Math.round(total * discountPercent / 100))) * (1 + (companySettings?.service_charge_rate || 0) / 100) * (1 + (companySettings?.tax_rate || 0) / 100) + deliveryCharge),
                discount: Math.round(total * discountPercent / 100),
                delivery_charge: deliveryCharge,
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
                delivery_partner_id: deliveryPartnerId ? parseInt(deliveryPartnerId) : null,
                order_type: orderType,
                status: 'Pending',
                gross_amount: total,
                service_charge_amount: Math.round((total - (Math.round(total * discountPercent / 100))) * (companySettings?.service_charge_rate || 0) / 100 * 100) / 100,
                tax_amount: Math.round(((total - (Math.round(total * discountPercent / 100))) + ((total - (Math.round(total * discountPercent / 100))) * (companySettings?.service_charge_rate || 0) / 100)) * (companySettings?.tax_rate || 0) / 100 * 100) / 100,
                net_amount: Math.round((total - (Math.round(total * discountPercent / 100))) * (1 + (companySettings?.service_charge_rate || 0) / 100) * (1 + (companySettings?.tax_rate || 0) / 100) + deliveryCharge),
                discount: Math.round(total * discountPercent / 100),
                delivery_charge: deliveryCharge,
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
                <CircularProgress sx={{ color: '#FFC107' }} />
            </Box>
        );
    }

    return (
        <Box sx={{
            display: 'flex',
            flexDirection: { xs: 'column', md: 'row' },
            height: '100vh',
            bgcolor: '#f8fafc',
            overflow: 'hidden'
        }}>
            {/* Left: Item Selection */}
            <Box sx={{
                flex: 1,
                display: 'flex',
                flexDirection: 'column',
                bgcolor: 'white',
                minWidth: 0,
                height: { xs: '60%', md: '100%' }, // On mobile, limit height of left part
                borderBottom: { xs: '1px solid #f1f5f9', md: 'none' }
            }}>
                {/* Header */}
                <Box sx={{ p: 2, borderBottom: '1px solid #f1f5f9', display: 'flex', alignItems: 'center', gap: 2 }}>
                    <IconButton onClick={() => navigate(-1)} sx={{ bgcolor: '#f8fafc' }}>
                        <ArrowLeft size={20} />
                    </IconButton>
                    <Box>
                        <Typography variant="h6" fontWeight={800} sx={{ lineHeight: 1.2 }}>
                            {table ? (table.is_hold_table === 'Yes' ? table.hold_table_name : `Table ${table.table_id}`) : (orderType || 'New Order')}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                            Order Taking
                        </Typography>
                    </Box>

                    {existingOrder && orderType === 'Table' && (
                        <Button
                            variant="outlined"
                            startIcon={<ArrowRightLeft size={18} />}
                            onClick={() => {
                                loadTables();
                                setChangeTableDialogOpen(true);
                            }}
                            sx={{
                                ml: 3,
                                borderRadius: '12px',
                                textTransform: 'none',
                                fontWeight: 700,
                                borderColor: '#e2e8f0',
                                color: '#64748b',
                                '&:hover': { borderColor: '#FFC107', color: '#FFC107', bgcolor: 'transparent' }
                            }}
                        >
                            Change Table
                        </Button>
                    )}

                    <TextField
                        size="small"
                        placeholder="Search items..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        sx={{
                            ml: 'auto',
                            width: { xs: 150, sm: 200, md: 250 },
                            '& .MuiOutlinedInput-root': { borderRadius: '20px', bgcolor: '#f8fafc' }
                        }}
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
                                '&.Mui-selected': { color: '#FFC107' }
                            },
                            '& .MuiTabs-indicator': { bgcolor: '#FFC107', height: '3px', borderRadius: '3px 3px 0 0' }
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
                        width: { xs: 120, sm: 150, md: 180 },
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
                                    border: selectedGroupId === null ? '1px solid #FFC107' : '1px solid transparent',
                                    transition: 'all 0.2s',
                                    '&:hover': { bgcolor: selectedGroupId === null ? 'white' : '#f1f5f9' }
                                }}
                            >
                                <Typography
                                    sx={{
                                        fontWeight: 700,
                                        fontSize: '13px',
                                        color: selectedGroupId === null ? '#FFC107' : '#64748b'
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
                                        border: selectedGroupId === group.id ? '1px solid #FFC107' : '1px solid transparent',
                                        transition: 'all 0.2s',
                                        '&:hover': { bgcolor: selectedGroupId === group.id ? 'white' : '#f1f5f9' }
                                    }}
                                >
                                    <Typography
                                        sx={{
                                            fontWeight: 700,
                                            fontSize: '13px',
                                            color: selectedGroupId === group.id ? '#FFC107' : '#64748b',
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
                        <Box sx={{ mb: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <Typography variant="subtitle1" fontWeight={800} color="#1e293b">
                                {searchTerm ? `Search Results for "${searchTerm}"` : (groups.find(g => g.id === selectedGroupId)?.name || categories.find(c => c.id === selectedCategoryId)?.name || 'Menu Items')}
                            </Typography>
                            {searchTerm && (
                                <Button
                                    size="small"
                                    onClick={() => setSearchTerm('')}
                                    sx={{ textTransform: 'none', color: '#64748b', fontWeight: 600 }}
                                >
                                    Clear Search
                                </Button>
                            )}
                        </Box>
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
                                                    borderColor: '#FFC107',
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
                                                    overflow: 'hidden'
                                                }}>
                                                    {item.image ? (
                                                        <Box
                                                            component="img"
                                                            src={item.image.startsWith('http') ? item.image : `${API_BASE_URL}${item.image}`}
                                                            sx={{ width: '100%', height: '100%', objectFit: 'cover' }}
                                                        />
                                                    ) : (
                                                        <Typography sx={{ fontSize: '40px' }}>🍽️</Typography>
                                                    )}
                                                </Box>
                                                <Typography fontWeight={700} fontSize="14px" sx={{ mb: 0.2, lineHeight: 1.3 }}>
                                                    {item.name}
                                                </Typography>
                                                {searchTerm && (
                                                    <Typography variant="caption" sx={{ color: '#64748b', fontWeight: 600, display: 'block', mb: 0.5, fontSize: '11px' }}>
                                                        In {categories.find(c => c.id === item.category_id)?.name || 'General'}
                                                    </Typography>
                                                )}
                                            </Box>
                                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mt: 1 }}>
                                                <Typography fontWeight={800} color="#FFC107" fontSize="16px">
                                                    NPRs. {Number(item.price).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                                                </Typography>
                                                <Box sx={{ bgcolor: '#fff7ed', p: 0.5, borderRadius: '8px' }}>
                                                    <Plus size={16} color="#FFC107" />
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
                width: { xs: '100%', md: 320, lg: 380 }, // Responsive width
                height: { xs: '40%', md: '100%' }, // On mobile, takes remaining height
                bgcolor: 'white',
                borderLeft: { md: '1px solid #f1f5f9' },
                display: 'flex',
                flexDirection: 'column',
                boxShadow: '-4px 0 15px rgba(0,0,0,0.02)',
                minWidth: { md: 320 }
            }}>
                <Box sx={{ p: 2, borderBottom: '1px solid #f1f5f9' }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                        <Typography variant="h6" fontWeight={800} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            Current Order <Chip label={orderItems.length} size="small" sx={{ bgcolor: '#FFC107', color: 'white', fontWeight: 800, height: 20 }} />
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
                                <UserCircle size={20} color="#FFC107" />
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
                                                <Typography variant="body2" fontWeight={700} color="#FFC107">
                                                    + Quick Add "{customerSearch}"
                                                </Typography>
                                            </ListItem>
                                        </List>
                                    </Paper>
                                )}
                            </Box>
                        )}
                    </Box>

                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                            <Chip
                                label="Dine In"
                                icon={<Armchair size={16} />}
                                sx={{
                                    height: 32,
                                    bgcolor: orderType === 'Table' ? '#fff7ed' : '#f8fafc',
                                    color: orderType === 'Table' ? '#FFC107' : '#94a3b8',
                                    fontWeight: 800,
                                    border: '1px solid',
                                    borderColor: orderType === 'Table' ? '#FFC107' : '#e2e8f0',
                                    borderRadius: '8px',
                                    '& .MuiChip-icon': { color: 'inherit' }
                                }}
                            />
                            <Chip
                                label="Takeaway"
                                icon={<ShoppingBag size={16} />}
                                sx={{
                                    height: 32,
                                    bgcolor: orderType === 'Takeaway' ? '#fff7ed' : '#f8fafc',
                                    color: orderType === 'Takeaway' ? '#FFC107' : '#94a3b8',
                                    fontWeight: 800,
                                    border: '1px solid',
                                    borderColor: orderType === 'Takeaway' ? '#FFC107' : '#e2e8f0',
                                    borderRadius: '8px',
                                    '& .MuiChip-icon': { color: 'inherit' }
                                }}
                            />
                            <Chip
                                label="Delivery"
                                icon={<Bike size={16} />}
                                sx={{
                                    height: 32,
                                    bgcolor: orderType === 'Delivery' ? '#fff7ed' : '#f8fafc',
                                    color: orderType === 'Delivery' ? '#FFC107' : '#94a3b8',
                                    fontWeight: 800,
                                    border: '1px solid',
                                    borderColor: orderType === 'Delivery' ? '#FFC107' : '#e2e8f0',
                                    borderRadius: '8px',
                                    '& .MuiChip-icon': { color: 'inherit' }
                                }}
                            />
                        </Box>

                        {orderType === 'Delivery' && (
                            <TextField
                                label="Delivery Charge"
                                size="small"
                                type="number"
                                value={deliveryCharge}
                                onChange={(e) => setDeliveryCharge(parseFloat(e.target.value) || 0)}
                                fullWidth
                                InputProps={{
                                    startAdornment: <InputAdornment position="start">NPRs.</InputAdornment>,
                                    sx: { borderRadius: '12px' }
                                }}
                            />
                        )}
                    </Box>
                </Box>

                <Box sx={{ flexGrow: 1, p: 2, overflowY: 'auto', minHeight: 0 }}>
                    {orderItems.length > 0 ? (
                        orderItems.map((item) => (
                            <Paper
                                key={item.item_id}
                                elevation={0}
                                sx={{
                                    p: 1,
                                    mb: 1.5,
                                    borderRadius: '16px',
                                    border: '1px solid #f1f5f9',
                                    bgcolor: '#f8fafc',
                                    transition: 'all 0.2s',
                                    '&:hover': { border: '1px solid #FFC107' }
                                }}
                            >
                                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                    <Typography fontWeight={700} fontSize="14px">{item.name}</Typography>
                                    <Typography fontWeight={800} color="#1e293b">NPRs. {Number(item.price * item.quantity).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                                </Box>
                                <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 1.5 }}>
                                    NPRs. {Number(item.price).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} / item
                                </Typography>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                    <Box sx={{ display: 'flex', alignItems: 'center', bgcolor: 'white', borderRadius: '10px', p: 0.5, border: '1px solid #e2e8f0' }}>
                                        <IconButton
                                            size="small"
                                            onClick={() => updateQuantity(item.item_id, -1)}
                                            sx={{ p: 0.5, color: '#FFC107' }}
                                        >
                                            <Minus size={16} />
                                        </IconButton>
                                        <Typography sx={{ width: 30, textAlign: 'center', fontWeight: 800, fontSize: '14px' }}>
                                            {Number(item.quantity).toFixed(2)}
                                        </Typography>
                                        <IconButton
                                            size="small"
                                            onClick={() => updateQuantity(item.item_id, 1)}
                                            sx={{ p: 0.5, color: '#FFC107' }}
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

                <Box sx={{ p: 2, bgcolor: '#f8fafc', borderTop: '1px solid #f1f5f9', mt: 'auto' }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                        <Typography color="text.secondary" fontWeight={500} fontSize="13px">Subtotal</Typography>
                        <Typography fontWeight={700} fontSize="13px">NPRs. {Number(total).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5, alignItems: 'center' }}>
                        <Typography color="text.secondary" fontWeight={500} fontSize="13px">Discount (%)</Typography>
                        <TextField
                            size="small"
                            type="number"
                            value={discountPercent}
                            onChange={(e) => setDiscountPercent(parseFloat(e.target.value) || 0)}
                            sx={{
                                width: '70px',
                                '& .MuiInputBase-input': {
                                    py: 0.3,
                                    px: 1,
                                    textAlign: 'right',
                                    fontWeight: 700,
                                    fontSize: '12px'
                                },
                                '& .MuiOutlinedInput-root': {
                                    borderRadius: '6px',
                                    bgcolor: 'white'
                                }
                            }}
                        />
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                        <Typography color="text.secondary" fontWeight={500} fontSize="13px">Discount Amt</Typography>
                        <Typography fontWeight={700} fontSize="13px">NPRs. {Number(total * discountPercent / 100).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                    </Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                        <Typography color="text.secondary" fontWeight={500} fontSize="13px">Service Charge ({companySettings?.service_charge_rate || 0}%)</Typography>
                        <Typography fontWeight={700} fontSize="13px">NPRs. {Number((total - (total * discountPercent / 100)) * (companySettings?.service_charge_rate || 0) / 100).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                    </Box>
                    {(companySettings?.tax_rate > 0 || (total - (Math.round(total * discountPercent / 100)) + ((total - (Math.round(total * discountPercent / 100))) * (companySettings?.service_charge_rate || 0) / 100)) * (companySettings?.tax_rate || 0) / 100 > 0) && (
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                            <Typography color="text.secondary" fontWeight={500} fontSize="13px">VAT ({companySettings?.tax_rate || 0}%)</Typography>
                            <Typography fontWeight={700} fontSize="13px">NPRs. {Number(((total - (total * discountPercent / 100)) + ((total - (total * discountPercent / 100)) * (companySettings?.service_charge_rate || 0) / 100)) * (companySettings?.tax_rate || 0) / 100).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                        </Box>
                    )}
                    {orderType === 'Delivery' && (
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                            <Typography color="text.secondary" fontWeight={500} fontSize="13px">Delivery Charge</Typography>
                            <Typography fontWeight={700} fontSize="13px">NPRs. {Number(deliveryCharge).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                        </Box>
                    )}
                    <Divider sx={{ my: 1, borderStyle: 'dashed' }} />
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1.5 }}>
                        <Typography variant="subtitle1" fontWeight={800} fontSize="18px">Total Payable</Typography>
                        <Typography variant="subtitle1" fontWeight={800} color="#FFC107" fontSize="18px">NPRs. {Number((total - (total * discountPercent / 100)) * (1 + (companySettings?.service_charge_rate || 0) / 100) * (1 + (companySettings?.tax_rate || 0) / 100) + deliveryCharge).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                    </Box>

                    <Button
                        fullWidth
                        variant="contained"
                        disabled={orderItems.length === 0}
                        onClick={handlePlaceOrder}
                        sx={{
                            bgcolor: '#FFC107',
                            mb: 1,
                            py: 1.5,
                            fontWeight: 800,
                            fontSize: '16px',
                            borderRadius: '12px',
                            boxShadow: '0 4px 12px rgba(255,140,0,0.2)',
                            textTransform: 'none',
                            '&:hover': { bgcolor: '#e67e00' }
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
                                '&:hover': { bgcolor: 'white', borderColor: '#FFC107', color: '#FFC107' }
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
                                '&:hover': { bgcolor: 'white', borderColor: '#FFC107', color: '#FFC107' }
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
                                settings={companySettings}
                                order={{
                                    order_number: 'DRAFT',
                                    created_at: new Date().toISOString(),
                                    table: table || { table_id: tableId || 'N/A' },
                                    order_type: orderType,
                                    customer: selectedCustomer,
                                    items: orderItems.map(item => ({
                                        id: item.id || Date.now(),
                                        menu_item: { name: item.name },
                                        quantity: item.quantity,
                                        price: item.price,
                                        subtotal: item.quantity * item.price
                                    })),
                                    gross_amount: total,
                                    delivery_charge: deliveryCharge,
                                    net_amount: Math.round(total * (1 + (companySettings?.service_charge_rate || 0) / 100) * (1 + (companySettings?.tax_rate || 0) / 100)) + deliveryCharge,
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
                        sx={{ borderRadius: '10px', bgcolor: '#FFC107', '&:hover': { bgcolor: '#FF7700' }, textTransform: 'none', fontWeight: 700 }}
                    >
                        Print Bill
                    </Button>
                </DialogActions>
            </Dialog>

            {/* Change Table Dialog */}
            <Dialog
                open={changeTableDialogOpen}
                onClose={() => setChangeTableDialogOpen(false)}
                maxWidth="sm"
                fullWidth
                PaperProps={{ sx: { borderRadius: '20px' } }}
            >
                <DialogTitle sx={{ fontWeight: 800, px: 3, pt: 3 }}>
                    Move Order to Another Table
                </DialogTitle>
                <DialogContent sx={{ px: 3, pb: 3 }}>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                        Select an available table to move this order.
                    </Typography>
                    <Grid container spacing={2}>
                        {allTables
                            .filter(t => t.id !== table?.id && t.is_active && t.is_hold_table !== 'Yes')
                            .map(t => (
                                <Grid key={t.id} size={{ xs: 6, sm: 4, md: 3 }}>
                                    <Paper
                                        elevation={0}
                                        onClick={() => handleChangeTable(t)}
                                        sx={{
                                            p: 2,
                                            textAlign: 'center',
                                            cursor: 'pointer',
                                            border: '1.5px solid #f1f5f9',
                                            borderRadius: '16px',
                                            bgcolor: t.status === 'Available' ? 'white' : '#f8fafc',
                                            opacity: t.status === 'Available' ? 1 : 0.6,
                                            transition: t.status === 'Available' ? 'all 0.2s' : 'none',
                                            '&:hover': t.status === 'Available' ? {
                                                borderColor: '#FFC107',
                                                bgcolor: '#fff7ed',
                                                transform: 'translateY(-2px)'
                                            } : {}
                                        }}
                                    >
                                        <Typography variant="h6" fontWeight={800} color={t.status === 'Available' ? '#1e293b' : '#94a3b8'}>
                                            {t.table_id}
                                        </Typography>
                                        <Typography variant="caption" sx={{
                                            fontWeight: 800,
                                            color: t.status === 'Available' ? '#10b981' : '#ef4444'
                                        }}>
                                            {t.status}
                                        </Typography>
                                    </Paper>
                                </Grid>
                            ))
                        }
                    </Grid>
                </DialogContent>
                <DialogActions sx={{ px: 3, pb: 3 }}>
                    <Button onClick={() => setChangeTableDialogOpen(false)} sx={{ fontWeight: 700, color: '#64748b' }}>
                        Cancel
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default OrderTaking;

