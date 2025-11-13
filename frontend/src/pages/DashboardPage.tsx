import { useNavigate } from 'react-router-dom';
import {
  Container,
  Box,
  Paper,
  Typography,
  Button,
  AppBar,
  Toolbar,
  Grid,
  Card,
  CardContent,
} from '@mui/material';
import LogoutIcon from '@mui/icons-material/Logout';
import ServerIcon from '@mui/icons-material/Storage';
import { authAPI } from '../services/api';

interface DashboardPageProps {
  setIsAuthenticated: (value: boolean) => void;
}

export default function DashboardPage({ setIsAuthenticated }: DashboardPageProps) {
  const navigate = useNavigate();
  const username = localStorage.getItem('username') || 'User';
  const email = localStorage.getItem('email') || '';

  const handleLogout = async () => {
    try {
      await authAPI.logout();
    } catch (err) {
      console.error('Logout error:', err);
    } finally {
      // Clear local storage
      localStorage.clear();
      setIsAuthenticated(false);
      navigate('/login');
    }
  };

  return (
    <Box sx={{ flexGrow: 1 }}>
      <AppBar position="static">
        <Toolbar>
          <ServerIcon sx={{ mr: 2 }} />
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Zedin Steam Manager
          </Typography>
          <Typography variant="body1" sx={{ mr: 2 }}>
            {username}
          </Typography>
          <Button color="inherit" onClick={handleLogout} startIcon={<LogoutIcon />}>
            Logout
          </Button>
        </Toolbar>
      </AppBar>

      <Container maxWidth="lg" sx={{ mt: 4 }}>
        <Paper elevation={3} sx={{ p: 3, mb: 3 }}>
          <Typography variant="h4" gutterBottom>
            Welcome, {username}!
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {email}
          </Typography>
        </Paper>

        <Grid container spacing={3}>
          <Grid item xs={12} md={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Total Servers
                </Typography>
                <Typography variant="h3" color="primary">
                  0
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  No servers configured yet
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Running Servers
                </Typography>
                <Typography variant="h3" color="success.main">
                  0
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  All servers stopped
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Total Players
                </Typography>
                <Typography variant="h3" color="info.main">
                  0
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  No active players
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="h5" gutterBottom>
                Getting Started
              </Typography>
              <Typography variant="body1" paragraph>
                Welcome to Zedin Steam Manager! This is your dashboard where you can manage your ASE and ASA servers.
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Server management features coming soon...
              </Typography>
            </Paper>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
}
