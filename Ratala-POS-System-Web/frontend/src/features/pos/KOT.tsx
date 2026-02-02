import React, { useState, useEffect, useRef } from 'react';
import {
    Box,
    Typography,
    Paper,
    Button,
    Tabs,
    Tab,
    Divider,
    CircularProgress,
    Chip,
    IconButton,
    Tooltip
} from '@mui/material';
import { ChefHat, Beer, Clock, Printer, CheckCircle2, XCircle } from 'lucide-react';
import { kotAPI } from '../../services/api';
import { useReactToPrint } from 'react-to-print';
import { useBranch } from '../../app/providers/BranchProvider';
import KOTPrintView from './billing/KOTPrintView';

interface KOTItem {
    id: number;
    kot_number: string;
    kot_type: string;
    order_id: number;
    status: string;
    created_at: string;
    order?: {
        table_id?: number;
        table?: { table_id: string };
        customer?: { name: string };
        order_type?: string;
    };
    items?: Array<{
        id: number;
        menu_item_id: number;
        quantity: number;
        notes?: string;
        menu_item?: {
            name: string;
            price: number;
        };
    }>;
}

const KOT: React.FC = () => {
    const [mainTab, setMainTab] = useState(0);
    const [statusFilter, setStatusFilter] = useState('Pending'); // Pending, Served, All
    const [kots, setKots] = useState<KOTItem[]>([]);
    const [loading, setLoading] = useState(true);
    const { currentBranch } = useBranch();
    const [selectedKot, setSelectedKot] = useState<KOTItem | null>(null);

    const kotRef = useRef<HTMLDivElement>(null);

    const handlePrintKot = useReactToPrint({
        contentRef: kotRef,
        documentTitle: `KOT_${selectedKot?.kot_number}`,
        onPrintError: () => alert("Printer not found or error occurred while printing.")
    });

    useEffect(() => {
        loadKots();
    }, [mainTab, statusFilter]);

    const loadKots = async () => {
        try {
            setLoading(true);
            const kotType = mainTab === 0 ? 'KOT' : 'BOT';
            const params: { kot_type: string; status?: string } = { kot_type: kotType };
            if (statusFilter !== 'All') params.status = statusFilter;

            const response = await kotAPI.getAll(params);
            const allKots: KOTItem[] = response.data || [];
            allKots.sort((a: KOTItem, b: KOTItem) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
            setKots(allKots);

            // Auto select first one if none selected or selected one no longer in list
            if (allKots.length > 0 && (!selectedKot || !allKots.find((k: KOTItem) => k.id === selectedKot.id))) {
                setSelectedKot(allKots[0]);
            } else if (allKots.length === 0) {
                setSelectedKot(null);
            }
        } catch (error) {
            setKots([]);
        } finally {
            setLoading(false);
        }
    };

    const handleStatusUpdate = async (kotId: number, newStatus: string) => {
        try {
            await kotAPI.updateStatus(kotId, newStatus);
            loadKots();
        } catch (error) {
            console.error('Error updating status:', error);
        }
    };

    const formatTime = (dateString: string) => {
        const date = new Date(dateString);
        return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    };

    const getWaitTime = (dateString: string) => {
        const diff = Math.floor((new Date().getTime() - new Date(dateString).getTime()) / 60000);
        return `${diff}m ago`;
    };

    return (
        <Box sx={{ display: 'flex', height: 'calc(100vh - 120px)', bgcolor: '#f8fafc', m: -3, p: 3 }}>
            {/* Hidden Print Content */}
            <Box sx={{ display: 'none' }}>
                <KOTPrintView ref={kotRef} kot={selectedKot} branch={currentBranch} />
            </Box>

            {/* Left: KOT List */}
            <Box sx={{ width: 400, display: 'flex', flexDirection: 'column', gap: 2, pr: 2 }}>
                <Paper sx={{ p: 1, borderRadius: '12px' }}>
                    <Tabs
                        value={mainTab}
                        onChange={(_, v) => setMainTab(v)}
                        variant="fullWidth"
                        sx={{ minHeight: 40 }}
                    >
                        <Tab
                            label="Kitchen (KOT)"
                            icon={<ChefHat size={16} />}
                            iconPosition="start"
                            sx={{ minHeight: 40, textTransform: 'none', fontWeight: 700 }}
                        />
                        <Tab
                            label="Bar (BOT)"
                            icon={<Beer size={16} />}
                            iconPosition="start"
                            sx={{ minHeight: 40, textTransform: 'none', fontWeight: 700 }}
                        />
                    </Tabs>
                </Paper>

                <Box sx={{ display: 'flex', gap: 1 }}>
                    {['Pending', 'Served', 'All'].map(status => (
                        <Button
                            key={status}
                            size="small"
                            variant={statusFilter === status ? 'contained' : 'outlined'}
                            onClick={() => setStatusFilter(status)}
                            sx={{
                                flex: 1,
                                borderRadius: '20px',
                                textTransform: 'none',
                                bgcolor: statusFilter === status ? '#FF8C00' : 'white',
                                color: statusFilter === status ? 'white' : '#64748b',
                                border: statusFilter === status ? 'none' : '1px solid #e2e8f0',
                                '&:hover': { bgcolor: statusFilter === status ? '#FF7700' : '#f1f5f9' }
                            }}
                        >
                            {status}
                        </Button>
                    ))}
                </Box>

                <Box sx={{ flexGrow: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                    {loading ? (
                        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}><CircularProgress size={24} /></Box>
                    ) : kots.length === 0 ? (
                        <Box sx={{ textAlign: 'center', py: 8 }}>
                            <Typography variant="body2" color="text.secondary">No active orders</Typography>
                        </Box>
                    ) : (
                        kots.map((kot) => (
                            <Paper
                                key={kot.id}
                                onClick={() => setSelectedKot(kot)}
                                sx={{
                                    p: 2,
                                    cursor: 'pointer',
                                    borderRadius: '12px',
                                    border: '2px solid',
                                    borderColor: selectedKot?.id === kot.id ? '#FF8C00' : 'transparent',
                                    transition: 'all 0.2s',
                                    '&:hover': { bgcolor: '#fff' }
                                }}
                                elevation={selectedKot?.id === kot.id ? 2 : 0}
                            >
                                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1 }}>
                                    <Typography variant="h6" fontWeight={800}>{kot.order?.table?.table_id || 'Walk-in'}</Typography>
                                    <Chip
                                        label={kot.status}
                                        size="small"
                                        sx={{
                                            fontSize: '0.65rem',
                                            fontWeight: 800,
                                            bgcolor: kot.status === 'Served' ? '#ecfdf5' : '#fff7ed',
                                            color: kot.status === 'Served' ? '#10b981' : '#f59e0b'
                                        }}
                                    />
                                </Box>
                                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                    <Typography variant="caption" color="text.secondary">#{kot.kot_number}</Typography>
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                                        <Clock size={12} color="#64748b" />
                                        <Typography variant="caption" color="text.secondary">{getWaitTime(kot.created_at)}</Typography>
                                    </Box>
                                </Box>
                            </Paper>
                        ))
                    )}
                </Box>
            </Box>

            {/* Right: Detailed View */}
            <Box sx={{ flexGrow: 1 }}>
                {selectedKot ? (
                    <Paper sx={{ height: '100%', borderRadius: '16px', display: 'flex', flexDirection: 'column' }}>
                        <Box sx={{ p: 3, borderBottom: '1px solid #f1f5f9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <Box>
                                <Typography variant="h5" fontWeight={900}>Table {selectedKot.order?.table?.table_id || 'N/A'}</Typography>
                                <Typography variant="body2" color="text.secondary">Order #{selectedKot.kot_number} • {formatTime(selectedKot.created_at)}</Typography>
                            </Box>
                            <Box sx={{ display: 'flex', gap: 1 }}>
                                <Tooltip title="Print KOT">
                                    <IconButton onClick={() => handlePrintKot()}><Printer size={20} /></IconButton>
                                </Tooltip>
                                {selectedKot.status !== 'Served' ? (
                                    <Button
                                        variant="contained"
                                        startIcon={<CheckCircle2 size={18} />}
                                        onClick={() => handleStatusUpdate(selectedKot.id, 'Served')}
                                        sx={{ bgcolor: '#10b981', '&:hover': { bgcolor: '#059669' }, textTransform: 'none', borderRadius: '10px' }}
                                    >
                                        Mark as Served
                                    </Button>
                                ) : (
                                    <Button
                                        variant="outlined"
                                        onClick={() => handleStatusUpdate(selectedKot.id, 'Pending')}
                                        sx={{ color: '#f59e0b', borderColor: '#f59e0b', textTransform: 'none', borderRadius: '10px' }}
                                    >
                                        Revert to Pending
                                    </Button>
                                )}
                                <Button
                                    variant="outlined"
                                    color="error"
                                    startIcon={<XCircle size={18} />}
                                    sx={{ textTransform: 'none', borderRadius: '10px' }}
                                >
                                    Cancel
                                </Button>
                            </Box>
                        </Box>

                        <Box sx={{ p: 3, flexGrow: 1, overflowY: 'auto' }}>
                            <Typography variant="subtitle1" fontWeight={800} sx={{ mb: 2 }}>Items Preparation</Typography>
                            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                                {selectedKot.items?.map((item) => (
                                    <Box
                                        key={item.id}
                                        sx={{
                                            p: 2,
                                            bgcolor: '#f8fafc',
                                            borderRadius: '12px',
                                            display: 'flex',
                                            justifyContent: 'space-between',
                                            alignItems: 'center'
                                        }}
                                    >
                                        <Box>
                                            <Typography variant="subtitle1" fontWeight={700}>
                                                <span style={{ color: '#FF8C00', marginRight: '12px' }}>{item.quantity}x</span>
                                                {item.menu_item?.name}
                                            </Typography>
                                            {item.notes && (
                                                <Typography variant="body2" color="error" sx={{ mt: 0.5, fontWeight: 600 }}>
                                                    Note: {item.notes}
                                                </Typography>
                                            )}
                                        </Box>
                                        <Box sx={{ display: 'flex', gap: 1 }}>
                                            {/* Could add individual item status tracking here */}
                                        </Box>
                                    </Box>
                                ))}
                            </Box>
                        </Box>

                        <Divider />
                        <Box sx={{ p: 1, bgcolor: 'white', borderRadius: '0 0 16px 16px' }}>
                            <Button
                                fullWidth
                                variant="contained"
                                startIcon={<Printer size={20} />}
                                onClick={() => handlePrintKot()}
                                sx={{
                                    py: 1,
                                    bgcolor: '#FF8C00',
                                    '&:hover': { bgcolor: '#e67e00' },
                                    borderRadius: '12px',
                                    fontWeight: 800,
                                    fontSize: '16px',
                                    textTransform: 'none'
                                }}
                            >
                                Print {selectedKot.kot_type || 'KOT'}
                            </Button>
                        </Box>
                    </Paper>
                ) : (
                    <Paper sx={{ height: '100%', borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Box sx={{ textAlign: 'center' }}>
                            <ChefHat size={48} color="#e2e8f0" style={{ marginBottom: '16px' }} />
                            <Typography variant="body1" color="text.secondary">Select a KOT to view details</Typography>
                        </Box>
                    </Paper>
                )}
            </Box>
        </Box>
    );
};

export default KOT;
