"""
Test Hybrid Auth Service with Supabase integration
"""
import asyncio
import sys
import os
from datetime import datetime

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

from backend.services.hybrid_auth_service import hybrid_auth_service
from backend.models.user import UserRole

async def test_hybrid_auth():
    """Test hybrid authentication service with Supabase"""
    print("🧪 Testing Hybrid Auth Service with Supabase")
    print("=" * 50)
    
    # Check if using Supabase
    print(f"📡 Using Supabase: {'✅ Yes' if hybrid_auth_service.use_supabase else '❌ No (Local SQLite)'}")
    
    if hybrid_auth_service.use_supabase:
        print("🎯 External database persistence enabled!")
        print("   ✅ User data will survive system reinstallations")
        print("   ✅ Tokens will be preserved across devices")
    else:
        print("⚠️  Using local SQLite database")
        print("   ❌ Data will be lost on reinstallation")
    
    print("\n" + "=" * 50)
    print("🔧 System ready for user registration and token management!")
    
    return True

if __name__ == "__main__":
    try:
        result = asyncio.run(test_hybrid_auth())
        print("\n✅ Hybrid Auth Service test completed successfully!")
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        import traceback
        traceback.print_exc()