from fastapi import APIRouter
import psutil
import platform

router = APIRouter()

@router.get("/info")
async def get_system_info():
    """Get real-time system information"""
    return {
        "cpu": {
            "percent": psutil.cpu_percent(interval=1),
            "cores": psutil.cpu_count()
        },
        "memory": {
            "total": psutil.virtual_memory().total,
            "used": psutil.virtual_memory().used,
            "percent": psutil.virtual_memory().percent
        },
        "disk": {
            "total": psutil.disk_usage('/').total,
            "used": psutil.disk_usage('/').used,
            "percent": psutil.disk_usage('/').percent
        },
        "platform": platform.system(),
        "version": platform.version()
    }
