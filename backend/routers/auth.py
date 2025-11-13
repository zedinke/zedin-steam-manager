from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta
from jose import jwt
import os
from services.supabase_client import get_supabase
from services.email_service import send_verification_email
import secrets

router = APIRouter()

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    username: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class VerifyEmailRequest(BaseModel):
    token: str

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(hours=72)  # 72 hours = 3 days
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, os.getenv("JWT_SECRET"), algorithm="HS256")

@router.post("/register")
async def register(request: RegisterRequest, background_tasks: BackgroundTasks):
    """Register new user with custom email verification"""
    supabase = get_supabase()
    
    try:
        # Simple sign up - Supabase email confirmation should be DISABLED in dashboard
        response = supabase.auth.sign_up({
            "email": request.email,
            "password": request.password,
            "options": {
                "data": {
                    "username": request.username,
                    "email_verified": False
                }
            }
        })
        
        if response.user:
            # Generate our own verification token
            verification_token = secrets.token_urlsafe(32)
            
            # Store token in database
            supabase.table("email_verifications").insert({
                "user_id": response.user.id,
                "token": verification_token,
                "expires_at": (datetime.utcnow() + timedelta(hours=24)).isoformat()
            }).execute()
            
            # Send our custom verification email in background
            background_tasks.add_task(
                send_verification_email,
                request.email,
                request.username,
                verification_token
            )
            
            return {
                "message": "Registration successful. Please check your email to verify your account.",
                "email": request.email
            }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/verify-email")
async def verify_email(request: VerifyEmailRequest):
    """Verify user email with token"""
    supabase = get_supabase()
    
    try:
        # Find verification token (check if exists and not expired)
        result = supabase.table("email_verifications")\
            .select("*")\
            .eq("token", request.token)\
            .execute()
        
        if not result.data or len(result.data) == 0:
            raise HTTPException(status_code=400, detail="Invalid or expired verification token")
        
        verification = result.data[0]
        
        # Check if token is expired
        expires_at = datetime.fromisoformat(verification["expires_at"].replace('Z', '+00:00'))
        if expires_at < datetime.utcnow().replace(tzinfo=expires_at.tzinfo):
            raise HTTPException(status_code=400, detail="Verification token has expired")
        
        user_id = verification["user_id"]
        
        # Delete verification token (marks as verified)
        supabase.table("email_verifications")\
            .delete()\
            .eq("token", request.token)\
            .execute()
        
        # For now, we'll consider the user verified if the token was found and deleted
        # In production, you might want to update user metadata via admin API
        
        return {
            "message": "Email verified successfully. You can now login.",
            "user_id": user_id
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/login")
async def login(request: LoginRequest):
    """Login - check if email was verified via token"""
    supabase = get_supabase()
    
    try:
        # Sign in user
        response = supabase.auth.sign_in_with_password({
            "email": request.email,
            "password": request.password
        })
        
        if response.user:
            # Check if there's still a pending verification token
            pending = supabase.table("email_verifications")\
                .select("id")\
                .eq("user_id", response.user.id)\
                .execute()
            
            if pending.data and len(pending.data) > 0:
                raise HTTPException(
                    status_code=403,
                    detail="Please verify your email before logging in. Check your email for the verification link."
                )
            
            # Create JWT token
            token = create_access_token({
                "sub": response.user.id,
                "email": response.user.email,
                "username": response.user.user_metadata.get("username")
            })
            
            return {
                "access_token": token,
                "token_type": "bearer",
                "user": {
                    "id": response.user.id,
                    "email": response.user.email,
                    "username": response.user.user_metadata.get("username")
                }
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid credentials")

@router.post("/logout")
async def logout():
    """Logout user"""
    return {"message": "Logged out successfully"}
