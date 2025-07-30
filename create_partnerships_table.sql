-- Create partnerships table for duos functionality
-- Run this in your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS partnerships (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user1_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  user2_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  nickname TEXT, -- Optional nickname for the partnership
  is_starred BOOLEAN DEFAULT FALSE, -- Whether this partnership is starred/favorited
  matches_played INTEGER DEFAULT 0, -- Track number of matches played together
  matches_won INTEGER DEFAULT 0, -- Track number of matches won together
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique partnerships (prevent duplicates)
  CONSTRAINT unique_partnership UNIQUE (
    LEAST(user1_id, user2_id), 
    GREATEST(user1_id, user2_id)
  )
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_partnerships_user1 ON partnerships(user1_id);
CREATE INDEX IF NOT EXISTS idx_partnerships_user2 ON partnerships(user2_id);

-- Enable Row Level Security
ALTER TABLE partnerships ENABLE ROW LEVEL SECURITY;

-- RLS Policies for partnerships
CREATE POLICY "Users can view partnerships they are part of" ON partnerships
  FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can create partnerships involving themselves" ON partnerships
  FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can update partnerships they are part of" ON partnerships
  FOR UPDATE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can delete partnerships they are part of" ON partnerships
  FOR DELETE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Function to automatically create/update partnerships when matches are played
CREATE OR REPLACE FUNCTION update_partnership_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process if both creator and teammate are set
  IF NEW.creator_id IS NOT NULL AND NEW.teammate_id IS NOT NULL THEN
    -- Insert or update partnership
    INSERT INTO partnerships (
      user1_id, 
      user2_id, 
      matches_played,
      matches_won
    ) VALUES (
      LEAST(NEW.creator_id, NEW.teammate_id),
      GREATEST(NEW.creator_id, NEW.teammate_id),
      1,
      CASE WHEN NEW.status = 'completed' THEN 1 ELSE 0 END
    )
    ON CONFLICT (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id))
    DO UPDATE SET
      matches_played = partnerships.matches_played + 1,
      matches_won = partnerships.matches_won + CASE WHEN NEW.status = 'completed' THEN 1 ELSE 0 END,
      updated_at = NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to update partnership stats when matches are updated
DROP TRIGGER IF EXISTS update_partnership_stats_trigger ON matches;
CREATE TRIGGER update_partnership_stats_trigger
  AFTER UPDATE ON matches
  FOR EACH ROW
  WHEN (OLD.status != NEW.status AND NEW.status IN ('completed', 'active'))
  EXECUTE FUNCTION update_partnership_stats();
