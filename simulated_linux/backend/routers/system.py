from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from config.database import get_db
from services.auth_service import get_current_user
from services.system_service import SystemService
import os

router = APIRouter()

@router.get("/info")
async def get_system_info(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get real-time system information"""
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

@router.delete("/shared-files/{game_type}")
async def delete_shared_files(
    game_type: str,  # 'ASE' or 'ASA'
    current_user = Depends(get_current_user)
):
    """Delete shared files for ASE or ASA"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    return {
        "success": True,
        "message": f"Shared files deletion for {game_type} not implemented yet"
    }