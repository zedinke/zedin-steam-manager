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
        # Get user by email using admin API
        print("Fetching users...")
        response = supabase.auth.admin.list_users()
        
        target_user = None
        for user in response:
            if user.email == 'geleako@gmail.com':
                target_user = user
                break
        
        if not target_user:
            print('❌ User not found with email: geleako@gmail.com')
            return
        
        print(f'✅ User found: {target_user.id}')
        print(f'   Email: {target_user.email}')
        
        # Check if notifications table exists and insert
        print("\nCreating test notification...")
        notification_data = {
            'user_id': str(target_user.id),
            'title': '🎉 Teszt Értesítés',
            'message': 'Ez egy teszt értesítés a Module 1.5 notification rendszerből! Minden működik!',
            'type': 'success',
            'read': False
        }
        
        result = supabase.table('notifications').insert(notification_data).execute()
        
        if result.data:
            print(f'✅ Test notification created successfully!')
            print(f'   Notification ID: {result.data[0]["id"]}')
            print(f'   Title: {result.data[0]["title"]}')
            print(f'\n🔔 Check the notification bell in the dashboard!')
        else:
            print('❌ Failed to create notification')
            
    except Exception as e:
        print(f'❌ Error: {e}')
        print('\n⚠️  If you see "relation does not exist" error:')
        print('   Please run the SQL schema first:')
        print('   backend/database/tokens_schema.sql in Supabase SQL Editor')
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    create_test_notification()
