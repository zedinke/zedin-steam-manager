import React from 'react';
import { Card, CardContent, Typography, LinearProgress, Box } from '@mui/material';

interface SystemResourceCardProps {
  title: string;
  value: number;
  unit?: string;
  total?: number;
  icon?: React.ReactNode;
  color?: string;
}

const SystemResourceCard: React.FC<SystemResourceCardProps> = ({ 
  title, 
  value, 
  unit = '%', 
  total, 
  icon, 
  color = 'primary' 
}) => {
  return (
    <Card sx={{ minWidth: 275, mb: 2 }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
          {icon && <Box sx={{ mr: 1 }}>{icon}</Box>}
          <Typography color="textSecondary" gutterBottom>
            {title}
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
          <Typography variant="h4" component="div">
            {value}{unit}
            {total && <Typography variant="body2" component="span" sx={{ ml: 1 }}>
              / {total}{unit}
            </Typography>}
          </Typography>
        </Box>
        <LinearProgress variant="determinate" value={value} color={color as any} />
      </CardContent>
    </Card>
  );
};

export default SystemResourceCard;