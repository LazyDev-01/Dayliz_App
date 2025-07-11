# Create Test Agent User

After running the `create_test_agent.sql` script to create the agents table, follow these steps to create a test agent user:

## Step 1: Create the Database Table

1. Open your Supabase project dashboard
2. Go to the "SQL Editor" tab
3. Copy and paste the contents of `scripts/create_test_agent.sql`
4. Click "Run" to execute the script

This will create the `agents` table with proper RLS policies.

## Step 2: Create Test Agent User

Since we can't directly insert into `auth.users`, we need to use the agent app's registration flow or create the user manually:

### Option A: Use Agent Registration (Recommended)

1. Open the agent app
2. Go to the registration screen
3. Fill in the registration form with these details:
   - Full Name: `Test Agent`
   - Phone: `+91 9876543210`
   - Email: `testagent@dayliz.com`
   - Work Type: `full_time`
   - Age: `25`
   - Gender: `male`
   - Address: `Test Address, Guwahati`
   - Vehicle Type: `bike`
   - Password: `test123`

4. After registration, you'll get a temporary agent ID
5. You can then manually update the database to set the agent ID to `DLZ-AG-GHY-00001` and status to `active`

### Option B: Manual Creation via Supabase Auth

1. Go to Supabase Dashboard > Authentication > Users
2. Click "Add User"
3. Create a user with:
   - Email: `DLZ-AG-GHY-00001@dayliz.internal`
   - Password: `test123`
   - Auto Confirm User: Yes

4. After the user is created, note the User ID
5. Go to SQL Editor and run:

```sql
INSERT INTO agents (
    user_id,
    agent_id,
    full_name,
    phone,
    email,
    assigned_zone,
    status,
    total_deliveries,
    total_earnings,
    is_verified
) VALUES (
    'USER_ID_FROM_STEP_4',  -- Replace with actual user ID
    'DLZ-AG-GHY-00001',
    'Test Agent',
    '+91 9876543210',
    'testagent@dayliz.com',
    'Guwahati Zone 1',
    'active',
    0,
    0.00,
    true
);
```

## Step 3: Test Login

After creating the test agent, you can login with:
- **Agent ID**: `DLZ-AG-GHY-00001`
- **Password**: `test123`

## Troubleshooting

If you get "invalid credentials" error:
1. Check that the user exists in Supabase Auth
2. Check that the agent record exists in the agents table
3. Verify the agent status is 'active'
4. Make sure the user_id in agents table matches the auth user ID
