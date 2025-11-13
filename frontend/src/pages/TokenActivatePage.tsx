import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Container, Paper, Typography, Box, Button, TextField,
  Alert, CircularProgress, Card, CardContent, Grid
} from '@mui/material'
import VpnKeyIcon from '@mui/icons-material/VpnKey'
import api from '../services/api'

export default function TokenActivatePage() {
  const navigate = useNavigate()
  const [tokenCode, setTokenCode] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [messageType, setMessageType] = useState<'success' | 'error'>('success')

  const handleActivate = async () => {
    if (!tokenCode.trim()) {
      setMessage('Kérlek add meg a token kódot!')
      setMessageType('error')
      return
    }

    setLoading(true)
    setMessage('')

    try {
      const token = localStorage.getItem('token')
      const response = await api.post('/tokens/activate', {
        token_code: tokenCode.trim()
      }, {
        params: { token }
      })

      setMessage('🎉 Token sikeresen aktiválva! Most már Server Admin jogosultságod van!')
      setMessageType('success')
      setTokenCode('')

      // Update user role in localStorage
      const user = JSON.parse(localStorage.getItem('user') || '{}')
      user.role = 'server_admin'
      localStorage.setItem('user', JSON.stringify(user))

      // Redirect to dashboard after 3 seconds
      setTimeout(() => {
        navigate('/dashboard')
      }, 3000)
    } catch (err: any) {
      setMessage(err.response?.data?.detail || 'Token aktiválás sikertelen')
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
            <VpnKeyIcon sx={{ fontSize: 40, mr: 2, color: 'primary.main' }} />
            <Box>
              <Typography variant="h4">
                Token Aktiválás
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Aktiváld a Server Admin tokenodet
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
                label="Token Kód"
                value={tokenCode}
                onChange={(e) => setTokenCode(e.target.value)}
                placeholder="Másold be a token kódot az email-ből"
                helperText="A token kódot email-ben kaptad meg"
                disabled={loading}
              />
            </Grid>

            <Grid item xs={12}>
              <Button
                variant="contained"
                fullWidth
                size="large"
                onClick={handleActivate}
                disabled={loading || !tokenCode.trim()}
                startIcon={loading ? <CircularProgress size={20} /> : <VpnKeyIcon />}
              >
                {loading ? 'Aktiválás...' : 'Token Aktiválása'}
              </Button>
            </Grid>
          </Grid>

          <Box sx={{ mt: 3, p: 2, bgcolor: 'success.light', borderRadius: 1 }}>
            <Typography variant="subtitle2" gutterBottom>
              ✨ Mit kapsz az aktiválás után?
            </Typography>
            <Typography variant="body2" color="text.secondary">
              • Server Admin jogosultság a rendszerben<br />
              • Teljes hozzáférés a szerverkezelési funkciókhoz<br />
              • RCON parancsok futtatása<br />
              • Szerver konfigurációk szerkesztése<br />
              • Játékos kezelés és moderálás
            </Typography>
          </Box>

          <Box sx={{ mt: 2, p: 2, bgcolor: 'warning.light', borderRadius: 1 }}>
            <Typography variant="subtitle2" gutterBottom>
              ⚠️ Fontos
            </Typography>
            <Typography variant="body2" color="text.secondary">
              • Egy token csak egyszer aktiválható<br />
              • A token lejárati dátumát a dashboardon követheted<br />
              • Lejárat előtt 5 nappal értesítést kapsz
            </Typography>
          </Box>
        </CardContent>
      </Card>
    </Container>
  )
}
