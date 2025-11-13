from supabase import create_client, Client
import os
from dotenv import load_dotenv

load_dotenv()

_supabase_client: Client = None

def get_supabase() -> Client:
    """Get Supabase client singleton with service role key for backend operations"""
    global _supabase_client
    if _supabase_client is None:
        url = os.getenv("SUPABASE_URL")
        # Use SERVICE_KEY for backend operations to bypass RLS
        key = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_KEY")
        _supabase_client = create_client(url, key)
    return _supabase_client
