import { Card, CardContent, Typography, Box } from '@mui/material'

interface SystemInfoProps {
  user: {
    email: string
    role: string
  }
}

export default function SystemInfo({ user }: SystemInfoProps) {
  return (
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
            Email: {user?.email}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Role: {user?.role === 'manager_admin' ? 'Manager Admin' : user?.role === 'server_admin' ? 'Server Admin' : 'User'}
          </Typography>
        </Box>
      </CardContent>
    </Card>
  )
}
