from sqlalchemy import Column, Integer, String, DateTime, Boolean, Enum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from passlib.context import CryptContext

Base = declarative_base()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserRole(str, enum.Enum):
    MANAGER_ADMIN = "manager_admin"  # Only you
    SERVER_ADMIN = "server_admin"    # Server administrators
    ADMIN = "admin"                  # General administrators
    USER = "user"                    # Regular users

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    birth_date = Column(DateTime, nullable=False)
    role = Column(Enum(UserRole), default=UserRole.USER, nullable=False)
    is_active = Column(Boolean, default=False)  # Email verification required
    is_verified = Column(Boolean, default=False)
    verification_token = Column(String(255), nullable=True)
    verification_expires = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)
    
    # Relationships
    tokens = relationship("UserToken", back_populates="user")
    
    @property
    def active_token(self):
        """Get the user's active token"""
        for token in self.tokens:
            if token.is_valid:
                return token
        return None
    
    @property
    def has_valid_license(self):
        """Check if user has a valid license"""
        return self.active_token is not None
    
    def verify_password(self, password: str) -> bool:
        return pwd_context.verify(password, self.hashed_password)
    
    @staticmethod
    def hash_password(password: str) -> str:
        return pwd_context.hash(password)
    
    def get_full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"
    
    def has_permission(self, required_role: UserRole) -> bool:
        role_hierarchy = {
            UserRole.USER: 0,
            UserRole.ADMIN: 1,
            UserRole.SERVER_ADMIN: 2,
            UserRole.MANAGER_ADMIN: 3
        }
        return role_hierarchy.get(self.role, 0) >= role_hierarchy.get(required_role, 0)