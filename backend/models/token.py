from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, ForeignKey, Enum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime, timedelta
import enum
import uuid

Base = declarative_base()

class TokenType(str, enum.Enum):
    TRIAL = "trial"           # 30 napos próbaverzió
    PERSONAL = "personal"     # Személyes licenc
    BUSINESS = "business"     # Üzleti licenc
    ENTERPRISE = "enterprise" # Vállalati licenc

class TokenStatus(str, enum.Enum):
    ACTIVE = "active"
    EXPIRED = "expired"
    REVOKED = "revoked"
    PENDING = "pending"

class UserToken(Base):
    __tablename__ = "user_tokens"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    token_key = Column(String(255), unique=True, index=True, nullable=False)
    token_type = Column(Enum(TokenType), default=TokenType.TRIAL, nullable=False)
    status = Column(Enum(TokenStatus), default=TokenStatus.ACTIVE, nullable=False)
    
    # Token details
    issued_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=False)
    last_used = Column(DateTime, nullable=True)
    
    # Usage tracking
    max_servers = Column(Integer, default=5)       # Hány szerver kezelhető
    current_servers = Column(Integer, default=0)   # Jelenleg használt szerverek
    
    # Hardware fingerprint (optional)
    hardware_id = Column(String(255), nullable=True)
    
    # Payment/purchase info
    purchase_reference = Column(String(255), nullable=True)
    purchase_amount = Column(Integer, default=0)  # Amount in cents
    
    # Metadata
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship
    user = relationship("User", back_populates="tokens")
    
    @property
    def is_valid(self):
        """Check if token is currently valid"""
        return (
            self.status == TokenStatus.ACTIVE and 
            self.expires_at > datetime.utcnow()
        )
    
    @property
    def days_remaining(self):
        """Get days remaining until expiration"""
        if self.expires_at > datetime.utcnow():
            return (self.expires_at - datetime.utcnow()).days
        return 0
    
    @classmethod
    def generate_token_key(cls):
        """Generate a unique token key"""
        return f"ZSM-{uuid.uuid4().hex[:16].upper()}"
    
    @classmethod
    def create_trial_token(cls, user_id: int):
        """Create a 30-day trial token"""
        return cls(
            user_id=user_id,
            token_key=cls.generate_token_key(),
            token_type=TokenType.TRIAL,
            expires_at=datetime.utcnow() + timedelta(days=30),
            max_servers=3  # Trial limit
        )

class TokenUsageLog(Base):
    __tablename__ = "token_usage_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    token_id = Column(Integer, ForeignKey("user_tokens.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Usage details
    action = Column(String(100), nullable=False)  # "login", "server_start", etc.
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(String(500), nullable=True)
    
    # Server info (if applicable)
    server_name = Column(String(200), nullable=True)
    server_type = Column(String(50), nullable=True)  # "ASE", "ASA"
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    token = relationship("UserToken")
    user = relationship("User")