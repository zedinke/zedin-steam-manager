"""Host model for multi-host SSH management."""
from sqlalchemy import Column, String, Integer, Boolean, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from backend.config.database import Base

class Host(Base):
    __tablename__ = "hosts"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False)
    hostname = Column(String, nullable=False)
    port = Column(Integer, default=22)
    username = Column(String, nullable=False)
    ssh_key_path = Column(String, nullable=True)  # Optional SSH key
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    servers = relationship("Server", back_populates="host")
