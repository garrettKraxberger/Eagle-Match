-- Add custom course columns to the matches table
-- Run this in your Supabase SQL Editor

ALTER TABLE matches 
ADD COLUMN IF NOT EXISTS custom_course_name TEXT,
ADD COLUMN IF NOT EXISTS custom_course_city TEXT;

-- Update the updated_at timestamp when these columns are modified
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger if it doesn't exist
DROP TRIGGER IF EXISTS update_matches_updated_at ON matches;
CREATE TRIGGER update_matches_updated_at 
    BEFORE UPDATE ON matches 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
