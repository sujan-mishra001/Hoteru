import React, { useState, useEffect } from 'react';
import {
    Box,
    Button,
    Card,
    CardContent,
    CardMedia,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    Grid,
    IconButton,
    TextField,
    Typography,
    Switch,
    FormControlLabel,
    CircularProgress,
    Chip,
} from '@mui/material';
import {
    Add as AddIcon,
    Edit as EditIcon,
    Delete as DeleteIcon,
    QrCode2 as QrCodeIcon,
    CloudUpload as UploadIcon,
} from '@mui/icons-material';
import { settingsAPI } from '../../services/api';

interface QRCode {
    id: number;
    name: string;
    image_url: string;
    is_active: boolean;
    display_order: number;
    branch_id?: number;
    created_at: string;
    updated_at: string;
}

const QRManagement: React.FC = () => {
    const [qrCodes, setQrCodes] = useState<QRCode[]>([]);
    const [loading, setLoading] = useState(true);
    const [dialogOpen, setDialogOpen] = useState(false);
    const [editMode, setEditMode] = useState(false);
    const [selectedQR, setSelectedQR] = useState<QRCode | null>(null);

    const [formData, setFormData] = useState({
        name: '',
        is_active: true,
        display_order: 0,
    });
    const [selectedFile, setSelectedFile] = useState<File | null>(null);
    const [previewUrl, setPreviewUrl] = useState<string>('');

    useEffect(() => {
        loadQRCodes();
    }, []);

    const loadQRCodes = async () => {
        try {
            setLoading(true);
            const response = await settingsAPI.get('/qr-codes/');
            setQrCodes(response.data);
        } catch (error) {
            console.error('Failed to load QR codes:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleOpenDialog = (qr?: QRCode) => {
        if (qr) {
            setEditMode(true);
            setSelectedQR(qr);
            setFormData({
                name: qr.name,
                is_active: qr.is_active,
                display_order: qr.display_order,
            });
            setPreviewUrl(`${import.meta.env.VITE_API_URL}${qr.image_url}`);
        } else {
            setEditMode(false);
            setSelectedQR(null);
            setFormData({
                name: '',
                is_active: true,
                display_order: 0,
            });
            setPreviewUrl('');
            setSelectedFile(null);
        }
        setDialogOpen(true);
    };

    const handleCloseDialog = () => {
        setDialogOpen(false);
        setSelectedFile(null);
        setPreviewUrl('');
    };

    const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (file) {
            setSelectedFile(file);
            const reader = new FileReader();
            reader.onloadend = () => {
                setPreviewUrl(reader.result as string);
            };
            reader.readAsDataURL(file);
        }
    };

    const handleSubmit = async () => {
        try {
            const formDataToSend = new FormData();
            formDataToSend.append('name', formData.name);
            formDataToSend.append('is_active', formData.is_active.toString());
            formDataToSend.append('display_order', formData.display_order.toString());

            if (selectedFile) {
                formDataToSend.append('image', selectedFile);
            }

            if (editMode && selectedQR) {
                await settingsAPI.put(`/qr-codes/${selectedQR.id}`, formDataToSend, {
                    headers: { 'Content-Type': 'multipart/form-data' },
                });
            } else {
                if (!selectedFile) {
                    alert('Please select an image');
                    return;
                }
                await settingsAPI.post('/qr-codes/', formDataToSend, {
                    headers: { 'Content-Type': 'multipart/form-data' },
                });
            }

            handleCloseDialog();
            loadQRCodes();
        } catch (error) {
            console.error('Failed to save QR code:', error);
            alert('Failed to save QR code');
        }
    };

    const handleDelete = async (id: number) => {
        if (window.confirm('Are you sure you want to delete this QR code?')) {
            try {
                await settingsAPI.delete(`/qr-codes/${id}`);
                loadQRCodes();
            } catch (error) {
                console.error('Failed to delete QR code:', error);
                alert('Failed to delete QR code');
            }
        }
    };

    if (loading) {
        return (
            <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
                <CircularProgress />
            </Box>
        );
    }

    return (
        <Box>
            <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
                <Typography variant="h4" fontWeight="bold">
                    QR Code Management
                </Typography>
                <Button
                    variant="contained"
                    startIcon={<AddIcon />}
                    onClick={() => handleOpenDialog()}
                    sx={{
                        bgcolor: '#FFC107',
                        color: '#000',
                        '&:hover': { bgcolor: '#FFB300' },
                    }}
                >
                    Add QR Code
                </Button>
            </Box>

            {qrCodes.length === 0 ? (
                <Card sx={{ p: 4, textAlign: 'center' }}>
                    <QrCodeIcon sx={{ fontSize: 100, color: 'grey.300', mb: 2 }} />
                    <Typography variant="h6" gutterBottom>
                        No QR Codes Yet
                    </Typography>
                    <Typography color="text.secondary" mb={3}>
                        Add QR codes for payment methods like Fonepay, eSewa, or Khalti.
                    </Typography>
                    <Button
                        variant="contained"
                        startIcon={<AddIcon />}
                        onClick={() => handleOpenDialog()}
                        sx={{
                            bgcolor: '#FFC107',
                            color: '#000',
                            '&:hover': { bgcolor: '#FFB300' },
                        }}
                    >
                        Add First QR Code
                    </Button>
                </Card>
            ) : (
                <Grid container spacing={3}>
                    {qrCodes.map((qr) => (
                        <Grid item xs={12} sm={6} md={4} lg={3} key={qr.id}>
                            <Card>
                                <CardMedia
                                    component="img"
                                    height="200"
                                    image={`${import.meta.env.VITE_API_URL}${qr.image_url}`}
                                    alt={qr.name}
                                    sx={{ objectFit: 'contain', bgcolor: 'grey.100', p: 2 }}
                                />
                                <CardContent>
                                    <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                                        <Typography variant="h6" fontWeight="bold">
                                            {qr.name}
                                        </Typography>
                                        <Chip
                                            label={qr.is_active ? 'Active' : 'Inactive'}
                                            color={qr.is_active ? 'success' : 'error'}
                                            size="small"
                                        />
                                    </Box>
                                    <Typography variant="body2" color="text.secondary" mb={2}>
                                        Display Order: {qr.display_order}
                                    </Typography>
                                    <Box display="flex" gap={1}>
                                        <IconButton
                                            size="small"
                                            onClick={() => handleOpenDialog(qr)}
                                            sx={{ color: 'warning.main' }}
                                        >
                                            <EditIcon />
                                        </IconButton>
                                        <IconButton
                                            size="small"
                                            onClick={() => handleDelete(qr.id)}
                                            sx={{ color: 'error.main' }}
                                        >
                                            <DeleteIcon />
                                        </IconButton>
                                    </Box>
                                </CardContent>
                            </Card>
                        </Grid>
                    ))}
                </Grid>
            )}

            {/* Add/Edit Dialog */}
            <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
                <DialogTitle>{editMode ? 'Edit QR Code' : 'Add QR Code'}</DialogTitle>
                <DialogContent>
                    <Box sx={{ pt: 2, display: 'flex', flexDirection: 'column', gap: 2 }}>
                        <TextField
                            label="QR Name"
                            fullWidth
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            placeholder="e.g., Fonepay, eSewa, Khalti"
                        />

                        {/* Image Upload */}
                        <Box>
                            <input
                                accept="image/*"
                                style={{ display: 'none' }}
                                id="qr-image-upload"
                                type="file"
                                onChange={handleFileSelect}
                            />
                            <label htmlFor="qr-image-upload">
                                <Button
                                    variant="outlined"
                                    component="span"
                                    startIcon={<UploadIcon />}
                                    fullWidth
                                >
                                    {selectedFile ? 'Change Image' : 'Upload QR Image'}
                                </Button>
                            </label>
                            {previewUrl && (
                                <Box mt={2} textAlign="center">
                                    <img
                                        src={previewUrl}
                                        alt="Preview"
                                        style={{ maxWidth: '100%', maxHeight: '300px', borderRadius: '8px' }}
                                    />
                                </Box>
                            )}
                        </Box>

                        <FormControlLabel
                            control={
                                <Switch
                                    checked={formData.is_active}
                                    onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
                                    color="warning"
                                />
                            }
                            label="Active"
                        />

                        <TextField
                            label="Display Order"
                            type="number"
                            fullWidth
                            value={formData.display_order}
                            onChange={(e) => setFormData({ ...formData, display_order: parseInt(e.target.value) || 0 })}
                        />
                    </Box>
                </DialogContent>
                <DialogActions>
                    <Button onClick={handleCloseDialog}>Cancel</Button>
                    <Button
                        onClick={handleSubmit}
                        variant="contained"
                        sx={{
                            bgcolor: '#FFC107',
                            color: '#000',
                            '&:hover': { bgcolor: '#FFB300' },
                        }}
                    >
                        {editMode ? 'Update' : 'Create'}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default QRManagement;
