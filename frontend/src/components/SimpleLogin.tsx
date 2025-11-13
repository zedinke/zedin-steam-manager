import React, { useState } from 'react';

interface SimpleLoginProps {
  onLoginSuccess: () => void;
}

const SimpleLogin: React.FC<SimpleLoginProps> = ({ onLoginSuccess }) => {
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  });
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setMessage('');

    try {
      console.log('🔑 Attempting login with:', formData.email);
      
      // For testing, we'll simulate a successful login
      // In real implementation, this would call the backend API
      await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate API call
      
      console.log('✅ Login successful!');
      setMessage('✅ Bejelentkezés sikeres!');
      
      // Simulate successful login
      setTimeout(() => {
        onLoginSuccess();
      }, 500);
      
    } catch (error) {
      console.error('❌ Login error:', error);
      setMessage('❌ Bejelentkezési hiba');
    } finally {
      setIsLoading(false);
    }
  };

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
          <label style={{ display: 'block', marginBottom: '8px', color: '#ccc' }}>
            Email:
          </label>
          <input
            type="email"
            value={formData.email}
            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            style={{
              width: '100%',
              padding: '12px',
              borderRadius: '4px',
              border: '1px solid #555',
              backgroundColor: '#2e2e2e',
              color: 'white',
              fontSize: '14px'
            }}
            placeholder="test@example.com"
            required
          />
        </div>

        <div style={{ marginBottom: '24px' }}>
          <label style={{ display: 'block', marginBottom: '8px', color: '#ccc' }}>
            Password:
          </label>
          <input
            type="password"
            value={formData.password}
            onChange={(e) => setFormData({ ...formData, password: e.target.value })}
            style={{
              width: '100%',
              padding: '12px',
              borderRadius: '4px',
              border: '1px solid #555',
              backgroundColor: '#2e2e2e',
              color: 'white',
              fontSize: '14px'
            }}
            placeholder="Password"
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
          color: 'white',
          textAlign: 'center'
        }}>
          {message}
        </div>
      )}

      <div style={{
        marginTop: '32px',
        padding: '16px',
        backgroundColor: '#1e1e1e',
        borderRadius: '4px',
        border: '1px solid #555',
        textAlign: 'center'
      }}>
        <h3 style={{ color: '#4caf50', marginBottom: '8px' }}>🧪 Test Info:</h3>
        <p style={{ margin: '4px 0', fontSize: '14px' }}>Any email/password will work for testing</p>
        <p style={{ margin: '4px 0', fontSize: '14px' }}>Check browser console (F12) for debug logs</p>
      </div>
    </div>
  );
};

export default SimpleLogin;