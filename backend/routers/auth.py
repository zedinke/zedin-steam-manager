from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional
import jwt
from passlib.context import CryptContext

from config.database import get_db
from config.settings import settings
from models.user import User, UserRole
from schemas.auth import (
    UserRegistration, UserLogin, UserResponse, EmailVerificationRequest,
    PasswordChange, PasswordResetRequest, PasswordReset
)
from services.email_service import email_service

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

# Security setup
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class AuthService:
    @staticmethod
    def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode.update({"exp": expire})
        return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    
    @staticmethod
    def verify_token(token: str):
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
            email: str = payload.get("sub")
            if email is None:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid authentication credentials",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            return email
        except jwt.PyJWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )

auth_service = AuthService()

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    email = auth_service.verify_token(token)
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user

async def get_current_active_user(current_user: User = Depends(get_current_user)):
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user - email verification required"
        )
    return current_user

def require_role(required_role: UserRole):
    def role_checker(current_user: User = Depends(get_current_active_user)):
        if not current_user.has_permission(required_role):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions"
            )
        return current_user
    return role_checker

@router.post("/register", response_model=dict)
async def register_user(
    user_data: UserRegistration,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Register a new user"""
    
    # Check if user already exists
    if db.query(User).filter(User.email == user_data.email).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ez az email cím már regisztrálva van"
        )
    
    # Create new user
    hashed_password = User.hash_password(user_data.password)
    new_user = User(
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        email=user_data.email,
        hashed_password=hashed_password,
        birth_date=datetime.combine(user_data.birth_date, datetime.min.time()),
        role=UserRole.USER,
        is_active=False,  # Requires email verification
        is_verified=False
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Send verification email
    if settings.EMAIL_ENABLED:
        background_tasks.add_task(email_service.send_verification_email, db, new_user)
        message = "Regisztráció sikeres! Kérlek ellenőrizd az email fiókod és erősítsd meg a regisztrációt."
    else:
        # For development - auto-activate user
        new_user.is_active = True
        new_user.is_verified = True
        db.commit()
        message = "Regisztráció sikeres! (Email verification disabled in development)"
    
    return {
        "message": message,
        "user_id": new_user.id,
        "email": new_user.email,
        "requires_verification": not new_user.is_active
    }

@router.post("/login")
async def login(login_data: UserLogin, db: Session = Depends(get_db)):
    """Login user and return access token"""
    
    user = db.query(User).filter(User.email == login_data.email).first()
    
    if not user or not user.verify_password(login_data.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Helytelen email cím vagy jelszó",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A fiók nincs aktiválva. Kérlek ellenőrizd az emailt és erősítsd meg a regisztrációt."
        )
    
    # Update last login
    user.last_login = datetime.utcnow()
    db.commit()
    
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth_service.create_access_token(
        data={"sub": user.email, "role": user.role.value},
        expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "user": UserResponse.model_validate(user)
    }

@router.post("/verify-email")
async def verify_email(
    verification_data: EmailVerificationRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Verify email with token or code"""
    
    # Handle both token and code verification
    token_parts = verification_data.token.split(":")
    if len(token_parts) == 2:
        # Token with code format
        token, code = token_parts
        user = db.query(User).filter(User.verification_token.like(f"{token}:%")).first()
    else:
        # Direct token or code
        user = db.query(User).filter(
            (User.verification_token == verification_data.token) |
            (User.verification_token.like(f"%:{verification_data.token}"))
        ).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Érvénytelen megerősítő kód vagy token"
        )
    
    # Check if token expired
    if user.verification_expires and user.verification_expires < datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A megerősítő kód lejárt. Kérj új megerősítést."
        )
    
    # Activate user
    user.is_active = True
    user.is_verified = True
    user.verification_token = None
    user.verification_expires = None
    db.commit()
    
    # Send welcome email
    if settings.EMAIL_ENABLED:
        background_tasks.add_task(email_service.send_welcome_email, user)
    
    return {"message": "Email sikeresen megerősítve! Most már bejelentkezhetsz."}

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_active_user)):
    """Get current user information"""
    return UserResponse.model_validate(current_user)

@router.post("/change-password")
async def change_password(
    password_data: PasswordChange,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Change user password"""
    
    if not current_user.verify_password(password_data.current_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A jelenlegi jelszó nem helyes"
        )
    
    current_user.hashed_password = User.hash_password(password_data.new_password)
    db.commit()
    
    return {"message": "Jelszó sikeresen megváltoztatva"}

@router.post("/logout")
async def logout():
    """Logout user (frontend should remove token)"""
    return {"message": "Sikeresen kijelentkeztél"}

# Admin endpoints
@router.get("/users", response_model=list[UserResponse])
async def list_users(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """List all users (Admin only)"""
    users = db.query(User).offset(skip).limit(limit).all()
    return [UserResponse.model_validate(user) for user in users]

@router.patch("/users/{user_id}/role")
async def update_user_role(
    user_id: int,
    new_role: UserRole,
    current_user: User = Depends(require_role(UserRole.MANAGER_ADMIN)),
    db: Session = Depends(get_db)
):
    """Update user role (Manager Admin only)"""
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Felhasználó nem található"
        )
    
    # Prevent changing manager admin role
    if user.role == UserRole.MANAGER_ADMIN and current_user.id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Manager Admin szerepkör nem módosítható"
        )
    
    user.role = new_role
    db.commit()
    
    return {"message": f"Felhasználó szerepköre frissítve: {new_role.value}"}

@router.delete("/users/{user_id}")
async def delete_user(
    user_id: int,
    current_user: User = Depends(require_role(UserRole.ADMIN)),
    db: Session = Depends(get_db)
):
    """Delete user (Admin only)"""
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Felhasználó nem található"
        )
    
    # Prevent deleting manager admin
    if user.role == UserRole.MANAGER_ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Manager Admin nem törölhető"
        )
    
    # Prevent self-deletion
    if user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nem törölheted saját magad"
        )
    
    db.delete(user)
    db.commit()
    
    return {"message": "Felhasználó törölve"}