import { useState, useEffect } from 'react'
import { useNavigate, useSearchParams, Link } from 'react-router-dom'
import {
  Container, Box, Card, CardContent, Typography,
  TextField, Button, Alert, CircularProgress, InputAdornment,
  IconButton
} from '@mui/material'
import LockResetIcon from '@mui/icons-material/LockReset'
import VisibilityIcon from '@mui/icons-material/Visibility'
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import api from '../services/api'

export default function ResetPasswordPage() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const token = searchParams.get('token')
  
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [messageType, setMessageType] = useState<'success' | 'error'>('success')
  const [success, setSuccess] = useState(false)

  useEffect(() => {
    if (!token) {
      setMessage('Érvénytelen vagy hiányzó token')
      setMessageType('error')
    }
  }, [token])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!token) {
      setMessage('Érvénytelen vagy hiányzó token')
      setMessageType('error')
      return
    }

    if (password.length < 6) {
      setMessage('A jelszónak legalább 6 karakter hosszúnak kell lennie')
      setMessageType('error')
      return
    }

    if (password !== confirmPassword) {
      setMessage('A két jelszó nem egyezik')
      setMessageType('error')
      return
    }

    setLoading(true)
    setMessage('')

    try {
      await api.post('/auth/reset-password', {
        token,
        new_password: password
      })
      
      setMessage('🎉 Jelszó sikeresen megváltoztatva! Átirányítás a bejelentkezéshez...')
      setMessageType('success')
      setSuccess(true)
      
      // Redirect to login after 3 seconds
      setTimeout(() => {
        navigate('/login')
      }, 3000)
    } catch (err: any) {
      setMessage(err.response?.data?.detail || 'Hiba történt. A token lehet, hogy lejárt.')
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
              {success ? (
                <CheckCircleIcon sx={{ fontSize: 60, color: 'success.main', mb: 2 }} />
              ) : (
                <LockResetIcon sx={{ fontSize: 60, color: '#667eea', mb: 2 }} />
              )}
              <Typography variant="h4" gutterBottom fontWeight="bold">
                {success ? 'Sikeres Változtatás' : 'Új Jelszó Beállítása'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {success 
                  ? 'Most már bejelentkezhetsz az új jelszóval'
                  : 'Válassz egy erős, biztonságos jelszót'
                }
              </Typography>
            </Box>

            {message && (
              <Alert severity={messageType} sx={{ mb: 3 }}>
                {message}
              </Alert>
            )}

            {!success && token && (
              <form onSubmit={handleSubmit}>
                <TextField
                  fullWidth
                  type={showPassword ? 'text' : 'password'}
                  label="Új Jelszó"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={loading}
                  margin="normal"
                  required
                  autoFocus
                  helperText="Minimum 6 karakter"
                  InputProps={{
                    endAdornment: (
                      <InputAdornment position="end">
                        <IconButton
                          onClick={() => setShowPassword(!showPassword)}
                          edge="end"
                        >
                          {showPassword ? <VisibilityOffIcon /> : <VisibilityIcon />}
                        </IconButton>
                      </InputAdornment>
                    )
                  }}
                />

                <TextField
                  fullWidth
                  type={showPassword ? 'text' : 'password'}
                  label="Jelszó Megerősítése"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  disabled={loading}
                  margin="normal"
                  required
                  error={confirmPassword !== '' && password !== confirmPassword}
                  helperText={
                    confirmPassword !== '' && password !== confirmPassword
                      ? 'A jelszavak nem egyeznek'
                      : ''
                  }
                />

                <Button
                  type="submit"
                  fullWidth
                  variant="contained"
                  size="large"
                  disabled={loading || !password || !confirmPassword || password !== confirmPassword}
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
                      Mentés...
                    </>
                  ) : (
                    <>
                      <LockResetIcon sx={{ mr: 1 }} />
                      Jelszó Megváltoztatása
                    </>
                  )}
                </Button>

                <Button
                  fullWidth
                  component={Link}
                  to="/login"
                  disabled={loading}
                >
                  Mégse
                </Button>
              </form>
            )}

            {success && (
              <Button
                fullWidth
                component={Link}
                to="/login"
                variant="contained"
                size="large"
                sx={{
                  mt: 2,
                  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
                }}
              >
                Bejelentkezés
              </Button>
            )}

            {!success && (
              <Box sx={{ mt: 3, p: 2, bgcolor: '#f8f9fa', borderRadius: 2 }}>
                <Typography variant="caption" color="text.secondary" display="block" gutterBottom>
                  <strong>💡 Erős jelszó kritériumok:</strong>
                </Typography>
                <Typography variant="caption" color="text.secondary" component="ul" sx={{ m: 0, pl: 2 }}>
                  <li>Minimum 6 karakter (javasolt: 12+)</li>
                  <li>Tartalmaz kis- és nagybetűket</li>
                  <li>Tartalmaz számokat</li>
                  <li>Tartalmaz speciális karaktereket (@, #, $ stb.)</li>
                </Typography>
              </Box>
            )}
          </CardContent>
        </Card>
      </Container>
    </Box>
  )
}
