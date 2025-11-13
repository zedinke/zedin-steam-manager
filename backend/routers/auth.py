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
    expire = datetime.utcnow() + timedelta(days=30)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, os.getenv("JWT_SECRET"), algorithm="HS256")

@router.post("/register")
async def register(request: RegisterRequest, background_tasks: BackgroundTasks):
    """Register new user with email verification (custom email only)"""
    supabase = get_supabase()
    
    try:
        # Use admin API to create user without sending Supabase's email
        # This requires SUPABASE_SERVICE_KEY instead of anon key
        from supabase import create_client
        
        service_url = os.getenv("SUPABASE_URL")
        service_key = os.getenv("SUPABASE_SERVICE_KEY", os.getenv("SUPABASE_KEY"))
        service_client = create_client(service_url, service_key)
        
        # Create user with admin client (no auto-email)
        response = service_client.auth.admin.create_user({
            "email": request.email,
            "password": request.password,
            "email_confirm": False,  # Don't send Supabase confirmation email
            "user_metadata": {
                "username": request.username,
                "email_verified": False
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
        # Find verification token
        result = supabase.table("email_verifications")\
            .select("*")\
            .eq("token", request.token)\
            .gt("expires_at", datetime.utcnow().isoformat())\
            .execute()
        
        if not result.data:
            raise HTTPException(status_code=400, detail="Invalid or expired verification token")
        
        verification = result.data[0]
        
        # Update user as verified
        supabase.auth.admin.update_user_by_id(
            verification["user_id"],
            {"email_verified": True}
        )
        
        # Delete verification token
        supabase.table("email_verifications")\
            .delete()\
            .eq("token", request.token)\
            .execute()
        
        return {"message": "Email verified successfully. You can now login."}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/login")
async def login(request: LoginRequest):
    """Login with email verification check"""
    supabase = get_supabase()
    
    try:
        # Sign in user
        response = supabase.auth.sign_in_with_password({
            "email": request.email,
            "password": request.password
        })
        
        if response.user:
            # Check if email is verified
            if not response.user.user_metadata.get("email_verified", False):
                raise HTTPException(
                    status_code=403,
                    detail="Please verify your email before logging in"
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
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid credentials")

@router.post("/logout")
async def logout():
    """Logout user"""
    return {"message": "Logged out successfully"}
