import { useState, useEffect } from 'react'
import {
  IconButton, Badge, Menu, MenuItem, Typography, Box,
  Divider, ListItemIcon, ListItemText, Chip
} from '@mui/material'
import NotificationsIcon from '@mui/icons-material/Notifications'
import MarkEmailReadIcon from '@mui/icons-material/MarkEmailRead'
import InfoIcon from '@mui/icons-material/Info'
import WarningIcon from '@mui/icons-material/Warning'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import ErrorIcon from '@mui/icons-material/Error'
import ConfirmationNumberIcon from '@mui/icons-material/ConfirmationNumber'
import api from '../services/api'

interface Notification {
  id: string
  title: string
  message: string
  type: 'info' | 'warning' | 'success' | 'error' | 'token'
  read: boolean
  created_at: string
  link?: string
}

export default function NotificationBell() {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null)
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [unreadCount, setUnreadCount] = useState(0)

  useEffect(() => {
    fetchUnreadCount()
    const interval = setInterval(fetchUnreadCount, 30000) // Check every 30 seconds
    return () => clearInterval(interval)
  }, [])

  const fetchUnreadCount = async () => {
    try {
      const token = localStorage.getItem('token')
      if (!token) return

      const response = await api.get('/notifications/unread-count', {
        params: { token }
      })
      setUnreadCount(response.data.count)
    } catch (err) {
      console.error('Failed to fetch unread count:', err)
    }
  }

  const fetchNotifications = async () => {
    try {
      const token = localStorage.getItem('token')
      if (!token) return

      const response = await api.get('/notifications', {
        params: { token }
      })
      setNotifications(response.data.notifications)
    } catch (err) {
      console.error('Failed to fetch notifications:', err)
    }
  }

  const handleClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget)
    fetchNotifications()
  }

  const handleClose = () => {
    setAnchorEl(null)
  }

  const markAsRead = async (notificationId: string) => {
    try {
      const token = localStorage.getItem('token')
      if (!token) return

      await api.patch(`/notifications/${notificationId}/read`, null, {
        params: { token }
      })
      
      setNotifications(prev =>
        prev.map(n => n.id === notificationId ? { ...n, read: true } : n)
      )
      setUnreadCount(prev => Math.max(0, prev - 1))
    } catch (err) {
      console.error('Failed to mark as read:', err)
    }
  }

  const getIcon = (type: string) => {
    switch (type) {
      case 'info': return <InfoIcon fontSize="small" color="info" />
      case 'warning': return <WarningIcon fontSize="small" color="warning" />
      case 'success': return <CheckCircleIcon fontSize="small" color="success" />
      case 'error': return <ErrorIcon fontSize="small" color="error" />
      case 'token': return <ConfirmationNumberIcon fontSize="small" color="secondary" />
      default: return <InfoIcon fontSize="small" />
    }
  }

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    const now = new Date()
    const diffMs = now.getTime() - date.getTime()
    const diffMins = Math.floor(diffMs / 60000)
    const diffHours = Math.floor(diffMs / 3600000)
    const diffDays = Math.floor(diffMs / 86400000)

    if (diffMins < 1) return 'Most'
    if (diffMins < 60) return `${diffMins} perce`
    if (diffHours < 24) return `${diffHours} órája`
    if (diffDays < 7) return `${diffDays} napja`
    return date.toLocaleDateString('hu-HU')
  }

  return (
    <>
      <IconButton color="inherit" onClick={handleClick}>
        <Badge badgeContent={unreadCount} color="error">
          <NotificationsIcon />
        </Badge>
      </IconButton>

      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleClose}
        PaperProps={{
          sx: { width: 360, maxHeight: 500 }
        }}
      >
        <Box sx={{ px: 2, py: 1 }}>
          <Typography variant="h6">Értesítések</Typography>
        </Box>
        <Divider />

        {notifications.length === 0 ? (
          <MenuItem disabled>
            <Typography variant="body2" color="text.secondary">
              Nincs új értesítés
            </Typography>
          </MenuItem>
        ) : (
          notifications.map((notification) => (
            <MenuItem
              key={notification.id}
              onClick={() => {
                if (!notification.read) {
                  markAsRead(notification.id)
                }
                if (notification.link) {
                  window.location.href = notification.link
                }
                handleClose()
              }}
              sx={{
                backgroundColor: notification.read ? 'transparent' : 'action.hover',
                flexDirection: 'column',
                alignItems: 'flex-start',
                py: 1.5
              }}
            >
              <Box sx={{ display: 'flex', alignItems: 'center', width: '100%', mb: 0.5 }}>
                <ListItemIcon sx={{ minWidth: 32 }}>
                  {getIcon(notification.type)}
                </ListItemIcon>
                <Typography variant="subtitle2" sx={{ flexGrow: 1 }}>
                  {notification.title}
                </Typography>
                {!notification.read && (
                  <Chip label="Új" size="small" color="primary" sx={{ height: 20 }} />
                )}
              </Box>
              <Typography variant="body2" color="text.secondary" sx={{ pl: 4 }}>
                {notification.message}
              </Typography>
              <Typography variant="caption" color="text.disabled" sx={{ pl: 4, mt: 0.5 }}>
                {formatDate(notification.created_at)}
              </Typography>
            </MenuItem>
          ))
        )}

        {notifications.length > 0 && (
          <>
            <Divider />
            <MenuItem
              onClick={async () => {
                const unreadNotifications = notifications.filter(n => !n.read)
                for (const n of unreadNotifications) {
                  await markAsRead(n.id)
                }
                handleClose()
              }}
            >
              <ListItemIcon>
                <MarkEmailReadIcon fontSize="small" />
              </ListItemIcon>
              <ListItemText primary="Összes olvasottnak jelölése" />
            </MenuItem>
          </>
        )}
      </Menu>
    </>
  )
}
