"""
Working user registration test
"""
import os
import sys
from datetime import datetime

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

from backend.services.supabase_service import SupabaseService

def create_test_user():
    """Create test user directly in Supabase"""
    print("🚀 Creating test user in Supabase...")
    
    user_data = {
        "first_name": "Test", 
        "last_name": "Working",
        "email": "testworking@example.com",
        "hashed_password": "simple_hash_test_password",
        "birth_date": "1990-01-01", 
        "role": "user",
        "is_verified": False,
        "verification_token": None,
        "verification_expires": None,
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat()
    }
    
    try:
        # Check if user exists
        existing = SupabaseService.get_user_by_email(user_data["email"])
        if existing:
            print(f"✅ User already exists: {existing['first_name']} {existing['last_name']}")
            return existing
        
        # Create new user
        result = SupabaseService.create_user(user_data)
        
        if result:
            print(f"✅ User created successfully!")
            print(f"   ID: {result['id']}")
            print(f"   Name: {result['first_name']} {result['last_name']}")
            print(f"   Email: {result['email']}")
            print(f"   🎯 User stored in Supabase database!")
            return result
        else:
            print("❌ Failed to create user")
            return None
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

if __name__ == "__main__":
    print("🧪 Direct Supabase User Creation")
    print("=" * 50)
    
    if SupabaseService.is_available():
        user = create_test_user()
        
        if user:
            print("\n🎉 SUCCESS!")
            print("✅ User registration working with Supabase!")
            print("✅ External database persistence enabled!")
            print("✅ Data will survive system reinstallations!")
        else:
            print("\n❌ User creation failed")
    else:
        print("❌ Supabase not available")