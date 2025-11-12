import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

export const systemApi = {
  getSystemInfo: () => api.get('/system/info'),
  getUpdateInfo: () => api.get('/updates/check'),
  getHealth: () => api.get('/health'),
  getServers: () => api.get('/servers'),
  checkUpdates: () => api.get('/updates/check'),
  startServer: (id: number) => api.post(`/servers/${id}/start`),
  stopServer: (id: number) => api.post(`/servers/${id}/stop`),
  installServer: (id: number) => api.post(`/servers/${id}/install`),
  deleteSharedFiles: (gameType: string) => api.delete(`/shared-files/${gameType}`),
  updateManager: () => api.post('/updates/install'),
};

export const serverApi = {
  getServers: () => api.get('/servers'),
  getServer: (id: string) => api.get(`/servers/${id}`),
  createServer: (data: any) => api.post('/servers', data),
  updateServer: (id: string, data: any) => api.put(`/servers/${id}`, data),
  deleteServer: (id: string) => api.delete(`/servers/${id}`),
};

export default api;