import { create } from 'zustand';

interface AuthState {
  isAuthenticated: boolean;
  user: any;
  login: (credentials: any) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  isAuthenticated: false,
  user: null,
  login: (credentials) => {
    // Mock login
    set({ isAuthenticated: true, user: { name: 'Admin' } });
  },
  logout: () => {
    set({ isAuthenticated: false, user: null });
  },
}));