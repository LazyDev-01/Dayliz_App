# MCP Server for Dayliz App Database Management

This directory contains the MCP (Management Control Panel) server implementation for managing the Dayliz App database schema in Supabase.

## Overview

The MCP server provides a controlled way to apply database migrations and schema changes to the Supabase database. It ensures that changes are applied consistently and safely.

## Current Migrations

### User Profile Simplification

This migration simplifies the `user_profiles` table by removing unused columns to match the simplified UserProfile entity in the clean architecture implementation. The following columns are removed:

- `display_name`
- `bio`
- `is_public`
- `avatar_url` (after migrating any data to `profile_image_url`)

## Prerequisites

- Node.js (v14 or higher)
- Supabase project with appropriate permissions
- Supabase service key with admin privileges

## Installation

1. Navigate to this directory:
   ```
   cd docs/database
   ```

2. Install dependencies:
   ```
   npm install
   ```

## Usage

### Running Migrations

You can run the migrations using the provided script:

```bash
# Set Supabase credentials as environment variables
export SUPABASE_URL=https://your-project-id.supabase.co
export SUPABASE_SERVICE_KEY=your-service-key

# Run the migration
npm run migrate
```

Alternatively, you can provide the credentials as command line arguments:

```bash
npm run migrate -- --url https://your-project-id.supabase.co --key your-service-key
```

### Adding New Migrations

To add a new migration:

1. Create a new migration file in the `migrations` directory
2. Import and add the migration to the `runMigrations` function in `mcp_server.js`

## File Structure

- `mcp_server.js` - Main server implementation
- `run_migration.js` - Script to run migrations
- `migrations/` - Directory containing migration files
  - `user_profile_simplification_mcp.js` - Migration to simplify the user_profiles table

## Troubleshooting

If you encounter issues:

1. Check that your Supabase credentials are correct
2. Ensure you have the necessary permissions
3. Check the console output for detailed error messages

## Security Considerations

- Never commit your Supabase service key to version control
- Use environment variables or secure secret management for credentials
- The MCP server uses security definer functions to ensure proper permission handling
