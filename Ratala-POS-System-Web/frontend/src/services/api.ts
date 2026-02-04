import axios from 'axios';
import { sessionManager } from '../utils/sessionManager';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';
const API_PREFIX = '/api/v1'; // Backend API prefix

const api = axios.create({
  baseURL: `${API_BASE_URL}${API_PREFIX}`, // Include API prefix in baseURL
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000, // 30 second timeout
});

// Add token to requests
api.interceptors.request.use((config) => {
  const token = sessionManager.getToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle 401 errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      sessionManager.clearSession();
      window.location.href = '/login?reason=unauthorized';
    }
    return Promise.reject(error);
  }
);

// Auth API - these endpoints are at root level, not under /api/v1
export const authAPI = {
  login: (username: string, password: string) => {
    // Use URLSearchParams for application/x-www-form-urlencoded format (required by OAuth2PasswordRequestForm)
    const params = new URLSearchParams();
    params.append('username', username);
    params.append('password', password);
    return axios.post(`${API_BASE_URL}${API_PREFIX}/auth/token`, params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      timeout: 30000
    });
  },
  signup: (data: any) => axios.post(`${API_BASE_URL}${API_PREFIX}/auth/signup`, data, { timeout: 30000 }), // Root level endpoint
  getCurrentUser: (token?: string) => {
    // Use axios directly with token explicitly provided or from localStorage for root-level endpoint
    const authToken = token || localStorage.getItem('token');
    return axios.get(`${API_BASE_URL}${API_PREFIX}/auth/users/me`, {
      headers: {
        'Authorization': authToken ? `Bearer ${authToken}` : ''
      }
    });
  },
};

// Customers API
export const customersAPI = {
  getAll: () => api.get('/customers'),
  getById: (id: number) => api.get(`/customers/${id}`),
  create: (data: any) => api.post('/customers', data),
  update: (id: number, data: any) => api.put(`/customers/${id}`, data),
  delete: (id: number) => api.delete(`/customers/${id}`),
};

// Menu API
export const menuAPI = {
  getItems: () => api.get('/menu/items'),
  getItem: (id: number) => api.get(`/menu/items/${id}`),
  createItem: (data: any) => api.post('/menu/items', data),
  updateItem: (id: number, data: any) => api.put(`/menu/items/${id}`, data),
  deleteItem: (id: number) => api.delete(`/menu/items/${id}`),
  getCategories: () => api.get('/menu/categories'),
  createCategory: (data: any) => api.post('/menu/categories', data),
  updateCategory: (id: number, data: any) => api.put(`/menu/categories/${id}`, data),
  deleteCategory: (id: number) => api.delete(`/menu/categories/${id}`),
  getGroups: () => api.get('/menu/groups'),
  createGroup: (data: any) => api.post('/menu/groups', data),
  updateGroup: (id: number, data: any) => api.put(`/menu/groups/${id}`, data),
  deleteGroup: (id: number) => api.delete(`/menu/groups/${id}`),
};

// Inventory API
export const inventoryAPI = {
  getProducts: () => api.get('/inventory/products'),
  getProduct: (id: number) => api.get(`/inventory/products/${id}`),
  createProduct: (data: any) => api.post('/inventory/products', data),
  updateProduct: (id: number, data: any) => api.put(`/inventory/products/${id}`, data),
  deleteProduct: (id: number) => api.delete(`/inventory/products/${id}`),
  getUnits: () => api.get('/inventory/units'),
  createUnit: (data: any) => api.post('/inventory/units', data),
  updateUnit: (id: number, data: any) => api.put(`/inventory/units/${id}`, data),
  deleteUnit: (id: number) => api.delete(`/inventory/units/${id}`),
  getTransactions: () => api.get('/inventory/transactions'),
  createTransaction: (data: any) => api.post('/inventory/transactions', data),
  getAdjustments: () => api.get('/inventory/adjustments'),
  createAdjustment: (data: any) => api.post('/inventory/adjustments', data),
  getCounts: () => api.get('/inventory/counts'),
  createCount: (data: any) => api.post('/inventory/counts', data),
  getBOMs: () => api.get('/inventory/boms'),
  createBOM: (data: any) => api.post('/inventory/boms', data),
  updateBOM: (id: number, data: any) => api.put(`/inventory/boms/${id}`, data),
  getProductions: () => api.get('/inventory/productions'),
  createProduction: (data: any) => api.post('/inventory/productions', data),
};

// Purchase API
export const purchaseAPI = {
  getSuppliers: () => api.get('/purchase/suppliers'),
  getSupplier: (id: number) => api.get(`/purchase/suppliers/${id}`),
  createSupplier: (data: any) => api.post('/purchase/suppliers', data),
  updateSupplier: (id: number, data: any) => api.put(`/purchase/suppliers/${id}`, data),
  deleteSupplier: (id: number) => api.delete(`/purchase/suppliers/${id}`),
  getBills: () => api.get('/purchase/bills'),
  getBill: (id: number) => api.get(`/purchase/bills/${id}`),
  createBill: (data: any) => api.post('/purchase/bills', data),
  updateBill: (id: number, data: any) => api.put(`/purchase/bills/${id}`, data),
  deleteBill: (id: number) => api.delete(`/purchase/bills/${id}`),
  getReturns: () => api.get('/purchase/returns'),
  createReturn: (data: any) => api.post('/purchase/returns', data),
  deleteReturn: (id: number) => api.delete(`/purchase/returns/${id}`),
};

// Orders API
export const ordersAPI = {
  getAll: () => api.get('/orders'),
  getById: (id: number) => api.get(`/orders/${id}`),
  create: (data: any) => api.post('/orders', data),
  update: (id: number, data: any) => api.put(`/orders/${id}`, data),
  delete: (id: number) => api.delete(`/orders/${id}`),
};

// Floors API
export const floorsAPI = {
  getAll: () => api.get('/floors'),
  getById: (id: number) => api.get(`/floors/${id}`),
  create: (data: any) => api.post('/floors', data),
  update: (id: number, data: any) => api.put(`/floors/${id}`, data),
  delete: (id: number) => api.delete(`/floors/${id}`),
  reorder: (id: number, newOrder: number) => api.put(`/floors/${id}/reorder`, { new_order: newOrder }),
};

// Tables API
export const tablesAPI = {
  getAll: (params?: { floor?: string; floor_id?: number }) => api.get('/tables', { params }),
  getWithStats: () => api.get('/tables/with-stats'),
  getById: (id: number) => api.get(`/tables/${id}`),
  create: (data: any) => api.post('/tables', data),
  update: (id: number, data: any) => api.put(`/tables/${id}`, data),
  updateStatus: (id: number, status: string) => api.put(`/tables/${id}/status`, { status }),
  delete: (id: number) => api.delete(`/tables/${id}`),
  reorder: (id: number, newOrder: number) => api.put(`/tables/${id}/reorder`, { new_order: newOrder }),
};

// KOT API
export const kotAPI = {
  getAll: (params?: { kot_type?: string; status?: string }) => api.get('/kots', { params }),
  getById: (id: number) => api.get(`/kots/${id}`),
  create: (data: any) => api.post('/kots', data),
  update: (id: number, data: any) => api.put(`/kots/${id}`, data),
  updateStatus: (id: number, status: string) => api.put(`/kots/${id}/status`, { status }),
};

// Sessions API
export const sessionsAPI = {
  getAll: () => api.get('/sessions'),
  getById: (id: number) => api.get(`/sessions/${id}`),
  create: (data: any) => api.post('/sessions', data),
  update: (id: number, data: any) => api.put(`/sessions/${id}`, data),
  delete: (id: number) => api.delete(`/sessions/${id}`),
};

// Reports API
export const reportsAPI = {
  getDashboardSummary: (params?: any) => api.get('/reports/dashboard-summary', { params }),
  getOrdersChartData: (params: { period: 'hourly' | 'daily' | 'weekly' }) => api.get('/reports/orders-chart', { params }),
  getSalesSummary: (params?: any) => api.get('/reports/sales', { params }),
  getInventoryReport: () => api.get('/reports/inventory'),
  getDayBook: (params: any) => api.get('/reports/day-book', { params }),
  getSessions: () => api.get('/reports/sessions'),
  exportSessionsPDF: () => api.get('/reports/export/sessions/pdf', { responseType: 'blob' }),
  exportPDF: (type: string, params: any) => api.get(`/reports/export/pdf/${type}`, { params, responseType: 'blob' }),
  exportExcel: (type: string, params: any) => api.get(`/reports/export/excel/${type}`, { params, responseType: 'blob' }),
  exportAllExcel: () => api.get('/reports/export/all/excel', { responseType: 'blob' }),
};

// Users API
export const usersAPI = {
  getAll: () => api.get('/users'),
  getById: (id: number) => api.get(`/users/${id}`),
  create: (data: any) => api.post('/users', data),
  update: (id: number, data: any) => api.put(`/users/${id}`, data),
  delete: (id: number) => api.delete(`/users/${id}`),
};

// Settings API
export const settingsAPI = {
  getCompanySettings: () => api.get('/settings/company'),
  updateCompanySettings: (data: any) => api.put('/settings/company', data),
  getPaymentModes: () => api.get('/settings/payment-modes'),
  createPaymentMode: (data: any) => api.post('/settings/payment-modes', data),
  updatePaymentMode: (id: number, data: any) => api.put(`/settings/payment-modes/${id}`, data),
  deletePaymentMode: (id: number) => api.delete(`/settings/payment-modes/${id}`),
  getStorageAreas: () => api.get('/settings/storage-areas'),
  createStorageArea: (data: any) => api.post('/settings/storage-areas', data),
  updateStorageArea: (id: number, data: any) => api.put(`/settings/storage-areas/${id}`, data),
  deleteStorageArea: (id: number) => api.delete(`/settings/storage-areas/${id}`),
  getDiscountRules: () => api.get('/settings/discount-rules'),
  createDiscountRule: (data: any) => api.post('/settings/discount-rules', data),
  updateDiscountRule: (id: number, data: any) => api.put(`/settings/discount-rules/${id}`, data),
  deleteDiscountRule: (id: number) => api.delete(`/settings/discount-rules/${id}`),
  // QR Codes
  get: (endpoint: string) => api.get(endpoint),
  post: (endpoint: string, data: any, config?: any) => api.post(endpoint, data, config),
  put: (endpoint: string, data: any, config?: any) => api.put(endpoint, data, config),
  delete: (endpoint: string) => api.delete(endpoint),
};

// Branches API
export const branchAPI = {
  getAll: () => api.get('/branches'),
  getById: (id: number) => api.get(`/branches/${id}`),
  create: (data: any) => api.post('/branches', data),
  update: (id: number, data: any) => api.put(`/branches/${id}`, data),
  delete: (id: number) => api.delete(`/branches/${id}`),
  select: (branchId: number) => {
    // This is a direct axios call because it's at the root level /select-branch
    const token = localStorage.getItem('token');
    return axios.post(`${API_BASE_URL}${API_PREFIX}/auth/select-branch`,
      { branch_id: branchId },
      { headers: { Authorization: `Bearer ${token}` } }
    );
  }
};

// Roles API
export const rolesAPI = {
  getAll: () => api.get('/roles'),
  getById: (id: number) => api.get(`/roles/${id}`),
  create: (data: any) => api.post('/roles', data),
  update: (id: number, data: any) => api.put(`/roles/${id}`, data),
  delete: (id: number) => api.delete(`/roles/${id}`),
  getPermissions: () => api.get('/roles/permissions'),
};

// OTP API
export const otpAPI = {
  sendOTP: (email: string, type: string = 'signup') => api.post('/otp/send-otp', { email, type }),
  verifyOTP: (email: string, code: string, consume: boolean = true) => api.post('/otp/verify-otp', { email, code, consume }),
  completePasswordReset: (data: any) => api.post('/otp/complete-password-reset', data),
  health: () => api.get('/otp/health'),
};

// ... keep existing ones and add to export if needed
// Actually, it's better to export all individual APIs as they were.

export default api;

