import React from 'react';
import { Paper, Typography, Button, Box } from '@mui/material';

const Login: React.FC = () => {
  return (
    <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh' }}>
      <Paper sx={{ p: 4, maxWidth: 400 }}>
        <Typography variant="h4" gutterBottom align="center">
          Login
        </Typography>
        <Typography align="center" sx={{ mb: 2 }}>
          Authentication system coming soon...
        </Typography>
        <Button variant="contained" fullWidth>
          Login
        </Button>
      </Paper>
    </Box>
  );
};

export default Login;