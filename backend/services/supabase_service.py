"""
Supabase Service - External database operations using Supabase API
"""
import os
from typing import Optional, Dict, Any, List
from supabase import create_client, Client
from config.settings import settings
import logging

logger = logging.getLogger(__name__)

class SupabaseService:
    _client: Optional[Client] = None
    
    @classmethod
    def get_client(cls) -> Optional[Client]:
        """Get Supabase client instance"""
        if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
            logger.warning("Supabase credentials not configured, using local database")
            return None
            
        if not cls._client:
            try:
                cls._client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)
                logger.info("Supabase client initialized successfully")
            except Exception as e:
                logger.error(f"Failed to initialize Supabase client: {e}")
                return None
                
        return cls._client
    
    @classmethod
    def is_available(cls) -> bool:
        """Check if Supabase is available and configured"""
        return cls.get_client() is not None
    
    @classmethod
    async def test_connection(cls) -> Dict[str, Any]:
        """Test Supabase connection and return status"""
        try:
            client = cls.get_client()
            if not client:
                return {
                    "success": False,
                    "error": "Supabase client not available",
                    "details": "Missing credentials or initialization failed"
                }
            
            # Test with a simple query
            result = client.table("users").select("id").limit(1).execute()
            
            return {
                "success": True,
                "message": "Supabase connection successful",
                "details": f"Connected to: {settings.SUPABASE_URL}"
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "details": "Connection test failed"
            }
    
    @classmethod
    def create_user(cls, user_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create user in Supabase"""
        try:
            client = cls.get_client()
            if not client:
                return None
                
            result = client.table("users").insert(user_data).execute()
            return result.data[0] if result.data else None
            
        except Exception as e:
            logger.error(f"Failed to create user in Supabase: {e}")
            return None
    
    @classmethod
    def get_user_by_email(cls, email: str) -> Optional[Dict[str, Any]]:
        """Get user by email from Supabase"""
        try:
            client = cls.get_client()
            if not client:
                return None
                
            result = client.table("users").select("*").eq("email", email).single().execute()
            return result.data if result.data else None
            
        except Exception as e:
            logger.error(f"Failed to get user from Supabase: {e}")
            return None
    
    @classmethod
    def get_user_by_id(cls, user_id: int) -> Optional[Dict[str, Any]]:
        """Get user by ID from Supabase"""
        try:
            client = cls.get_client()
            if not client:
                return None
                
            result = client.table("users").select("*").eq("id", user_id).single().execute()
            return result.data if result.data else None
            
        except Exception as e:
            logger.error(f"Failed to get user by ID from Supabase: {e}")
            return None
    
    @classmethod
    def update_user(cls, user_id: int, update_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update user in Supabase"""
        try:
            client = cls.get_client()
            if not client:
                return None
                
            result = client.table("users").update(update_data).eq("id", user_id).execute()
            return result.data[0] if result.data else None
            
        except Exception as e:
            logger.error(f"Failed to update user in Supabase: {e}")
            return None
    
    @classmethod
    def create_user_token(cls, token_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create user token in Supabase"""
        try:
            client = cls.get_client()
            if not client:
                return None
                
            result = client.table("user_tokens").insert(token_data).execute()
            return result.data[0] if result.data else None
            
        except Exception as e:
            logger.error(f"Failed to create user token in Supabase: {e}")
            return None
    
    @classmethod
    def get_user_tokens(cls, user_id: int) -> List[Dict[str, Any]]:
        """Get user tokens from Supabase"""
        try:
            client = cls.get_client()
            if not client:
                return []
                
            result = client.table("user_tokens").select("*").eq("user_id", user_id).execute()
            return result.data if result.data else []
            
        except Exception as e:
            logger.error(f"Failed to get user tokens from Supabase: {e}")
            return []
    
    @classmethod
    def get_active_token(cls, user_id: int) -> Optional[Dict[str, Any]]:
        """Get active token for user from Supabase"""
        try:
            client = cls.get_client()
            if not client:
                return None
                
            result = client.table("user_tokens").select("*").eq("user_id", user_id).eq("status", "ACTIVE").single().execute()
            return result.data if result.data else None
            
        except Exception as e:
            logger.error(f"Failed to get active token from Supabase: {e}")
            return None
    
    @classmethod
    def update_token(cls, token_id: int, update_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update token in Supabase"""
        try:
            client = cls.get_client()
            if not client:
                return None
                
            result = client.table("user_tokens").update(update_data).eq("id", token_id).execute()
            return result.data[0] if result.data else None
            
        except Exception as e:
            logger.error(f"Failed to update token in Supabase: {e}")
            return None
    
    @classmethod
    def log_token_usage(cls, usage_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Log token usage in Supabase"""
        try:
            client = cls.get_client()
            if not client:
                return None
                
            result = client.table("token_usage_logs").insert(usage_data).execute()
            return result.data[0] if result.data else None
            
        except Exception as e:
            logger.error(f"Failed to log token usage in Supabase: {e}")
            return None