from datetime import datetime, timedelta
from typing import Optional
from sqlalchemy.orm import Session
from models.user import User, UserRole
from models.token import UserToken
from services.email_service import email_service
from services.token_service import token_service
from services.supabase_service import SupabaseService
from config.settings import settings
from passlib.context import CryptContext
from jose import JWTError, jwt
import secrets
import string
import logging

logger = logging.getLogger(__name__)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class AuthService:
    def __init__(self):
        pass
    
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
            
            # Create user
            user = User(
                first_name=first_name,
                last_name=last_name,
                email=email,
                hashed_password=pwd_context.hash(password),
                birth_date=birth_date,
                role=role,
                verification_token=verification_token,
                verification_expires=verification_expires,
                is_active=False,
                is_verified=False
            )
            
            db.add(user)
            db.commit()
            db.refresh(user)
            
            # Send verification email
            email_service.send_verification_email(user, verification_token)
            
            logger.info(f"Created user account: {email}")
            return user
            
        except Exception as e:
            db.rollback()
            logger.error(f"Failed to create user: {e}")
            raise
    
    def verify_user_email(self, db: Session, email: str, verification_code: str) -> User:
        """Verify user's email address and activate account"""
        try:
            user = db.query(User).filter(
                User.email == email,
                User.verification_token == verification_code
            ).first()
            
            if not user:
                raise HTTPException(status_code=400, detail="Invalid verification code")
            
            if user.verification_expires < datetime.utcnow():
                raise HTTPException(status_code=400, detail="Verification code expired")
            
            # Activate user
            user.is_verified = True
            user.is_active = True
            user.verification_token = None
            user.verification_expires = None
            
            db.commit()
            db.refresh(user)
            
            # Create trial token for new verified user
            trial_token = token_service.create_trial_token(db, user)
            
            # Send welcome email
            email_service.send_welcome_email(user)
            
            logger.info(f"User verified and trial token created: {email}")
            return user
            
        except Exception as e:
            db.rollback()
            logger.error(f"Failed to verify user: {e}")
            raise
    
    def authenticate_user(self, db: Session, email: str, password: str) -> Optional[User]:
        """Authenticate user credentials"""
        user = self.get_user_by_email(db, email)
        if not user:
            return None
        
        if not pwd_context.verify(password, user.hashed_password):
            return None
        
        if not user.is_active or not user.is_verified:
            raise HTTPException(status_code=400, detail="Account not activated")
        
        # Update last login
        user.last_login = datetime.utcnow()
        db.commit()
        
        return user
    
    def get_user_by_email(self, db: Session, email: str) -> Optional[User]:
        """Get user by email address"""
        return db.query(User).filter(User.email == email).first()
    
    def get_user_by_id(self, db: Session, user_id: int) -> Optional[User]:
        """Get user by ID"""
        return db.query(User).filter(User.id == user_id).first()
    
    def create_access_token(self, user: User) -> str:
        """Create JWT access token for user"""
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode = {
            "user_id": user.id,
            "email": user.email,
            "role": user.role.value,
            "exp": expire
        }
        encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        return encoded_jwt
    
    def verify_token(self, token: str) -> Optional[dict]:
        """Verify JWT token"""
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
            return payload
        except JWTError:
            return None
    
    def generate_verification_code(self) -> str:
        """Generate 6-digit verification code"""
        return ''.join(secrets.choice(string.digits) for _ in range(6))
    
    def check_user_license(self, db: Session, user: User) -> dict:
        """Check user's license status"""
        token_stats = token_service.get_token_stats(db, user.id)
        
        return {
            "has_valid_license": user.has_valid_license,
            "active_token": user.active_token.token_key if user.active_token else None,
            "token_type": user.active_token.token_type.value if user.active_token else None,
            "expires_at": user.active_token.expires_at if user.active_token else None,
            "days_remaining": user.active_token.days_remaining if user.active_token else 0,
            "max_servers": user.active_token.max_servers if user.active_token else 0,
            "stats": token_stats
        }

# Create global instance
auth_service = AuthService()

def get_current_user():
    """Get current user - simplified for demo"""
    from models.user import User
    # This is a simplified version - in real implementation would validate JWT token
    user = User()
    user.id = 1
    user.email = "admin@zedin.com"
    user.first_name = "Admin"
    user.last_name = "User"
    user.role = "admin"
    user.is_verified = True
    return user