import "jsr:@supabase/functions-js/edge-runtime.d.ts";

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
    const { clientId, clientSecret } = await req.json();

    if (!clientId || !clientSecret) {
      return new Response(
        JSON.stringify({ 
          error: 'Client ID and Client Secret are required',
          instructions: 'Get these from Google Cloud Console > APIs & Services > Credentials'
        }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // Instructions for manual setup since we can't directly configure via API
    const setupInstructions = {
      success: true,
      message: 'Google OAuth credentials received. Please complete setup manually.',
      steps: [
        {
          step: 1,
          title: 'Go to Supabase Dashboard',
          url: 'https://supabase.com/dashboard/project/zdezerezpbeuebnompyj',
          action: 'Navigate to your project dashboard'
        },
        {
          step: 2,
          title: 'Open Authentication Settings',
          path: 'Authentication → Providers',
          action: 'Click on Authentication in the sidebar, then Providers'
        },
        {
          step: 3,
          title: 'Configure Google Provider',
          action: 'Find Google in the list and click to configure',
          settings: {
            enabled: true,
            clientId: clientId,
            clientSecret: '[PROVIDED]',
            redirectUrl: 'https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback'
          }
        },
        {
          step: 4,
          title: 'Save Configuration',
          action: 'Click Save to enable Google authentication'
        }
      ],
      testInstructions: [
        'After saving, test Google sign-in from your app',
        'Check the browser console for any errors',
        'Verify users are created in Authentication → Users'
      ],
      credentials: {
        clientId: clientId,
        clientSecretLength: clientSecret.length,
        redirectUrl: 'https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback'
      }
    };

    return new Response(
      JSON.stringify(setupInstructions),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );

  } catch (error) {
    console.error('Error in setup-google-auth function:', error);
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  }
});
