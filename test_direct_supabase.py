"""
Direct Supabase user creation test
"""
import os
import sys
from datetime import datetime

# Add backend to path  
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

from backend.services.supabase_service import SupabaseService

def test_direct_supabase():
    """Test direct Supabase user creation"""
    print("🧪 Direct Supabase User Creation Test")
    print("=" * 50)
    
    # Test user data
    user_data = {
        "first_name": "Geleta", 
        "last_name": "Ákos",
        "email": "geleako@gmail.com",
        "hashed_password": "$2b$12$example.hash.here",  # Dummy hash
        "birth_date": "1991-05-24",
        "role": "user",
        "is_verified": False,
        "verification_token": "test-token-123",
        "verification_expires": "2025-11-14T00:00:00",
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat()
    }
    
    print(f"📋 Creating user in Supabase:")
    print(f"   Name: {user_data['first_name']} {user_data['last_name']}")
    print(f"   Email: {user_data['email']}")
    
    # Check if Supabase is available
    if not SupabaseService.is_available():
        print("❌ Supabase not available")
        return False
    
    print("✅ Supabase client available")
    
    try:
        # Create user directly in Supabase
        result = SupabaseService.create_user(user_data)
        
        if result:
            print(f"✅ User created successfully!")
            print(f"   User ID: {result['id']}")
            print(f"   Email: {result['email']}")
            print(f"   Created: {result['created_at']}")
            
            # Test lookup
            print(f"\n🔍 Testing user lookup...")
            found_user = SupabaseService.get_user_by_email(user_data['email'])
            
            if found_user:
                print(f"✅ User found by email!")
                print(f"   ID: {found_user['id']}")
                print(f"   Name: {found_user['first_name']} {found_user['last_name']}")
            else:
                print("❌ User not found after creation")
            
            return True
        else:
            print("❌ Failed to create user")
            return False
            
    except Exception as e:
        print(f"❌ Error creating user: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("🚀 Zedin Steam Manager - Direct Supabase Test")
    print("=" * 50)
    
    success = test_direct_supabase()
    
    print("\n" + "=" * 50)
    if success:
        print("✅ Direct Supabase test completed successfully!")
        print("🎯 Check your Supabase dashboard - you should see the user in the 'users' table!")
    else:
        print("❌ Direct Supabase test failed!")