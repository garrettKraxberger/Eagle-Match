-- Add profile_image_url field to profiles table
-- Run this script in your Supabase SQL Editor if you already have a profiles table

-- Add the profile_image_url column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'profile_image_url'
    ) THEN
        ALTER TABLE profiles ADD COLUMN profile_image_url TEXT;
        RAISE NOTICE 'Added profile_image_url column to profiles table';
    ELSE
        RAISE NOTICE 'profile_image_url column already exists in profiles table';
    END IF;
END $$;

-- Verify the column was added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position;
