"""Server model for ASE/ASA server management."""
from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from backend.config.database import Base

class ServerType(str, enum.Enum):
    ASE = "ASE"
    ASA = "ASA"

class ServerStatus(str, enum.Enum):
    RUNNING = "RUNNING"
    STOPPED = "STOPPED"
    INSTALLING = "INSTALLING"
    NOT_INSTALLED = "NOT_INSTALLED"

class Server(Base):
    __tablename__ = "servers"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False)
    server_type = Column(Enum(ServerType), nullable=False)
    status = Column(Enum(ServerStatus), default=ServerStatus.NOT_INSTALLED)
    
    # Connection details
    host_id = Column(String, ForeignKey("hosts.id"), nullable=False)
    game_port = Column(Integer, nullable=False)
    query_port = Column(Integer, nullable=False)
    rcon_port = Column(Integer, nullable=False)
    rcon_password = Column(String, nullable=False)
    
    # Installation paths
    install_path = Column(String, nullable=False)
    steamcmd_path = Column(String, nullable=False)
    
    # Ownership
    owner_id = Column(String, ForeignKey("users.id"), nullable=False)
    
    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    owner = relationship("User", back_populates="servers")
    host = relationship("Host", back_populates="servers")
