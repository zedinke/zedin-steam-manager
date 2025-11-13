#!/usr/bin/env python3
"""
Script to create a test user directly in Supabase database using REST API
"""
import os
import json
from dotenv import load_dotenv
import httpx

load_dotenv()

def create_test_user():
    """Create a test user using Supabase REST API"""

    # Get Supabase configuration
    url = os.getenv("SUPABASE_URL")
    service_key = os.getenv("SUPABASE_SERVICE_KEY")

    if not url or not service_key:
        print("❌ Missing SUPABASE_URL or SUPABASE_SERVICE_KEY in .env")
        return

    print(f"🔗 Connecting to Supabase: {url}")

    # Supabase admin API endpoint
    admin_url = f"{url}/auth/v1/admin/users"

    headers = {
        "Authorization": f"Bearer {service_key}",
        "Content-Type": "application/json",
        "apikey": service_key
    }

    # Test user data
    user_data = {
        "email": "test@example.com",
        "password": "test123",
        "email_confirm": True,  # Skip email verification for testing
        "user_metadata": {
            "username": "testuser"
        }
    }

    print(f"👤 Creating test user: {user_data['email']}")

    try:
        # Create user using admin API
        response = httpx.post(admin_url, json=user_data, headers=headers)

        if response.status_code == 201:
            user = response.json()
            user_id = user.get("id")
            print("✅ User created successfully!")
            print(f"   ID: {user_id}")
            print(f"   Email: {user_data['email']}")
            print(f"   Username: {user_data['user_metadata']['username']}")
            print(f"   Email confirmed: {user.get('email_confirmed_at') is not None}")

            # Test login
            print("\n🔐 Testing login...")
            login_url = f"{url}/auth/v1/token?grant_type=password"
            login_data = {
                "email": user_data["email"],
                "password": user_data["password"]
            }

            login_response = httpx.post(login_url, json=login_data, headers={
                "Content-Type": "application/json",
                "apikey": os.getenv("SUPABASE_KEY")  # Use anon key for login
            })

            if login_response.status_code == 200:
                login_data = login_response.json()
                print("✅ Login successful!")
                print(f"   Access token: {login_data.get('access_token')[:20]}...")
                return True
            else:
                print(f"❌ Login failed: {login_response.status_code}")
                print(f"Response: {login_response.text}")
                return False
        else:
            print(f"❌ User creation failed: {response.status_code}")
            print(f"Response: {response.text}")
            return False

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

if __name__ == "__main__":
    print("🚀 Creating test user in Supabase...")
    success = create_test_user()
    if success:
        print("\n🎉 Test user created and login works!")
        print("You can now login with:")
        print("Email: test@example.com")
        print("Password: test123")
    else:
        print("\n💥 Failed to create test user")