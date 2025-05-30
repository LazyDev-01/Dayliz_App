import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Create Supabase client with service role key to access auth.users
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Get all users from auth.users
    const { data: users, error: usersError } = await supabaseAdmin.auth.admin.listUsers();

    if (usersError) {
      console.error('Error fetching users:', usersError);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch users' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    const results = [];
    let updatedCount = 0;
    let skippedCount = 0;

    // Process each user
    for (const user of users.users) {
      try {
        // Skip if display_name is already set
        if (user.user_metadata?.display_name) {
          skippedCount++;
          results.push({
            userId: user.id,
            email: user.email,
            status: 'skipped',
            reason: 'display_name already exists'
          });
          continue;
        }

        // Get display name from user_metadata or email
        const displayName = user.user_metadata?.name || 
                           user.user_metadata?.full_name || 
                           user.email?.split('@')[0] || 
                           'User';

        // Update the user's metadata
        const { data: updatedUser, error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
          user.id,
          {
            user_metadata: {
              ...user.user_metadata,
              display_name: displayName,
              name: user.user_metadata?.name || displayName,
              full_name: user.user_metadata?.full_name || displayName,
            }
          }
        );

        if (updateError) {
          console.error(`Error updating user ${user.id}:`, updateError);
          results.push({
            userId: user.id,
            email: user.email,
            status: 'error',
            error: updateError.message
          });
        } else {
          updatedCount++;
          results.push({
            userId: user.id,
            email: user.email,
            status: 'updated',
            displayName: displayName
          });
        }

      } catch (error) {
        console.error(`Error processing user ${user.id}:`, error);
        results.push({
          userId: user.id,
          email: user.email,
          status: 'error',
          error: error.message
        });
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true,
        summary: {
          totalUsers: users.users.length,
          updated: updatedCount,
          skipped: skippedCount,
          errors: results.filter(r => r.status === 'error').length
        },
        results: results
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );

  } catch (error) {
    console.error('Error in fix-existing-display-names function:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  }
});
