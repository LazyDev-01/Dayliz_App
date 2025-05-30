# UserProfile Table Simplification Implementation

## Overview

This document describes the implementation of the UserProfile entity simplification in the Supabase database. The goal was to align the database schema with the simplified UserProfile entity in the clean architecture implementation.

## Changes Made

The following columns have been removed from the `user_profiles` table:

- `display_name`: Not needed as `fullName` is sufficient for user identification
- `bio`: Not needed for the current application requirements
- `is_public`: Not needed as all profiles are treated the same way
- `avatar_url`: Redundant with `profile_image_url`

## Implementation Approach

We used two approaches to implement these changes:

### 1. Direct SQL Migration

A SQL migration script was created and applied directly to the database using Supabase's migration system. The script:

1. Checks for dependencies (triggers and views) that might prevent column removal
2. Drops these dependencies if they exist
3. Migrates any data from `avatar_url` to `profile_image_url` if needed
4. Removes the unused columns
5. Recreates any views that were dropped, but with the simplified structure
6. Adds a comment to the table documenting the simplification

### 2. MCP Server Implementation

An MCP (Management Control Panel) server implementation was also created to provide a more controlled way to apply the changes. The MCP server:

1. Sets up helper functions for executing SQL and getting column information
2. Checks for dependencies that might prevent column removal
3. Handles these dependencies appropriately
4. Migrates data if needed
5. Removes the unused columns
6. Recreates any views that were dropped
7. Adds a comment to the table

## Challenges and Solutions

### Dependency Handling

The main challenge was handling dependencies on the columns we wanted to remove. We discovered that there was a trigger (`on_user_profile_save`) and a view (`user_profile_view`) that depended on the `display_name` column.

**Solution**: We implemented a two-step approach:
1. First, drop the dependencies
2. Then, remove the columns
3. Finally, recreate the dependencies with the simplified structure

### Data Migration

We needed to ensure that any data in the `avatar_url` column was migrated to `profile_image_url` before removing the column.

**Solution**: We implemented a data migration step that:
1. Checks if there's any data in `avatar_url`
2. If there is, copies it to `profile_image_url`
3. Only then removes the `avatar_url` column

## Verification

After applying the changes, we verified that:

1. The unused columns were successfully removed
2. The table structure now matches the simplified UserProfile entity
3. No data was lost during the migration
4. The application still works correctly with the simplified table

## Current Table Structure

The current structure of the `user_profiles` table is:

| Column Name       | Data Type                | Nullable | Description                           |
|-------------------|--------------------------|----------|---------------------------------------|
| id                | uuid                     | NO       | Primary key                           |
| user_id           | uuid                     | NO       | Foreign key to auth.users             |
| full_name         | text                     | YES      | User's full name                      |
| profile_image_url | text                     | YES      | URL to user's profile image           |
| date_of_birth     | date                     | YES      | User's date of birth                  |
| gender            | text                     | YES      | User's gender                         |
| last_updated      | timestamp with time zone | YES      | When the profile was last updated     |
| preferences       | jsonb                    | YES      | User preferences stored as JSON       |
| created_at        | timestamp with time zone | YES      | When the profile was created          |
| updated_at        | timestamp with time zone | YES      | When the profile was last updated     |

## Next Steps

1. Update any code that might still be referencing the removed columns
2. Update tests to reflect the simplified table structure
3. Consider similar simplifications for other entities if needed
