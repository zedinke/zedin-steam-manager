import React, { useState, useEffect } from 'react';

// Inline simple login component
function SimpleLogin({ onLoginSuccess }: { onLoginSuccess: (email: string) => void }) {
  const [formData, setFormData] = useState({ email: '', password: '' });
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage('');
    
    console.log('🔑 Login attempt started');
    
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      console.log('✅ Login successful');
      setMessage('✅ Bejelentkezés sikeres!');
      
      setTimeout(() => {
        console.log('🚀 Navigating to dashboard');
        onLoginSuccess(formData.email);
      }, 500);
      
    } catch (error) {
      console.error('❌ Login error:', error);
      setMessage('❌ Hiba történt');
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
function Dashboard({ userEmail }: { userEmail: string }) {
  console.log('🏠 Dashboard component rendered');
  
  const handleLogout = () => {
    console.log('🚪 Logout clicked');
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
          <StatCard title="Összes Szerver" value="12" icon="🎮" color="#2196f3" />
          <StatCard title="Aktív Szerverek" value="8" icon="✅" color="#4caf50" />
          <StatCard title="Online Játékosok" value="245" icon="👥" color="#ff9800" />
          <StatCard title="Rendszer Állapot" value="100%" icon="💚" color="#4caf50" />
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
            <h3 style={{ color: 'white', marginBottom: '20px', fontSize: '18px' }}>Szerver Statisztikák</h3>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
              <div>
                <div style={{ color: '#2196f3', fontSize: '24px', fontWeight: 'bold', marginBottom: '5px' }}>156</div>
                <div style={{ color: '#bbb', fontSize: '14px' }}>Befejezett Játékok</div>
                <div style={{ color: '#4caf50', fontSize: '20px', marginTop: '10px' }}>487.2h</div>
                <div style={{ color: '#bbb', fontSize: '14px' }}>Összes Játékidő</div>
              </div>
              <div>
                <div style={{ color: '#f44336', fontSize: '24px', fontWeight: 'bold', marginBottom: '5px' }}>3</div>
                <div style={{ color: '#bbb', fontSize: '14px' }}>Aktív Események</div>
                <div style={{ color: '#ff9800', fontSize: '20px', marginTop: '10px' }}>2,847</div>
                <div style={{ color: '#bbb', fontSize: '14px' }}>Összes Játékos</div>
              </div>
            </div>
          </div>

          {/* System Status */}
          <div style={{
            background: '#1e1e1e',
            padding: '24px',
            borderRadius: '8px',
            border: '1px solid #333'
          }}>
            <h3 style={{ color: 'white', marginBottom: '20px', fontSize: '18px' }}>Karbantartás</h3>
            <div>
              <div style={{ color: '#2196f3', fontSize: '24px', fontWeight: 'bold', marginBottom: '5px' }}>5</div>
              <div style={{ color: '#bbb', fontSize: '14px' }}>Ütemezett</div>
              <div style={{ color: '#ff9800', fontSize: '20px', marginTop: '15px' }}>2</div>
              <div style={{ color: '#bbb', fontSize: '14px' }}>Folyamatban</div>
              <div style={{ color: '#4caf50', fontSize: '20px', marginTop: '15px' }}>98</div>
              <div style={{ color: '#bbb', fontSize: '14px' }}>Befejezett</div>
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
          <h3 style={{ color: 'white', marginBottom: '20px', fontSize: '18px' }}>Havi Szerver Aktivitás (2025)</h3>
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
            {[60, 45, 80, 55, 70, 35, 40, 65, 75, 85, 90, 100].map((height, index) => (
              <div key={index} style={{
                width: '20px',
                height: `${height}%`,
                background: 'linear-gradient(180deg, #2196f3 0%, #1976d2 100%)',
                borderRadius: '4px 4px 0 0',
                transition: 'all 0.3s ease'
              }} />
            ))}
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
              Szerverek: 12
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

// Main App component
function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [userEmail, setUserEmail] = useState('');
  
  console.log('🚀 App component loaded - isLoggedIn:', isLoggedIn);

  useEffect(() => {
    console.log('isLoggedIn state changed to:', isLoggedIn);
  }, [isLoggedIn]);
  
  if (!isLoggedIn) {
    console.log('📝 Showing login component');
    return <SimpleLogin onLoginSuccess={(email) => {
      console.log('🔄 Setting login state to true');
      setIsLoggedIn(true);
      setUserEmail(email);
    }} />;
  }
  
  console.log('🏠 Showing dashboard component');
  return <Dashboard userEmail={userEmail} />;
}

export default App;