from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_admin = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)
    
    # Relationships
    servers = relationship("Server", back_populates="owner")
    tokens = relationship("UserToken", back_populates="user")

class UserToken(Base):
    __tablename__ = "user_tokens"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    token = Column(String(255), unique=True, index=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=False)
    is_active = Column(Boolean, default=True)
    
    # Relationships
    user = relationship("User", back_populates="tokens")

class RemoteHost(Base):
    __tablename__ = "remote_hosts"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    hostname = Column(String(255), nullable=False)
    port = Column(Integer, default=22)
    username = Column(String(100), nullable=False)
    ssh_key_path = Column(String(500), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_ping = Column(DateTime, nullable=True)
    
    # Relationships
    servers = relationship("Server", back_populates="host")

class Server(Base):
    __tablename__ = "servers"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    game_type = Column(String(20), nullable=False)  # 'ASE' or 'ASA'
    status = Column(String(20), default="NOT_INSTALLED")  # NOT_INSTALLED, INSTALLING, INSTALLED, RUNNING, STOPPED
    
    # Server configuration
    port = Column(Integer, nullable=False)
    query_port = Column(Integer, nullable=True)
    rcon_port = Column(Integer, nullable=True)
    rcon_password = Column(String(255), nullable=True)
    max_players = Column(Integer, default=20)
    
    # Paths
    install_path = Column(String(500), nullable=True)
    config_path = Column(String(500), nullable=True)
    
    # Host information
    host_id = Column(Integer, ForeignKey("remote_hosts.id"), nullable=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    last_started = Column(DateTime, nullable=True)
    last_stopped = Column(DateTime, nullable=True)
    
    # Process information
    process_id = Column(Integer, nullable=True)
    cpu_usage = Column(Float, default=0.0)
    memory_usage = Column(Float, default=0.0)
    
    # Relationships
    owner = relationship("User", back_populates="servers")
    host = relationship("RemoteHost", back_populates="servers")
    logs = relationship("ServerLog", back_populates="server")
    configs = relationship("ServerConfig", back_populates="server")

class ServerConfig(Base):
    __tablename__ = "server_configs"
    
    id = Column(Integer, primary_key=True, index=True)
    server_id = Column(Integer, ForeignKey("servers.id"), nullable=False)
    config_type = Column(String(50), nullable=False)  # 'GameUserSettings', 'Game', 'Engine'
    config_content = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    server = relationship("Server", back_populates="configs")

class ServerLog(Base):
    __tablename__ = "server_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    server_id = Column(Integer, ForeignKey("servers.id"), nullable=False)
    log_type = Column(String(20), nullable=False)  # 'INSTALL', 'RUNTIME', 'ERROR'
    message = Column(Text, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    server = relationship("Server", back_populates="logs")

class SystemInfo(Base):
    __tablename__ = "system_info"
    
    id = Column(Integer, primary_key=True, index=True)
    host_id = Column(Integer, ForeignKey("remote_hosts.id"), nullable=True)
    
    # System resources
    cpu_percent = Column(Float, nullable=False)
    memory_total = Column(Integer, nullable=False)  # in MB
    memory_used = Column(Integer, nullable=False)   # in MB
    disk_total = Column(Integer, nullable=False)    # in GB
    disk_used = Column(Integer, nullable=False)     # in GB
    
    # Network
    network_sent = Column(Integer, default=0)       # in MB
    network_recv = Column(Integer, default=0)       # in MB
    
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    host = relationship("RemoteHost")

class SharedFiles(Base):
    __tablename__ = "shared_files"
    
    id = Column(Integer, primary_key=True, index=True)
    game_type = Column(String(20), nullable=False)  # 'ASE' or 'ASA'
    file_path = Column(String(500), nullable=False)
    file_size = Column(Integer, nullable=False)     # in bytes
    checksum = Column(String(64), nullable=True)    # SHA256
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True)