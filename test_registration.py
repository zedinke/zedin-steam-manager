"""
Test user registration directly with Supabase
"""
import asyncio
import sys
import os
from datetime import datetime, date

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

from backend.services.hybrid_auth_service import hybrid_auth_service
from backend.models.user import UserRole
from backend.config.database import get_db

async def test_user_registration():
    """Test user registration with Supabase"""
    print("🧪 Testing User Registration with Supabase")
    print("=" * 50)
    
    # Test user data
    test_user = {
        "first_name": "Geleta",
        "last_name": "Ákos",
        "email": "geleako@gmail.com",
        "password": "test123",
        "birth_date": date(1991, 5, 24)
    }
    
    print(f"📋 Registering user: {test_user['first_name']} {test_user['last_name']}")
    print(f"   Email: {test_user['email']}")
    print(f"   Using: {'Supabase' if hybrid_auth_service.use_supabase else 'Local SQLite'}")
    
    try:
        # Get database session
        db = next(get_db())
        
        # Register user
        user = hybrid_auth_service.create_user(
            db=db,
            first_name=test_user["first_name"],
            last_name=test_user["last_name"],
            email=test_user["email"],
            password=test_user["password"],
            birth_date=datetime.combine(test_user["birth_date"], datetime.min.time())
        )
        
        print(f"✅ User registration successful!")
        print(f"   User ID: {user.id}")
        print(f"   Email: {user.email}")
        print(f"   Role: {user.role}")
        print(f"   Verified: {user.is_verified}")
        print(f"   Created: {user.created_at}")
        
        if hybrid_auth_service.use_supabase:
            print("🎯 User data saved to Supabase database!")
            print("   ✅ Data will persist across reinstallations")
        else:
            print("⚠️  User data saved to local SQLite")
            print("   ❌ Data will be lost on reinstallation")
        
        return True
        
    except Exception as e:
        print(f"❌ Registration failed: {e}")
        import traceback
        traceback.print_exc()
        return False

async def test_user_lookup():
    """Test user lookup"""
    print(f"\n🔍 Testing User Lookup")
    print("=" * 50)
    
    try:
        db = next(get_db())
        user = hybrid_auth_service.get_user_by_email(db, "geleako@gmail.com")
        
        if user:
            print(f"✅ User found!")
            print(f"   Name: {user.first_name} {user.last_name}")
            print(f"   Email: {user.email}")
            print(f"   Role: {user.role}")
        else:
            print("❌ User not found")
        
    except Exception as e:
        print(f"❌ Lookup failed: {e}")

if __name__ == "__main__":
    try:
        print("🚀 Zedin Steam Manager - User Registration Test")
        print("=" * 50)
        
        # Test registration
        success = asyncio.run(test_user_registration())
        
        if success:
            # Test lookup
            asyncio.run(test_user_lookup())
            
        print("\n" + "=" * 50)
        print("✅ Registration test completed!")
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        import traceback
        traceback.print_exc()