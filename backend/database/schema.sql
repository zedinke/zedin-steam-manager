-- Zedin Steam Manager Database Schema
-- Run this in Supabase SQL Editor

-- Email verification tokens table
CREATE TABLE IF NOT EXISTS public.email_verifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster token lookups
CREATE INDEX IF NOT EXISTS idx_email_verifications_token ON public.email_verifications(token);
CREATE INDEX IF NOT EXISTS idx_email_verifications_user_id ON public.email_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_email_verifications_expires_at ON public.email_verifications(expires_at);

-- Enable Row Level Security
ALTER TABLE public.email_verifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies - Allow all operations for service role and anon
CREATE POLICY "Allow service role full access" ON public.email_verifications
    FOR ALL 
    TO service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow anon to insert verification tokens" ON public.email_verifications
    FOR INSERT 
    TO anon
    WITH CHECK (true);

CREATE POLICY "Allow anon to select verification tokens" ON public.email_verifications
    FOR SELECT 
    TO anon
    USING (true);

CREATE POLICY "Allow authenticated users to manage their tokens" ON public.email_verifications
    FOR ALL 
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON public.email_verifications TO service_role;
GRANT ALL ON public.email_verifications TO anon;
GRANT ALL ON public.email_verifications TO authenticated;
