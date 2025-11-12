import React from 'react';
import { Paper, Typography } from '@mui/material';

const System: React.FC = () => {
  return (
    <Paper sx={{ p: 2 }}>
      <Typography variant="h4" gutterBottom>
        System
      </Typography>
      <Typography>
        System monitoring coming soon...
      </Typography>
    </Paper>
  );
};

export default System;