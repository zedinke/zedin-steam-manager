import React from 'react';
import { Card, CardContent, Typography, Chip, Box } from '@mui/material';

interface ServerCardProps {
  server: {
    id: number;
    name: string;
    status: string;
    players: number;
  };
}

const ServerCard: React.FC<ServerCardProps> = ({ server }) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'running':
        return 'success';
      case 'stopped':
        return 'error';
      default:
        return 'default';
    }
  };

  return (
    <Card sx={{ minWidth: 275, mb: 2 }}>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
          <Typography variant="h6" component="div">
            {server.name}
          </Typography>
          <Chip 
            label={server.status} 
            color={getStatusColor(server.status) as any} 
            size="small" 
          />
        </Box>
        <Typography color="textSecondary">
          Players: {server.players}
        </Typography>
      </CardContent>
    </Card>
  );
};

export default ServerCard;