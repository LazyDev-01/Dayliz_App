/**
 * MCP Server implementation for simplifying the user_profiles table
 * This script removes unused columns from the user_profiles table to match the simplified UserProfile entity
 */

const simplifyUserProfilesTable = async (supabase) => {
  console.log('Starting user_profiles table simplification...');

  try {
    // Check if columns exist before attempting to drop them
    const { data: columns, error: columnsError } = await supabase.rpc('get_columns_info', {
      p_table_name: 'user_profiles',
      p_schema_name: 'public'
    });

    if (columnsError) {
      console.error('Error checking columns:', columnsError);
      return { success: false, error: columnsError };
    }

    // Get column names
    const columnNames = columns.map(col => col.column_name);

    // First, check for dependencies that might prevent column removal
    console.log('Checking for dependencies...');

    // Check for triggers
    const checkTriggersQuery = `
      SELECT tgname FROM pg_trigger
      WHERE tgrelid = 'public.user_profiles'::regclass
    `;

    const { data: triggers, error: triggersError } = await supabase.rpc('execute_sql_with_results', {
      sql: checkTriggersQuery
    });

    if (triggersError) {
      console.error('Error checking triggers:', triggersError);
      // Continue anyway, we'll handle errors during column removal
    } else if (triggers && triggers.length > 0) {
      console.log(`Found ${triggers.length} triggers on user_profiles table`);

      // Drop triggers that might depend on columns we want to remove
      for (const trigger of triggers) {
        console.log(`Dropping trigger: ${trigger.tgname}`);

        const dropTriggerQuery = `
          DROP TRIGGER IF EXISTS ${trigger.tgname} ON public.user_profiles
        `;

        const { error: dropTriggerError } = await supabase.rpc('execute_sql', {
          sql: dropTriggerQuery
        });

        if (dropTriggerError) {
          console.error(`Error dropping trigger ${trigger.tgname}:`, dropTriggerError);
          // Continue anyway, we'll handle errors during column removal
        }
      }
    }

    // Check for views
    const checkViewsQuery = `
      SELECT viewname FROM pg_views
      WHERE schemaname = 'public' AND viewname = 'user_profile_view'
    `;

    const { data: views, error: viewsError } = await supabase.rpc('execute_sql_with_results', {
      sql: checkViewsQuery
    });

    if (viewsError) {
      console.error('Error checking views:', viewsError);
      // Continue anyway, we'll handle errors during column removal
    } else if (views && views.length > 0) {
      console.log(`Found ${views.length} views that might depend on user_profiles table`);

      // Drop views that might depend on columns we want to remove
      for (const view of views) {
        console.log(`Dropping view: ${view.viewname}`);

        const dropViewQuery = `
          DROP VIEW IF EXISTS public.${view.viewname}
        `;

        const { error: dropViewError } = await supabase.rpc('execute_sql', {
          sql: dropViewQuery
        });

        if (dropViewError) {
          console.error(`Error dropping view ${view.viewname}:`, dropViewError);
          // Continue anyway, we'll handle errors during column removal
        }
      }
    }

    // Now we can proceed with column removal
    console.log('Removing unused columns...');

    // Check for avatar_url (we'll keep profile_image_url as per the entity)
    if (columnNames.includes('avatar_url')) {
      // First check if there's any data in avatar_url that needs to be migrated
      const { data: avatarData, error: avatarError } = await supabase
        .from('user_profiles')
        .select('id, avatar_url')
        .not('avatar_url', 'is', null);

      if (avatarError) {
        console.error('Error checking avatar_url data:', avatarError);
      } else if (avatarData && avatarData.length > 0) {
        // Migrate data from avatar_url to profile_image_url
        console.log(`Migrating ${avatarData.length} avatar_url values to profile_image_url`);

        for (const row of avatarData) {
          const { error: updateError } = await supabase
            .from('user_profiles')
            .update({ profile_image_url: row.avatar_url })
            .eq('id', row.id);

          if (updateError) {
            console.error(`Error migrating avatar_url for user ${row.id}:`, updateError);
          }
        }
      }
    }

    // Remove columns one by one to better handle errors
    const columnsToRemove = ['display_name', 'bio', 'is_public', 'avatar_url'];

    for (const column of columnsToRemove) {
      if (columnNames.includes(column)) {
        console.log(`Removing ${column} column...`);

        const dropColumnQuery = `
          ALTER TABLE public.user_profiles DROP COLUMN IF EXISTS ${column}
        `;

        const { error: dropColumnError } = await supabase.rpc('execute_sql', {
          sql: dropColumnQuery
        });

        if (dropColumnError) {
          console.error(`Error dropping column ${column}:`, dropColumnError);
          // Continue with other columns
        } else {
          console.log(`Successfully removed ${column} column`);
        }
      }
    }

    // Recreate views if they existed
    if (views && views.length > 0) {
      console.log('Recreating views with simplified structure...');

      // Recreate user_profile_view if it existed
      if (views.some(view => view.viewname === 'user_profile_view')) {
        console.log('Recreating user_profile_view...');

        const createViewQuery = `
          CREATE OR REPLACE VIEW public.user_profile_view AS
          SELECT
            id,
            user_id,
            full_name,
            profile_image_url,
            date_of_birth,
            gender,
            last_updated,
            preferences,
            created_at,
            updated_at
          FROM public.user_profiles
        `;

        const { error: createViewError } = await supabase.rpc('execute_sql', {
          sql: createViewQuery
        });

        if (createViewError) {
          console.error('Error recreating user_profile_view:', createViewError);
          // Not critical, so continue
        } else {
          console.log('Successfully recreated user_profile_view');
        }
      }
    }

    // Add comment to document the simplification
    const commentQuery = `COMMENT ON TABLE public.user_profiles IS 'User profiles table simplified to match the clean architecture UserProfile entity'`;

    const { error: commentError } = await supabase.rpc('execute_sql', {
      sql: commentQuery
    });

    if (commentError) {
      console.error('Error adding comment to table:', commentError);
      // Not critical, so continue
    }

    console.log('User profiles table simplification completed successfully');
    return { success: true };
  } catch (error) {
    console.error('Unexpected error during user_profiles simplification:', error);
    return { success: false, error };
  }
};

module.exports = {
  simplifyUserProfilesTable
};
