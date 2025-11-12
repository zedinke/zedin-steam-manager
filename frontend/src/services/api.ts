import axios from 'axios';

const API_BASE_URL = '/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

export const systemApi = {
  getSystemInfo: () => api.get('/system/info'),
  getUpdateInfo: () => api.get('/updates/check'),
  getHealth: () => api.get('/health'),
};

export const serverApi = {
  getServers: () => api.get('/servers'),
  getServer: (id: string) => api.get(`/servers/${id}`),
  createServer: (data: any) => api.post('/servers', data),
  updateServer: (id: string, data: any) => api.put(`/servers/${id}`, data),
  deleteServer: (id: string) => api.delete(`/servers/${id}`),
};

export default api;