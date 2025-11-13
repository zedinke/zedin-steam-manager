#!/usr/bin/env python3
import os
from dotenv import load_dotenv
load_dotenv()

from supabase import create_client

supabase = create_client(
    os.getenv('SUPABASE_URL'), 
    os.getenv('SUPABASE_SERVICE_KEY')
)

print("Checking notifications in database...")
try:
    result = supabase.table('notifications').select('*').execute()
    print(f'\n✅ Total notifications: {len(result.data)}')
    
    if result.data:
        for n in result.data:
            print(f'\n📧 Notification:')
            print(f'   ID: {n["id"]}')
            print(f'   User ID: {n["user_id"]}')
            print(f'   Title: {n["title"]}')
            print(f'   Message: {n["message"]}')
            print(f'   Type: {n["type"]}')
            print(f'   Read: {n["read"]}')
            print(f'   Created: {n["created_at"]}')
    else:
        print('\n❌ No notifications found in database')
        
except Exception as e:
    print(f'\n❌ Error: {e}')
