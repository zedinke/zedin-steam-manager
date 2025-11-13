import React, { useState, useEffect } from 'react';

// API URL: use relative path in production, localhost in development
const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
  ? 'http://localhost:8001/api'
  : '/api';

interface UserData {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  role: string;
  is_active: boolean;
}

interface SystemInfo {
  cpu?: {
    percent: number;
    count: number;
  };
  memory?: {
    percent: number;
    used: number;
    total: number;
  };
  disk?: {
    percent: number;
    used: number;
    total: number;
  };
  network?: {
    bytes_sent: number;
    bytes_recv: number;
  };
  uptime?: number;
  boot_time?: number;
}

// Inline simple login component
function SimpleLogin({ onLoginSuccess }: { onLoginSuccess: (email: string, token: string, userData: UserData) => void }) {
  const [formData, setFormData] = useState({ email: '', password: '' });
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage('');
    
    console.log('🔑 Login attempt started');
    
    try {
      const response = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: formData.email,
          password: formData.password
        })
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.detail || 'Bejelentkezési hiba');
      }

      console.log('✅ Login successful');
      setMessage('✅ Bejelentkezés sikeres!');
      
      // Store token
      localStorage.setItem('authToken', data.access_token);
      localStorage.setItem('userEmail', formData.email);
      
      setTimeout(() => {
        console.log('🚀 Navigating to dashboard');
        onLoginSuccess(formData.email, data.access_token, data.user);
      }, 500);
      
    } catch (error: any) {
      console.error('❌ Login error:', error);
      setMessage(`❌ ${error.message || 'Hiba történt'}`);
    } finally {
      setIsLoading(false);
    }
  };

  console.log('🔑 Login component rendered');

  return (
    <div style={{
      padding: '40px',
      fontFamily: 'Arial, sans-serif',
      backgroundColor: '#121212',
      color: 'white',
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center'
    }}>
      <h1 style={{ color: '#2196f3', marginBottom: '32px' }}>
        🔑 Zedin Steam Manager
      </h1>
      <p style={{ marginBottom: '30px', color: '#bbb' }}>Professional Steam Server Management</p>

      <form onSubmit={handleSubmit} style={{
        backgroundColor: '#1e1e1e',
        padding: '32px',
        borderRadius: '8px',
        border: '1px solid #555',
        width: '100%',
        maxWidth: '400px'
      }}>
        <div style={{ marginBottom: '16px' }}>
          <input
            type="email"
            value={formData.email}
            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            placeholder="Email cím"
            style={{
              width: '100%',
              padding: '15px',
              borderRadius: '4px',
              border: '1px solid #555',
              backgroundColor: '#2e2e2e',
              color: 'white',
              fontSize: '16px'
            }}
            required
          />
        </div>

        <div style={{ marginBottom: '24px' }}>
          <input
            type="password"
            value={formData.password}
            onChange={(e) => setFormData({ ...formData, password: e.target.value })}
            placeholder="Jelszó"
            style={{
              width: '100%',
              padding: '15px',
              borderRadius: '4px',
              border: '1px solid #555',
              backgroundColor: '#2e2e2e',
              color: 'white',
              fontSize: '16px'
            }}
            required
          />
        </div>

        <button
          type="submit"
          disabled={isLoading}
          style={{
            width: '100%',
            padding: '15px',
            backgroundColor: isLoading ? '#555' : '#2196f3',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            fontSize: '16px',
            cursor: isLoading ? 'not-allowed' : 'pointer',
            marginTop: '15px'
          }}
        >
          {isLoading ? '⏳ Bejelentkezés...' : '🚀 Bejelentkezés'}
        </button>
      </form>

      {message && (
        <div style={{
          marginTop: '20px',
          padding: '15px',
          borderRadius: '4px',
          backgroundColor: message.includes('✅') ? '#4caf50' : '#f44336',
          color: 'white'
        }}>
          {message}
        </div>
      )}
    </div>
  );
}

// Simple inline dashboard component
function Dashboard({ userEmail, token, userData }: { userEmail: string; token: string; userData: UserData | null }) {
  const [systemData, setSystemData] = useState<SystemInfo | null>(null);
  const [dashboardData, setDashboardData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
    // Refresh every 5 seconds
    const interval = setInterval(loadDashboardData, 5000);
    return () => clearInterval(interval);
  }, []);

  const loadDashboardData = async () => {
    try {
      const [systemRes, dashboardRes] = await Promise.all([
        fetch(`${API_URL}/system/info`, {
          headers: { 'Authorization': `Bearer ${token}` }
        }),
        fetch(`${API_URL}/dashboard`, {
          headers: { 'Authorization': `Bearer ${token}` }
        })
      ]);

      if (systemRes.ok) {
        const sysData = await systemRes.json();
        setSystemData(sysData);
      }

      if (dashboardRes.ok) {
        const dashData = await dashboardRes.json();
        setDashboardData(dashData);
      }
    } catch (error) {
      console.error('Error loading dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  console.log('🏠 Dashboard component rendered');
  
  const handleLogout = () => {
    console.log('🚪 Logout clicked');
    localStorage.removeItem('authToken');
    localStorage.removeItem('userEmail');
    window.location.reload();
  };

  return (
    <div style={{
      fontFamily: 'Arial, sans-serif',
      backgroundColor: '#121212',
      color: 'white',
      minHeight: '100vh'
    }}>
      {/* Top Navigation Bar */}
      <div style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        height: '60px',
        background: '#1a1a1a',
        borderBottom: '1px solid #333',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '0 20px',
        zIndex: 100
      }}>
        <div style={{ display: 'flex', alignItems: 'center' }}>
          <h2 style={{ color: '#2196f3', margin: 0, fontSize: '20px' }}>🎮 Zedin Steam Manager</h2>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
          <span style={{ color: '#bbb', fontSize: '14px' }}>Üdvözöljük, {userEmail}</span>
          <button onClick={handleLogout} style={{
            padding: '8px 16px',
            background: '#f44336',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer',
            fontSize: '14px'
          }}>
            🚪 Kijelentkezés
          </button>
        </div>
      </div>

      {/* Sidebar Navigation */}
      <div style={{
        position: 'fixed',
        left: 0,
        top: '60px',
        bottom: 0,
        width: '200px',
        background: '#1e1e1e',
        borderRight: '1px solid #333',
        zIndex: 99
      }}>
        <div style={{ padding: '20px 0' }}>
          <NavItem icon="📊" label="Dashboard" active />
          <NavItem icon="🎮" label="Szerverek" />
          <NavItem icon="📁" label="Fájlkezelő" />
          <NavItem icon="📈" label="Monitoring" />
          <NavItem icon="🔧" label="Karbantartás" />
          <NavItem icon="⚙️" label="Beállítások" />
        </div>
      </div>

      {/* Main Content Area */}
      <div style={{
        marginLeft: '200px',
        marginTop: '60px',
        padding: '30px',
        background: '#121212',
        minHeight: 'calc(100vh - 60px)'
      }}>
        {/* Statistics Cards Row */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
          gap: '20px',
          marginBottom: '30px'
        }}>
          <StatCard 
            title="CPU Használat" 
            value={systemData ? `${systemData.cpu?.percent || 0}%` : '0%'} 
            icon="💻" 
            color="#2196f3" 
          />
          <StatCard 
            title="RAM Használat" 
            value={systemData ? `${systemData.memory?.percent || 0}%` : '0%'} 
            icon="🧠" 
            color="#4caf50" 
          />
          <StatCard 
            title="Disk Használat" 
            value={systemData ? `${systemData.disk?.percent || 0}%` : '0%'} 
            icon="💾" 
            color="#ff9800" 
          />
          <StatCard 
            title="Rendszer Állapot" 
            value={systemData ? "Online" : "Loading"} 
            icon="💚" 
            color="#4caf50" 
          />
        </div>

        {/* Content Panels Row */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: '2fr 1fr',
          gap: '20px',
          marginBottom: '30px'
        }}>
          {/* Server Statistics */}
          <div style={{
            background: '#1e1e1e',
            padding: '24px',
            borderRadius: '8px',
            border: '1px solid #333'
          }}>
            <h3 style={{ color: 'white', marginBottom: '20px', fontSize: '18px' }}>Rendszer Információ</h3>
            {systemData ? (
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                <div>
                  <div style={{ color: '#2196f3', fontSize: '24px', fontWeight: 'bold', marginBottom: '5px' }}>
                    {systemData.cpu?.count || 0}
                  </div>
                  <div style={{ color: '#bbb', fontSize: '14px' }}>CPU Magok</div>
                  <div style={{ color: '#4caf50', fontSize: '20px', marginTop: '10px' }}>
                    {systemData.memory ? `${(systemData.memory.used / (1024**3)).toFixed(1)} GB` : '0 GB'}
                  </div>
                  <div style={{ color: '#bbb', fontSize: '14px' }}>Használt RAM</div>
                </div>
                <div>
                  <div style={{ color: '#f44336', fontSize: '24px', fontWeight: 'bold', marginBottom: '5px' }}>
                    {systemData.disk ? `${(systemData.disk.used / (1024**3)).toFixed(0)} GB` : '0 GB'}
                  </div>
                  <div style={{ color: '#bbb', fontSize: '14px' }}>Használt Disk</div>
                  <div style={{ color: '#ff9800', fontSize: '20px', marginTop: '10px' }}>
                    {systemData.network ? `${(systemData.network.bytes_sent / (1024**2)).toFixed(0)} MB` : '0 MB'}
                  </div>
                  <div style={{ color: '#bbb', fontSize: '14px' }}>Küldött Adat</div>
                </div>
              </div>
            ) : (
              <div style={{ color: '#bbb' }}>Betöltés...</div>
            )}
          </div>

          {/* System Status */}
          <div style={{
            background: '#1e1e1e',
            padding: '24px',
            borderRadius: '8px',
            border: '1px solid #333'
          }}>
            <h3 style={{ color: 'white', marginBottom: '20px', fontSize: '18px' }}>Gyors Statisztikák</h3>
            <div>
              <div style={{ color: '#2196f3', fontSize: '24px', fontWeight: 'bold', marginBottom: '5px' }}>
                {systemData?.uptime ? Math.floor(systemData.uptime / 3600) : 0}h
              </div>
              <div style={{ color: '#bbb', fontSize: '14px' }}>Rendszer Uptime</div>
              <div style={{ color: '#ff9800', fontSize: '20px', marginTop: '15px' }}>
                {systemData?.boot_time ? new Date(systemData.boot_time * 1000).toLocaleDateString() : 'N/A'}
              </div>
              <div style={{ color: '#bbb', fontSize: '14px' }}>Utolsó Indítás</div>
              <div style={{ color: '#4caf50', fontSize: '20px', marginTop: '15px' }}>
                {systemData ? 'Működik' : 'Betöltés'}
              </div>
              <div style={{ color: '#bbb', fontSize: '14px' }}>Állapot</div>
            </div>
          </div>
        </div>

        {/* Chart Section */}
        <div style={{
          background: '#1e1e1e',
          padding: '24px',
          borderRadius: '8px',
          border: '1px solid #333'
        }}>
          <h3 style={{ color: 'white', marginBottom: '20px', fontSize: '18px' }}>
            Rendszer Monitoring {loading && '(Betöltés...)'}
          </h3>
          <div style={{
            height: '300px',
            background: '#1a1a1a',
            borderRadius: '8px',
            display: 'flex',
            alignItems: 'end',
            justifyContent: 'space-around',
            padding: '20px',
            position: 'relative'
          }}>
            {systemData ? (
              <>
                <ChartBar height={systemData.cpu?.percent || 0} label="CPU" />
                <ChartBar height={systemData.memory?.percent || 0} label="RAM" />
                <ChartBar height={systemData.disk?.percent || 0} label="Disk" />
                <ChartBar height={80} label="Net" />
              </>
            ) : (
              <div style={{ color: '#bbb', margin: 'auto' }}>Betöltés...</div>
            )}
            <div style={{
              position: 'absolute',
              top: '20px',
              right: '20px',
              color: '#bbb',
              fontSize: '14px',
              background: 'rgba(0,0,0,0.5)',
              padding: '5px 10px',
              borderRadius: '4px'
            }}>
              Live Data
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// Helper Components
function NavItem({ icon, label, active = false }: { icon: string; label: string; active?: boolean }) {
  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      gap: '10px',
      padding: '12px 20px',
      color: active ? 'white' : '#bbb',
      cursor: 'pointer',
      borderLeft: active ? '3px solid #2196f3' : '3px solid transparent',
      background: active ? '#2196f3' : 'transparent',
      transition: 'all 0.3s ease'
    }}>
      <span>{icon}</span> {label}
    </div>
  );
}

function StatCard({ title, value, icon, color }: { title: string; value: string; icon: string; color: string }) {
  return (
    <div style={{
      background: '#1e1e1e',
      padding: '20px',
      borderRadius: '8px',
      border: '1px solid #333',
      transition: 'transform 0.2s ease'
    }}>
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
        marginBottom: '10px'
      }}>
        <div>
          <div style={{ fontSize: '14px', color: '#bbb', marginBottom: '5px' }}>{title}</div>
          <div style={{ fontSize: '32px', fontWeight: 'bold', color }}>{value}</div>
        </div>
        <div style={{ color, fontSize: '24px' }}>{icon}</div>
      </div>
    </div>
  );
}

function ChartBar({ height, label }: { height: number; label: string }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '5px' }}>
      <div style={{
        width: '40px',
        height: `${Math.min(height, 100)}%`,
        background: 'linear-gradient(180deg, #2196f3 0%, #1976d2 100%)',
        borderRadius: '4px 4px 0 0',
        transition: 'all 0.3s ease'
      }} />
      <div style={{ color: '#bbb', fontSize: '12px' }}>{label}</div>
      <div style={{ color: 'white', fontSize: '14px', fontWeight: 'bold' }}>{Math.round(height)}%</div>
    </div>
  );
}

// Main App component
function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [userEmail, setUserEmail] = useState('');
  const [authToken, setAuthToken] = useState('');
  const [userData, setUserData] = useState<UserData | null>(null);
  
  console.log('🚀 App component loaded - isLoggedIn:', isLoggedIn);

  useEffect(() => {
    // Check for existing token on mount
    const token = localStorage.getItem('authToken');
    const email = localStorage.getItem('userEmail');
    
    if (token && email) {
      console.log('🔄 Found existing session, verifying...');
      verifyToken(token, email);
    }
  }, []);

  const verifyToken = async (token: string, email: string) => {
    try {
      const response = await fetch(`${API_URL}/auth/me`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      if (response.ok) {
        const user: UserData = await response.json();
        console.log('✅ Token valid, auto-login');
        setIsLoggedIn(true);
        setUserEmail(email);
        setAuthToken(token);
        setUserData(user);
      } else {
        console.log('❌ Token invalid, clearing session');
        localStorage.removeItem('authToken');
        localStorage.removeItem('userEmail');
      }
    } catch (error) {
      console.error('Token verification failed:', error);
      localStorage.removeItem('authToken');
      localStorage.removeItem('userEmail');
    }
  };

  useEffect(() => {
    console.log('isLoggedIn state changed to:', isLoggedIn);
  }, [isLoggedIn]);
  
  if (!isLoggedIn) {
    console.log('📝 Showing login component');
    return <SimpleLogin onLoginSuccess={(email, token, user) => {
      console.log('🔄 Setting login state to true');
      setIsLoggedIn(true);
      setUserEmail(email);
      setAuthToken(token);
      setUserData(user);
    }} />;
  }
  
  console.log('🏠 Showing dashboard component');
  return <Dashboard userEmail={userEmail} token={authToken} userData={userData} />;
}

export default App;