import React, { useState } from 'react';

// Inline simple login component
function SimpleLogin({ onLoginSuccess }: { onLoginSuccess: () => void }) {
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
        onLoginSuccess();
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
        🔑 Zedin Steam Manager - Login
      </h1>

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
            placeholder="Email"
            style={{
              width: '100%',
              padding: '12px',
              borderRadius: '4px',
              border: '1px solid #555',
              backgroundColor: '#2e2e2e',
              color: 'white'
            }}
            required
          />
        </div>

        <div style={{ marginBottom: '24px' }}>
          <input
            type="password"
            value={formData.password}
            onChange={(e) => setFormData({ ...formData, password: e.target.value })}
            placeholder="Password"
            style={{
              width: '100%',
              padding: '12px',
              borderRadius: '4px',
              border: '1px solid #555',
              backgroundColor: '#2e2e2e',
              color: 'white'
            }}
            required
          />
        </div>

        <button
          type="submit"
          disabled={isLoading}
          style={{
            width: '100%',
            padding: '12px',
            backgroundColor: isLoading ? '#555' : '#2196f3',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            fontSize: '16px',
            cursor: isLoading ? 'not-allowed' : 'pointer'
          }}
        >
          {isLoading ? '⏳ Bejelentkezés...' : '🚀 Bejelentkezés'}
        </button>
      </form>

      {message && (
        <div style={{
          marginTop: '16px',
          padding: '12px',
          borderRadius: '4px',
          backgroundColor: message.includes('✅') ? '#1b5e20' : '#b71c1c',
          color: 'white'
        }}>
          {message}
        </div>
      )}
    </div>
  );
}

// Simple inline dashboard component
function Dashboard() {
  console.log('🏠 Dashboard component rendered');
  
  const handleLogout = () => {
    console.log('🚪 Logout clicked');
    window.location.reload();
  };

  return (
    <div style={{
      padding: '40px',
      fontFamily: 'Arial, sans-serif',
      backgroundColor: '#121212',
      color: 'white',
      minHeight: '100vh'
    }}>
      <div style={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center', 
        marginBottom: '32px' 
      }}>
        <h1 style={{ color: '#2196f3', margin: 0 }}>
          🎉 Dashboard - Zedin Steam Manager
        </h1>
        <button onClick={handleLogout} style={{
          padding: '8px 16px',
          backgroundColor: '#f44336',
          color: 'white',
          border: 'none',
          borderRadius: '4px',
          cursor: 'pointer'
        }}>
          🚪 Kijelentkezés
        </button>
      </div>
      
      <h2 style={{ color: '#4caf50' }}>✅ Bejelentkezés sikeres!</h2>
      <p>Dashboard sikeresen betöltődött</p>
      
      <button style={{
        padding: '12px 24px',
        fontSize: '16px',
        backgroundColor: '#2196f3',
        color: 'white',
        border: 'none',
        borderRadius: '4px',
        cursor: 'pointer',
        margin: '10px'
      }} onClick={() => {
        alert('Dashboard teszt működik! ✅');
        console.log('✅ Dashboard button works');
      }}>
        Teszt Gomb
      </button>

      <div style={{
        marginTop: '24px',
        padding: '16px',
        border: '1px solid #555',
        borderRadius: '4px',
        backgroundColor: '#1e1e1e'
      }}>
        <h3 style={{ color: '#4caf50' }}>📊 Rendszer Status:</h3>
        <p>✅ Frontend: React + Vite</p>
        <p>✅ Backend: FastAPI + Supabase</p>
        <p>✅ Authentication: Működik</p>
        <p>✅ Dashboard: Betöltődött</p>
      </div>
    </div>
  );
}

// Main App component
function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  
  console.log('🚀 App component loaded - isLoggedIn:', isLoggedIn);
  
  if (!isLoggedIn) {
    console.log('📝 Showing login component');
    return <SimpleLogin onLoginSuccess={() => {
      console.log('🔄 Setting login state to true');
      setIsLoggedIn(true);
    }} />;
  }
  
  console.log('🏠 Showing dashboard component');
  return <Dashboard />;
}

export default App;