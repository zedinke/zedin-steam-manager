#!/bin/bash

#############################################
# Block 05: Frontend Setup
#############################################

echo "Setting up React frontend..."

APP_DIR="/opt/zedin-steam-manager"
FRONTEND_DIR="$APP_DIR/frontend"

mkdir -p "$FRONTEND_DIR"
cd "$FRONTEND_DIR"

# Check if already initialized
if [ ! -f "package.json" ]; then
    echo "Initializing React + TypeScript + Vite project..."
    
    # Create package.json
    cat > package.json << 'EOFJSON'
{
  "name": "zedin-steam-manager-frontend",
  "version": "0.0.1",
  "type": "module",
  "scripts": {
    "dev": "vite --host 0.0.0.0",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "@mui/material": "^5.14.20",
    "@mui/icons-material": "^5.14.19",
    "@emotion/react": "^11.11.1",
    "@emotion/styled": "^11.11.0",
    "axios": "^1.6.2"
  },
  "devDependencies": {
    "@types/react": "^18.2.43",
    "@types/react-dom": "^18.2.17",
    "@vitejs/plugin-react": "^4.2.1",
    "typescript": "^5.3.3",
    "vite": "^5.0.8"
  }
}
EOFJSON
    
    echo "✅ package.json created"
fi

# Install npm dependencies
echo "Installing npm dependencies..."
npm install --silent

if [ $? -eq 0 ]; then
    echo "✅ npm dependencies installed"
else
    echo "❌ Error: Failed to install npm dependencies"
    exit 1
fi

# Create directory structure
mkdir -p src/components
mkdir -p src/pages
mkdir -p src/services
mkdir -p src/types
mkdir -p public

# Create vite.config.ts
cat > vite.config.ts << 'EOFTS'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: false
  }
})
EOFTS

# Create tsconfig.json
cat > tsconfig.json << 'EOFJSON'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOFJSON

# Create tsconfig.node.json
cat > tsconfig.node.json << 'EOFJSON'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
EOFJSON

# Create index.html
cat > index.html << 'EOFHTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Zedin Steam Manager</title>
</head>
<body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
</body>
</html>
EOFHTML

# Create main.tsx
cat > src/main.tsx << 'EOFTSX'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import { CssBaseline, ThemeProvider, createTheme } from '@mui/material'

const darkTheme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#2196f3',
    },
    secondary: {
      main: '#f50057',
    },
    background: {
      default: '#0a1929',
      paper: '#132f4c',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
  },
})

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ThemeProvider theme={darkTheme}>
      <CssBaseline />
      <App />
    </ThemeProvider>
  </React.StrictMode>,
)
EOFTSX

# Create App.tsx with router
cat > src/App.tsx << 'EOFTSX'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import VerifyEmailPage from './pages/VerifyEmailPage'
import DashboardPage from './pages/DashboardPage'
import { useEffect, useState } from 'react'

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)

  useEffect(() => {
    const token = localStorage.getItem('token')
    setIsAuthenticated(!!token)
  }, [])

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register" element={<RegisterPage />} />
        <Route path="/verify-email" element={<VerifyEmailPage />} />
        <Route 
          path="/dashboard" 
          element={isAuthenticated ? <DashboardPage /> : <Navigate to="/login" />} 
        />
        <Route path="/" element={<Navigate to="/dashboard" />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App
EOFTSX

# Create API service
cat > src/services/api.ts << 'EOFTS'
import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add token to requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Handle 401 errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

export default api
EOFTS

# Create LoginPage
cat > src/pages/LoginPage.tsx << 'EOFTSX'
import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import {
  Container, Paper, TextField, Button, Typography,
  Box, Alert, CircularProgress
} from '@mui/material'
import api from '../services/api'

export default function LoginPage() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      const response = await api.post('/auth/login', { email, password })
      localStorage.setItem('token', response.data.access_token)
      localStorage.setItem('user', JSON.stringify(response.data.user))
      navigate('/dashboard')
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Login failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Container maxWidth="sm">
      <Box sx={{ mt: 8 }}>
        <Paper elevation={3} sx={{ p: 4 }}>
          <Typography variant="h4" align="center" gutterBottom>
            Zedin Steam Manager
          </Typography>
          <Typography variant="h6" align="center" color="text.secondary" gutterBottom>
            Login
          </Typography>

          {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

          <form onSubmit={handleLogin}>
            <TextField
              label="Email"
              type="email"
              fullWidth
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              margin="normal"
              autoComplete="email"
            />
            <TextField
              label="Password"
              type="password"
              fullWidth
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              margin="normal"
              autoComplete="current-password"
            />
            <Button
              type="submit"
              variant="contained"
              fullWidth
              size="large"
              disabled={loading}
              sx={{ mt: 3, mb: 2 }}
            >
              {loading ? <CircularProgress size={24} /> : 'Login'}
            </Button>
          </form>

          <Box sx={{ textAlign: 'center', mt: 2 }}>
            <Typography variant="body2">
              Don't have an account?{' '}
              <Link to="/register" style={{ color: '#2196f3' }}>
                Register here
              </Link>
            </Typography>
          </Box>
        </Paper>
      </Box>
    </Container>
  )
}
EOFTSX

# Create RegisterPage
cat > src/pages/RegisterPage.tsx << 'EOFTSX'
import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import {
  Container, Paper, TextField, Button, Typography,
  Box, Alert, CircularProgress
} from '@mui/material'
import api from '../services/api'

export default function RegisterPage() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [loading, setLoading] = useState(false)

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setSuccess('')

    if (password !== confirmPassword) {
      setError('Passwords do not match')
      return
    }

    if (password.length < 6) {
      setError('Password must be at least 6 characters')
      return
    }

    setLoading(true)

    try {
      const response = await api.post('/auth/register', {
        email,
        username,
        password
      })
      setSuccess(response.data.message)
      setTimeout(() => navigate('/login'), 3000)
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Registration failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Container maxWidth="sm">
      <Box sx={{ mt: 8 }}>
        <Paper elevation={3} sx={{ p: 4 }}>
          <Typography variant="h4" align="center" gutterBottom>
            Zedin Steam Manager
          </Typography>
          <Typography variant="h6" align="center" color="text.secondary" gutterBottom>
            Register
          </Typography>

          {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
          {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}

          <form onSubmit={handleRegister}>
            <TextField
              label="Email"
              type="email"
              fullWidth
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              margin="normal"
              autoComplete="email"
            />
            <TextField
              label="Username"
              type="text"
              fullWidth
              required
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              margin="normal"
              autoComplete="username"
            />
            <TextField
              label="Password"
              type="password"
              fullWidth
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              margin="normal"
              autoComplete="new-password"
            />
            <TextField
              label="Confirm Password"
              type="password"
              fullWidth
              required
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              margin="normal"
              autoComplete="new-password"
            />
            <Button
              type="submit"
              variant="contained"
              fullWidth
              size="large"
              disabled={loading}
              sx={{ mt: 3, mb: 2 }}
            >
              {loading ? <CircularProgress size={24} /> : 'Register'}
            </Button>
          </form>

          <Box sx={{ textAlign: 'center', mt: 2 }}>
            <Typography variant="body2">
              Already have an account?{' '}
              <Link to="/login" style={{ color: '#2196f3' }}>
                Login here
              </Link>
            </Typography>
          </Box>
        </Paper>
      </Box>
    </Container>
  )
}
EOFTSX

# Create VerifyEmailPage
cat > src/pages/VerifyEmailPage.tsx << 'EOFTSX'
import { useEffect, useState } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'
import {
  Container, Paper, Typography, Box, Alert, CircularProgress, Button
} from '@mui/material'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import ErrorIcon from '@mui/icons-material/Error'
import api from '../services/api'

export default function VerifyEmailPage() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading')
  const [message, setMessage] = useState('')

  useEffect(() => {
    const token = searchParams.get('token')
    
    if (!token) {
      setStatus('error')
      setMessage('Invalid verification link')
      return
    }

    verifyEmail(token)
  }, [searchParams])

  const verifyEmail = async (token: string) => {
    try {
      const response = await api.post('/auth/verify-email', { token })
      setStatus('success')
      setMessage(response.data.message)
    } catch (err: any) {
      setStatus('error')
      setMessage(err.response?.data?.detail || 'Verification failed')
    }
  }

  return (
    <Container maxWidth="sm">
      <Box sx={{ mt: 8 }}>
        <Paper elevation={3} sx={{ p: 4, textAlign: 'center' }}>
          <Typography variant="h4" gutterBottom>
            Email Verification
          </Typography>

          {status === 'loading' && (
            <Box sx={{ my: 4 }}>
              <CircularProgress size={60} />
              <Typography variant="body1" sx={{ mt: 2 }}>
                Verifying your email...
              </Typography>
            </Box>
          )}

          {status === 'success' && (
            <Box sx={{ my: 4 }}>
              <CheckCircleIcon sx={{ fontSize: 60, color: 'success.main' }} />
              <Alert severity="success" sx={{ mt: 2 }}>
                {message}
              </Alert>
              <Button
                variant="contained"
                onClick={() => navigate('/login')}
                sx={{ mt: 3 }}
              >
                Go to Login
              </Button>
            </Box>
          )}

          {status === 'error' && (
            <Box sx={{ my: 4 }}>
              <ErrorIcon sx={{ fontSize: 60, color: 'error.main' }} />
              <Alert severity="error" sx={{ mt: 2 }}>
                {message}
              </Alert>
              <Button
                variant="contained"
                onClick={() => navigate('/register')}
                sx={{ mt: 3 }}
              >
                Back to Register
              </Button>
            </Box>
          )}
        </Paper>
      </Box>
    </Container>
  )
}
EOFTSX

# Create DashboardPage with Git Update button
cat > src/pages/DashboardPage.tsx << 'EOFTSX'
import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Container, Paper, Typography, Box, Button, Grid,
  AppBar, Toolbar, IconButton, Card, CardContent,
  Alert, CircularProgress, Chip
} from '@mui/material'
import LogoutIcon from '@mui/icons-material/Logout'
import UpdateIcon from '@mui/icons-material/Update'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import api from '../services/api'

export default function DashboardPage() {
  const navigate = useNavigate()
  const [user, setUser] = useState<any>(null)
  const [updateStatus, setUpdateStatus] = useState<any>(null)
  const [updating, setUpdating] = useState(false)
  const [message, setMessage] = useState('')

  useEffect(() => {
    const userData = localStorage.getItem('user')
    if (userData) {
      setUser(JSON.parse(userData))
    }
    
    checkForUpdates()
  }, [])

  const checkForUpdates = async () => {
    try {
      const response = await api.get('/dashboard/git-status')
      setUpdateStatus(response.data)
    } catch (err) {
      console.error('Failed to check updates:', err)
    }
  }

  const handleGitUpdate = async () => {
    setMessage('')
    setUpdating(true)

    try {
      const response = await api.post('/dashboard/git-update')
      setMessage(response.data.message)
      
      if (response.data.updated) {
        setTimeout(() => {
          window.location.reload()
        }, 3000)
      }
      
      await checkForUpdates()
    } catch (err: any) {
      setMessage(err.response?.data?.detail || 'Update failed')
    } finally {
      setUpdating(false)
    }
  }

  const handleLogout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    navigate('/login')
  }

  return (
    <Box>
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" sx={{ flexGrow: 1 }}>
            Zedin Steam Manager
          </Typography>
          <Typography variant="body2" sx={{ mr: 2 }}>
            {user?.username}
          </Typography>
          <IconButton color="inherit" onClick={handleLogout}>
            <LogoutIcon />
          </IconButton>
        </Toolbar>
      </AppBar>

      <Container maxWidth="lg" sx={{ mt: 4 }}>
        {message && (
          <Alert 
            severity={message.includes('failed') ? 'error' : 'success'} 
            sx={{ mb: 2 }}
          >
            {message}
          </Alert>
        )}

        <Grid container spacing={3}>
          {/* Git Update Card */}
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="h6">Git Updates</Typography>
                  {updateStatus?.updates_available ? (
                    <Chip label={`${updateStatus.commits_behind} updates`} color="warning" />
                  ) : (
                    <Chip icon={<CheckCircleIcon />} label="Up to date" color="success" />
                  )}
                </Box>
                
                <Typography variant="body2" color="text.secondary" sx={{ mt: 2, mb: 2 }}>
                  {updateStatus?.updates_available 
                    ? 'New updates are available from the repository'
                    : 'Your installation is up to date'}
                </Typography>

                <Button
                  variant="contained"
                  startIcon={updating ? <CircularProgress size={20} /> : <UpdateIcon />}
                  onClick={handleGitUpdate}
                  disabled={updating || !updateStatus?.updates_available}
                  fullWidth
                >
                  {updating ? 'Updating...' : 'Update Now'}
                </Button>
              </CardContent>
            </Card>
          </Grid>

          {/* System Info Card */}
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6">System Information</Typography>
                <Box sx={{ mt: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    Version: 0.0.1-alpha
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Module: 1 (Installation & Base System)
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Email: {user?.email}
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>

          {/* Placeholder for future modules */}
          <Grid item xs={12}>
            <Paper sx={{ p: 3, textAlign: 'center' }}>
              <Typography variant="h6" color="text.secondary">
                Additional features coming in future modules...
              </Typography>
            </Paper>
          </Grid>
        </Grid>
      </Container>
    </Box>
  )
}
EOFTSX

# Build frontend
echo "Building frontend..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend built successfully"
else
    echo "⚠️  Warning: Frontend build failed, but will be available in dev mode"
fi

echo ""
echo "✅ Frontend setup completed"
echo ""
