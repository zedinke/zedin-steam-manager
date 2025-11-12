from pydantic import BaseModel, validator
from typing import Optional, List
from datetime import datetime

class ServerBase(BaseModel):
    name: str
    game_type: str  # 'ASE' or 'ASA'
    port: int
    query_port: Optional[int] = None
    rcon_port: Optional[int] = None
    rcon_password: Optional[str] = None
    max_players: int = 20

class ServerCreate(ServerBase):
    @validator('game_type')
    def validate_game_type(cls, v):
        if v not in ['ASE', 'ASA']:
            raise ValueError('Game type must be either ASE or ASA')
        return v

class ServerUpdate(BaseModel):
    name: Optional[str] = None
    port: Optional[int] = None
    query_port: Optional[int] = None
    rcon_port: Optional[int] = None
    rcon_password: Optional[str] = None
    max_players: Optional[int] = None

class ServerResponse(ServerBase):
    id: int
    status: str
    owner_id: int
    created_at: datetime
    last_started: Optional[datetime] = None
    last_stopped: Optional[datetime] = None
    process_id: Optional[int] = None
    cpu_usage: float = 0.0
    memory_usage: float = 0.0

    class Config:
        from_attributes = True