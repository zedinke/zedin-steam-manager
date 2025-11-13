-- Zedin Steam Manager Database Schema
-- Run this in Supabase SQL Editor

-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    birth_date DATE,
    role VARCHAR(20) DEFAULT 'user',
    is_verified BOOLEAN DEFAULT FALSE,
    verification_token VARCHAR(255),
    verification_expires TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- User tokens table
CREATE TABLE user_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    usage_count INTEGER DEFAULT 0,
    usage_limit INTEGER DEFAULT 1000,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Token usage logs table
CREATE TABLE token_usage_logs (
    id SERIAL PRIMARY KEY,
    token_id INTEGER REFERENCES user_tokens(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    timestamp TIMESTAMP DEFAULT NOW(),
    metadata JSONB
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_verification_token ON users(verification_token);
CREATE INDEX idx_user_tokens_user_id ON user_tokens(user_id);
CREATE INDEX idx_user_tokens_status ON user_tokens(status);
CREATE INDEX idx_token_usage_logs_token_id ON token_usage_logs(token_id);
CREATE INDEX idx_token_usage_logs_user_id ON token_usage_logs(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE token_usage_logs ENABLE ROW LEVEL SECURITY;

-- Create policies for RLS (allow service_role to do everything)
CREATE POLICY "Service role can do everything" ON users FOR ALL USING (true);
CREATE POLICY "Service role can do everything" ON user_tokens FOR ALL USING (true);
CREATE POLICY "Service role can do everything" ON token_usage_logs FOR ALL USING (true);