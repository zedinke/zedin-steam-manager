import { useState, useEffect } from 'react'
import { Grid, Card, CardContent, Typography, Box, LinearProgress } from '@mui/material'
import { Line } from 'react-chartjs-2'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
} from 'chart.js'
import api from '../services/api'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
)

interface SystemInfo {
  cpu: {
    percent: number
    cores: number
    threads: number
  }
  memory: {
    total: number
    used: number
    free: number
    percent: number
  }
  disk: {
    total: number
    used: number
    free: number
    percent: number
  }
  network: {
    bytes_sent: number
    bytes_recv: number
    packets_sent: number
    packets_recv: number
  }
}

interface SystemHistory {
  cpu: number[]
  memory: number[]
  network_sent: number[]
  network_recv: number[]
  timestamps: string[]
}

export default function SystemMonitor() {
  const [systemInfo, setSystemInfo] = useState<SystemInfo | null>(null)
  const [history, setHistory] = useState<SystemHistory>({ 
    cpu: [], 
    memory: [], 
    network_sent: [], 
    network_recv: [], 
    timestamps: [] 
  })
  const [realtimeCpu, setRealtimeCpu] = useState<number[]>([])
  const [realtimeMemory, setRealtimeMemory] = useState<number[]>([])
  const [realtimeNetworkSent, setRealtimeNetworkSent] = useState<number[]>([])
  const [realtimeNetworkRecv, setRealtimeNetworkRecv] = useState<number[]>([])
  const [realtimeLabels, setRealtimeLabels] = useState<string[]>([])
  const [lastNetworkBytes, setLastNetworkBytes] = useState<{sent: number, recv: number} | null>(null)

  // Fetch real-time data every 2 seconds
  useEffect(() => {
    const fetchRealtime = async () => {
      try {
        const response = await api.get('/system/info')
        const data = response.data
        setSystemInfo(data)

        // Calculate network rates (MB/s)
        if (lastNetworkBytes) {
          const sentRate = ((data.network.bytes_sent - lastNetworkBytes.sent) / 2 / 1024 / 1024).toFixed(2) // MB/s over 2 seconds
          const recvRate = ((data.network.bytes_recv - lastNetworkBytes.recv) / 2 / 1024 / 1024).toFixed(2) // MB/s over 2 seconds
          
          setRealtimeNetworkSent(prev => {
            const newData = [...prev, parseFloat(sentRate)]
            return newData.slice(-30)
          })
          
          setRealtimeNetworkRecv(prev => {
            const newData = [...prev, parseFloat(recvRate)]
            return newData.slice(-30)
          })
        }
        
        setLastNetworkBytes({
          sent: data.network.bytes_sent,
          recv: data.network.bytes_recv
        })

        // Update realtime chart (last 30 samples = 1 minute)
        const now = new Date().toLocaleTimeString('hu-HU', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
        
        setRealtimeCpu(prev => {
          const newData = [...prev, data.cpu.percent]
          return newData.slice(-30) // Keep last 30 samples (1 minute)
        })
        
        setRealtimeMemory(prev => {
          const newData = [...prev, data.memory.percent]
          return newData.slice(-30)
        })
        
        setRealtimeLabels(prev => {
          const newLabels = [...prev, now]
          return newLabels.slice(-30)
        })
      } catch (err) {
        console.error('Failed to fetch system info:', err)
      }
    }

    fetchRealtime()
    const interval = setInterval(fetchRealtime, 2000) // Every 2 seconds

    return () => clearInterval(interval)
  }, [lastNetworkBytes])

  // Fetch historical data every 2 minutes
  useEffect(() => {
    const fetchHistory = async () => {
      try {
        const response = await api.get('/system/history')
        setHistory(response.data)
      } catch (err) {
        console.error('Failed to fetch history:', err)
      }
    }

    fetchHistory()
    const interval = setInterval(fetchHistory, 120000) // Every 2 minutes

    return () => clearInterval(interval)
  }, [])

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  const realtimeChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      title: { display: false }
    },
    scales: {
      y: {
        beginAtZero: true,
        max: 100,
        ticks: { callback: (value: any) => value + '%' }
      },
      x: {
        display: false
      }
    },
    animation: { duration: 0 }
  }

  const historyChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { position: 'top' as const },
      title: { display: false }
    },
    scales: {
      y: {
        beginAtZero: true,
        max: 100,
        ticks: { callback: (value: any) => value + '%' }
      }
    }
  }

  const realtimeCpuData = {
    labels: realtimeLabels,
    datasets: [{
      label: 'CPU használat',
      data: realtimeCpu,
      borderColor: 'rgb(75, 192, 192)',
      backgroundColor: 'rgba(75, 192, 192, 0.1)',
      fill: true,
      tension: 0.4
    }]
  }

  const realtimeMemoryData = {
    labels: realtimeLabels,
    datasets: [{
      label: 'RAM használat',
      data: realtimeMemory,
      borderColor: 'rgb(255, 99, 132)',
      backgroundColor: 'rgba(255, 99, 132, 0.1)',
      fill: true,
      tension: 0.4
    }]
  }

  const historyCpuData = {
    labels: history.timestamps,
    datasets: [{
      label: 'CPU használat (2 óra)',
      data: history.cpu,
      borderColor: 'rgb(75, 192, 192)',
      backgroundColor: 'rgba(75, 192, 192, 0.1)',
      fill: true,
      tension: 0.4
    }]
  }

  const historyMemoryData = {
    labels: history.timestamps,
    datasets: [{
      label: 'RAM használat (2 óra)',
      data: history.memory,
      borderColor: 'rgb(255, 99, 132)',
      backgroundColor: 'rgba(255, 99, 132, 0.1)',
      fill: true,
      tension: 0.4
    }]
  }

  const realtimeNetworkData = {
    labels: realtimeLabels,
    datasets: [
      {
        label: 'Letöltés (MB/s)',
        data: realtimeNetworkRecv,
        borderColor: 'rgb(54, 162, 235)',
        backgroundColor: 'rgba(54, 162, 235, 0.1)',
        fill: true,
        tension: 0.4
      },
      {
        label: 'Feltöltés (MB/s)',
        data: realtimeNetworkSent,
        borderColor: 'rgb(255, 206, 86)',
        backgroundColor: 'rgba(255, 206, 86, 0.1)',
        fill: true,
        tension: 0.4
      }
    ]
  }

  const historyNetworkData = {
    labels: history.timestamps,
    datasets: [
      {
        label: 'Letöltés (MB/s)',
        data: history.network_recv,
        borderColor: 'rgb(54, 162, 235)',
        backgroundColor: 'rgba(54, 162, 235, 0.1)',
        fill: true,
        tension: 0.4
      },
      {
        label: 'Feltöltés (MB/s)',
        data: history.network_sent,
        borderColor: 'rgb(255, 206, 86)',
        backgroundColor: 'rgba(255, 206, 86, 0.1)',
        fill: true,
        tension: 0.4
      }
    ]
  }

  const networkChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { position: 'top' as const },
      title: { display: false }
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: { callback: (value: any) => value + ' MB/s' }
      }
    },
    animation: { duration: 0 }
  }

  const networkHistoryOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { position: 'top' as const },
      title: { display: false }
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: { callback: (value: any) => value + ' MB/s' }
      }
    }
  }

  if (!systemInfo) {
    return <Typography>Betöltés...</Typography>
  }

  return (
    <Grid container spacing={2}>
      {/* Disk Space */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="subtitle2" gutterBottom>
              Tárhely
            </Typography>
            <Typography variant="caption" color="text.secondary" display="block">
              {formatBytes(systemInfo.disk.free)} szabad
            </Typography>
            <Typography variant="caption" color="text.secondary" display="block">
              {formatBytes(systemInfo.disk.total)} összesen
            </Typography>
            <Box sx={{ mt: 1 }}>
              <LinearProgress 
                variant="determinate" 
                value={systemInfo.disk.percent} 
                sx={{ height: 8, borderRadius: 4 }}
                color={systemInfo.disk.percent > 90 ? 'error' : 'primary'}
              />
              <Typography variant="caption" align="center" display="block" sx={{ mt: 0.5 }}>
                {systemInfo.disk.percent.toFixed(1)}% használva
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* CPU Real-time */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="subtitle2" gutterBottom>
              CPU (valós idejű)
            </Typography>
            <Typography variant="caption" color="text.secondary" display="block">
              {systemInfo.cpu.percent.toFixed(1)}%
            </Typography>
            <Box sx={{ height: 100, mt: 1 }}>
              <Line data={realtimeCpuData} options={realtimeChartOptions} />
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* RAM Real-time */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="subtitle2" gutterBottom>
              RAM (valós idejű)
            </Typography>
            <Typography variant="caption" color="text.secondary" display="block">
              {formatBytes(systemInfo.memory.free)} szabad
            </Typography>
            <Box sx={{ height: 100, mt: 1 }}>
              <Line data={realtimeMemoryData} options={realtimeChartOptions} />
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Network Real-time */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="subtitle2" gutterBottom>
              Hálózat (valós idejű)
            </Typography>
            <Box sx={{ height: 100, mt: 1 }}>
              <Line data={realtimeNetworkData} options={networkChartOptions} />
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* CPU History */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="subtitle2" gutterBottom>
              CPU történet (2 óra)
            </Typography>
            <Box sx={{ height: 120, mt: 1 }}>
              <Line data={historyCpuData} options={historyChartOptions} />
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* RAM History */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="subtitle2" gutterBottom>
              RAM történet (2 óra)
            </Typography>
            <Box sx={{ height: 120, mt: 1 }}>
              <Line data={historyMemoryData} options={historyChartOptions} />
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Network History */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="subtitle2" gutterBottom>
              Hálózat történet (2 óra)
            </Typography>
            <Box sx={{ height: 120, mt: 1 }}>
              <Line data={historyNetworkData} options={networkHistoryOptions} />
            </Box>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  )
}
