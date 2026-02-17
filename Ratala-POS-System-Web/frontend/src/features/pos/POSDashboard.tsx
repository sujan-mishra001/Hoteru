import React, { useState, useEffect, useCallback } from 'react';
import {
    Box,
    Typography,
    Paper,
    IconButton,
    CircularProgress,
    Button,
    Tabs,
    Tab,
    Divider,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    FormControl,
    InputLabel,
    Select,
    Chip,
    ListItemButton,
    Menu,
    MenuItem
} from '@mui/material';
import {
    RefreshCw,
    Armchair,
    Bike,
    ShoppingBag,
    Play,
    Square,
    QrCode
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../app/providers/AuthProvider';
import { usePermission } from '../../app/providers/PermissionProvider';
import { floorsAPI, tablesAPI, sessionsAPI, authAPI, deliveryAPI, qrAPI, ordersAPI, customersAPI } from '../../services/api';
import { useNotification } from '../../app/providers/NotificationProvider';
import { useBranch } from '../../app/providers/BranchProvider';
import { Search, Plus, UserCircle, MoreHorizontal } from 'lucide-react';
import { TextField, List, ListItem, InputAdornment } from '@mui/material';

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
    status: 'Available' | 'Occupied' | 'Reserved' | 'BillRequested';
    active_order_id: number | null;
    total_amount: number;
    order_start_time?: string;
    is_hold_table: string;
    hold_table_name: string | null;
    merged_to_id: number | null;
    merge_group_id: string | null;
}

// Table Card Component
const TableCard: React.FC<{
    table: TableData;
    onClick: () => void;
    onPaymentClick: () => void;
    onMenuOpen: (e: React.MouseEvent<HTMLElement>, table: TableData) => void;
}> = ({ table, onClick, onPaymentClick, onMenuOpen }) => {
    const isOccupied = table.status !== 'Available' || table.active_order_id !== null;
    const [duration, setDuration] = useState<string>('');

    // Timer logic
    useEffect(() => {
        if (!isOccupied || !table.order_start_time) return;

        const updateTimer = () => {
            // Safely parse order_start_time as UTC if no timezone is present
            const startStr = table.order_start_time!;
            const isoStart = (startStr.endsWith('Z') || startStr.includes('+'))
                ? startStr
                : `${startStr.replace(' ', 'T')}Z`;

            const start = new Date(isoStart).getTime();
            const now = new Date().getTime();
            const diff = now - start;

            if (diff > 0) {
                const totalMinutes = Math.floor(diff / 60000);
                const hours = Math.floor(totalMinutes / 60);
                const minutes = totalMinutes % 60;

                if (hours > 0) {
                    setDuration(`${hours} hr ${minutes} min`);
                } else {
                    setDuration(`${minutes} min`);
                }
            } else {
                setDuration('0 min');
            }
        };

        updateTimer();
        const interval = setInterval(updateTimer, 60000); // Update every minute
        return () => clearInterval(interval);
    }, [isOccupied, table.order_start_time]);

    return (
        <Paper
            onClick={onClick}
            elevation={0}
            sx={{
                p: 2,
                cursor: 'pointer',
                borderRadius: '12px',
                border: '1.5px solid',
                borderColor: isOccupied ? '#ef4444' : '#10b981', // Red if occupied, Green if vacant
                bgcolor: 'white',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                minHeight: 140,
                position: 'relative',
                transition: 'all 0.2s',
                '&:hover': {
                    boxShadow: '0 4px 12px rgba(0,0,0,0.05)',
                    transform: 'translateY(-2px)'
                }
            }}
        >
            <Box sx={{ mb: 1, position: 'relative' }}>
                <Armchair
                    size={48}
                    color={isOccupied ? '#ef4444' : '#10b981'} // Icon color based on status
                    style={{ opacity: 0.8 }}
                />
            </Box>

            <Typography variant="h6" fontWeight={800} sx={{ mb: 0.5 }}>
                {table.table_id}
            </Typography>

            {isOccupied ? (
                <>
                    <Typography variant="body2" sx={{ color: '#ef4444', fontWeight: 600, mb: 1.5 }}>
                        {duration || 'Just now'}
                    </Typography>
                    <Button
                        variant="contained"
                        size="small"
                        onClick={(e) => {
                            e.stopPropagation();
                            onPaymentClick();
                        }}
                        sx={{
                            bgcolor: '#ff6b6b',
                            color: 'white',
                            fontSize: '0.65rem',
                            fontWeight: 700,
                            borderRadius: '20px',
                            textTransform: 'none',
                            py: 0.5,
                            px: 2,
                            boxShadow: 'none',
                            '&:hover': { bgcolor: '#fa5252' }
                        }}
                    >
                        Go to Payment
                    </Button>
                </>
            ) : (
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                    <Box sx={{ width: 6, height: 6, borderRadius: '50%', bgcolor: '#10b981' }} />
                    <Typography variant="body2" sx={{ color: '#10b981', fontWeight: 600 }}>
                        {table.merged_to_id ? 'Merged' : (table.is_hold_table === "Yes" ? "Hold" : "Vacant")}
                    </Typography>
                    <IconButton
                        size="small"
                        onClick={(e) => {
                            e.stopPropagation();
                            onMenuOpen(e, table);
                        }}
                        sx={{ ml: 0.5, p: 0.2, color: '#94a3b8' }}
                    >
                        <MoreHorizontal size={14} />
                    </IconButton>
                </Box>
            )}
        </Paper>
    );
};

// Main POS Dashboard
const POSDashboard: React.FC = () => {
    const navigate = useNavigate();
    const { user } = useAuth();
    const { hasPermission } = usePermission();
    const { currentBranch } = useBranch();
    const { showAlert } = useNotification();
    const [loading, setLoading] = useState(true);

    // Data
    const [floors, setFloors] = useState<Floor[]>([]);
    const [selectedFloorId, setSelectedFloorId] = useState<number>(0);
    const [tables, setTables] = useState<TableData[]>([]);
    const [activeSessionId, setActiveSessionId] = useState<number | null>(null);
    const [globalActiveSession, setGlobalActiveSession] = useState<any>(null); // For Admin to see other's session
    const [deliveryPartners, setDeliveryPartners] = useState<any[]>([]);
    const [selectedPartnerId] = useState<string>('');
    const [openDigitalMenu, setOpenDigitalMenu] = useState(false);
    const [qrSrc, setQrSrc] = useState<string>('');

    // Right Panel Tabs
    const [rightPanelTab, setRightPanelTab] = useState(0); // 0: Takeaway, 1: Delivery
    const [activeOrders, setActiveOrders] = useState<any[]>([]);
    const [activeSession, setActiveSession] = useState<any>(null);

    // Session dialog states
    const [openingDialog, setOpeningDialog] = useState(false);
    const [closingDialog, setClosingDialog] = useState(false);
    const [openingCash, setOpeningCash] = useState('0');
    const [actualCash, setActualCash] = useState('0');

    // Customer Selection
    const [customers, setCustomers] = useState<any[]>([]);

    // Options Menu State
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
    const [menuTarget, setMenuTarget] = useState<TableData | null>(null);

    const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, table: TableData) => {
        event.stopPropagation();
        setAnchorEl(event.currentTarget);
        setMenuTarget(table);
    };

    const handleMenuClose = () => {
        setAnchorEl(null);
        setMenuTarget(null);
    };

    const handleToggleHold = async () => {
        if (!menuTarget) return;
        try {
            const newStatus = menuTarget.is_hold_table === 'Yes' ? 'No' : 'Yes';
            await tablesAPI.update(menuTarget.id, { ...menuTarget, is_hold_table: newStatus });
            showAlert(`Table ${menuTarget.table_id} moved to ${newStatus === 'Yes' ? 'Hold' : 'Normal'} section`, 'success');
            loadData();
        } catch (error) {
            showAlert('Error updating hold status', 'error');
        } finally {
            handleMenuClose();
        }
    };

    const handleMergeTable = async (targetId: number | null) => {
        if (!menuTarget) return;

        if (targetId === null) {
            // Unmerge
            console.log(`Unmerging table ${menuTarget.table_id} (ID: ${menuTarget.id})`);
            try {
                const response = await tablesAPI.unmerge(menuTarget.id);
                console.log('Unmerge response:', response.data);
                showAlert(`Table ${menuTarget.table_id} unmerged successfully`, 'success');
                await loadData();
            } catch (error: any) {
                console.error('Error unmerging table:', error);
                showAlert(error.response?.data?.detail || 'Error unmerging table', 'error');
            } finally {
                handleMenuClose();
            }
        } else {
            // Merge
            const targetTable = tables.find(t => t.id === targetId);
            console.log(`Merging table ${menuTarget.table_id} (ID: ${menuTarget.id}) with ${targetTable?.table_id} (ID: ${targetId})`);
            try {
                const response = await tablesAPI.merge(menuTarget.id, targetId);
                console.log('Merge response:', response.data);
                const mergeGroupId = response.data.merge_group_id;
                showAlert(`${menuTarget.table_id} successfully merged with ${targetTable?.table_id} into ${mergeGroupId}`, 'success');
                await loadData();
                console.log('Data reloaded after merge');
            } catch (error: any) {
                console.error('Error merging table:', error);
                showAlert(error.response?.data?.detail || 'Error merging table', 'error');
            } finally {
                handleMenuClose();
            }
        }
    };

    // New Order Dialog
    const [openNewOrderDialog, setOpenNewOrderDialog] = useState(false);
    const [newOrderType, setNewOrderType] = useState<'Takeaway' | 'Delivery'>('Takeaway');
    const [dialogCustomerSearch, setDialogCustomerSearch] = useState('');
    const [dialogSelectedCustomer, setDialogSelectedCustomer] = useState<any>(null);
    const [dialogSelectedPartnerId, setDialogSelectedPartnerId] = useState<string>('');

    // Loader
    const loadData = useCallback(async () => {
        try {
            const [floorsRes, tablesRes, userRes, sessionsRes, deliveryRes, ordersRes, custRes] = await Promise.all([
                floorsAPI.getAll(),
                tablesAPI.getAll(),
                authAPI.getCurrentUser(),
                sessionsAPI.getAll(),
                deliveryAPI.getAll(),
                ordersAPI.getAll(),
                customersAPI.getAll()
            ]);

            setFloors(floorsRes.data || []);
            const tablesData = tablesRes.data || [];
            setTables(tablesData);

            // Log merge states
            const mergedTables = tablesData.filter((t: any) => t.merged_to_id);
            console.log('Tables with merged_to_id:', mergedTables.map((t: any) => ({
                id: t.id,
                table_id: t.table_id,
                merged_to_id: t.merged_to_id
            })));

            setDeliveryPartners(deliveryRes.data || []);
            setCustomers(custRes.data || []);

            const allOrders = ordersRes.data || [];
            const activeOrdersList = allOrders.filter((o: any) =>
                (o.status === 'Pending' || o.status === 'In Progress' || o.status === 'Draft' || o.status === 'Completed') &&
                (o.order_type === 'Takeaway' || o.order_type === 'Delivery')
            );
            setActiveOrders(activeOrdersList);

            const sessionData = sessionsRes.data || [];


            // 1. My personal active session
            const userActiveSession = sessionData.find((s: any) => s.user_id === userRes.data.id && s.status === 'Open');

            // 2. Any global active session (for admins to see)
            const globalSession = sessionData.find((s: any) => s.status === 'Open');

            if (userActiveSession) {
                setActiveSessionId(userActiveSession.id);
                setActiveSession(userActiveSession);
                setGlobalActiveSession(null);
            } else if (globalSession) {
                // Everyone adapts to the global session context (Admins can manage, Workers view only)
                setActiveSessionId(globalSession.id);
                setActiveSession(globalSession);
                setGlobalActiveSession(globalSession);
            } else {
                setActiveSessionId(null);
                setActiveSession(null);
                setGlobalActiveSession(null);
            }

            // Set initial floor if currently on 0 (uninitialized)
            if (floorsRes.data?.length > 0 && selectedFloorId === 0) {
                setSelectedFloorId(floorsRes.data[0].id);
            }
        } catch (error) {
            console.error('Error loading data:', error);
        } finally {
            setLoading(false);
        }
    }, [selectedFloorId, currentBranch?.id]);

    // Fetch QR when dialog opens
    useEffect(() => {
        let objectUrl = '';
        if (openDigitalMenu) {
            qrAPI.getMenuQR().then(res => {
                const blob = new Blob([res.data], { type: 'image/png' });
                objectUrl = URL.createObjectURL(blob);
                setQrSrc(objectUrl);
            }).catch(err => {
                console.error('Error fetching QR:', err);
                showAlert('Failed to generate QR Code', 'error');
            });
        }
        return () => {
            if (objectUrl) URL.revokeObjectURL(objectUrl);
            setQrSrc('');
        };
    }, [openDigitalMenu, showAlert]);

    const handleStartSession = async () => {
        setOpeningDialog(true);
    };

    const confirmStartSession = async () => {
        try {
            const payload = {
                opening_cash: parseFloat(openingCash) || 0,
                notes: 'Session started via POS Header'
            };
            const response = await sessionsAPI.create(payload);
            setActiveSessionId(response.data.id);
            setActiveSession(response.data);
            showAlert('Session started successfully', 'success');
            setOpeningDialog(false);
            setOpeningCash('0');
            loadData();
        } catch (error: any) {
            showAlert(error.response?.data?.detail || 'Failed to start session', 'error');
        }
    };

    const handleEndSession = async () => {
        if (!activeSessionId) return;

        // Use opening_cash + total_sales as default closing balance
        setActualCash(((activeSession?.opening_cash || 0) + (activeSession?.total_sales || 0)).toString());
        setClosingDialog(true);
    };

    const confirmEndSession = async () => {
        const sessionId = activeSessionId;
        if (!sessionId) return;

        try {
            const payload = {
                actual_cash: parseFloat(actualCash) || 0,
                status: 'Closed'
            };
            const response = await sessionsAPI.update(sessionId, payload);
            setActiveSessionId(null);
            setActiveSession(null);
            setClosingDialog(false);
            setActualCash('0');

            showAlert(`Session closed successfully. Total Sales: Rs. ${Number(response.data.total_sales).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`, 'success');

            // Redirect to POS/Tables swiftly
            const branchPath = currentBranch?.slug || currentBranch?.code || localStorage.getItem('branchSlug');
            navigate(`/${branchPath}/pos`);
        } catch (error: any) {
            showAlert(error.response?.data?.detail || 'Failed to close session', 'error');
        }
    };

    useEffect(() => {
        loadData();
        const interval = setInterval(loadData, 30000); // Refresh every 30s
        return () => clearInterval(interval);
    }, [loadData]);


    const handleTableClick = (table: TableData, customOrderType?: string, deliveryPartnerId?: string) => {
        // Find if any table in the same merge group has an active order
        let activeOrderId = table.active_order_id;

        if (!activeOrderId && table.merge_group_id) {
            const groupMemberWithOrder = tables.find(t =>
                t.merge_group_id === table.merge_group_id && !!t.active_order_id
            );
            if (groupMemberWithOrder) {
                activeOrderId = groupMemberWithOrder.active_order_id;
            }
        }

        const branchPath = currentBranch?.slug || currentBranch?.code || localStorage.getItem('branchSlug');
        if (activeOrderId) {
            navigate(`/${branchPath}/pos/order/${table.id}`, { state: { table, orderId: activeOrderId, customOrderType, deliveryPartnerId } });
        } else {
            navigate(`/${branchPath}/pos/order/${table.id}`, { state: { table, customOrderType, deliveryPartnerId } });
        }
    };

    // Helper to identify tables in merge section
    const tablesInMergeGroups = tables.filter(t => !!t.merge_group_id);
    const isInMergeSection = (t: TableData) => !!t.merge_group_id;

    console.log('Tables in merge groups:', tablesInMergeGroups.map(t => ({
        id: t.id,
        table_id: t.table_id,
        merge_group_id: t.merge_group_id
    })));

    // Group tables by merge_group_id
    const mergeGroupsMap = new Map<string, TableData[]>();
    tablesInMergeGroups.forEach(table => {
        if (table.merge_group_id) {
            if (!mergeGroupsMap.has(table.merge_group_id)) {
                mergeGroupsMap.set(table.merge_group_id, []);
            }
            mergeGroupsMap.get(table.merge_group_id)!.push(table);
        }
    });

    // Convert to array format and calculate totals
    const mergeGroups = Array.from(mergeGroupsMap.entries()).map(([groupId, members]) => ({
        groupId,
        members,
        totalAmount: members.reduce((sum, m) => sum + (m.total_amount || 0), 0)
    }));

    // Only show merge groups when on the Merge Table tab
    const displayMergeGroups = selectedFloorId === -2 ? mergeGroups : [];

    console.log(`Merge Groups: ${displayMergeGroups.length}`);

    // Filter normal tables for current view (excluding merged completely)
    const effectiveFloorId = selectedFloorId === 0 ? (floors[0]?.id || 0) : selectedFloorId;
    const filteredTables = selectedFloorId === -1
        ? tables.filter(t => t.is_hold_table === 'Yes' && !isInMergeSection(t))
        : selectedFloorId === -2
            ? []
            : tables.filter(t => t.floor_id === effectiveFloorId && t.is_hold_table !== 'Yes' && !isInMergeSection(t));

    console.log('Filtered Tables:', filteredTables.length);

    return (
        <Box sx={{ display: 'flex', height: '100vh', bgcolor: '#f8fafc', overflow: 'hidden' }}>
            <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', borderRight: '1px solid #e2e8f0', overflow: 'hidden' }}>
                {/* Header / Floor Tabs */}
                <Box sx={{ px: 3, pt: 3, pb: 2, bgcolor: 'white' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
                        {/* Floor Tabs */}
                        <Tabs
                            value={selectedFloorId === 0 ? (floors.length > 0 ? floors[0].id : -1) : selectedFloorId}
                            onChange={(_, val) => setSelectedFloorId(val)}
                            variant="scrollable"
                            scrollButtons="auto"
                            sx={{
                                minHeight: 40,
                                '& .MuiTab-root': {
                                    textTransform: 'none',
                                    fontWeight: 700,
                                    fontSize: '1rem',
                                    color: '#94a3b8',
                                    mr: 2,
                                    minWidth: 'auto',
                                    p: 0,
                                    '&.Mui-selected': { color: '#FFC107' }
                                },
                                '& .MuiTabs-indicator': {
                                    bgcolor: '#FFC107',
                                    height: 3
                                }
                            }}
                        >
                            {floors.map(floor => (
                                <Tab key={floor.id} label={floor.name} value={floor.id} disableRipple />
                            ))}
                            <Tab label="Hold Table" value={-1} />
                            <Tab label="Merge Table" value={-2} />
                        </Tabs>

                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            {hasPermission('sessions.manage') && (
                                <>
                                    {activeSessionId ? (
                                        // Active Session Logic
                                        globalActiveSession && (user?.role?.toLowerCase() !== 'admin') ? (
                                            // Non-Admin viewing Global Session -> Read Only Label
                                            <Button
                                                variant="outlined"
                                                color="warning"
                                                size="small"
                                                startIcon={<Square size={16} />}
                                                disabled
                                                sx={{ borderRadius: '8px', textTransform: 'none', fontWeight: 700, borderColor: '#fbbf24', color: '#d97706' }}
                                            >
                                                Session by {globalActiveSession.user?.full_name || globalActiveSession.user?.username || 'Admin'}
                                            </Button>
                                        ) : (
                                            // Owner OR Admin -> Can End Session
                                            <Button
                                                variant="outlined"
                                                color="error"
                                                size="small"
                                                startIcon={<Square size={16} />}
                                                onClick={handleEndSession}
                                                sx={{ borderRadius: '8px', textTransform: 'none', fontWeight: 700 }}
                                            >
                                                {globalActiveSession ? `End ${globalActiveSession.user?.full_name || 'User'}'s Session` : 'End Session'}
                                            </Button>
                                        )
                                    ) : (
                                        // No active session in context. Check if we should allow starting one.
                                        // If global session exists AND user isn't admin, they shouldn't start a new one (safety lock)
                                        globalActiveSession && (user?.role?.toLowerCase() !== 'admin') ? (
                                            <Button
                                                variant="outlined"
                                                color="warning"
                                                size="small"
                                                startIcon={<Square size={16} />}
                                                disabled
                                                sx={{ borderRadius: '8px', textTransform: 'none', fontWeight: 700, borderColor: '#fbbf24', color: '#d97706' }}
                                            >
                                                Active Session by {globalActiveSession.user?.full_name || 'Admin'}
                                            </Button>
                                        ) : (
                                            <Button
                                                variant="contained"
                                                size="small"
                                                startIcon={<Play size={16} />}
                                                onClick={handleStartSession}
                                                sx={{
                                                    bgcolor: '#FFC107',
                                                    '&:hover': { bgcolor: '#e67e00' },
                                                    borderRadius: '8px',
                                                    textTransform: 'none',
                                                    fontWeight: 700
                                                }}
                                            >
                                                Start Session
                                            </Button>
                                        )
                                    )}
                                </>
                            )}
                            <Button
                                variant="outlined"
                                startIcon={<QrCode size={16} />}
                                onClick={() => setOpenDigitalMenu(true)}
                                sx={{ borderRadius: '8px', textTransform: 'none', fontWeight: 700, borderColor: '#FFC107', color: '#2C1810' }}
                            >
                                Digital Menu
                            </Button>
                            <IconButton onClick={() => loadData()}>
                                <RefreshCw size={18} color="#94a3b8" />
                            </IconButton>
                        </Box>
                    </Box>
                </Box>

                {/* Scrollable Table Grid */}
                <Box sx={{ flex: 1, p: 3, overflowY: 'auto', bgcolor: '#f9fafb' }}>
                    {loading ? (
                        <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}>
                            <CircularProgress sx={{ color: '#FFC107' }} />
                        </Box>
                    ) : (
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                            {/* 1. Merged Tables Section (Groups) */}
                            {displayMergeGroups.map((group) => (
                                <Paper key={group.groupId} elevation={0} sx={{ p: 3, border: '1.5px solid #e2e8f0', borderRadius: '16px', bgcolor: 'white', mb: 2 }}>
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                                        <Typography variant="subtitle1" fontWeight={800} color="#64748b">
                                            {group.groupId}
                                        </Typography>
                                        <Chip
                                            label={`Total: Rs. ${Number(group.totalAmount).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`}
                                            color="success"
                                            sx={{ fontWeight: 800, borderRadius: '8px' }}
                                        />
                                    </Box>
                                    <Box sx={{
                                        display: 'grid',
                                        gridTemplateColumns: 'repeat(auto-fill, minmax(160px, 1fr))',
                                        gap: 3
                                    }}>
                                        {group.members.map((table: TableData) => (
                                            <TableCard
                                                key={table.id}
                                                table={table}
                                                onClick={() => handleTableClick(table)}
                                                onPaymentClick={() => {
                                                    const branchPath = currentBranch?.slug || currentBranch?.code || localStorage.getItem('branchSlug');
                                                    navigate(`/${branchPath}/pos/billing/${table.id}`, { state: { table, orderId: table.active_order_id } });
                                                }}
                                                onMenuOpen={handleMenuOpen}
                                            />
                                        ))}
                                    </Box>
                                </Paper>
                            ))}

                            {/* 2. Normal Tables Grid */}
                            {filteredTables.length > 0 && (
                                <Box sx={{
                                    display: 'grid',
                                    gridTemplateColumns: 'repeat(auto-fill, minmax(160px, 1fr))',
                                    gap: 3
                                }}>
                                    {filteredTables.map(table => (
                                        <TableCard
                                            key={table.id}
                                            table={table}
                                            onClick={() => handleTableClick(table)}
                                            onPaymentClick={() => {
                                                const branchPath = currentBranch?.slug || currentBranch?.code || localStorage.getItem('branchSlug');
                                                navigate(`/${branchPath}/pos/billing/${table.id}`, { state: { table, orderId: table.active_order_id } });
                                            }}
                                            onMenuOpen={handleMenuOpen}
                                        />
                                    ))}
                                </Box>
                            )}

                            {/* 3. Empty State */}
                            {displayMergeGroups.length === 0 && filteredTables.length === 0 && (
                                <Box sx={{ textAlign: 'center', py: 8 }}>
                                    <CircularProgress sx={{ color: '#FFC107', mb: 2 }} size={24} />
                                    <Typography color="text.secondary">No tables found here.</Typography>
                                </Box>
                            )}
                        </Box>
                    )}
                </Box>
            </Box>

            {/* 3. Right Sidebar (Takeaway/Delivery) */}
            <Box sx={{ width: 380, bgcolor: 'white', display: 'flex', flexDirection: 'column', height: '100%' }}>
                {/* Tabs */}
                <Box sx={{ px: 2, pt: 3 }}>
                    <Tabs
                        value={rightPanelTab}
                        onChange={(_, v) => setRightPanelTab(v)}
                        sx={{
                            '& .MuiTab-root': {
                                textTransform: 'none',
                                fontWeight: 600,
                                fontSize: '0.95rem',
                                minHeight: 48
                            },
                            '& .MuiTabs-indicator': { bgcolor: '#FFC107' },
                            '& .Mui-selected': { color: '#FFC107 !important' }
                        }}
                    >
                        <Tab
                            icon={<ShoppingBag size={18} />}
                            iconPosition="start"
                            label="Takeaway"
                        />
                        <Tab
                            icon={<Bike size={18} />}
                            iconPosition="start"
                            label="Delivery"
                        />
                    </Tabs>
                </Box>

                <Divider />

                {/* Content */}
                {/* Content */}
                <Box sx={{ flex: 1, overflowY: 'auto', p: 2 }}>
                    {activeOrders.filter(o => (rightPanelTab === 0 ? o.order_type === 'Takeaway' : o.order_type === 'Delivery')).length > 0 ? (
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                            {activeOrders
                                .filter(o => (rightPanelTab === 0 ? o.order_type === 'Takeaway' : o.order_type === 'Delivery'))
                                .map((order) => (
                                    <Paper
                                        key={order.id}
                                        onClick={() => {
                                            const branchPath = currentBranch?.slug || currentBranch?.code || localStorage.getItem('branchSlug');
                                            const targetUrl = order.table_id ? `/${branchPath}/pos/order/${order.table_id}` : `/${branchPath}/pos/order`;
                                            navigate(targetUrl, { state: { orderId: order.id } });
                                        }}
                                        elevation={0}
                                        sx={{
                                            p: 2,
                                            borderRadius: '16px',
                                            border: '1px solid #f1f5f9',
                                            cursor: 'pointer',
                                            transition: 'all 0.2s',
                                            '&:hover': { borderColor: '#FFC107', bgcolor: '#fff7ed' }
                                        }}
                                    >
                                        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                            <Typography fontWeight={800} color="#1e293b">#{order.order_number}</Typography>
                                            <Chip
                                                label={order.status}
                                                size="small"
                                                sx={{
                                                    height: 20,
                                                    fontSize: '10px',
                                                    fontWeight: 800,
                                                    bgcolor: order.status === 'Draft' ? '#f1f5f9' : '#fff7ed',
                                                    color: order.status === 'Draft' ? '#64748b' : '#FFC107'
                                                }}
                                            />
                                        </Box>
                                        <Typography variant="body2" fontWeight={700} sx={{ mb: 0.5 }}>{order.customer?.name || 'Walk-in Customer'}</Typography>
                                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                            <Typography variant="caption" color="text.secondary">
                                                {order.items?.length || 0} Items • Rs. {Number(order.net_amount).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                                            </Typography>
                                            <Button
                                                size="small"
                                                variant="contained"
                                                onClick={(e) => {
                                                    e.stopPropagation();
                                                    const branchPath = currentBranch?.slug || currentBranch?.code || localStorage.getItem('branchSlug');
                                                    navigate(`/${branchPath}/pos/billing/${order.table_id || '0'}`, { state: { table: order.table, orderId: order.id } });
                                                }}
                                                sx={{
                                                    height: 26,
                                                    fontSize: '10px',
                                                    fontWeight: 800,
                                                    borderRadius: '8px',
                                                    bgcolor: '#FFC107',
                                                    boxShadow: 'none',
                                                    '&:hover': { bgcolor: '#e67e00', boxShadow: 'none' }
                                                }}
                                            >
                                                Pay
                                            </Button>
                                        </Box>
                                    </Paper>
                                ))}
                        </Box>
                    ) : (
                        <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', opacity: 0.5 }}>
                            {rightPanelTab === 0 ? <ShoppingBag size={48} color="#94a3b8" /> : <Bike size={48} color="#94a3b8" />}
                            <Typography variant="h6" fontWeight={700} sx={{ mt: 2 }}>
                                No {rightPanelTab === 0 ? 'Takeaway' : 'Delivery'} Orders
                            </Typography>
                            <Typography variant="body2">Click below to start a new order</Typography>
                        </Box>
                    )}
                </Box>

                {/* Footer Action */}
                <Box sx={{ p: 3, borderTop: '1px solid #f0f0f0' }}>
                    <Button
                        fullWidth
                        variant="contained"
                        onClick={() => {
                            setNewOrderType(rightPanelTab === 0 ? 'Takeaway' : 'Delivery');
                            setDialogSelectedCustomer(null);
                            setDialogCustomerSearch('');
                            setDialogSelectedPartnerId(selectedPartnerId);
                            setOpenNewOrderDialog(true);
                        }}
                        sx={{
                            bgcolor: '#FFC107',
                            '&:hover': { bgcolor: '#e67e00' },
                            py: 1.5,
                            borderRadius: '12px',
                            textTransform: 'none',
                            fontWeight: 700,
                            fontSize: '1rem',
                            display: 'flex',
                            justifyContent: 'space-between',
                            px: 3
                        }}
                        endIcon={<Box component="span">›</Box>}
                    >
                        {rightPanelTab === 0 ? 'Add New Takeaway' : 'Add New Delivery'}
                    </Button>
                </Box>
            </Box>

            {/* Digital Menu QR Dialog */}
            <Dialog open={openDigitalMenu} onClose={() => setOpenDigitalMenu(false)}>
                <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Typography variant="h6" fontWeight={800}>Digital Menu QR</Typography>
                    <IconButton onClick={() => setOpenDigitalMenu(false)} size="small">×</IconButton>
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ p: 2, textAlign: 'center' }}>
                        <Box
                            sx={{
                                width: '100%', height: 320, bgcolor: '#f1f5f9', mb: 3, borderRadius: '16px',
                                display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden'
                            }}
                        >
                            {qrSrc ? (
                                <img
                                    src={qrSrc}
                                    alt="Digital Menu QR"
                                    style={{ width: 280, height: 280 }}
                                />
                            ) : (
                                <Box sx={{ width: 280, height: 280, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                    <CircularProgress sx={{ color: '#FFC107' }} />
                                </Box>
                            )}
                        </Box>

                        <Typography variant="subtitle1" fontWeight={800} color="#1e293b">Professional Digital Menu</Typography>

                        <Box
                            sx={{
                                mt: 1.5, mb: 2, p: 1.5, bgcolor: '#f8fafc', borderRadius: '12px', border: '1px dashed #cbd5e1',
                                cursor: 'pointer', '&:hover': { bgcolor: '#f1f5f9' }, transition: 'all 0.2s'
                            }}
                            onClick={() => window.open(`${window.location.origin}/digital-menu/${currentBranch?.slug || currentBranch?.code}`, '_blank')}
                        >
                            <Typography variant="caption" sx={{ color: '#4f46e5', fontWeight: 800, fontFamily: 'monospace', fontSize: '13px' }}>
                                {window.location.origin}/digital-menu/{currentBranch?.slug || currentBranch?.code}
                            </Typography>
                        </Box>

                        <Typography variant="body2" sx={{ mb: 3, color: 'text.secondary', fontWeight: 500, px: 2 }}>
                            Customers can scan this QR code to browse your live menu, categories, and prices instantly.
                        </Typography>

                        <Box sx={{ display: 'flex', gap: 2 }}>
                            <Button
                                fullWidth variant="outlined"
                                startIcon={<Plus size={18} style={{ transform: 'rotate(45deg)' }} />}
                                sx={{ borderRadius: '12px', textTransform: 'none', fontWeight: 700, borderColor: '#e2e8f0', color: '#1e293b' }}
                                onClick={() => setOpenDigitalMenu(false)}
                            >
                                Close
                            </Button>
                            <Button
                                fullWidth variant="contained"
                                sx={{
                                    bgcolor: '#2C1810', '&:hover': { bgcolor: '#000' },
                                    borderRadius: '12px', textTransform: 'none', fontWeight: 700
                                }}
                                onClick={() => window.open(`/digital-menu/${currentBranch?.slug || currentBranch?.code}`, '_blank')}
                            >
                                View Menu
                            </Button>
                        </Box>
                    </Box>
                </DialogContent>
            </Dialog>

            {/* New Order (Takeaway/Delivery) Setup Dialog */}
            <Dialog
                open={openNewOrderDialog}
                onClose={() => setOpenNewOrderDialog(false)}
                maxWidth="sm"
                PaperProps={{ sx: { borderRadius: '16px', minWidth: 400 } }}
            >
                <DialogTitle sx={{ fontWeight: 800, pb: 2 }}>
                    New {newOrderType} Order
                </DialogTitle>
                <DialogContent sx={{ minHeight: 250 }}>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.5, py: 1 }}>
                        {/* Customer Search & Select */}
                        <Box sx={{ position: 'relative' }}>
                            <Typography variant="subtitle2" fontWeight={700} sx={{ mb: 1, color: '#64748b' }}>
                                Customer <span style={{ color: '#ef4444' }}>*</span>
                            </Typography>
                            {dialogSelectedCustomer ? (
                                <Paper sx={{
                                    p: 1.5, borderRadius: '12px', bgcolor: '#fff7ed', border: '1px solid #ffedd5',
                                    display: 'flex', alignItems: 'center', gap: 2
                                }}>
                                    <UserCircle size={20} color="#FFC107" />
                                    <Box sx={{ flex: 1 }}>
                                        <Typography fontWeight={700} fontSize="14px">{dialogSelectedCustomer.name}</Typography>
                                        <Typography variant="caption" color="text.secondary">{dialogSelectedCustomer.phone || 'No phone'}</Typography>
                                    </Box>
                                    <IconButton size="small" onClick={() => setDialogSelectedCustomer(null)}>
                                        <Plus size={16} style={{ transform: 'rotate(45deg)' }} />
                                    </IconButton>
                                </Paper>
                            ) : (
                                <>
                                    <TextField
                                        fullWidth
                                        size="small"
                                        placeholder="Search by name or phone..."
                                        value={dialogCustomerSearch}
                                        onChange={(e) => setDialogCustomerSearch(e.target.value)}
                                        InputProps={{
                                            startAdornment: <InputAdornment position="start"><Search size={16} /></InputAdornment>,
                                            sx: { borderRadius: '12px' }
                                        }}
                                    />
                                    {dialogCustomerSearch && (
                                        <Paper sx={{
                                            position: 'absolute', top: '100%', left: 0, right: 0, zIndex: 10, mt: 0.5,
                                            maxHeight: 200, overflow: 'auto', borderRadius: '12px', boxShadow: '0 10px 25px rgba(0,0,0,0.1)'
                                        }}>
                                            <List sx={{ p: 0 }}>
                                                {customers
                                                    .filter(c => c.name.toLowerCase().includes(dialogCustomerSearch.toLowerCase()) || c.phone?.includes(dialogCustomerSearch))
                                                    .map(c => (
                                                        <ListItem
                                                            key={c.id}
                                                            disablePadding
                                                            sx={{ borderBottom: '1px solid #f1f5f9' }}
                                                        >
                                                            <ListItemButton
                                                                onClick={() => {
                                                                    setDialogSelectedCustomer(c);
                                                                    setDialogCustomerSearch('');
                                                                }}
                                                                sx={{ py: 1, px: 2 }}
                                                            >
                                                                <Box>
                                                                    <Typography variant="body2" fontWeight={700}>{c.name}</Typography>
                                                                    <Typography variant="caption" color="text.secondary">{c.phone}</Typography>
                                                                </Box>
                                                            </ListItemButton>
                                                        </ListItem>
                                                    ))
                                                }
                                                <ListItem
                                                    disablePadding
                                                    sx={{ bgcolor: '#f8fafc' }}
                                                >
                                                    <ListItemButton
                                                        onClick={async () => {
                                                            try {
                                                                const res = await customersAPI.create({ name: dialogCustomerSearch });
                                                                setDialogSelectedCustomer(res.data);
                                                                setCustomers(prev => [...prev, res.data]);
                                                                setDialogCustomerSearch('');
                                                            } catch (err) { showAlert("Error creating customer", "error"); }
                                                        }}
                                                    >
                                                        <Plus size={14} color="#FFC107" style={{ marginRight: 8 }} />
                                                        <Typography variant="body2" fontWeight={700} color="#FFC107">Quick Add "{dialogCustomerSearch}"</Typography>
                                                    </ListItemButton>
                                                </ListItem>
                                            </List>
                                        </Paper>
                                    )}
                                </>
                            )}
                        </Box>

                        {/* Delivery Partner Selection (for Delivery only) */}
                        {newOrderType === 'Delivery' && (
                            <Box>
                                <Typography variant="subtitle2" fontWeight={700} sx={{ mb: 1, color: '#64748b' }}>
                                    Delivery Partner <span style={{ color: '#ef4444' }}>*</span>
                                </Typography>
                                <FormControl fullWidth size="small">
                                    <InputLabel>Select Partner</InputLabel>
                                    <Select
                                        value={dialogSelectedPartnerId}
                                        onChange={(e) => setDialogSelectedPartnerId(e.target.value as string)}
                                        label="Select Partner"
                                        sx={{ borderRadius: '12px' }}
                                    >
                                        <MenuItem value=""><em>None</em></MenuItem>
                                        {deliveryPartners.map(p => (
                                            <MenuItem key={p.id} value={p.id.toString()}>{p.name}</MenuItem>
                                        ))}
                                    </Select>
                                </FormControl>
                            </Box>
                        )}
                    </Box>
                </DialogContent>
                <DialogActions sx={{ p: 2.5, pt: 1 }}>
                    <Button onClick={() => setOpenNewOrderDialog(false)} sx={{ color: '#64748b', fontWeight: 700 }}>Cancel</Button>
                    <Button
                        variant="contained"
                        disabled={!dialogSelectedCustomer || (newOrderType === 'Delivery' && !dialogSelectedPartnerId)}
                        onClick={() => {
                            navigate(`/${currentBranch?.code}/pos/order`, {
                                state: {
                                    customOrderType: newOrderType,
                                    deliveryPartnerId: dialogSelectedPartnerId,
                                    preSelectedCustomer: dialogSelectedCustomer
                                }
                            });
                            setOpenNewOrderDialog(false);
                        }}
                        sx={{
                            bgcolor: '#FFC107', '&:hover': { bgcolor: '#e67e00' },
                            fontWeight: 800, borderRadius: '12px', px: 3,
                            '&:disabled': { bgcolor: '#e2e8f0', color: '#94a3b8' }
                        }}
                    >
                        Start Order
                    </Button>
                </DialogActions>
            </Dialog>
            {/* Options Menu */}
            <Menu
                anchorEl={anchorEl}
                open={Boolean(anchorEl)}
                onClose={handleMenuClose}
                transformOrigin={{ horizontal: 'right', vertical: 'top' }}
                anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
            >
                <MenuItem onClick={handleToggleHold} sx={{ fontWeight: 600, fontSize: '0.9rem' }}>
                    {menuTarget?.is_hold_table === 'Yes' ? 'Set as Normal Table' : 'Set as Hold Table'}
                </MenuItem>
                <Divider />
                <Typography variant="caption" sx={{ px: 2, py: 1, display: 'block', color: 'text.secondary', fontWeight: 700 }}>
                    Merge With
                </Typography>
                <MenuItem onClick={() => handleMergeTable(null)} sx={{ fontSize: '0.9rem' }}>
                    None
                </MenuItem>
                {tables
                    .filter(t => t.status === 'Available' && t.id !== menuTarget?.id && !t.merge_group_id && t.is_hold_table !== 'Yes')
                    .map(t => (
                        <MenuItem key={t.id} onClick={() => handleMergeTable(t.id)} sx={{ fontSize: '0.9rem' }}>
                            Table {t.table_id}
                        </MenuItem>
                    ))
                }
            </Menu>

            {/* Opening Balance Dialog */}
            <Dialog open={openingDialog} onClose={() => setOpeningDialog(false)} maxWidth="xs" fullWidth>
                <DialogTitle sx={{ fontWeight: 800 }}>Start POS Session</DialogTitle>
                <DialogContent>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                        Please enter the starting cash amount in your drawer.
                    </Typography>
                    <TextField
                        autoFocus
                        label="Opening Balance"
                        type="number"
                        fullWidth
                        value={openingCash}
                        onChange={(e) => setOpeningCash(e.target.value)}
                        InputProps={{
                            startAdornment: <InputAdornment position="start">Rs.</InputAdornment>,
                        }}
                        sx={{
                            '& .MuiOutlinedInput-root': {
                                borderRadius: '12px',
                            }
                        }}
                    />
                </DialogContent>
                <DialogActions sx={{ p: 3 }}>
                    <Button onClick={() => setOpeningDialog(false)} sx={{ color: '#64748b', fontWeight: 700 }}>
                        Cancel
                    </Button>
                    <Button
                        onClick={confirmStartSession}
                        variant="contained"
                        sx={{
                            bgcolor: '#FFC107',
                            '&:hover': { bgcolor: '#e67e00' },
                            fontWeight: 800,
                            borderRadius: '12px',
                            px: 3
                        }}
                    >
                        Start Session
                    </Button>
                </DialogActions>
            </Dialog>

            {/* Closing Balance Dialog */}
            <Dialog open={closingDialog} onClose={() => setClosingDialog(false)} maxWidth="xs" fullWidth>
                <DialogTitle sx={{ fontWeight: 800 }}>End POS Session</DialogTitle>
                <DialogContent>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                        Enter the actual cash amount currently in the drawer to close your session.
                    </Typography>
                    <TextField
                        autoFocus
                        label="Actual Cash Reported"
                        type="number"
                        fullWidth
                        value={actualCash}
                        onChange={(e) => setActualCash(e.target.value)}
                        InputProps={{
                            startAdornment: <InputAdornment position="start">Rs.</InputAdornment>,
                        }}
                        sx={{
                            '& .MuiOutlinedInput-root': {
                                borderRadius: '12px',
                            }
                        }}
                    />
                    {activeSession && (
                        <Box sx={{ mt: 3, p: 2, bgcolor: '#f8fafc', borderRadius: '12px' }}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                <Typography variant="body2" color="text.secondary">Total Sales:</Typography>
                                <Typography variant="body2" fontWeight={700}>Rs. {Number(activeSession.total_sales).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                            </Box>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                                <Typography variant="body2" color="text.secondary">Opening Balance:</Typography>
                                <Typography variant="body2" fontWeight={700}>Rs. {Number(activeSession.opening_cash).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</Typography>
                            </Box>
                        </Box>
                    )}
                </DialogContent>
                <DialogActions sx={{ p: 3 }}>
                    <Button onClick={() => setClosingDialog(false)} sx={{ color: '#64748b', fontWeight: 700 }}>
                        Cancel
                    </Button>
                    <Button
                        onClick={confirmEndSession}
                        variant="contained"
                        sx={{
                            bgcolor: '#ef4444',
                            '&:hover': { bgcolor: '#dc2626' },
                            fontWeight: 800,
                            borderRadius: '12px',
                            px: 3
                        }}
                    >
                        End Session
                    </Button>
                </DialogActions>
            </Dialog>
        </Box >
    );
};

export default POSDashboard;
