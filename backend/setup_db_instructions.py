#!/usr/bin/env python3
"""
Quick Database Setup via HTTP
Uses Supabase REST API to create tables
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import httpx

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ SUPABASE_URL and SUPABASE_SERVICE_KEY required in .env")
    sys.exit(1)

# SQL to create table
SQL_SCHEMA = """
-- Email verification tokens table
CREATE TABLE IF NOT EXISTS public.email_verifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_email_verifications_token ON public.email_verifications(token);
CREATE INDEX IF NOT EXISTS idx_email_verifications_user_id ON public.email_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_email_verifications_expires_at ON public.email_verifications(expires_at);

ALTER TABLE public.email_verifications ENABLE ROW LEVEL SECURITY;
"""

print("=" * 60)
print("SUPABASE DATABASE SETUP")
print("=" * 60)
print("\n📋 To create the required database tables:\n")
print("1. Open Supabase Dashboard:")
print(f"   {SUPABASE_URL.replace('https://', 'https://supabase.com/dashboard/project/')}\n")
print("2. Click 'SQL Editor' in the left menu\n")
print("3. Click 'New Query'\n")
print("4. Copy and paste this SQL:\n")
print("-" * 60)
print(SQL_SCHEMA)
print("-" * 60)
print("\n5. Click 'Run' (or press Ctrl+Enter)\n")
print("✅ Done! Your database will be ready.\n")

# Save SQL to file
schema_file = Path(__file__).parent / "database" / "schema.sql"
print(f"💾 SQL schema saved to: {schema_file}")
