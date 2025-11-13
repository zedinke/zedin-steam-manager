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
                    Version: 0.0.3-final
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
