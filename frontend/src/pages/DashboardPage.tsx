import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Container, Typography, Box, Button, Grid,
  AppBar, Toolbar, IconButton, Card, CardContent,
  Alert, CircularProgress, Chip
} from '@mui/material'
import LogoutIcon from '@mui/icons-material/Logout'
import UpdateIcon from '@mui/icons-material/Update'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import ConfirmationNumberIcon from '@mui/icons-material/ConfirmationNumber'
import VpnKeyIcon from '@mui/icons-material/VpnKey'
import api from '../services/api'
import SystemMonitor from '../components/SystemMonitor'
import NotificationBell from '../components/NotificationBell'

export default function DashboardPage() {
  const navigate = useNavigate()
  const [user, setUser] = useState<any>(null)
  const [updateStatus, setUpdateStatus] = useState<any>(null)
  const [updating, setUpdating] = useState(false)
  const [message, setMessage] = useState('')
  const [tokenExpiry, setTokenExpiry] = useState<string | null>(null)

  useEffect(() => {
    const userData = localStorage.getItem('user')
    if (userData) {
      const parsedUser = JSON.parse(userData)
      setUser(parsedUser)
      
      // Fetch token expiry if user is server_admin
      if (parsedUser.role === 'server_admin') {
        fetchTokenExpiry()
      }
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

  const fetchTokenExpiry = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await api.get('/tokens/my', {
        params: { token }
      })
      if (response.data.tokens && response.data.tokens.length > 0) {
        const activeToken = response.data.tokens.find((t: any) => t.status === 'active')
        if (activeToken) {
          setTokenExpiry(activeToken.expires_at)
        }
      }
    } catch (err) {
      console.error('Failed to fetch token expiry:', err)
    }
  }

  const handleGitUpdate = async () => {
    setMessage('')
    setUpdating(true)

    try {
      // Redirect to static updating page immediately
      window.location.href = '/updating.html';
      
      // Start the update process
      await api.post('/dashboard/git-update')
    } catch (err: any) {
      setMessage(err.response?.data?.detail || 'Update failed')
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
          <NotificationBell />
          <IconButton color="inherit" onClick={handleLogout}>
            <LogoutIcon />
          </IconButton>
        </Toolbar>
      </AppBar>

      <Container maxWidth="xl" sx={{ mt: 4 }}>
        {message && (
          <Alert 
            severity={message.includes('failed') ? 'error' : 'success'} 
            sx={{ mb: 2 }}
          >
            {message}
          </Alert>
        )}

        <Grid container spacing={3}>
          {/* Left Sidebar - Menu */}
          <Grid item xs={12} md={2}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Menü
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1, mt: 2 }}>
                  {user?.role === 'manager_admin' && (
                    <Button
                      variant="outlined"
                      startIcon={<ConfirmationNumberIcon />}
                      size="small"
                      onClick={() => navigate('/tokens/generate')}
                      fullWidth
                    >
                      Token Generálás
                    </Button>
                  )}
                  {(user?.role === 'user' || user?.role === 'server_admin') && (
                    <Button
                      variant="outlined"
                      startIcon={<VpnKeyIcon />}
                      size="small"
                      onClick={() => navigate('/tokens/activate')}
                      fullWidth
                    >
                      Token Aktiválás
                    </Button>
                  )}
                </Box>
              </CardContent>
            </Card>
          </Grid>

          {/* Center Content */}
          <Grid item xs={12} md={7}>
            <Grid container spacing={3}>
              {/* Git Update Card */}
              <Grid item xs={12}>
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
              <Grid item xs={12}>
                <Card>
                  <CardContent>
                    <Typography variant="h6">System Information</Typography>
                    <Box sx={{ mt: 2 }}>
                      <Typography variant="body2" color="text.secondary">
                        Version: 0.0.3-final
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Module: 1.5 (Token & Notification System)
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Email: {user?.email}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Role: {user?.role === 'manager_admin' ? 'Manager Admin' : user?.role === 'server_admin' ? 'Server Admin' : 'User'}
                      </Typography>
                    </Box>
                  </CardContent>
                </Card>
              </Grid>

              {/* Token Expiry Card (Server Admin Only) */}
              {user?.role === 'server_admin' && tokenExpiry && (
                <Grid item xs={12}>
                  <Card sx={{ bgcolor: 'warning.light' }}>
                    <CardContent>
                      <Typography variant="h6" gutterBottom>
                        🎟️ Token Érvényesség
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        A Server Admin tokened lejár:
                      </Typography>
                      <Typography variant="h5" sx={{ mt: 1 }}>
                        {new Date(tokenExpiry).toLocaleDateString('hu-HU')}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {(() => {
                          const days = Math.ceil((new Date(tokenExpiry).getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24))
                          if (days < 0) return 'Lejárt'
                          if (days < 5) return `⚠️ Még ${days} nap van hátra!`
                          return `${days} nap van hátra`
                        })()}
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
              )}
            </Grid>
          </Grid>

          {/* Right Sidebar - System Monitoring */}
          <Grid item xs={12} md={3}>
            <SystemMonitor />
          </Grid>
        </Grid>
      </Container>
    </Box>
  )
}
