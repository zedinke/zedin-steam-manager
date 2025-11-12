from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer
from sqlalchemy.orm import Session

from config.database import get_db

router = APIRouter()
security = HTTPBearer()

@router.post("/login")
async def login():
    """Login endpoint - simplified for now"""
    return {
        "access_token": "demo-token",
        "token_type": "bearer"
    }

@router.get("/me")
async def get_current_user():
    """Get current user info"""
    return {
        "id": 1,
        "username": "admin",
        "email": "admin@zedin.com",
        "is_admin": True
    }