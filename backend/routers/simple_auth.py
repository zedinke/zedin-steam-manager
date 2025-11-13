"""
Simple Supabase registration endpoint
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from datetime import datetime, date
import hashlib
import secrets

from services.supabase_service import SupabaseService

router = APIRouter()

def simple_hash_password(password: str) -> str:
    """Simple password hashing without bcrypt"""
    salt = secrets.token_hex(16)
    return hashlib.sha256((password + salt).encode()).hexdigest() + ":" + salt

class SimpleUserRegistration(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    password: str
    birth_date: date

@router.post("/simple-register")
async def simple_register(user_data: SimpleUserRegistration):
    """Simple user registration directly to Supabase"""
    try:
        # Check if Supabase is available
        if not SupabaseService.is_available():
            raise HTTPException(status_code=500, detail="External database not available")
        
        # Check if user already exists
        existing_user = SupabaseService.get_user_by_email(user_data.email)
        if existing_user:
            raise HTTPException(status_code=400, detail="Email already registered")
        
        # Create user data
        user_dict = {
            "first_name": user_data.first_name,
            "last_name": user_data.last_name,
            "email": user_data.email,
            "hashed_password": simple_hash_password(user_data.password),
            "birth_date": user_data.birth_date.isoformat(),
            "role": "user",
            "is_verified": False,
            "verification_token": None,
            "verification_expires": None,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        }
        
        # Create user in Supabase
        created_user = SupabaseService.create_user(user_dict)
        
        if not created_user:
            raise HTTPException(status_code=500, detail="Failed to create user in database")
        
        return {
            "success": True,
            "user_id": created_user["id"],
            "email": created_user["email"],
            "message": "User registered successfully in Supabase database"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        # Log the actual error for debugging
        import logging
        logging.error(f"Registration error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")