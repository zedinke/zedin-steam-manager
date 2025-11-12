import { create } from 'zustand';

interface SystemState {
  systemInfo: any;
  updateInfo: any;
  servers: any[];
  updateSystemInfo: (info: any) => void;
  fetchSystemInfo: () => void;
  fetchUpdateInfo: () => void;
  fetchServers: () => void;
}

export const useSystemStore = create<SystemState>((set) => ({
  systemInfo: {},
  updateInfo: {},
  servers: [],
  updateSystemInfo: (info) => set({ systemInfo: info }),
  fetchSystemInfo: () => {
    // Mock data
    set({
      systemInfo: {
        cpu: { usage: 45 },
        memory: { usage: 67 },
        disk: { usage: 23 },
        network: { upload: 1.2, download: 3.4 }
      }
    });
  },
  fetchUpdateInfo: () => {
    set({
      updateInfo: {
        hasUpdate: false,
        currentVersion: '0.000001'
      }
    });
  },
  fetchServers: () => {
    set({
      servers: [
        { id: 1, name: 'ARK Server 1', status: 'running', players: 5 },
        { id: 2, name: 'ARK Server 2', status: 'stopped', players: 0 }
      ]
    });
  },
}));