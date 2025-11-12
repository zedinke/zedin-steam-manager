import React from 'react';
import { Paper, Typography, Box } from '@mui/material';

const LogViewer: React.FC = () => {
  return (
    <Paper sx={{ p: 2, backgroundColor: '#1e1e1e', color: '#ffffff' }}>
      <Typography variant="h6" gutterBottom>
        System Logs
      </Typography>
      <Box sx={{ fontFamily: 'monospace', fontSize: '0.875rem' }}>
        <Typography component="pre">
{`[2025-11-12 22:54:15] System startup complete
[2025-11-12 22:54:15] Backend service running on port 8000
[2025-11-12 22:54:15] Nginx configured successfully
[2025-11-12 22:54:15] All services operational`}
        </Typography>
      </Box>
    </Paper>
  );
};

export default LogViewer;