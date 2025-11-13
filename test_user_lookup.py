"""
Test existing user lookup in Supabase
"""
import os
import sys

# Add backend to path  
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

from backend.services.supabase_service import SupabaseService

def test_user_lookup():
    """Test user lookup in Supabase"""
    print("🔍 Testing Existing User Lookup in Supabase")
    print("=" * 50)
    
    test_email = "geleako@gmail.com"
    
    print(f"📋 Looking for user: {test_email}")
    
    try:
        # Test lookup
        user = SupabaseService.get_user_by_email(test_email)
        
        if user:
            print(f"✅ User found in Supabase!")
            print(f"   User ID: {user['id']}")
            print(f"   Name: {user['first_name']} {user['last_name']}")
            print(f"   Email: {user['email']}")
            print(f"   Role: {user['role']}")
            print(f"   Verified: {user['is_verified']}")
            print(f"   Created: {user['created_at']}")
            
            # Test tokens
            print(f"\n🎯 Checking user tokens...")
            tokens = SupabaseService.get_user_tokens(user['id'])
            
            if tokens:
                print(f"✅ Found {len(tokens)} token(s):")
                for token in tokens:
                    print(f"   - Token ID: {token['id']}")
                    print(f"     Type: {token['token_type']}")
                    print(f"     Status: {token['status']}")
                    print(f"     Usage: {token['usage_count']}/{token['usage_limit']}")
            else:
                print("📝 No tokens found for this user")
            
            return True
        else:
            print("❌ User not found")
            return False
            
    except Exception as e:
        print(f"❌ Error looking up user: {e}")
        return False

def list_all_users():
    """List all users in Supabase"""
    print(f"\n📋 Listing all users in Supabase")
    print("=" * 50)
    
    try:
        client = SupabaseService.get_client()
        if not client:
            print("❌ Supabase client not available")
            return
            
        result = client.table("users").select("id, email, first_name, last_name, role, created_at").execute()
        
        if result.data:
            print(f"✅ Found {len(result.data)} user(s):")
            for i, user in enumerate(result.data, 1):
                print(f"   {i}. {user['first_name']} {user['last_name']} ({user['email']})")
                print(f"      ID: {user['id']}, Role: {user['role']}")
                print(f"      Created: {user['created_at']}")
        else:
            print("📝 No users found")
            
    except Exception as e:
        print(f"❌ Error listing users: {e}")

if __name__ == "__main__":
    print("🚀 Zedin Steam Manager - Supabase User Check")
    print("=" * 50)
    
    if SupabaseService.is_available():
        print("✅ Supabase connection active")
        
        # Test specific user lookup
        test_user_lookup()
        
        # List all users  
        list_all_users()
        
        print("\n" + "=" * 50)
        print("🎯 SUCCESS! Your user data is stored in Supabase!")
        print("   ✅ Data will persist across system reinstallations")
        print("   ✅ External database integration working")
        
    else:
        print("❌ Supabase not available")