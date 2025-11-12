import React from 'react';
import { Card, CardContent, Typography, Chip, Box, Button, ButtonGroup } from '@mui/material';

interface ServerCardProps {
  server: {
    id: number;
    name: string;
    status: string;
    players: number;
  };
  onStart?: () => void;
  onStop?: () => void;
  onInstall?: () => void;
  onViewLogs?: () => void;
  onConfigure?: () => void;
}

const ServerCard: React.FC<ServerCardProps> = ({ 
  server, 
  onStart, 
  onStop, 
  onInstall, 
  onViewLogs, 
  onConfigure 
}) => {
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
        <Typography color="textSecondary" sx={{ mb: 2 }}>
          Players: {server.players}
        </Typography>
        <ButtonGroup size="small" variant="outlined">
          {onStart && (
            <Button onClick={onStart} color="success">
              Start
            </Button>
          )}
          {onStop && (
            <Button onClick={onStop} color="error">
              Stop
            </Button>
          )}
          {onInstall && (
            <Button onClick={onInstall}>
              Install
            </Button>
          )}
          {onViewLogs && (
            <Button onClick={onViewLogs}>
              Logs
            </Button>
          )}
          {onConfigure && (
            <Button onClick={onConfigure}>
              Configure
            </Button>
          )}
        </ButtonGroup>
      </CardContent>
    </Card>
  );
};

export default ServerCard;