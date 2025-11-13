"""
Hybrid Auth Service - Works with both local SQLite and external Supabase
"""
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from sqlalchemy.orm import Session
from models.user import User, UserRole
from models.token import UserToken
from services.email_service import email_service
from services.token_service import token_service
from services.supabase_service import SupabaseService
from config.settings import settings
from passlib.context import CryptContext
from jose import JWTError, jwt
from fastapi import HTTPException
import secrets
import string
import logging

logger = logging.getLogger(__name__)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class HybridAuthService:
    """Hybrid authentication service that uses Supabase when available, falls back to local SQLite"""
    
    def __init__(self):
        self.use_supabase = SupabaseService.is_available()
        logger.info(f"HybridAuthService initialized - Using {'Supabase' if self.use_supabase else 'Local SQLite'}")
    
    def create_user(
        self,
        db: Session,
        first_name: str,
        last_name: str,
        email: str,
        password: str,
        birth_date: datetime,
        role: UserRole = UserRole.USER
    ) -> User:
        """Create a new user account"""
        try:
            # Check if user already exists
            if self.get_user_by_email(db, email):
                raise HTTPException(status_code=400, detail="Email already registered")
            
            # Generate verification token
            verification_token = self.generate_verification_code()
            verification_expires = datetime.utcnow() + timedelta(hours=24)
            
            if self.use_supabase:
                # Create user in Supabase
                user_data = {
                    "first_name": first_name,
                    "last_name": last_name,
                    "email": email,
                    "hashed_password": pwd_context.hash(password),
                    "birth_date": birth_date.isoformat(),
                    "role": role.value,
                    "verification_token": verification_token,
                    "verification_expires": verification_expires.isoformat(),
                    "is_verified": False,
                    "created_at": datetime.utcnow().isoformat(),
                    "updated_at": datetime.utcnow().isoformat()
                }
                
                supabase_user = SupabaseService.create_user(user_data)
                if not supabase_user:
                    raise HTTPException(status_code=500, detail="Failed to create user in external database")
                
                # Convert to local User object for return
                user = User(
                    id=supabase_user["id"],
                    first_name=supabase_user["first_name"],
                    last_name=supabase_user["last_name"],
                    email=supabase_user["email"],
                    hashed_password=supabase_user["hashed_password"],
                    birth_date=datetime.fromisoformat(supabase_user["birth_date"]),
                    role=UserRole(supabase_user["role"]),
                    verification_token=supabase_user["verification_token"],
                    verification_expires=datetime.fromisoformat(supabase_user["verification_expires"]),
                    is_verified=supabase_user["is_verified"],
                    created_at=datetime.fromisoformat(supabase_user["created_at"]),
                    updated_at=datetime.fromisoformat(supabase_user["updated_at"])
                )
            else:
                # Create user locally
                user = User(
                    first_name=first_name,
                    last_name=last_name,
                    email=email,
                    hashed_password=pwd_context.hash(password),
                    birth_date=birth_date,
                    role=role,
                    verification_token=verification_token,
                    verification_expires=verification_expires,
                    is_verified=False
                )
                db.add(user)
                db.commit()
                db.refresh(user)
            
            # Send verification email
            try:
                email_service.send_verification_email(email, verification_token)
                logger.info(f"Verification email sent to {email}")
            except Exception as e:
                logger.error(f"Failed to send verification email: {e}")
                # Don't fail user creation if email fails
            
            return user
            
        except Exception as e:
            logger.error(f"Failed to create user: {e}")
            if not self.use_supabase:
                db.rollback()
            raise e
    
    def get_user_by_email(self, db: Session, email: str) -> Optional[User]:
        """Get user by email"""
        if self.use_supabase:
            supabase_user = SupabaseService.get_user_by_email(email)
            if supabase_user:
                return self._convert_supabase_to_user(supabase_user)
            return None
        else:
            return db.query(User).filter(User.email == email).first()
    
    def get_user_by_id(self, db: Session, user_id: int) -> Optional[User]:
        """Get user by ID"""
        if self.use_supabase:
            supabase_user = SupabaseService.get_user_by_id(user_id)
            if supabase_user:
                return self._convert_supabase_to_user(supabase_user)
            return None
        else:
            return db.query(User).filter(User.id == user_id).first()
    
    def verify_user(self, db: Session, verification_token: str) -> bool:
        """Verify user account"""
        if self.use_supabase:
            # Find user by verification token
            # Note: This would require a query by verification_token in Supabase
            # For now, we'll handle this differently
            return False  # TODO: Implement Supabase verification
        else:
            user = db.query(User).filter(
                User.verification_token == verification_token,
                User.verification_expires > datetime.utcnow(),
                User.is_verified == False
            ).first()
            
            if user:
                user.is_verified = True
                user.verification_token = None
                user.verification_expires = None
                user.updated_at = datetime.utcnow()
                
                db.commit()
                db.refresh(user)
                
                # Create trial token for verified user
                try:
                    token_service.create_trial_token(db, user.id)
                    logger.info(f"Trial token created for verified user {user.email}")
                except Exception as e:
                    logger.error(f"Failed to create trial token: {e}")
                
                return True
            return False
    
    def authenticate_user(self, db: Session, email: str, password: str) -> Optional[User]:
        """Authenticate user login"""
        user = self.get_user_by_email(db, email)
        if not user:
            return None
        
        if not pwd_context.verify(password, user.hashed_password):
            return None
        
        return user
    
    def _convert_supabase_to_user(self, supabase_data: Dict[str, Any]) -> User:
        """Convert Supabase data to User object"""
        return User(
            id=supabase_data["id"],
            first_name=supabase_data["first_name"],
            last_name=supabase_data["last_name"],
            email=supabase_data["email"],
            hashed_password=supabase_data["hashed_password"],
            birth_date=datetime.fromisoformat(supabase_data["birth_date"]),
            role=UserRole(supabase_data["role"]),
            verification_token=supabase_data.get("verification_token"),
            verification_expires=datetime.fromisoformat(supabase_data["verification_expires"]) if supabase_data.get("verification_expires") else None,
            is_verified=supabase_data["is_verified"],
            created_at=datetime.fromisoformat(supabase_data["created_at"]),
            updated_at=datetime.fromisoformat(supabase_data["updated_at"])
        )
    
    @staticmethod
    def generate_verification_code() -> str:
        """Generate random verification code"""
        alphabet = string.ascii_letters + string.digits
        return ''.join(secrets.choice(alphabet) for _ in range(32))
    
    @staticmethod
    def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
        """Create JWT access token"""
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        return encoded_jwt
    
    @staticmethod
    def verify_token(token: str) -> Optional[dict]:
        """Verify and decode JWT token"""
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
            return payload
        except JWTError:
            return None

# Global instance
hybrid_auth_service = HybridAuthService()