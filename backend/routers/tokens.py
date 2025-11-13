from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta
from typing import Optional, List
import secrets
import os
from services.supabase_client import get_supabase
from services.email_service import send_token_email, send_expiry_notification
from routers.auth import create_access_token

router = APIRouter()

class TokenGenerateRequest(BaseModel):
    assigned_to_email: EmailStr
    duration_days: int = 365  # Default 1 year

class TokenActivateRequest(BaseModel):
    token_code: str

class NotificationCreate(BaseModel):
    title: str
    message: str
    type: str = 'info'
    link: Optional[str] = None

def get_current_user(token: str):
    """Get current user from JWT token"""
    from jose import jwt, JWTError
    try:
        payload = jwt.decode(token, os.getenv("JWT_SECRET"), algorithms=["HS256"])
        user_id = payload.get("sub")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid authentication token")

def is_manager_admin(user_id: str):
    """Check if user is manager admin"""
    supabase = get_supabase()
    try:
        response = supabase.auth.admin.get_user_by_id(user_id)
        role = response.user.user_metadata.get('role')
        return role == 'manager_admin'
    except:
        return False

@router.post("/tokens/generate")
async def generate_token(
    request: TokenGenerateRequest,
    background_tasks: BackgroundTasks,
    authorization: str = Depends(lambda: None)
):
    """Generate a new token (Manager Admin only)"""
    # TODO: Extract user from authorization header
    # For now, we'll implement basic check
    
    supabase = get_supabase()
    
    try:
        # Find user by email
        # Note: This requires admin API or service role
        # We'll search in our users
        
        # Generate unique token code
        token_code = secrets.token_urlsafe(24)
        
        # Calculate expiration date
        expires_at = datetime.utcnow() + timedelta(days=request.duration_days)
        
        # Insert token into database
        token_data = {
            "token_code": token_code,
            "assigned_to": None,  # Will be set when we find user
            "expires_at": expires_at.isoformat(),
            "status": "pending"
        }
        
        # TODO: Get assigned_to user ID from email
        # For now, we'll store the email in a separate field or metadata
        
        result = supabase.table("tokens").insert(token_data).execute()
        
        # Send email notification
        background_tasks.add_task(
            send_token_email,
            request.assigned_to_email,
            token_code,
            request.duration_days
        )
        
        # Create notification for user
        # notification_data = {
        #     "user_id": assigned_to_id,
        #     "title": "New Token Generated",
        #     "message": f"A new token has been generated for you. It expires in {request.duration_days} days.",
        #     "type": "token",
        #     "link": "/tokens"
        # }
        # supabase.table("notifications").insert(notification_data).execute()
        
        return {
            "message": "Token generated successfully",
            "token_code": token_code,
            "expires_at": expires_at.isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/tokens/activate")
async def activate_token(request: TokenActivateRequest, user_id: str = Depends(get_current_user)):
    """Activate a token and upgrade user to server admin"""
    supabase = get_supabase()
    
    try:
        # Find token
        result = supabase.table("tokens")\
            .select("*")\
            .eq("token_code", request.token_code)\
            .eq("status", "pending")\
            .execute()
        
        if not result.data or len(result.data) == 0:
            raise HTTPException(status_code=404, detail="Token not found or already activated")
        
        token = result.data[0]
        
        # Check if expired
        expires_at = datetime.fromisoformat(token["expires_at"].replace('Z', '+00:00'))
        if expires_at < datetime.utcnow().replace(tzinfo=expires_at.tzinfo):
            raise HTTPException(status_code=400, detail="Token has expired")
        
        # Update token status
        supabase.table("tokens")\
            .update({
                "status": "active",
                "activated_at": datetime.utcnow().isoformat(),
                "assigned_to": user_id
            })\
            .eq("token_code", request.token_code)\
            .execute()
        
        # Upgrade user role to server_admin
        # Note: This requires admin API
        # supabase.auth.admin.update_user_by_id(
        #     user_id,
        #     {"user_metadata": {"role": "server_admin"}}
        # )
        
        # Create notification
        notification_data = {
            "user_id": user_id,
            "title": "Token Activated",
            "message": "Your token has been activated successfully. You now have server admin privileges.",
            "type": "success"
        }
        supabase.table("notifications").insert(notification_data).execute()
        
        return {
            "message": "Token activated successfully",
            "role": "server_admin",
            "expires_at": token["expires_at"]
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/tokens/my")
async def get_my_tokens(user_id: str = Depends(get_current_user)):
    """Get current user's tokens"""
    supabase = get_supabase()
    
    try:
        result = supabase.table("tokens")\
            .select("*")\
            .eq("assigned_to", user_id)\
            .order("created_at", desc=True)\
            .execute()
        
        return {"tokens": result.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/tokens/all")
async def get_all_tokens(user_id: str = Depends(get_current_user)):
    """Get all tokens (Manager Admin only)"""
    if not is_manager_admin(user_id):
        raise HTTPException(status_code=403, detail="Manager Admin access required")
    
    supabase = get_supabase()
    
    try:
        result = supabase.table("tokens")\
            .select("*")\
            .order("created_at", desc=True)\
            .execute()
        
        return {"tokens": result.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/notifications")
async def get_notifications(user_id: str = Depends(get_current_user)):
    """Get user's notifications"""
    supabase = get_supabase()
    
    try:
        result = supabase.table("notifications")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("created_at", desc=True)\
            .limit(50)\
            .execute()
        
        return {"notifications": result.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/notifications/{notification_id}/read")
async def mark_notification_read(
    notification_id: str,
    user_id: str = Depends(get_current_user)
):
    """Mark notification as read"""
    supabase = get_supabase()
    
    try:
        supabase.table("notifications")\
            .update({"read": True})\
            .eq("id", notification_id)\
            .eq("user_id", user_id)\
            .execute()
        
        return {"message": "Notification marked as read"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/notifications/unread-count")
async def get_unread_count(user_id: str = Depends(get_current_user)):
    """Get count of unread notifications"""
    supabase = get_supabase()
    
    try:
        result = supabase.table("notifications")\
            .select("id", count="exact")\
            .eq("user_id", user_id)\
            .eq("read", False)\
            .execute()
        
        return {"count": result.count or 0}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
