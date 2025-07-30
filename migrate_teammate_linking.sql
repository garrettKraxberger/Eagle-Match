-- Migration script to update matches table for proper teammate linking
-- Run this in your Supabase SQL Editor to update the existing matches table

-- STEP 1: Add the new teammate_id column
ALTER TABLE matches ADD COLUMN IF NOT EXISTS teammate_id UUID REFERENCES profiles(id) ON DELETE SET NULL;

-- STEP 2: Create an index for the new teammate_id column
CREATE INDEX IF NOT EXISTS idx_matches_teammate_id ON matches(teammate_id);

-- STEP 3: Optional - Migrate existing teammate text data to teammate_id
-- This attempts to match teammate names to existing profiles
-- Note: This is a best-effort migration and may not match all records perfectly

DO $$
DECLARE
    match_record RECORD;
    profile_id UUID;
BEGIN
    -- Loop through matches that have teammate text but no teammate_id
    FOR match_record IN 
        SELECT id, teammate 
        FROM matches 
        WHERE teammate IS NOT NULL 
        AND teammate != '' 
        AND teammate_id IS NULL
    LOOP
        -- Try to find a profile with matching full_name
        SELECT id INTO profile_id 
        FROM profiles 
        WHERE LOWER(full_name) = LOWER(match_record.teammate)
        LIMIT 1;
        
        -- If found, update the teammate_id
        IF profile_id IS NOT NULL THEN
            UPDATE matches 
            SET teammate_id = profile_id 
            WHERE id = match_record.id;
            
            RAISE NOTICE 'Updated match % with teammate_id %', match_record.id, profile_id;
        ELSE
            RAISE NOTICE 'Could not find profile for teammate: %', match_record.teammate;
        END IF;
        
        -- Reset for next iteration
        profile_id := NULL;
    END LOOP;
END $$;

-- STEP 4: Once you're satisfied with the migration, you can drop the old teammate column
-- UNCOMMENT THE LINE BELOW ONLY AFTER VERIFYING THE MIGRATION WORKED CORRECTLY
-- ALTER TABLE matches DROP COLUMN IF EXISTS teammate;

-- Verify the migration
SELECT 
    COUNT(*) as total_matches,
    COUNT(teammate_id) as matches_with_teammate_id,
    COUNT(teammate) as matches_with_teammate_text
FROM matches 
WHERE match_mode = 'Duo';

SELECT 'Migration completed successfully!' as message;
