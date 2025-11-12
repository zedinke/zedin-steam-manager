from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import psutil
import shutil
import os
from typing import Dict, Any

from config.database import get_db
from config.settings import Settings
from services.auth_service import get_current_user
from services.system_service import SystemService
from services.update_service import UpdateService

router = APIRouter()

@router.get("/info")
async def get_system_info(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get real-time system information (updated every 5 seconds)"""
    system_service = SystemService(db)
    return system_service.get_system_info()

@router.get("/servers")
async def get_servers_summary(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get summary of all servers"""
    system_service = SystemService(db)
    return system_service.get_servers_summary(current_user.id)

@router.get("/version")
async def get_version():
    """Get manager version"""
    settings = Settings()
    return {
        "version": settings.VERSION,
        "name": settings.APP_NAME
    }

@router.get("/check-updates")
async def check_updates():
    """Check for manager updates (called every hour)"""
    update_service = UpdateService()
    return await update_service.check_for_updates()

@router.post("/update")
async def update_manager(
    current_user = Depends(get_current_user)
):
    """Update manager to latest version"""
    # Only admin can trigger updates
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    update_service = UpdateService()
    return await update_service.update_manager()

@router.delete("/shared-files/{game_type}")
async def delete_shared_files(
    game_type: str,  # 'ASE' or 'ASA'
    current_user = Depends(get_current_user)
):
    """Delete shared files for ASE or ASA"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    settings = Settings()
    shared_path = f"{settings.SHARED_FILES_PATH}/{game_type.lower()}"
    
    try:
        if os.path.exists(shared_path):
            shutil.rmtree(shared_path)
            return {
                "success": True,
                "message": f"Successfully deleted {game_type} shared files"
            }
        else:
            return {
                "success": False,
                "message": f"No {game_type} shared files found"
            }
    except Exception as e:
        return {
            "success": False,
            "message": f"Failed to delete {game_type} shared files: {str(e)}"
        }

@router.get("/logs")
async def get_system_logs(
    limit: int = 100,
    current_user = Depends(get_current_user)
):
    """Get system logs"""
    # Implementation for system-wide logs
    return {"logs": [], "message": "System logs endpoint"}

@router.get("/processes")
async def get_running_processes(
    current_user = Depends(get_current_user)
):
    """Get all running game server processes"""
    processes = []
    
    for proc in psutil.process_iter(['pid', 'name', 'cmdline', 'cpu_percent', 'memory_info']):
        try:
            if 'ShooterGameServer' in proc.info['name'] or 'ArkAscendedServer' in proc.info['name']:
                processes.append({
                    'pid': proc.info['pid'],
                    'name': proc.info['name'],
                    'cmdline': ' '.join(proc.info['cmdline']) if proc.info['cmdline'] else '',
                    'cpu_percent': proc.info['cpu_percent'],
                    'memory_mb': proc.info['memory_info'].rss / 1024 / 1024 if proc.info['memory_info'] else 0
                })
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    
    return {"processes": processes}

@router.get("/hosts")
async def get_remote_hosts(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get registered remote hosts"""
    system_service = SystemService(db)
    return system_service.get_remote_hosts()

@router.post("/hosts")
async def register_remote_host(
    host_data: dict,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Register new remote host"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    system_service = SystemService(db)
    return system_service.register_remote_host(host_data)

@router.delete("/hosts/{host_id}")
async def remove_remote_host(
    host_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Remove remote host"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    system_service = SystemService(db)
    return system_service.remove_remote_host(host_id)