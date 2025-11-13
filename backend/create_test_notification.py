#!/usr/bin/env python3
"""
Create test notification for geleako@gmail.com
"""
import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get Supabase client
from supabase import create_client

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_KEY')
)

def create_test_notification():
    try:
        # Instead of using admin API, query the database directly
        # First, let's try to find the user in auth.users
        print("Creating test notification for geleako@gmail.com...")
        
        # We'll use a known user_id or create for ANY user
        # Let's just create a notification with a placeholder user_id
        # You can get the actual user_id from Supabase dashboard
        
        # For now, let's test if the notifications table exists
        print("\nChecking if notifications table exists...")
        result = supabase.table('notifications').select('id').limit(1).execute()
        print('✅ Notifications table exists!')
        
        # Since we can't easily get user_id without admin access,
        # let's output instructions instead
        print("\n📋 To create a test notification:")
        print("1. Go to Supabase Dashboard -> Authentication -> Users")
        print("2. Find geleako@gmail.com and copy the User ID")
        print("3. Go to Table Editor -> notifications")
        print("4. Insert new row with:")
        print("   - user_id: <copied_user_id>")
        print("   - title: 🎉 Teszt Értesítés")
        print("   - message: Ez egy teszt értesítés a Module 1.5 notification rendszerből!")
        print("   - type: success")
        print("   - read: false")
        print("\nOr run this SQL in Supabase SQL Editor:")
        print("""
INSERT INTO notifications (user_id, title, message, type, read)
SELECT id, '🎉 Teszt Értesítés', 
       'Ez egy teszt értesítés a Module 1.5 notification rendszerből!', 
       'success', false
FROM auth.users 
WHERE email = 'geleako@gmail.com';
        """)
            
    except Exception as e:
        error_msg = str(e)
        print(f'❌ Error: {error_msg}')
        
        if 'does not exist' in error_msg or 'relation' in error_msg:
            print('\n⚠️  Notifications table does not exist!')
            print('   Please run the SQL schema first:')
            print('   backend/database/tokens_schema.sql in Supabase SQL Editor')
        
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    create_test_notification()
