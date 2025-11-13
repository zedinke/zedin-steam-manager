-- Password Reset Tokens Table
CREATE TABLE IF NOT EXISTS password_resets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_at TIMESTAMP WITH TIME ZONE
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_password_resets_token ON password_resets(token);
CREATE INDEX IF NOT EXISTS idx_password_resets_user_id ON password_resets(user_id);
CREATE INDEX IF NOT EXISTS idx_password_resets_expires_at ON password_resets(expires_at);

-- Enable Row Level Security
ALTER TABLE password_resets ENABLE ROW LEVEL SECURITY;

-- Policy: Service role can do everything
CREATE POLICY "Service role can manage password resets"
    ON password_resets
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Policy: Users can only view their own reset tokens (optional, for debugging)
CREATE POLICY "Users can view own reset tokens"
    ON password_resets
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Function to clean up expired tokens (run periodically)
CREATE OR REPLACE FUNCTION clean_expired_password_resets()
RETURNS void AS $$
BEGIN
    DELETE FROM password_resets
    WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION clean_expired_password_resets() TO service_role;
