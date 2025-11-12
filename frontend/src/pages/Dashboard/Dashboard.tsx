import React, { useEffect, useState } from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  Button,
  Chip,
  LinearProgress,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
} from '@mui/material';
import {
  PlayArrow,
  Stop,
  Settings,
  DeleteForever,
  Visibility,
  Add,
  Computer,
  Storage,
  Memory,
  NetworkCheck,
} from '@mui/icons-material';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import { systemApi } from '../../services/api';
import { useSystemStore } from '../../stores/systemStore';
import SystemResourceCard from '../../components/System/SystemResourceCard';
import ServerCard from '../../components/Server/ServerCard';
import LogViewer from '../../components/Logs/LogViewer';

interface DashboardProps {}

const Dashboard: React.FC<DashboardProps> = () => {
  const queryClient = useQueryClient();
  const { systemInfo, updateSystemInfo } = useSystemStore();
  const [showLogDialog, setShowLogDialog] = useState(false);
  const [selectedServerId, setSelectedServerId] = useState<number | null>(null);

  // Real-time system monitoring (5 seconds interval)
  const { data: systemData } = useQuery({
    queryKey: ['system-info'],
    queryFn: systemApi.getSystemInfo,
    refetchInterval: 5000, // 5 seconds as required
  });

  // Server status monitoring
  const { data: servers } = useQuery({
    queryKey: ['servers'],
    queryFn: systemApi.getServers,
    refetchInterval: 2000, // 2 seconds for server status
  });

  // Update check (every hour)
  const { data: updateInfo } = useQuery({
    queryKey: ['update-check'],
    queryFn: systemApi.checkUpdates,
    refetchInterval: 60 * 60 * 1000, // 1 hour as required
  });

  useEffect(() => {
    if (systemData) {
      updateSystemInfo(systemData);
    }
  }, [systemData, updateSystemInfo]);

  const handleStartServer = useMutation({
    mutationFn: (serverId: number) => systemApi.startServer(serverId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['servers'] });
    },
  });

  const handleStopServer = useMutation({
    mutationFn: (serverId: number) => systemApi.stopServer(serverId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['servers'] });
    },
  });

  const handleInstallServer = useMutation({
    mutationFn: (serverId: number) => systemApi.installServer(serverId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['servers'] });
    },
  });

  const handleDeleteSharedFiles = useMutation({
    mutationFn: (gameType: 'ASE' | 'ASA') => systemApi.deleteSharedFiles(gameType),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['servers'] });
    },
  });

  const openLogViewer = (serverId: number) => {
    setSelectedServerId(serverId);
    setShowLogDialog(true);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'RUNNING':
        return 'success';
      case 'STOPPED':
        return 'error';
      case 'INSTALLING':
        return 'warning';
      case 'NOT_INSTALLED':
        return 'default';
      default:
        return 'default';
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        Dashboard - Zedin Steam Manager v0.000001
      </Typography>

      {/* Update notification */}
      {updateInfo?.hasUpdate && (
        <Card sx={{ mb: 3, backgroundColor: 'warning.dark' }}>
          <CardContent>
            <Typography variant="h6" color="warning.contrastText">
              Update Available: {updateInfo.latestVersion}
            </Typography>
            <Typography variant="body2" color="warning.contrastText">
              A new version is available. Click the Manager Update button to install.
            </Typography>
            <Button
              variant="contained"
              color="primary"
              sx={{ mt: 1 }}
              onClick={() => systemApi.updateManager()}
            >
              Manager Update
            </Button>
          </CardContent>
        </Card>
      )}

      {/* System Resources */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <SystemResourceCard
            title="CPU Usage"
            value={systemInfo?.cpu_percent || 0}
            unit="%"
            icon={<Computer />}
            color="primary"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <SystemResourceCard
            title="RAM Usage"
            value={systemInfo?.memory_used || 0}
            total={systemInfo?.memory_total || 0}
            unit="MB"
            icon={<Memory />}
            color="secondary"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <SystemResourceCard
            title="HDD Usage"
            value={systemInfo?.disk_used || 0}
            total={systemInfo?.disk_total || 0}
            unit="GB"
            icon={<Storage />}
            color="info"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <SystemResourceCard
            title="Network"
            value={systemInfo?.network_sent || 0}
            unit="MB/s"
            icon={<NetworkCheck />}
            color="success"
          />
        </Grid>
      </Grid>

      {/* Server Management */}
      <Box sx={{ mb: 3 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Typography variant="h5">Server Management</Typography>
          <Box>
            <Button
              variant="contained"
              color="error"
              startIcon={<DeleteForever />}
              onClick={() => handleDeleteSharedFiles.mutate('ASE')}
              sx={{ mr: 1 }}
            >
              Delete ASE Shared Files
            </Button>
            <Button
              variant="contained"
              color="error"
              startIcon={<DeleteForever />}
              onClick={() => handleDeleteSharedFiles.mutate('ASA')}
            >
              Delete ASA Shared Files
            </Button>
          </Box>
        </Box>

        <Grid container spacing={3}>
          {servers?.map((server: any) => (
            <Grid item xs={12} md={6} lg={4} key={server.id}>
              <ServerCard
                server={server}
                onStart={() => handleStartServer.mutate(server.id)}
                onStop={() => handleStopServer.mutate(server.id)}
                onInstall={() => handleInstallServer.mutate(server.id)}
                onViewLogs={() => openLogViewer(server.id)}
                onConfigure={() => {/* Navigate to config */}}
              />
            </Grid>
          ))}
        </Grid>
      </Box>

      {/* Log Viewer Dialog */}
      <Dialog
        open={showLogDialog}
        onClose={() => setShowLogDialog(false)}
        maxWidth="lg"
        fullWidth
      >
        <DialogTitle>
          Server Logs
          {selectedServerId && ` - Server ${selectedServerId}`}
        </DialogTitle>
        <DialogContent>
          {selectedServerId && (
            <LogViewer
              serverId={selectedServerId}
              logType="RUNTIME"
              refreshInterval={1000} // 1 second as required
            />
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowLogDialog(false)}>Close</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Dashboard;