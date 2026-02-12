import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import {
    Box,
    Typography,
    Container,
    Grid,
    Card,
    CardContent,
    CardMedia,
    Chip,
    CircularProgress,
    InputBase,
    useTheme,
    useMediaQuery,
    Paper,
    Snackbar,
    Alert
} from '@mui/material';
import { Search, MapPin, Phone, Instagram, Facebook } from 'lucide-react';
import { menuAPI, settingsAPI, API_BASE_URL } from '../../services/api';

const DigitalMenu: React.FC = () => {
    const { branchId } = useParams<{ branchId: string }>();
    const theme = useTheme();
    const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
    const [loading, setLoading] = useState(true);
    const [menuItems, setMenuItems] = useState<any[]>([]);
    const [categories, setCategories] = useState<any[]>([]);
    const [companySettings, setCompanySettings] = useState<any>(null);
    const [searchQuery, setSearchQuery] = useState('');
    const [activeCategory, setActiveCategory] = useState(0);
    const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as 'success' | 'error' });

    // Entry animation keyframes
    const fadeInUp = {
        '@keyframes fadeInUp': {
            from: { opacity: 0, transform: 'translateY(20px)' },
            to: { opacity: 1, transform: 'translateY(0)' }
        }
    };

    const showSnackbar = (message: string, severity: 'success' | 'error' = 'success') => {
        setSnackbar({ open: true, message, severity });
    };

    useEffect(() => {
        fetchData();
    }, [branchId]);

    const fetchData = async () => {
        const cleanBranchId = branchId?.replace(/^:/, '');
        const branchParam = cleanBranchId ? parseInt(cleanBranchId) : NaN;

        if (isNaN(branchParam)) {
            setLoading(false);
            return;
        }
        try {
            setLoading(true);
            const [itemsRes, catRes, settingsRes] = await Promise.all([
                menuAPI.getPublicItems(branchParam),
                menuAPI.getPublicCategories(branchParam),
                settingsAPI.getPublicCompanySettings(branchParam)
            ]);

            const activeItems = (itemsRes.data || []).filter((item: any) => item.is_active);
            const activeCats = (catRes.data || []).filter((cat: any) => cat.is_active);

            setMenuItems(activeItems);
            setCategories([{ id: 0, name: 'Our Specialties' }, ...activeCats]);
            setCompanySettings(settingsRes.data);
        } catch (error) {
            console.error('Error fetching digital menu data:', error);
        } finally {
            setLoading(false);
        }
    };

    const filteredItems = menuItems.filter(item => {
        const matchesSearch = item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
            (item.description && item.description.toLowerCase().includes(searchQuery.toLowerCase()));
        const matchesCategory = activeCategory === 0 || item.category_id === activeCategory;
        return matchesSearch && matchesCategory;
    });

    if (loading) {
        return (
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100vh', bgcolor: '#f8fafc' }}>
                <CircularProgress sx={{ color: '#FFC107', mb: 2, thickness: 5 }} />
                <Typography variant="body1" fontWeight={700} color="#1e293b" sx={{ letterSpacing: '1px' }}>PREPARING YOUR MENU...</Typography>
            </Box>
        );
    }

    return (
        <Box sx={{ bgcolor: '#fdfdfd', minHeight: '100vh', pb: 12, ...fadeInUp }}>
            {/* Elegant Hero Section */}
            <Box sx={{
                height: isMobile ? '260px' : '380px',
                position: 'relative',
                backgroundImage: `linear-gradient(to bottom, rgba(0,0,0,0.3), rgba(0,0,0,0.8)), url('https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&q=80&w=2070')`,
                backgroundSize: 'cover',
                backgroundPosition: 'center',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                textAlign: 'center',
                color: 'white',
                px: 2
            }}>
                <Box sx={{ animation: 'fadeInUp 0.8s ease-out' }}>
                    <Typography variant={isMobile ? "h3" : "h1"} fontWeight={900} sx={{ letterSpacing: '-0.04em', mb: 1, textShadow: '0 4px 12px rgba(0,0,0,0.3)' }}>
                        {companySettings?.company_name || 'RATALA'}
                    </Typography>
                    <Typography variant="h6" sx={{ opacity: 0.9, fontWeight: 500, maxWidth: '600px', mx: 'auto', fontStyle: 'italic', color: '#FFC107' }}>
                        "{companySettings?.slogan || 'Savor the authentic taste of tradition'}"
                    </Typography>
                </Box>

                {/* Glassmorphism Search Bar */}
                <Paper
                    elevation={0}
                    sx={{
                        position: 'absolute',
                        bottom: '-28px',
                        width: isMobile ? '90%' : '560px',
                        height: '56px',
                        display: 'flex',
                        alignItems: 'center',
                        px: 3,
                        borderRadius: '28px',
                        bgcolor: 'rgba(255, 255, 255, 0.95)',
                        backdropFilter: 'blur(10px)',
                        boxShadow: '0 10px 30px rgba(0,0,0,0.1)',
                        border: '1px solid rgba(255,255,255,0.2)',
                        animation: 'fadeInUp 1s ease-out'
                    }}
                >
                    <Search color="#64748b" size={22} />
                    <InputBase
                        sx={{ ml: 2, flex: 1, fontWeight: 600, fontSize: '16px', color: '#1e293b' }}
                        placeholder="Search for your favorite dishes..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                    />
                </Paper>
            </Box>

            {!companySettings && !loading ? (
                <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '50vh', p: 4, textAlign: 'center' }}>
                    <Typography variant="h4" fontWeight={900} color="#1e293b">Menu Unavailable</Typography>
                    <Typography color="text.secondary" sx={{ mt: 2, maxWidth: '400px', fontWeight: 500 }}>
                        We couldn't find the menu for this branch. Please check the scan or contact the restaurant.
                    </Typography>
                </Box>
            ) : (
                <Container maxWidth="lg" sx={{ mt: 10 }}>
                    {/* Premium Categories Scroll */}
                    <Box sx={{
                        mb: 6, overflowX: 'auto', display: 'flex', gap: 1.5, pb: 2,
                        '&::-webkit-scrollbar': { height: '4px' },
                        '&::-webkit-scrollbar-thumb': { bgcolor: '#e2e8f0', borderRadius: '10px' }
                    }}>
                        {categories.map((cat, idx) => (
                            <Chip
                                key={cat.id || idx}
                                label={cat.name}
                                onClick={() => setActiveCategory(cat.id)}
                                sx={{
                                    px: 2,
                                    height: '46px',
                                    fontWeight: 800,
                                    fontSize: '14px',
                                    textTransform: 'uppercase',
                                    letterSpacing: '0.5px',
                                    transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
                                    bgcolor: activeCategory === cat.id ? '#1e293b' : 'white',
                                    color: activeCategory === cat.id ? 'white' : '#64748b',
                                    border: '2px solid',
                                    borderColor: activeCategory === cat.id ? '#1e293b' : '#f1f5f9',
                                    boxShadow: activeCategory === cat.id ? '0 10px 20px rgba(30,41,59,0.2)' : 'none',
                                    '&:hover': {
                                        bgcolor: activeCategory === cat.id ? '#1e293b' : '#f8fafc',
                                        transform: 'translateY(-2px)'
                                    },
                                    '& .MuiChip-label': { px: 2 }
                                }}
                            />
                        ))}
                    </Box>

                    {/* Menu Items Showcase */}
                    {filteredItems.length === 0 ? (
                        <Box sx={{ textAlign: 'center', py: 12, bgcolor: '#f8fafc', borderRadius: '30px' }}>
                            <Typography variant="h5" fontWeight={700} color="#64748b">
                                No items found in this section.
                            </Typography>
                            <Typography variant="body2" color="#94a3b8" sx={{ mt: 1 }}>
                                Try searching for something else or browse different categories.
                            </Typography>
                        </Box>
                    ) : (
                        <Grid container spacing={4}>
                            {filteredItems.map((item, index) => (
                                <Grid size={{ xs: 12, sm: 6, md: 4 }} key={item.id}>
                                    <Card sx={{
                                        height: '100%',
                                        display: 'flex',
                                        flexDirection: 'column',
                                        borderRadius: '24px',
                                        overflow: 'hidden',
                                        transition: 'all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275)',
                                        border: '1px solid #f1f5f9',
                                        position: 'relative',
                                        bgcolor: 'white',
                                        animation: `fadeInUp ${0.3 + index * 0.1}s ease-out`,
                                        '&:hover': {
                                            transform: 'translateY(-10px) scale(1.02)',
                                            boxShadow: '0 30px 60px -12px rgba(50,50,93,0.15), 0 18px 36px -18px rgba(0,0,0,0.2)',
                                            '& .item-image': { transform: 'scale(1.1)' }
                                        }
                                    }}>
                                        <Box sx={{ position: 'relative', overflow: 'hidden' }}>
                                            <CardMedia
                                                component="img"
                                                height={isMobile ? "200" : "240"}
                                                image={item.image ? (item.image.startsWith('http') ? item.image : `${API_BASE_URL}${item.image}`) : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=1000'}
                                                alt={item.name}
                                                className="item-image"
                                                sx={{ transition: 'transform 0.6s ease' }}
                                            />
                                            <Box sx={{
                                                position: 'absolute',
                                                bottom: 20,
                                                right: 20,
                                                bgcolor: 'white',
                                                px: 2,
                                                py: 1,
                                                borderRadius: '14px',
                                                fontWeight: 900,
                                                color: '#1e293b',
                                                fontSize: '16px',
                                                boxShadow: '0 8px 20px rgba(0,0,0,0.15)',
                                                border: '1px solid #f1f5f9'
                                            }}>
                                                Rs. {Number(item.price).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                                            </Box>
                                        </Box>
                                        <CardContent sx={{ flexGrow: 1, p: 3 }}>
                                            <Typography variant="h5" fontWeight={900} color="#1e293b" sx={{ mb: 1.5, letterSpacing: '-0.5px' }}>
                                                {item.name}
                                            </Typography>
                                            <Typography variant="body2" color="#64748b" sx={{
                                                mb: 3,
                                                lineHeight: 1.7,
                                                fontWeight: 500,
                                                display: '-webkit-box',
                                                WebkitLineClamp: 3,
                                                WebkitBoxOrient: 'vertical',
                                                overflow: 'hidden',
                                                minHeight: '60px'
                                            }}>
                                                {item.description || "Indulge in our masterfully crafted specialty, prepared with the freshest seasonal ingredients and secret spices."}
                                            </Typography>

                                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                                <Chip
                                                    label={categories.find(c => c.id === item.category_id)?.name || "Signature"}
                                                    sx={{
                                                        height: '28px',
                                                        fontSize: '11px',
                                                        fontWeight: 800,
                                                        bgcolor: '#f1f5f9',
                                                        color: '#475569',
                                                        textTransform: 'uppercase'
                                                    }}
                                                />
                                            </Box>
                                        </CardContent>
                                    </Card>
                                </Grid>
                            ))}
                        </Grid>
                    )}
                </Container>
            )}

            {/* Premium Floating Contact Bar */}
            <Box sx={{
                position: 'fixed',
                bottom: 30,
                left: '50%',
                transform: 'translateX(-50%)',
                width: isMobile ? '92%' : '800px',
                bgcolor: 'rgba(30, 41, 59, 0.95)',
                backdropFilter: 'blur(10px)',
                color: 'white',
                py: 2,
                px: 4,
                borderRadius: '40px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5)',
                zIndex: 1000,
                animation: 'fadeInUp 1.2s ease-out'
            }}>
                <Box sx={{ display: 'flex', gap: 4 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                        <Box sx={{ bgcolor: '#FFC107', p: 0.8, borderRadius: '50%', color: '#1e293b' }}><MapPin size={16} /></Box>
                        {!isMobile && <Typography variant="caption" fontWeight={700}>{companySettings?.address || 'Available Nearby'}</Typography>}
                    </Box>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                        <Box sx={{ bgcolor: '#FFC107', p: 0.8, borderRadius: '50%', color: '#1e293b' }}><Phone size={16} /></Box>
                        {!isMobile && <Typography variant="caption" fontWeight={700}>{companySettings?.phone || 'Connect'}</Typography>}
                    </Box>
                </Box>

                <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
                    <Instagram
                        size={22}
                        style={{ cursor: 'pointer', transition: 'color 0.3s' }}
                        onClick={() => companySettings?.instagram_url ? window.open(companySettings.instagram_url, '_blank') : showSnackbar('Social link coming soon')}
                        onMouseOver={(e) => e.currentTarget.style.color = '#FFC107'}
                        onMouseOut={(e) => e.currentTarget.style.color = 'white'}
                    />
                    <Facebook
                        size={22}
                        style={{ cursor: 'pointer', transition: 'color 0.3s' }}
                        onClick={() => companySettings?.facebook_url ? window.open(companySettings.facebook_url, '_blank') : showSnackbar('Social link coming soon')}
                        onMouseOver={(e) => e.currentTarget.style.color = '#FFC107'}
                        onMouseOut={(e) => e.currentTarget.style.color = 'white'}
                    />
                </Box>
            </Box>

            <Snackbar
                open={snackbar.open}
                autoHideDuration={4000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
                anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
            >
                <Alert severity={snackbar.severity} sx={{ borderRadius: '15px', fontWeight: 700, px: 3 }}>
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </Box>
    );
};

export default DigitalMenu;
