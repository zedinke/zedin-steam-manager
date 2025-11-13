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
}

interface SystemHistory {
  cpu: number[]
  memory: number[]
  timestamps: string[]
}

export default function SystemMonitor() {
  const [systemInfo, setSystemInfo] = useState<SystemInfo | null>(null)
  const [history, setHistory] = useState<SystemHistory>({ cpu: [], memory: [], timestamps: [] })
  const [realtimeCpu, setRealtimeCpu] = useState<number[]>([])
  const [realtimeMemory, setRealtimeMemory] = useState<number[]>([])
  const [realtimeLabels, setRealtimeLabels] = useState<string[]>([])

  // Fetch real-time data every 2 seconds
  useEffect(() => {
    const fetchRealtime = async () => {
      try {
        const response = await api.get('/system/info')
        const data = response.data
        setSystemInfo(data)

        // Update realtime chart (last 60 samples = 2 minutes)
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
  }, [])

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

  if (!systemInfo) {
    return <Typography>Betöltés...</Typography>
  }

  return (
    <Grid container spacing={3}>
      {/* CPU Real-time */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              CPU használat (valós idejű - 2mp)
            </Typography>
            <Typography variant="body2" color="text.secondary" gutterBottom>
              {systemInfo.cpu.percent.toFixed(1)}% | {systemInfo.cpu.cores} mag, {systemInfo.cpu.threads} szál
            </Typography>
            <Box sx={{ height: 200, mt: 2 }}>
              <Line data={realtimeCpuData} options={realtimeChartOptions} />
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* RAM Real-time */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              RAM használat (valós idejű - 2mp)
            </Typography>
            <Typography variant="body2" color="text.secondary" gutterBottom>
              {formatBytes(systemInfo.memory.free)} szabad / {formatBytes(systemInfo.memory.total)} összesen
            </Typography>
            <Box sx={{ mt: 2 }}>
              <LinearProgress 
                variant="determinate" 
                value={systemInfo.memory.percent} 
                sx={{ height: 10, borderRadius: 5 }}
              />
              <Typography variant="body2" align="center" sx={{ mt: 1 }}>
                {systemInfo.memory.percent.toFixed(1)}%
              </Typography>
            </Box>
            <Box sx={{ height: 180, mt: 2 }}>
              <Line data={realtimeMemoryData} options={realtimeChartOptions} />
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* CPU History */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              CPU történet (2 óra - 2 perces minták)
            </Typography>
            <Box sx={{ height: 250, mt: 2 }}>
              <Line data={historyCpuData} options={historyChartOptions} />
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* RAM History */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              RAM történet (2 óra - 2 perces minták)
            </Typography>
            <Box sx={{ height: 250, mt: 2 }}>
              <Line data={historyMemoryData} options={historyChartOptions} />
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Disk Space */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Tárhely
            </Typography>
            <Typography variant="body2" color="text.secondary" gutterBottom>
              {formatBytes(systemInfo.disk.free)} szabad / {formatBytes(systemInfo.disk.total)} összesen
            </Typography>
            <Box sx={{ mt: 2 }}>
              <LinearProgress 
                variant="determinate" 
                value={systemInfo.disk.percent} 
                sx={{ height: 12, borderRadius: 5 }}
                color={systemInfo.disk.percent > 90 ? 'error' : 'primary'}
              />
              <Typography variant="body2" align="center" sx={{ mt: 1 }}>
                {systemInfo.disk.percent.toFixed(1)}% használva
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  )
}
