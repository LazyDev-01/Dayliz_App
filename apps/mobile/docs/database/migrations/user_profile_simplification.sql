-- Migration to simplify user_profiles table to match the UserProfile entity
-- This migration removes fields that are not used in the clean architecture implementation

-- First, check if the columns exist before attempting to drop them
DO $$
BEGIN
    -- Check and drop display_name column
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'display_name'
    ) THEN
        ALTER TABLE public.user_profiles DROP COLUMN IF EXISTS display_name;
    END IF;

    -- Check and drop bio column
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'bio'
    ) THEN
        ALTER TABLE public.user_profiles DROP COLUMN IF EXISTS bio;
    END IF;

    -- Check and drop is_public column
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'is_public'
    ) THEN
        ALTER TABLE public.user_profiles DROP COLUMN IF EXISTS is_public;
    END IF;

    -- Check and drop addresses column if it exists
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'addresses'
    ) THEN
        ALTER TABLE public.user_profiles DROP COLUMN IF EXISTS addresses;
    END IF;
END
$$;

-- Add a comment to the table to document the simplification
COMMENT ON TABLE public.user_profiles IS 'User profiles table simplified to match the clean architecture UserProfile entity';
