# DPDP Database Setup Guide

## Quick Setup for Testing

To fix the consent management system error, you need to create the required database tables in your Supabase project.

### Option 1: Run SQL Script in Supabase Dashboard

1. **Open Supabase Dashboard**
   - Go to your Supabase project dashboard
   - Navigate to the "SQL Editor" tab

2. **Execute the Schema Script**
   - Copy the contents of `docs/database/dpdp_consent_schema.sql`
   - Paste it into the SQL Editor
   - Click "Run" to execute the script

3. **Verify Tables Created**
   - Go to "Table Editor" tab
   - You should see these new tables:
     - `user_consents`
     - `consent_audit_log`
     - `data_correction_requests`
     - `data_deletion_requests`
     - `data_rights_audit_log`

### Option 2: Quick Test Tables (Minimal Setup)

If you just want to test the consent preferences screen quickly, run this minimal SQL:

```sql
-- Minimal tables for testing consent preferences
CREATE TABLE IF NOT EXISTS public.user_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    type TEXT NOT NULL,
    is_granted BOOLEAN NOT NULL DEFAULT false,
    granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ NULL,
    revoked_reason TEXT NULL,
    source TEXT NOT NULL,
    version TEXT NOT NULL DEFAULT '1.0.0',
    metadata JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;

-- Basic RLS policy
CREATE POLICY "Users can manage their own consents" ON public.user_consents
    FOR ALL USING (auth.uid() = user_id);

-- Audit log table
CREATE TABLE IF NOT EXISTS public.consent_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    action TEXT NOT NULL,
    consent_type TEXT NULL,
    consent_id UUID NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB NULL
);

-- Enable RLS for audit log
ALTER TABLE public.consent_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own audit logs" ON public.consent_audit_log
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert audit logs" ON public.consent_audit_log
    FOR INSERT WITH CHECK (true);
```

### Option 3: Test with Mock Data

After creating the tables, you can add some test consent data:

```sql
-- Insert test consent data for current user
-- Replace 'your-user-id' with actual user ID from auth.users table

INSERT INTO public.user_consents (user_id, type, is_granted, source, version) VALUES
('your-user-id', 'essential', true, 'onboarding', '1.0.0'),
('your-user-id', 'location', true, 'onboarding', '1.0.0'),
('your-user-id', 'marketing', false, 'settings', '1.0.0'),
('your-user-id', 'analytics', true, 'settings', '1.0.0');
```

## After Setup

Once you've created the database tables:

1. **Restart the app** to clear any cached errors
2. **Navigate to Profile → Privacy Preferences**
3. **The consent preferences screen should now load successfully**
4. **Test the "Manage Data Rights" link** to access the data rights screen

## Troubleshooting

### If you still get errors:

1. **Check table names** - Ensure tables are created in the `public` schema
2. **Verify RLS policies** - Make sure Row Level Security policies allow access
3. **Check user authentication** - Ensure you're logged in with a valid user
4. **Review Supabase logs** - Check the Supabase dashboard for detailed error messages

### Common Issues:

- **"relation does not exist"** - Tables not created or wrong schema
- **"permission denied"** - RLS policies too restrictive
- **"user_id null"** - Authentication issue or user provider not working

## Production Considerations

For production deployment:

1. **Use the full schema** from `docs/database/dpdp_consent_schema.sql`
2. **Set up proper backup policies**
3. **Configure monitoring and alerting**
4. **Review and test all RLS policies**
5. **Set up data retention policies**
6. **Configure audit log archiving**

## Next Steps

After the database is set up:

1. **Test consent management** - Grant/revoke different consent types
2. **Test data rights** - Try the export, correction, and deletion features
3. **Review audit logs** - Check that all actions are properly logged
4. **Implement backend services** - Connect the UI to actual data processing
5. **Add real user authentication** - Replace placeholder user IDs

The consent management system is now ready for testing and development!
