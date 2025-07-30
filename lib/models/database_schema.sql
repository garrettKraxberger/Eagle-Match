// Database schema guide for Eagle Match
// 
// You'll need to create these tables in your Supabase database:

-- 1. profiles table (should already exist if using Supabase Auth)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT,
  age INTEGER,
  handicap DECIMAL,
  location TEXT,
  profile_image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. counties table (for location management)
CREATE TABLE IF NOT EXISTS counties (
  id SERIAL PRIMARY KEY,
  county TEXT NOT NULL,
  state TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. courses table (for golf courses)
CREATE TABLE IF NOT EXISTS courses (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  city TEXT,
  state TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. matches table (main match postings)
CREATE TABLE IF NOT EXISTS matches (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  creator_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  match_type TEXT NOT NULL CHECK (match_type IN ('Match Play', 'Stroke Play')),
  match_mode TEXT NOT NULL CHECK (match_mode IN ('Single', 'Duo')),
  location_mode TEXT NOT NULL CHECK (location_mode IN ('counties', 'course')),
  location_ids INTEGER[] NOT NULL,
  schedule_mode TEXT NOT NULL CHECK (schedule_mode IN ('specific', 'flexible')),
  date DATE,
  time TEXT,
  days_of_week TEXT[],
  handicap_required BOOLEAN DEFAULT FALSE,
  is_private BOOLEAN DEFAULT FALSE,
  notes TEXT,
  teammate_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  participants UUID[],
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. match_requests table (for join/invite requests)
CREATE TABLE IF NOT EXISTS match_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  match_id UUID REFERENCES matches(id) ON DELETE CASCADE NOT NULL,
  requester_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  request_type TEXT NOT NULL CHECK (request_type IN ('join', 'invite')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. notifications table (for user notifications)
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_matches_creator ON matches(creator_id);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_match_requests_match ON match_requests(match_id);
CREATE INDEX IF NOT EXISTS idx_match_requests_requester ON match_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);

-- Row Level Security (RLS) policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view all profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Matches policies
CREATE POLICY "Anyone can view active matches" ON matches FOR SELECT USING (status = 'active');
CREATE POLICY "Users can insert own matches" ON matches FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "Users can update own matches" ON matches FOR UPDATE USING (auth.uid() = creator_id);

-- Match requests policies
CREATE POLICY "Users can view requests for their matches" ON match_requests FOR SELECT USING (
  EXISTS (SELECT 1 FROM matches WHERE matches.id = match_requests.match_id AND matches.creator_id = auth.uid())
  OR requester_id = auth.uid()
);
CREATE POLICY "Users can insert match requests" ON match_requests FOR INSERT WITH CHECK (auth.uid() = requester_id);
CREATE POLICY "Match creators can update requests" ON match_requests FOR UPDATE USING (
  EXISTS (SELECT 1 FROM matches WHERE matches.id = match_requests.match_id AND matches.creator_id = auth.uid())
);

-- Notifications policies
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);
