from fastapi import APIRouter
import psutil
import platform
from datetime import datetime, timedelta
from collections import deque
import time

router = APIRouter()

# Store historical data (last 2 hours, one sample every 2 minutes = 60 samples)
history_data = {
    "cpu": deque(maxlen=60),
    "memory": deque(maxlen=60),
    "network_sent": deque(maxlen=60),
    "network_recv": deque(maxlen=60),
    "timestamps": deque(maxlen=60)
}

# Last update time for 2-minute interval
last_history_update = time.time()
last_network_bytes = None

def update_history():
    """Update historical data every 2 minutes"""
    global last_history_update, last_network_bytes
    current_time = time.time()
    
    # Only update if 2 minutes (120 seconds) have passed
    if current_time - last_history_update >= 120:
        net_io = psutil.net_io_counters()
        
        history_data["cpu"].append(psutil.cpu_percent(interval=0.5))
        history_data["memory"].append(psutil.virtual_memory().percent)
        
        # Network rates (bytes per second averaged over 2 minutes)
        if last_network_bytes:
            time_diff = current_time - last_history_update
            sent_rate = (net_io.bytes_sent - last_network_bytes[0]) / time_diff / 1024 / 1024  # MB/s
            recv_rate = (net_io.bytes_recv - last_network_bytes[1]) / time_diff / 1024 / 1024  # MB/s
            history_data["network_sent"].append(round(sent_rate, 2))
            history_data["network_recv"].append(round(recv_rate, 2))
        else:
            history_data["network_sent"].append(0)
            history_data["network_recv"].append(0)
        
        history_data["timestamps"].append(datetime.now().strftime("%H:%M"))
        last_network_bytes = (net_io.bytes_sent, net_io.bytes_recv)
        last_history_update = current_time

@router.get("/info")
async def get_system_info():
    """Get real-time system information (called every 2 seconds)"""
    # Update history in background
    update_history()
    
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    net_io = psutil.net_io_counters()
    
    return {
        "cpu": {
            "percent": psutil.cpu_percent(interval=0.5),
            "cores": psutil.cpu_count(logical=False),
            "threads": psutil.cpu_count(logical=True)
        },
        "memory": {
            "total": mem.total,
            "used": mem.used,
            "free": mem.available,
            "percent": mem.percent
        },
        "disk": {
            "total": disk.total,
            "used": disk.used,
            "free": disk.free,
            "percent": disk.percent
        },
        "network": {
            "bytes_sent": net_io.bytes_sent,
            "bytes_recv": net_io.bytes_recv,
            "packets_sent": net_io.packets_sent,
            "packets_recv": net_io.packets_recv
        },
        "platform": platform.system(),
        "version": platform.version()
    }

@router.get("/history")
async def get_system_history():
    """Get historical data (last 2 hours)"""
    return {
        "cpu": list(history_data["cpu"]),
        "memory": list(history_data["memory"]),
        "network_sent": list(history_data["network_sent"]),
        "network_recv": list(history_data["network_recv"]),
        "timestamps": list(history_data["timestamps"])
    }
