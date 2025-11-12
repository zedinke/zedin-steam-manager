import React from 'react';
import { Paper, Typography } from '@mui/material';

const Servers: React.FC = () => {
  return (
    <Paper sx={{ p: 2 }}>
      <Typography variant="h4" gutterBottom>
        Servers
      </Typography>
      <Typography>
        Server management coming soon...
      </Typography>
    </Paper>
  );
};

export default Servers;