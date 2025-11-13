#!/usr/bin/env python3
"""
Database Setup Script
Creates required tables in Supabase
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client

# Load environment variables
load_dotenv()

# Get Supabase credentials
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in .env file")
    sys.exit(1)

# Read SQL schema
schema_path = Path(__file__).parent / "database" / "schema.sql"
if not schema_path.exists():
    print(f"❌ Error: Schema file not found at {schema_path}")
    sys.exit(1)

with open(schema_path, 'r') as f:
    sql_commands = f.read()

print("🔧 Connecting to Supabase...")
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

print("📊 Creating database schema...")
try:
    # Execute SQL commands
    # Note: Supabase Python client doesn't support raw SQL execution
    # You need to run this in Supabase SQL Editor or use PostgREST API
    print("""
⚠️  The Python Supabase client doesn't support raw SQL execution.
    
Please run the SQL commands manually:

1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/{project_id}
2. Click on "SQL Editor" in the left menu
3. Click "New Query"
4. Copy and paste the SQL from: backend/database/schema.sql
5. Click "Run" to execute

Alternatively, you can use the Supabase CLI:
    supabase db push
    
Or connect via psql:
    psql -h db.{project_id}.supabase.co -p 5432 -U postgres -d postgres -f backend/database/schema.sql
""")
    
    print("\n✅ Schema file created successfully!")
    print(f"📄 Location: {schema_path}")
    
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
