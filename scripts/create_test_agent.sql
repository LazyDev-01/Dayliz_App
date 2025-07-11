-- Create Test Agent for Dayliz Agent App
-- This script creates the agents table and a test agent account
-- Run this in your Supabase SQL Editor

-- Step 1: Create the agent status enum if it doesn't exist
DO $$ BEGIN
    CREATE TYPE agent_status AS ENUM ('pending', 'active', 'inactive', 'suspended');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Step 2: Create the agents table if it doesn't exist
CREATE TABLE IF NOT EXISTS agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) UNIQUE,
  agent_id VARCHAR(20) UNIQUE NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  phone VARCHAR(15) NOT NULL,
  email VARCHAR(100),
  assigned_zone VARCHAR(50),
  status agent_status DEFAULT 'pending',
  total_deliveries INTEGER DEFAULT 0,
  total_earnings DECIMAL(10,2) DEFAULT 0.00,
  join_date TIMESTAMP DEFAULT NOW(),
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Step 3: Enable RLS on agents table
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;

-- Step 4: Create RLS policies for agents table
DROP POLICY IF EXISTS "Agents can view their own data" ON agents;
CREATE POLICY "Agents can view their own data" ON agents
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Agents can update their own data" ON agents;
CREATE POLICY "Agents can update their own data" ON agents
    FOR UPDATE USING (auth.uid() = user_id);

-- Step 5: Check if agents table was created successfully
SELECT 'Agents table created successfully!' as status;
