-- Check and migrate profile image data from users to profiles table
-- Run this in your Supabase SQL Editor to diagnose and fix profile image issues

-- Step 1: Check if users table exists and has profile data
SELECT 'Checking users table...' as step;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        RAISE NOTICE 'Users table exists';
        -- Show sample data from users table
        PERFORM 1;
    ELSE
        RAISE NOTICE 'Users table does not exist';
    END IF;
END $$;

-- Step 2: Check profiles table structure
SELECT 'Checking profiles table structure...' as step;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
ORDER BY ordinal_position;

-- Step 3: Check if users table has profile images that need to be migrated
SELECT 'Checking for profile images in users table...' as step;

DO $$
DECLARE
    users_count INTEGER := 0;
    profiles_count INTEGER := 0;
BEGIN
    -- Check if users table exists and count records with profile images
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        SELECT COUNT(*) INTO users_count FROM users WHERE profile_image_url IS NOT NULL;
        RAISE NOTICE 'Users with profile images in users table: %', users_count;
        
        -- Check profiles table
        SELECT COUNT(*) INTO profiles_count FROM profiles WHERE profile_image_url IS NOT NULL;
        RAISE NOTICE 'Users with profile images in profiles table: %', profiles_count;
        
        -- If users table has profile images but profiles doesn't, suggest migration
        IF users_count > 0 AND profiles_count = 0 THEN
            RAISE NOTICE 'MIGRATION NEEDED: Profile images found in users table but not in profiles table';
            RAISE NOTICE 'Run the migration section below to move data from users to profiles';
        END IF;
    ELSE
        RAISE NOTICE 'No users table found - checking profiles only';
        SELECT COUNT(*) INTO profiles_count FROM profiles WHERE profile_image_url IS NOT NULL;
        RAISE NOTICE 'Users with profile images in profiles table: %', profiles_count;
    END IF;
END $$;

-- Step 4: Optional Migration (uncomment to run)
-- UNCOMMENT THE SECTION BELOW TO MIGRATE DATA FROM USERS TO PROFILES

/*
-- Migrate profile images from users to profiles table
DO $$
DECLARE
    user_record RECORD;
BEGIN
    -- Check if both tables exist
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') 
       AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN
        
        -- Loop through users with profile images
        FOR user_record IN 
            SELECT id, profile_image_url, first_name, last_name, birthday, city, state, handicap, home_course
            FROM users 
            WHERE profile_image_url IS NOT NULL
        LOOP
            -- Insert or update profiles table
            INSERT INTO profiles (
                id, 
                full_name, 
                age, 
                handicap, 
                location, 
                profile_image_url,
                created_at,
                updated_at
            ) VALUES (
                user_record.id,
                CONCAT(COALESCE(user_record.first_name, ''), ' ', COALESCE(user_record.last_name, '')),
                CASE 
                    WHEN user_record.birthday IS NOT NULL 
                    THEN EXTRACT(YEAR FROM AGE(user_record.birthday::date))::INTEGER
                    ELSE NULL 
                END,
                user_record.handicap,
                CASE 
                    WHEN user_record.city IS NOT NULL AND user_record.state IS NOT NULL 
                    THEN CONCAT(user_record.city, ', ', user_record.state)
                    ELSE NULL 
                END,
                user_record.profile_image_url,
                NOW(),
                NOW()
            )
            ON CONFLICT (id) DO UPDATE SET
                profile_image_url = EXCLUDED.profile_image_url,
                full_name = COALESCE(NULLIF(profiles.full_name, ''), EXCLUDED.full_name),
                age = COALESCE(profiles.age, EXCLUDED.age),
                handicap = COALESCE(profiles.handicap, EXCLUDED.handicap),
                location = COALESCE(profiles.location, EXCLUDED.location),
                updated_at = NOW();
                
            RAISE NOTICE 'Migrated profile image for user: %', user_record.id;
        END LOOP;
        
        RAISE NOTICE 'Migration completed successfully';
    ELSE
        RAISE NOTICE 'Cannot migrate - missing required tables';
    END IF;
END $$;
*/
