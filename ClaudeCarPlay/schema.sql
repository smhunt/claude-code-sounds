-- PostgreSQL schema for Claude CarPlay conversation persistence
-- Run this on your Postgres instance (Supabase, Neon, local, etc.)

CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_conversations_session ON conversations(session_id);
CREATE INDEX IF NOT EXISTS idx_conversations_timestamp ON conversations(timestamp);

-- Optional: Enable Row Level Security if using Supabase
-- ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Optional: Create a policy for anonymous access (for PostgREST)
-- CREATE POLICY "Allow all operations" ON conversations FOR ALL USING (true);
