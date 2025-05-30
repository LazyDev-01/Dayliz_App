/**
 * MCP Server for Supabase Database Management
 * This server handles database migrations and schema changes for the Dayliz App
 */

const { createClient } = require('@supabase/supabase-js');
const { simplifyUserProfilesTable } = require('./migrations/user_profile_simplification_mcp');

// Initialize Supabase client
const initSupabaseClient = (url, key) => {
  return createClient(url, key);
};

// Create stored procedures for executing SQL and getting column information
const setupHelperFunctions = async (supabase) => {
  console.log('Setting up helper functions...');

  // Create function to execute SQL statements
  const executeSqlFunction = `
    CREATE OR REPLACE FUNCTION execute_sql(sql text)
    RETURNS void
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $$
    BEGIN
      EXECUTE sql;
    END;
    $$;
  `;

  // Create function to execute SQL statements and return results
  const executeSqlWithResultsFunction = `
    CREATE OR REPLACE FUNCTION execute_sql_with_results(sql text)
    RETURNS SETOF json
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $$
    BEGIN
      RETURN QUERY EXECUTE sql;
    END;
    $$;
  `;

  // Create function to get column information
  const getColumnsInfoFunction = `
    CREATE OR REPLACE FUNCTION get_columns_info(p_table_name text, p_schema_name text DEFAULT 'public')
    RETURNS TABLE (
      table_name text,
      column_name text,
      data_type text,
      is_nullable boolean
    )
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $$
    BEGIN
      RETURN QUERY
      SELECT
        c.table_name::text,
        c.column_name::text,
        c.data_type::text,
        (c.is_nullable = 'YES')::boolean
      FROM
        information_schema.columns c
      WHERE
        c.table_schema = p_schema_name
        AND c.table_name = p_table_name
      ORDER BY
        c.ordinal_position;
    END;
    $$;
  `;

  try {
    // Execute the function creation statements
    const { error: executeSqlError } = await supabase.rpc('execute_sql', {
      sql: executeSqlFunction
    });

    if (executeSqlError) {
      console.error('Error creating execute_sql function:', executeSqlError);
      // Try to create it directly
      const { error: directError } = await supabase.query(executeSqlFunction);
      if (directError) {
        console.error('Error creating execute_sql function directly:', directError);
        return false;
      }
    }

    const { error: executeSqlWithResultsError } = await supabase.rpc('execute_sql', {
      sql: executeSqlWithResultsFunction
    });

    if (executeSqlWithResultsError) {
      console.error('Error creating execute_sql_with_results function:', executeSqlWithResultsError);
      // Try to create it directly
      const { error: directError } = await supabase.query(executeSqlWithResultsFunction);
      if (directError) {
        console.error('Error creating execute_sql_with_results function directly:', directError);
        return false;
      }
    }

    const { error: getColumnsInfoError } = await supabase.rpc('execute_sql', {
      sql: getColumnsInfoFunction
    });

    if (getColumnsInfoError) {
      console.error('Error creating get_columns_info function:', getColumnsInfoError);
      // Try to create it directly
      const { error: directError } = await supabase.query(getColumnsInfoFunction);
      if (directError) {
        console.error('Error creating get_columns_info function directly:', directError);
        return false;
      }
    }

    console.log('Helper functions set up successfully');
    return true;
  } catch (error) {
    console.error('Unexpected error setting up helper functions:', error);
    return false;
  }
};

// Main function to run migrations
const runMigrations = async (supabaseUrl, supabaseKey) => {
  console.log('Initializing MCP server...');

  const supabase = initSupabaseClient(supabaseUrl, supabaseKey);

  // Set up helper functions
  const helpersSetup = await setupHelperFunctions(supabase);
  if (!helpersSetup) {
    console.error('Failed to set up helper functions. Aborting migrations.');
    return { success: false, error: 'Failed to set up helper functions' };
  }

  // Run the user_profiles simplification migration
  console.log('Running user_profiles simplification migration...');
  const simplifyResult = await simplifyUserProfilesTable(supabase);

  if (!simplifyResult.success) {
    console.error('Failed to simplify user_profiles table:', simplifyResult.error);
    return { success: false, error: simplifyResult.error };
  }

  console.log('All migrations completed successfully');
  return { success: true };
};

// Export the main function
module.exports = {
  runMigrations
};

// If this script is run directly, execute the migrations
if (require.main === module) {
  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

  if (!supabaseUrl || !supabaseKey) {
    console.error('SUPABASE_URL and SUPABASE_SERVICE_KEY environment variables must be set');
    process.exit(1);
  }

  runMigrations(supabaseUrl, supabaseKey)
    .then(result => {
      if (result.success) {
        console.log('MCP server completed successfully');
        process.exit(0);
      } else {
        console.error('MCP server failed:', result.error);
        process.exit(1);
      }
    })
    .catch(error => {
      console.error('Unexpected error in MCP server:', error);
      process.exit(1);
    });
}
