import React from 'react';
import { Card, CardContent, Typography, LinearProgress, Box } from '@mui/material';

interface SystemResourceCardProps {
  title: string;
  value: number;
  unit?: string;
}

const SystemResourceCard: React.FC<SystemResourceCardProps> = ({ title, value, unit = '%' }) => {
  return (
    <Card sx={{ minWidth: 275, mb: 2 }}>
      <CardContent>
        <Typography color="textSecondary" gutterBottom>
          {title}
        </Typography>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
          <Typography variant="h4" component="div">
            {value}{unit}
          </Typography>
        </Box>
        <LinearProgress variant="determinate" value={value} />
      </CardContent>
    </Card>
  );
};

export default SystemResourceCard;