# UserProfile Entity Simplification

## Overview

This document explains the simplification of the UserProfile entity in the clean architecture implementation and the corresponding changes to the database schema.

## Changes Made

### 1. UserProfile Entity Simplification

The UserProfile entity has been simplified to include only the essential fields needed for the application. The following fields have been removed:

- `displayName`: Not needed as `fullName` is sufficient for user identification
- `bio`: Not needed for the current application requirements
- `isPublic`: Not needed as all profiles are treated the same way
- `addresses`: Addresses are now handled separately through the Address entity and repository

### 2. Database Schema Alignment

The database schema has been updated to match the simplified UserProfile entity. A migration script has been created to remove the unused columns from the `user_profiles` table:

```sql
-- Migration to simplify user_profiles table to match the UserProfile entity
ALTER TABLE public.user_profiles 
DROP COLUMN IF EXISTS display_name,
DROP COLUMN IF EXISTS bio,
DROP COLUMN IF EXISTS is_public,
DROP COLUMN IF EXISTS addresses;
```

### 3. Code Updates

The following code files have been updated to reflect the simplified UserProfile entity:

- `lib/domain/entities/user_profile.dart`: Removed unused fields
- `lib/data/models/user_profile_model.dart`: Updated to match the entity
- `lib/data/repositories/user_profile_repository_impl.dart`: Updated to handle the simplified entity
- `lib/data/repositories/user_profile_repository_impl_updated.dart`: Updated to handle the simplified entity
- `lib/data/datasources/auth_supabase_data_source.dart`: Updated profile creation
- `lib/data/datasources/auth_supabase_data_source_new.dart`: Updated profile creation
- `lib/data/datasources/auth_supabase_data_source_fixed.dart`: Updated profile creation

### 4. Documentation Updates

The following documentation files have been updated to reflect the changes:

- `docs/database/entity_database_mapping.md`: Updated to show the simplified UserProfile entity
- `docs/database/migrations/user_profile_simplification.sql`: Added migration script

## Rationale

The simplification of the UserProfile entity was done to:

1. **Reduce Complexity**: Remove fields that are not needed for the current application requirements
2. **Improve Maintainability**: Simplify the code and make it easier to understand and maintain
3. **Align with Database**: Ensure the entity matches the database schema
4. **Follow Clean Architecture Principles**: Keep the domain layer focused on essential business logic

## Impact

This change has no impact on existing functionality as the removed fields were not being used in the application. The simplification makes the code more maintainable and easier to understand.

## Next Steps

1. Apply the database migration script to remove the unused columns from the `user_profiles` table
2. Update any tests that might be affected by the changes
3. Continue with the implementation of other features based on the simplified UserProfile entity
