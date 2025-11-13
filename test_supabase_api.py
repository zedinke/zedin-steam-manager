"""
Supabase API Connection Test
Test Supabase API connectivity and basic operations
"""
import os
import asyncio
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add backend to path
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

from backend.services.supabase_service import SupabaseService

async def test_supabase_connection():
    """Test Supabase API connection and basic operations"""
    print("🔍 Supabase API Connection Test")
    print("=" * 50)
    
    # Check environment variables
    supabase_url = os.getenv("SUPABASE_URL")
    service_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    anon_key = os.getenv("SUPABASE_ANON_KEY")
    
    print(f"📋 Configuration Check:")
    print(f"   SUPABASE_URL: {'✓ Set' if supabase_url else '✗ Missing'}")
    print(f"   SERVICE_ROLE_KEY: {'✓ Set' if service_key else '✗ Missing'}")
    print(f"   ANON_KEY: {'✓ Set' if anon_key else '✗ Missing'}")
    
    if supabase_url:
        print(f"   URL: {supabase_url}")
    
    print("\n" + "=" * 50)
    
    # Test connection
    print("🔗 Testing Supabase Connection...")
    result = await SupabaseService.test_connection()
    
    if result["success"]:
        print(f"✅ {result['message']}")
        print(f"   Details: {result['details']}")
    else:
        print(f"❌ Connection Failed: {result['error']}")
        print(f"   Details: {result['details']}")
        return False
    
    # Test availability
    print(f"\n📡 Supabase Available: {'✅ Yes' if SupabaseService.is_available() else '❌ No'}")
    
    return True

def setup_instructions():
    """Show setup instructions for Supabase"""
    print("\n📋 Supabase Setup Instructions:")
    print("=" * 50)
    print("1. Go to https://supabase.com/dashboard/projects")
    print("2. Select your project (or create a new one)")
    print("3. Go to Settings → API")
    print("4. Copy the following values:")
    print("   - Project URL")
    print("   - anon/public key")
    print("   - service_role/secret key")
    print("\n5. Create .env file in project root with:")
    print("   SUPABASE_URL=your_project_url")
    print("   SUPABASE_ANON_KEY=your_anon_key")
    print("   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key")
    print("\n6. Create tables in Supabase SQL Editor:")
    print("""
-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user',
    is_verified BOOLEAN DEFAULT FALSE,
    verification_token VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User tokens table
CREATE TABLE user_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    usage_count INTEGER DEFAULT 0,
    usage_limit INTEGER DEFAULT 1000,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Token usage logs table
CREATE TABLE token_usage_logs (
    id SERIAL PRIMARY KEY,
    token_id INTEGER REFERENCES user_tokens(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    timestamp TIMESTAMP DEFAULT NOW(),
    metadata JSONB
);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE token_usage_logs ENABLE ROW LEVEL SECURITY;
""")

if __name__ == "__main__":
    import asyncio
    
    print("🚀 Zedin Steam Manager - Supabase API Test")
    print("=" * 50)
    
    # Check if environment file exists
    if not os.path.exists('.env'):
        print("❌ .env file not found!")
        setup_instructions()
        exit(1)
    
    # Run connection test
    try:
        success = asyncio.run(test_supabase_connection())
        if not success:
            print("\n💡 If connection failed, check your Supabase credentials!")
            setup_instructions()
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        setup_instructions()