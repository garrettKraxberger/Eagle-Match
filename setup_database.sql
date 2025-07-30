-- Simplified Database Setup for Eagle Match
-- Run this in your Supabase SQL Editor

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  age INTEGER,
  handicap DECIMAL,
  location TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create a trigger to automatically create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists and create new one
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Create counties table (for location selection)
CREATE TABLE IF NOT EXISTS counties (
  id SERIAL PRIMARY KEY,
  county TEXT NOT NULL,
  state TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert some sample counties
INSERT INTO counties (county, state) VALUES
('Orange County', 'CA'),
('Los Angeles County', 'CA'),
('San Diego County', 'CA'),
('Maricopa County', 'AZ'),
('Cook County', 'IL')
ON CONFLICT DO NOTHING;

-- Create courses table (for golf courses)
CREATE TABLE IF NOT EXISTS courses (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  city TEXT,
  state TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert some sample courses
INSERT INTO courses (name, city, state) VALUES
('Pebble Beach Golf Links', 'Pebble Beach', 'CA'),
('TPC Scottsdale', 'Scottsdale', 'AZ'),
('Augusta National', 'Augusta', 'GA'),
('Bethpage Black', 'Farmingdale', 'NY'),
('Torrey Pines', 'La Jolla', 'CA')
ON CONFLICT DO NOTHING;

-- Create matches table (MOST IMPORTANT)
CREATE TABLE IF NOT EXISTS matches (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  creator_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  match_type TEXT NOT NULL CHECK (match_type IN ('Match Play', 'Stroke Play')),
  match_mode TEXT NOT NULL CHECK (match_mode IN ('Single', 'Duo')),
  location_mode TEXT NOT NULL CHECK (location_mode IN ('counties', 'course')),
  location_ids INTEGER[] NOT NULL DEFAULT '{}',
  custom_course_name TEXT, -- For user-entered course names
  custom_course_city TEXT, -- For user-entered course cities
  schedule_mode TEXT NOT NULL CHECK (schedule_mode IN ('specific', 'flexible')),
  date DATE,
  time TEXT,
  days_of_week TEXT[],
  handicap_required BOOLEAN DEFAULT FALSE,
  is_private BOOLEAN DEFAULT FALSE,
  notes TEXT,
  teammate TEXT,
  participants UUID[] DEFAULT '{}',
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create match_requests table
CREATE TABLE IF NOT EXISTS match_requests (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE NOT NULL,
  requester_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  request_type TEXT NOT NULL CHECK (request_type IN ('join', 'invite')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Anyone can view active matches" ON matches;
DROP POLICY IF EXISTS "Users can insert own matches" ON matches;
DROP POLICY IF EXISTS "Users can update own matches" ON matches;

-- Create policies
CREATE POLICY "Users can view all profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Anyone can view active matches" ON matches FOR SELECT USING (status = 'active');
CREATE POLICY "Users can insert own matches" ON matches FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "Users can update own matches" ON matches FOR UPDATE USING (auth.uid() = creator_id);

CREATE POLICY "Users can view requests for their matches" ON match_requests FOR SELECT USING (
  EXISTS (SELECT 1 FROM matches WHERE matches.id = match_requests.match_id AND matches.creator_id = auth.uid())
  OR requester_id = auth.uid()
);
CREATE POLICY "Users can insert match requests" ON match_requests FOR INSERT WITH CHECK (auth.uid() = requester_id);
CREATE POLICY "Match creators can update requests" ON match_requests FOR UPDATE USING (
  EXISTS (SELECT 1 FROM matches WHERE matches.id = match_requests.match_id AND matches.creator_id = auth.uid())
);

CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_matches_creator ON matches(creator_id);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_match_requests_match ON match_requests(match_id);
CREATE INDEX IF NOT EXISTS idx_match_requests_requester ON match_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
