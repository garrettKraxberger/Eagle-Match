-- STEP 1: Create the partnerships table
-- Copy and paste this entire script into your Supabase SQL Editor and run it

-- First, check if the profiles table exists and has the right structure
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
    RAISE EXCEPTION 'profiles table does not exist. Please run setup_database.sql first.';
  END IF;
END $$;

-- Create partnerships table
CREATE TABLE IF NOT EXISTS partnerships (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user1_id UUID NOT NULL,
  user2_id UUID NOT NULL,
  nickname TEXT,
  is_starred BOOLEAN DEFAULT FALSE,
  matches_played INTEGER DEFAULT 0,
  matches_won INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Foreign key constraints
  CONSTRAINT partnerships_user1_id_fkey FOREIGN KEY (user1_id) REFERENCES profiles(id) ON DELETE CASCADE,
  CONSTRAINT partnerships_user2_id_fkey FOREIGN KEY (user2_id) REFERENCES profiles(id) ON DELETE CASCADE,
  
  -- Ensure users can't partner with themselves
  CONSTRAINT check_different_users CHECK (user1_id != user2_id)
);

-- Create a unique index to prevent duplicate partnerships (regardless of order)
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_partnerships 
ON partnerships (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id)) 
WHERE status = 'active';

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_partnerships_user1 ON partnerships(user1_id);
CREATE INDEX IF NOT EXISTS idx_partnerships_user2 ON partnerships(user2_id);
CREATE INDEX IF NOT EXISTS idx_partnerships_starred ON partnerships(is_starred);

-- Enable Row Level Security
ALTER TABLE partnerships ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view partnerships they are part of" ON partnerships;
DROP POLICY IF EXISTS "Users can create partnerships involving themselves" ON partnerships;
DROP POLICY IF EXISTS "Users can update partnerships they are part of" ON partnerships;
DROP POLICY IF EXISTS "Users can delete partnerships they are part of" ON partnerships;

-- RLS Policies for partnerships
CREATE POLICY "Users can view partnerships they are part of" ON partnerships
  FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can create partnerships involving themselves" ON partnerships
  FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can update partnerships they are part of" ON partnerships
  FOR UPDATE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can delete partnerships they are part of" ON partnerships
  FOR DELETE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Insert some sample data for testing (optional)
-- This will create a partnership between the first two users in your profiles table
DO $$
DECLARE
    user1_uuid UUID;
    user2_uuid UUID;
BEGIN
    -- Get two different users
    SELECT id INTO user1_uuid FROM profiles LIMIT 1;
    SELECT id INTO user2_uuid FROM profiles WHERE id != user1_uuid LIMIT 1;
    
    -- Insert partnership if both users exist
    IF user1_uuid IS NOT NULL AND user2_uuid IS NOT NULL THEN
        INSERT INTO partnerships (user1_id, user2_id, matches_played, matches_won, is_starred)
        VALUES (user1_uuid, user2_uuid, 5, 3, true)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- Verify the table was created successfully
SELECT 'Partnerships table created successfully!' as message;
