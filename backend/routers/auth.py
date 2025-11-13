from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta
from jose import jwt
import os
from services.supabase_client import get_supabase
from services.email_service import send_verification_email, send_password_reset_email
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

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str

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

@router.post("/forgot-password")
async def forgot_password(request: ForgotPasswordRequest, background_tasks: BackgroundTasks):
    """Send password reset email"""
    supabase = get_supabase()
    
    try:
        # Check if user exists using the admin API.
        # Note: list_users() can be slow with many users, but it's a reliable way
        # to find a user by email with the service_role key.
        all_users_response = supabase.auth.admin.list_users()
        user_list = all_users_response.users
        
        user_found = next((u for u in user_list if u.email == request.email), None)
        
        if not user_found:
            # Don't reveal if user exists or not for security
            return {
                "message": "If the email exists, a password reset link has been sent."
            }
        
        # Adapt the found user object to the dictionary format the rest of the function expects.
        user = {
            "id": user_found.id,
            "email": user_found.email,
            "username": user_found.user_metadata.get("username", "user")
        }
        
        # Generate reset token
        reset_token = secrets.token_urlsafe(32)
        
        # Store token in database (expires in 1 hour)
        supabase.table("password_resets").insert({
            "user_id": user["id"],
            "token": reset_token,
            "expires_at": (datetime.utcnow() + timedelta(hours=1)).isoformat()
        }).execute()
        
        # Send password reset email in background
        background_tasks.add_task(
            send_password_reset_email,
            user["email"],
            user["username"],
            reset_token
        )
        
        return {
            "message": "If the email exists, a password reset link has been sent."
        }
    except Exception as e:
        # Don't reveal errors for security
        return {
            "message": "If the email exists, a password reset link has been sent."
        }

@router.post("/reset-password")
async def reset_password(request: ResetPasswordRequest):
    """Reset password with token"""
    supabase = get_supabase()
    
    try:
        # Find reset token
        result = supabase.table("password_resets")\
            .select("*")\
            .eq("token", request.token)\
            .execute()
        
        if not result.data or len(result.data) == 0:
            raise HTTPException(status_code=400, detail="Invalid or expired reset token")
        
        reset = result.data[0]
        
        # Check if token is expired
        expires_at = datetime.fromisoformat(reset["expires_at"].replace('Z', '+00:00'))
        if expires_at < datetime.utcnow().replace(tzinfo=expires_at.tzinfo):
            raise HTTPException(status_code=400, detail="Reset token has expired")
        
        user_id = reset["user_id"]
        
        # Get user email for Supabase auth update
        user_result = supabase.table("users").select("email").eq("id", user_id).execute()
        if not user_result.data:
            raise HTTPException(status_code=400, detail="User not found")
        
        user_email = user_result.data[0]["email"]
        
        # Update password in Supabase Auth (using admin API)
        # Note: This requires service role key
        auth_response = supabase.auth.admin.update_user_by_id(
            user_id,
            {"password": request.new_password}
        )
        
        # Delete reset token
        supabase.table("password_resets")\
            .delete()\
            .eq("token", request.token)\
            .execute()
        
        return {
            "message": "Password reset successfully. You can now login with your new password."
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to reset password: {str(e)}")
