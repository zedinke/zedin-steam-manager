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
    "timestamps": deque(maxlen=60)
}

# Last update time for 2-minute interval
last_history_update = time.time()

def update_history():
    """Update historical data every 2 minutes"""
    global last_history_update
    current_time = time.time()
    
    # Only update if 2 minutes (120 seconds) have passed
    if current_time - last_history_update >= 120:
        history_data["cpu"].append(psutil.cpu_percent(interval=0.5))
        history_data["memory"].append(psutil.virtual_memory().percent)
        history_data["timestamps"].append(datetime.now().strftime("%H:%M"))
        last_history_update = current_time

@router.get("/info")
async def get_system_info():
    """Get real-time system information (called every 2 seconds)"""
    # Update history in background
    update_history()
    
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
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
        "platform": platform.system(),
        "version": platform.version()
    }

@router.get("/history")
async def get_system_history():
    """Get historical data (last 2 hours)"""
    return {
        "cpu": list(history_data["cpu"]),
        "memory": list(history_data["memory"]),
        "timestamps": list(history_data["timestamps"])
    }
