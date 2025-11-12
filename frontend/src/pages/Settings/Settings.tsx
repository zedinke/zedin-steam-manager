import React from 'react';
import { Paper, Typography } from '@mui/material';

const Settings: React.FC = () => {
  return (
    <Paper sx={{ p: 2 }}>
      <Typography variant="h4" gutterBottom>
        Settings
      </Typography>
      <Typography>
        Application settings coming soon...
      </Typography>
    </Paper>
  );
};

export default Settings;