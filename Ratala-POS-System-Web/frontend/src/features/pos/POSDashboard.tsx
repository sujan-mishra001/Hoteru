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
    Divider
} from '@mui/material';
import {
    RefreshCw,
    Armchair,
    Bike,
    ShoppingBag,
    Play,
    Square
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../app/providers/AuthProvider';
import { usePermission } from '../../app/providers/PermissionProvider';
import { floorsAPI, tablesAPI, sessionsAPI, authAPI } from '../../services/api';
import { useNotification } from '../../app/providers/NotificationProvider';

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
}

// Table Card Component
const TableCard: React.FC<{
    table: TableData;
    onClick: () => void;
    onPaymentClick: () => void;
}> = ({ table, onClick, onPaymentClick }) => {
    const isOccupied = table.status !== 'Available' || table.active_order_id !== null;
    const [duration, setDuration] = useState<string>('');

    // Timer logic
    useEffect(() => {
        if (!isOccupied || !table.order_start_time) return;

        const updateTimer = () => {
            const start = new Date(table.order_start_time!).getTime();
            const now = new Date().getTime();
            const diff = now - start;

            const hours = Math.floor(diff / (1000 * 60 * 60));
            const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));

            if (hours > 0) {
                setDuration(`${hours} hr ${minutes} min`);
            } else {
                setDuration(`${minutes} min`);
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
                        Vacant
                    </Typography>
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
    const { showAlert, showConfirm } = useNotification();
    const [loading, setLoading] = useState(true);

    // Data
    const [floors, setFloors] = useState<Floor[]>([]);
    const [selectedFloorId, setSelectedFloorId] = useState<number | null>(null);
    const [tables, setTables] = useState<TableData[]>([]);
    const [activeSessionId, setActiveSessionId] = useState<number | null>(null);
    const [globalActiveSession, setGlobalActiveSession] = useState<any>(null); // For Admin to see other's session

    // Right Panel Tabs
    const [rightPanelTab, setRightPanelTab] = useState(0); // 0: Takeaway, 1: Delivery

    // Loader
    const loadData = useCallback(async () => {
        try {
            const [floorsRes, tablesRes, userRes, sessionsRes] = await Promise.all([
                floorsAPI.getAll(),
                tablesAPI.getAll(),
                authAPI.getCurrentUser(),
                sessionsAPI.getAll()
            ]);

            setFloors(floorsRes.data || []);
            setTables(tablesRes.data || []);

            const sessionData = sessionsRes.data || [];


            // 1. My personal active session
            const userActiveSession = sessionData.find((s: any) => s.user_id === userRes.data.id && s.status === 'Open');

            // 2. Any global active session (for admins to see)
            const globalSession = sessionData.find((s: any) => s.status === 'Open');

            if (userActiveSession) {
                setActiveSessionId(userActiveSession.id);
                setGlobalActiveSession(null);
            } else if (globalSession) {
                // Everyone adapts to the global session context (Admins can manage, Workers view only)
                setActiveSessionId(globalSession.id);
                setGlobalActiveSession(globalSession);
            } else {
                setActiveSessionId(null);
                setGlobalActiveSession(null);
            }

            // Set initial floor if not set
            if (floorsRes.data?.length > 0 && !selectedFloorId) {
                setSelectedFloorId(floorsRes.data[0].id);
            }
        } catch (error) {
            console.error('Error loading data:', error);
        } finally {
            setLoading(false);
        }
    }, [selectedFloorId]);

    const handleStartSession = async () => {
        try {
            const payload = {
                opening_cash: 0,
                notes: 'Session started via POS Header'
            };
            const response = await sessionsAPI.create(payload);
            setActiveSessionId(response.data.id);
            showAlert('Session started successfully', 'success');
            loadData();
        } catch (error: any) {
            showAlert(error.response?.data?.detail || 'Failed to start session', 'error');
        }
    };

    const handleEndSession = async () => {
        if (!activeSessionId) return;

        showConfirm({
            title: 'End Session?',
            message: 'Are you sure you want to end your current session? This will generate a session report.',
            onConfirm: async () => {
                try {
                    const payload = {
                        status: 'Closed'
                    };
                    const response = await sessionsAPI.update(activeSessionId, payload);
                    setActiveSessionId(null);

                    // Trigger PDF Export immediately
                    window.open(`${import.meta.env.VITE_API_BASE_URL}/v1/reports/export/shift/${activeSessionId}`, '_blank');

                    showAlert(`Session closed successfully. Total Sales: Rs. ${response.data.total_sales.toLocaleString()}`, 'success');

                    // Redirect to POS/Tables swiftly
                    navigate('/pos');
                } catch (error: any) {
                    showAlert(error.response?.data?.detail || 'Failed to close session', 'error');
                }
            }
        });
    };

    useEffect(() => {
        loadData();
        const interval = setInterval(loadData, 30000); // Refresh every 30s
        return () => clearInterval(interval);
    }, [loadData]);


    const handleTableClick = (table: TableData) => {
        if (table.active_order_id) {
            navigate(`/pos/order/${table.id}`, { state: { table, orderId: table.active_order_id } });
        } else {
            navigate(`/pos/order/${table.id}`, { state: { table } });
        }
    };

    // Filter tables by selected floor
    const filteredTables = selectedFloorId === -1
        ? tables.filter(t => t.is_hold_table === 'Yes')
        : tables.filter(t => t.floor_id === selectedFloorId);
    return (
        <Box sx={{ display: 'flex', height: '100vh', bgcolor: '#f8fafc', overflow: 'hidden' }}>
            <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', borderRight: '1px solid #e2e8f0', overflow: 'hidden' }}>
                {/* Header / Floor Tabs */}
                <Box sx={{ px: 3, pt: 3, pb: 2, bgcolor: 'white' }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
                        {/* Floor Tabs */}
                        <Tabs
                            value={selectedFloorId}
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
                                    onPaymentClick={() => navigate(`/pos/billing/${table.id}`, { state: { table } })}
                                />
                            ))}

                            {/* Empty State */}
                            {filteredTables.length === 0 && (
                                <Box sx={{ gridColumn: '1/-1', textAlign: 'center', py: 8 }}>
                                    <Typography color="text.secondary">No tables found on this floor.</Typography>
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
                <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', p: 3 }}>
                    <Box
                        sx={{
                            width: 80,
                            height: 80,
                            bgcolor: '#f1f5f9',
                            borderRadius: '50%',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            mb: 2
                        }}
                    >
                        <Box
                            sx={{ border: '2px solid #cbd5e1', borderRadius: '8px', p: 1 }}
                        >
                            <Box sx={{ width: 24, height: 2, bgcolor: '#cbd5e1', mb: 0.5 }} />
                            <Box sx={{ width: 24, height: 2, bgcolor: '#cbd5e1', mb: 0.5 }} />
                            <Box sx={{ width: 16, height: 2, bgcolor: '#cbd5e1' }} />
                        </Box>
                    </Box>
                    <Typography variant="h6" color="text.secondary" fontWeight={600}>
                        No Orders Yet!
                    </Typography>
                </Box>

                {/* Footer Action */}
                <Box sx={{ p: 3, borderTop: '1px solid #f0f0f0' }}>
                    <Button
                        fullWidth
                        variant="contained"
                        onClick={() => {
                            const availableHoldTable = tables.find(t => t.is_hold_table === 'Yes' && t.active_order_id === null);
                            if (availableHoldTable) {
                                handleTableClick(availableHoldTable);
                            } else {
                                showAlert("No available hold tables. Please clear some first.", "warning");
                            }
                        }}
                        sx={{
                            bgcolor: '#FFC107', // Orange
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
        </Box >
    );
};

export default POSDashboard;

