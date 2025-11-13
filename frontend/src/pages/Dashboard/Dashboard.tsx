import React from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Button,
} from '@mui/material';

interface DashboardProps {}

const Dashboard: React.FC<DashboardProps> = () => {
  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        🎉 Dashboard - Zedin Steam Manager v0.000001
      </Typography>

      <Typography variant="h6" gutterBottom color="success.main">
        ✅ Bejelentkezés sikeres! 
      </Typography>

      <Grid container spacing={3} sx={{ mt: 2 }}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                🔧 Rendszer információk
              </Typography>
              <Typography variant="body2" color="text.secondary">
                CPU: Loading...
              </Typography>
              <Typography variant="body2" color="text.secondary">
                RAM: Loading...
              </Typography>
              <Typography variant="body2" color="text.secondary">
                HDD: Loading...
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                🎮 Szerverek
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Server lista loading...
              </Typography>
              <Button variant="contained" sx={{ mt: 2 }}>
                Szerver hozzáadása
              </Button>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                📊 Külső adatbázis
              </Typography>
              <Typography variant="body2" color="success.main">
                ✅ Supabase PostgreSQL kapcsolat aktív
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Felhasználói adatok külső adatbázisban tárolva
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Újratelepítésnél automatikus bejelentkezés
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;