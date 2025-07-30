-- Add teammate_id column to matches table
-- Run this in your Supabase SQL Editor

ALTER TABLE matches ADD COLUMN IF NOT EXISTS teammate_id UUID REFERENCES profiles(id) ON DELETE SET NULL;

-- Add comment to explain the fields
COMMENT ON COLUMN matches.teammate IS 'Display name of teammate (can be any text)';
COMMENT ON COLUMN matches.teammate_id IS 'Reference to actual user profile if teammate is a registered user';
