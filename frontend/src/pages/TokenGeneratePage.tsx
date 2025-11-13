import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Container, Paper, Typography, Box, Button, TextField,
  Alert, CircularProgress, Select, MenuItem, FormControl,
  InputLabel, Card, CardContent, Grid
} from '@mui/material'
import ConfirmationNumberIcon from '@mui/icons-material/ConfirmationNumber'
import api from '../services/api'

interface User {
  id: string
  email: string
  username: string
  role: string
}

export default function TokenGeneratePage() {
  const navigate = useNavigate()
  const [users, setUsers] = useState<User[]>([])
  const [selectedUserId, setSelectedUserId] = useState('')
  const [durationDays, setDurationDays] = useState(365)
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [messageType, setMessageType] = useState<'success' | 'error'>('success')

  useEffect(() => {
    // Check if user is manager_admin
    const user = JSON.parse(localStorage.getItem('user') || '{}')
    if (user.role !== 'manager_admin') {
      navigate('/dashboard')
      return
    }

    fetchUsers()
  }, [navigate])

  const fetchUsers = async () => {
    try {
      const token = localStorage.getItem('token')
      // TODO: Implement /api/auth/users endpoint to list users with server_admin and user roles
      // For now, we'll use a placeholder
      setUsers([])
    } catch (err) {
      console.error('Failed to fetch users:', err)
    }
  }

  const handleGenerate = async () => {
    if (!selectedUserId) {
      setMessage('Kérlek válassz egy felhasználót!')
      setMessageType('error')
      return
    }

    setLoading(true)
    setMessage('')

    try {
      const token = localStorage.getItem('token')
      const response = await api.post('/tokens/generate', {
        assigned_to_email: selectedUserId, // This should be email for now
        duration_days: durationDays
      }, {
        params: { token }
      })

      setMessage(`Token sikeresen generálva! Kód: ${response.data.token_code}`)
      setMessageType('success')
      setSelectedUserId('')
    } catch (err: any) {
      setMessage(err.response?.data?.detail || 'Token generálás sikertelen')
      setMessageType('error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Container maxWidth="md" sx={{ mt: 4 }}>
      <Button
        variant="text"
        onClick={() => navigate('/dashboard')}
        sx={{ mb: 2 }}
      >
        ← Vissza a Dashboardhoz
      </Button>

      <Card>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
            <ConfirmationNumberIcon sx={{ fontSize: 40, mr: 2, color: 'primary.main' }} />
            <Box>
              <Typography variant="h4">
                Token Generálás
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Server Admin token generálása felhasználóknak
              </Typography>
            </Box>
          </Box>

          {message && (
            <Alert severity={messageType} sx={{ mb: 3 }}>
              {message}
            </Alert>
          )}

          <Grid container spacing={3}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Felhasználó Email Címe"
                value={selectedUserId}
                onChange={(e) => setSelectedUserId(e.target.value)}
                placeholder="user@example.com"
                helperText="Add meg a felhasználó email címét, akinek a tokent generálod"
              />
            </Grid>

            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Érvényesség (napok)</InputLabel>
                <Select
                  value={durationDays}
                  label="Érvényesség (napok)"
                  onChange={(e) => setDurationDays(Number(e.target.value))}
                >
                  <MenuItem value={30}>30 nap (1 hónap)</MenuItem>
                  <MenuItem value={90}>90 nap (3 hónap)</MenuItem>
                  <MenuItem value={180}>180 nap (6 hónap)</MenuItem>
                  <MenuItem value={365}>365 nap (1 év)</MenuItem>
                  <MenuItem value={730}>730 nap (2 év)</MenuItem>
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12}>
              <Button
                variant="contained"
                fullWidth
                size="large"
                onClick={handleGenerate}
                disabled={loading || !selectedUserId}
                startIcon={loading ? <CircularProgress size={20} /> : <ConfirmationNumberIcon />}
              >
                {loading ? 'Generálás...' : 'Token Generálása'}
              </Button>
            </Grid>
          </Grid>

          <Box sx={{ mt: 3, p: 2, bgcolor: 'info.light', borderRadius: 1 }}>
            <Typography variant="subtitle2" gutterBottom>
              📋 Információ
            </Typography>
            <Typography variant="body2" color="text.secondary">
              • A token automatikusan elküldésre kerül email-ben<br />
              • A felhasználó értesítést kap a rendszerben<br />
              • Aktiválás után a felhasználó Server Admin jogot kap<br />
              • A token a megadott időtartam után lejár
            </Typography>
          </Box>
        </CardContent>
      </Card>
    </Container>
  )
}
