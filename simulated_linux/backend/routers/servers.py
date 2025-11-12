from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from config.database import get_db
from models.base import Server, ServerLog
from schemas.server import ServerCreate, ServerUpdate, ServerResponse
from services.server_service import ServerService
from services.auth_service import get_current_user

router = APIRouter()

@router.get("/", response_model=List[ServerResponse])
async def get_servers(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get all servers for the current user"""
    server_service = ServerService(db)
    return server_service.get_user_servers(current_user.id)

@router.post("/", response_model=ServerResponse)
async def create_server(
    server: ServerCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new server"""
    server_service = ServerService(db)
    return server_service.create_server(server, current_user.id)

@router.get("/{server_id}", response_model=ServerResponse)
async def get_server(
    server_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get a specific server"""
    server_service = ServerService(db)
    server = server_service.get_server(server_id, current_user.id)
    if not server:
        raise HTTPException(status_code=404, detail="Server not found")
    return server

@router.put("/{server_id}", response_model=ServerResponse)
async def update_server(
    server_id: int,
    server_update: ServerUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a server"""
    server_service = ServerService(db)
    server = server_service.update_server(server_id, server_update, current_user.id)
    if not server:
        raise HTTPException(status_code=404, detail="Server not found")
    return server

@router.delete("/{server_id}")
async def delete_server(
    server_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Delete a server"""
    server_service = ServerService(db)
    success = server_service.delete_server(server_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Server not found")
    return {"message": "Server deleted successfully"}

@router.post("/{server_id}/start")
async def start_server(
    server_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Start a server"""
    server_service = ServerService(db)
    result = await server_service.start_server(server_id, current_user.id)
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    return result

@router.post("/{server_id}/stop")
async def stop_server(
    server_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Stop a server safely using RCON DoExit"""
    server_service = ServerService(db)
    result = await server_service.stop_server(server_id, current_user.id)
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    return result

@router.post("/{server_id}/install")
async def install_server(
    server_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Install server files using SteamCMD"""
    server_service = ServerService(db)
    result = await server_service.install_server(server_id, current_user.id)
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    return result

@router.get("/{server_id}/status")
async def get_server_status(
    server_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get real-time server status"""
    server_service = ServerService(db)
    status_info = await server_service.get_server_status(server_id, current_user.id)
    if not status_info:
        raise HTTPException(status_code=404, detail="Server not found")
    return status_info

@router.get("/{server_id}/logs")
async def get_server_logs(
    server_id: int,
    log_type: str = "RUNTIME",
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get server logs with real-time updates"""
    server_service = ServerService(db)
    logs = server_service.get_server_logs(server_id, log_type, limit, current_user.id)
    return logs

@router.get("/{server_id}/players")
async def get_server_players(
    server_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get current players using RCON ListPlayers"""
    server_service = ServerService(db)
    players = await server_service.get_server_players(server_id, current_user.id)
    if players is None:
        raise HTTPException(status_code=404, detail="Server not found or RCON not available")
    return {"players": players}

@router.post("/{server_id}/rcon")
async def execute_rcon_command(
    server_id: int,
    command: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Execute RCON command on server"""
    server_service = ServerService(db)
    result = await server_service.execute_rcon_command(server_id, command, current_user.id)
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    return result

@router.get("/{server_id}/config/{config_type}")
async def get_server_config(
    server_id: int,
    config_type: str,  # 'GameUserSettings', 'Game', 'Engine'
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get server configuration file"""
    server_service = ServerService(db)
    config = server_service.get_server_config(server_id, config_type, current_user.id)
    if not config:
        raise HTTPException(status_code=404, detail="Configuration not found")
    return config

@router.put("/{server_id}/config/{config_type}")
async def update_server_config(
    server_id: int,
    config_type: str,
    config_content: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update server configuration file"""
    server_service = ServerService(db)
    result = server_service.update_server_config(
        server_id, config_type, config_content, current_user.id
    )
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])
    return result