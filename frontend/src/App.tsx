import React, { useState } from 'react';
import SimpleLogin from './components/SimpleLogin';

function Dashboard() {
  const handleLogout = () => {
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
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
        <h1 style={{ color: '#2196f3', margin: 0 }}>
          🎉 Dashboard - Zedin Steam Manager
        </h1>
        <button 
          onClick={handleLogout}
          style={{
            padding: '8px 16px',
            backgroundColor: '#f44336',
            color: 'white',
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer'
          }}
        >
          🚪 Kijelentkezés
        </button>
      </div>
      
      <h2 style={{ color: '#4caf50' }}>
        ✅ Bejelentkezés sikeres! 
      </h2>
      
      <p>React alkalmazás betöltődött és a login működik</p>
      
      <button 
        style={{
          padding: '12px 24px',
          fontSize: '16px',
          backgroundColor: '#2196f3',
          color: 'white',
          border: 'none',
          borderRadius: '4px',
          cursor: 'pointer',
          marginBottom: '24px'
        }}
        onClick={() => {
          alert('Dashboard működik! ✅');
          console.log('✅ Dashboard button clicked successfully!');
        }}
      >
        Teszt Dashboard Gomb
      </button>

      <div style={{ 
        padding: '16px', 
        border: '1px solid #555', 
        borderRadius: '4px',
        backgroundColor: '#1e1e1e'
      }}>
        <h3 style={{ color: '#4caf50' }}>📊 Projekt Status:</h3>
        <p>✅ Backend: FastAPI + Supabase</p>
        <p>✅ Frontend: React + Vite</p>
        <p>✅ Database: External Supabase PostgreSQL</p>
        <p>✅ Authentication: Working API</p>
        <p>✅ Login Flow: Successfully tested</p>
        <p>🔍 Debug: Check browser console (F12) for logs</p>
      </div>
    </div>
  );
}

function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  
  console.log('🚀 App component loaded successfully! Login state:', isLoggedIn);
  
  if (!isLoggedIn) {
    return <SimpleLogin onLoginSuccess={() => setIsLoggedIn(true)} />;
  }
  
  return <Dashboard />;
}

export default App;