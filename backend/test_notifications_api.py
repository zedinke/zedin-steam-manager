#!/usr/bin/env python3
import os
from dotenv import load_dotenv
load_dotenv()

from services.supabase_client import get_supabase

user_id = "cb35f26c-2d10-48b1-8855-224aa489fcc0"

print(f"Testing notifications API for user: {user_id}")
print(f"Using SUPABASE_SERVICE_KEY: {os.getenv('SUPABASE_SERVICE_KEY')[:20]}...")

supabase = get_supabase()

try:
    print("\nQuerying notifications...")
    result = supabase.table("notifications").select("*").eq("user_id", user_id).execute()
    print(f"✅ Success! Found {len(result.data)} notifications")
    
    for n in result.data:
        print(f"\n📧 {n['title']}")
        print(f"   Message: {n['message']}")
        print(f"   Read: {n['read']}")
        
except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
