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
  const [hasVerified, setHasVerified] = useState(false)

  useEffect(() => {
    // Prevent double verification
    if (hasVerified) return

    const token = searchParams.get('token')
    
    if (!token) {
      setStatus('error')
      setMessage('Invalid verification link')
      return
    }

    setHasVerified(true)
    verifyEmail(token)
  }, []) // Empty dependency array - only run once on mount

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
