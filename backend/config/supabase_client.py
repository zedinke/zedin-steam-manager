"""Supabase client configuration and initialization."""
from supabase import create_client, Client
from .settings import settings

# Initialize Supabase client
supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

def get_supabase() -> Client:
    """Get Supabase client instance."""
    return supabase
