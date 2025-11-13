import { useState, useEffect } from 'react'
import {
  Card, CardContent, Typography, Box, Button, Dialog,
  DialogTitle, DialogContent, DialogActions, TextField,
  Table, TableBody, TableCell, TableContainer, TableHead,
  TableRow, Paper, Chip, Alert
} from '@mui/material'
import ConfirmationNumberIcon from '@mui/icons-material/ConfirmationNumber'
import VpnKeyIcon from '@mui/icons-material/VpnKey'
import CloseIcon from '@mui/icons-material/Close'
import api from '../services/api'

interface SystemInfoProps {
  user: {
    username: string
    email: string
    role: string
  }
}

interface Token {
  id: string
  token_code: string
  activated_at: string
  expires_at: string
  status: string
}

export default function SystemInfo({ user }: SystemInfoProps) {
  const [tokens, setTokens] = useState<Token[]>([])
  const [tokenCount, setTokenCount] = useState(0)
  const [dialogOpen, setDialogOpen] = useState(false)
  const [activateDialogOpen, setActivateDialogOpen] = useState(false)
  const [tokenCode, setTokenCode] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [messageType, setMessageType] = useState<'success' | 'error'>('success')

  useEffect(() => {
    fetchTokens()
  }, [])

  const fetchTokens = async () => {
    try {
      const token = localStorage.getItem('token')
      const response = await api.get('/tokens/my', {
        params: { token }
      })
      if (response.data.tokens) {
        const activeTokens = response.data.tokens.filter((t: Token) => t.status === 'active')
        setTokens(response.data.tokens)
        setTokenCount(activeTokens.length)
      }
    } catch (err) {
      console.error('Failed to fetch tokens:', err)
    }
  }

  const handleActivateToken = async () => {
    if (!tokenCode.trim()) {
      setMessage('Kérlek add meg a token kódot')
      setMessageType('error')
      return
    }

    setLoading(true)
    setMessage('')

    try {
      const token = localStorage.getItem('token')
      await api.post('/tokens/activate', {
        token_code: tokenCode.trim()
      }, {
        params: { token }
      })

      setMessage('🎉 Token sikeresen aktiválva!')
      setMessageType('success')
      setTokenCode('')
      
      // Refresh tokens
      setTimeout(() => {
        fetchTokens()
        setActivateDialogOpen(false)
        setMessage('')
      }, 2000)
    } catch (err: any) {
      setMessage(err.response?.data?.detail || 'Token aktiválás sikertelen')
      setMessageType('error')
    } finally {
      setLoading(false)
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString('hu-HU', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'success'
      case 'expired':
        return 'error'
      case 'pending':
        return 'warning'
      default:
        return 'default'
    }
  }

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'active':
        return 'Aktív'
      case 'expired':
        return 'Lejárt'
      case 'pending':
        return 'Függőben'
      default:
        return status
    }
  }

  return (
    <>
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            System Information
          </Typography>
          <Box sx={{ mt: 1 }}>
            <Typography variant="body2" color="text.secondary">
              Version: 0.0.3-final
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Module: 1.5 (Token & Notification System)
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Username: {user?.username}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Email: {user?.email}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Role: {user?.role === 'manager_admin' ? 'Manager Admin' : user?.role === 'server_admin' ? 'Server Admin' : 'User'}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Aktív tokenek: {tokenCount}
            </Typography>
          </Box>

          <Box sx={{ mt: 2, display: 'flex', flexDirection: 'column', gap: 1 }}>
            <Button
              variant="outlined"
              size="small"
              startIcon={<ConfirmationNumberIcon />}
              onClick={() => setDialogOpen(true)}
              fullWidth
            >
              Tokenek Megtekintése
            </Button>
            <Button
              variant="contained"
              size="small"
              startIcon={<VpnKeyIcon />}
              onClick={() => setActivateDialogOpen(true)}
              fullWidth
            >
              Token Aktiválás
            </Button>
          </Box>
        </CardContent>
      </Card>

      {/* Tokens List Dialog */}
      <Dialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <ConfirmationNumberIcon color="primary" />
            Aktivált Tokenek
          </Box>
        </DialogTitle>
        <DialogContent>
          {tokens.length === 0 ? (
            <Typography variant="body2" color="text.secondary" align="center" sx={{ py: 3 }}>
              Még nincs aktivált tokened
            </Typography>
          ) : (
            <TableContainer component={Paper} variant="outlined">
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell><strong>Token Azonosító</strong></TableCell>
                    <TableCell><strong>Aktiválva</strong></TableCell>
                    <TableCell><strong>Lejár</strong></TableCell>
                    <TableCell><strong>Státusz</strong></TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {tokens.map((token) => (
                    <TableRow key={token.id}>
                      <TableCell>
                        <Typography variant="caption" sx={{ fontFamily: 'monospace' }}>
                          {token.id.substring(0, 8)}...
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="caption">
                          {formatDate(token.activated_at)}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="caption">
                          {formatDate(token.expires_at)}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={getStatusLabel(token.status)}
                          color={getStatusColor(token.status)}
                          size="small"
                        />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)} startIcon={<CloseIcon />}>
            Bezárás
          </Button>
        </DialogActions>
      </Dialog>

      {/* Token Activation Dialog */}
      <Dialog
        open={activateDialogOpen}
        onClose={() => {
          setActivateDialogOpen(false)
          setMessage('')
          setTokenCode('')
        }}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <VpnKeyIcon color="primary" />
            Token Aktiválás
          </Box>
        </DialogTitle>
        <DialogContent>
          {message && (
            <Alert severity={messageType} sx={{ mb: 2 }}>
              {message}
            </Alert>
          )}
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Másold be a Manager Admin által generált token kódot:
          </Typography>
          <TextField
            fullWidth
            label="Token Kód"
            value={tokenCode}
            onChange={(e) => setTokenCode(e.target.value)}
            placeholder="Például: ZEDIN-XXXX-XXXX-XXXX"
            disabled={loading}
            helperText="A token kód érzékeny a kis- és nagybetűkre"
          />
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => {
              setActivateDialogOpen(false)
              setMessage('')
              setTokenCode('')
            }}
            disabled={loading}
          >
            Mégse
          </Button>
          <Button
            onClick={handleActivateToken}
            variant="contained"
            disabled={loading || !tokenCode.trim()}
            startIcon={<VpnKeyIcon />}
          >
            {loading ? 'Aktiválás...' : 'Aktiválás'}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  )
}
