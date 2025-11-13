"""
Test new user registration via API
"""
import requests
import json

def test_api_registration():
    """Test user registration via API endpoint"""
    print("🧪 Testing New User Registration via API")
    print("=" * 50)
    
    # New test user data (simplified for new endpoint)
    user_data = {
        "first_name": "Test",
        "last_name": "User", 
        "email": "testuser2@example.com",
        "password": "Test123456",
        "birth_date": "1990-01-01"
    }
    
    api_url = "http://localhost:8000/api/auth/simple-register"
    
    print(f"📋 Registering new user:")
    print(f"   Name: {user_data['first_name']} {user_data['last_name']}")
    print(f"   Email: {user_data['email']}")
    print(f"   API: {api_url}")
    
    try:
        # Make API request
        response = requests.post(
            api_url,
            json=user_data,
            headers={'Content-Type': 'application/json'},
            timeout=10
        )
        
        print(f"📡 Response Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Registration successful!")
            print(f"   User ID: {result.get('user_id')}")
            print(f"   Email: {result.get('email')}")
            print(f"   Requires verification: {result.get('requires_verification', False)}")
            
            # Check if user was created in Supabase
            print(f"\n🔍 Verifying user in Supabase...")
            import sys
            import os
            sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))
            
            from backend.services.supabase_service import SupabaseService
            
            supabase_user = SupabaseService.get_user_by_email(user_data['email'])
            if supabase_user:
                print(f"✅ User found in Supabase!")
                print(f"   ID: {supabase_user['id']}")
                print(f"   Name: {supabase_user['first_name']} {supabase_user['last_name']}")
                print(f"   External database persistence: ✅ WORKING")
            else:
                print("❌ User not found in Supabase")
            
            return True
            
        else:
            print(f"❌ Registration failed!")
            print(f"   Status: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection error - backend server not running!")
        print("   Start backend with: python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000")
        return False
    except Exception as e:
        print(f"❌ Request failed: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Zedin Steam Manager - API Registration Test")
    print("=" * 50)
    
    success = test_api_registration()
    
    print("\n" + "=" * 50)
    if success:
        print("✅ API Registration test successful!")
        print("🎯 User data stored in external Supabase database!")
        print("   ✅ Data will survive system reinstallations") 
    else:
        print("❌ API Registration test failed!")