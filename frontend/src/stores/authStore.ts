import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
  id: number;
  first_name: string;
  last_name: string;
  email: string;
  role: 'manager_admin' | 'server_admin' | 'admin' | 'user';
  is_active: boolean;
  is_verified: boolean;
  created_at: string;
  last_login?: string;
}

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  
  login: (token: string, user: User) => void;
  logout: () => void;
  updateUser: (user: Partial<User>) => void;
  setLoading: (loading: boolean) => void;
  hasPermission: (requiredRole: User['role']) => boolean;
  getFullName: () => string;
}

const roleHierarchy = {
  user: 0,
  admin: 1,
  server_admin: 2,
  manager_admin: 3
} as const;

export const authStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,

      login: (token: string, user: User) => {
        set({
          token,
          user,
          isAuthenticated: true,
          isLoading: false
        });
      },

      logout: () => {
        set({
          user: null,
          token: null,
          isAuthenticated: false,
          isLoading: false
        });
      },

      updateUser: (updatedUser: Partial<User>) => {
        const currentUser = get().user;
        if (currentUser) {
          set({
            user: { ...currentUser, ...updatedUser }
          });
        }
      },

      setLoading: (loading: boolean) => {
        set({ isLoading: loading });
      },

      hasPermission: (requiredRole: User['role']) => {
        const user = get().user;
        if (!user) return false;
        
        const userLevel = roleHierarchy[user.role] || 0;
        const requiredLevel = roleHierarchy[requiredRole] || 0;
        
        return userLevel >= requiredLevel;
      },

      getFullName: () => {
        const user = get().user;
        if (!user) return '';
        return `${user.first_name} ${user.last_name}`;
      }
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        isAuthenticated: state.isAuthenticated
      })
    }
  )
);

// Deprecated - keeping for compatibility
export const useAuthStore = authStore;