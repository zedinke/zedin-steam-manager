import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import {
  Container, Box, Card, CardContent, Typography,
  TextField, Button, Alert, CircularProgress
} from '@mui/material'
import EmailIcon from '@mui/icons-material/Email'
import ArrowBackIcon from '@mui/icons-material/ArrowBack'
import api from '../services/api'

export default function ForgotPasswordPage() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [messageType, setMessageType] = useState<'success' | 'error'>('success')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!email.trim()) {
      setMessage('Kérlek add meg az email címed')
      setMessageType('error')
      return
    }

    setLoading(true)
    setMessage('')

    try {
      await api.post('/auth/forgot-password', { email: email.trim() })
      
      setMessage('✅ Elküldtük a jelszó visszaállító linket az email címedre!')
      setMessageType('success')
      setEmail('')
      
      // Redirect to login after 5 seconds
      setTimeout(() => {
        navigate('/login')
      }, 5000)
    } catch (err: any) {
      setMessage(err.response?.data?.detail || 'Hiba történt. Próbáld újra.')
      setMessageType('error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 2
      }}
    >
      <Container maxWidth="sm">
        <Card sx={{ borderRadius: 4, boxShadow: '0 20px 60px rgba(0,0,0,0.3)' }}>
          <CardContent sx={{ p: 4 }}>
            <Box sx={{ textAlign: 'center', mb: 3 }}>
              <EmailIcon sx={{ fontSize: 60, color: '#667eea', mb: 2 }} />
              <Typography variant="h4" gutterBottom fontWeight="bold">
                Elfelejtett Jelszó
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Add meg az email címed és küldünk egy jelszó visszaállító linket
              </Typography>
            </Box>

            {message && (
              <Alert severity={messageType} sx={{ mb: 3 }}>
                {message}
              </Alert>
            )}

            <form onSubmit={handleSubmit}>
              <TextField
                fullWidth
                type="email"
                label="Email cím"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={loading}
                margin="normal"
                required
                autoFocus
              />

              <Button
                type="submit"
                fullWidth
                variant="contained"
                size="large"
                disabled={loading}
                sx={{
                  mt: 3,
                  mb: 2,
                  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                  '&:hover': {
                    background: 'linear-gradient(135deg, #764ba2 0%, #667eea 100%)'
                  }
                }}
              >
                {loading ? (
                  <>
                    <CircularProgress size={24} sx={{ mr: 1, color: 'white' }} />
                    Küldés...
                  </>
                ) : (
                  <>
                    <EmailIcon sx={{ mr: 1 }} />
                    Link Küldése
                  </>
                )}
              </Button>

              <Button
                fullWidth
                component={Link}
                to="/login"
                startIcon={<ArrowBackIcon />}
                disabled={loading}
              >
                Vissza a Bejelentkezéshez
              </Button>
            </form>

            <Box sx={{ mt: 3, p: 2, bgcolor: '#f8f9fa', borderRadius: 2 }}>
              <Typography variant="caption" color="text.secondary">
                💡 <strong>Tipp:</strong> Nézd meg a spam mappádat is, ha nem érkezik meg az email 5 percen belül.
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Container>
    </Box>
  )
}
