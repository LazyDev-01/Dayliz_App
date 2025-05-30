# Google Sign-In Test Plan

## Current Status
- ✅ Google OAuth Client ID configured: `897976702780-qdgua0j0nj5jm98kl6nuvu2s0b7gg24i.apps.googleusercontent.com`
- ✅ Android Client ID configured: `897976702780-n8uvora9fv89jqrrvbc80hui2ngs6ehf.apps.googleusercontent.com`
- ✅ Supabase redirect URI: `https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback`
- ❌ Google Client Secret: Not configured (needed for Supabase)
- ❓ Supabase Google Provider: Status unknown

## What We Need to Complete

### 1. Get Google Client Secret
- Go to [Google Cloud Console](https://console.cloud.google.com/)
- Navigate to "APIs & Services" > "Credentials"
- Find the OAuth 2.0 Client ID: `897976702780-qdgua0j0nj5jm98kl6nuvu2s0b7gg24i.apps.googleusercontent.com`
- Copy the Client Secret

### 2. Configure Supabase Google Provider
- Go to Supabase Dashboard > Authentication > Providers
- Enable Google provider
- Enter Client ID and Client Secret
- Set redirect URL to: `https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback`

### 3. Test the Implementation
- Try Google sign-in from the app
- Check logs for any errors
- Verify user creation in Supabase

## Expected Flow
1. User clicks "Sign up with Google"
2. Google OAuth popup/redirect opens
3. User signs in with Google account
4. Google redirects to Supabase with auth code
5. Supabase exchanges code for tokens
6. User is created/signed in to Supabase
7. App receives authenticated user
8. User is redirected to home screen

## Troubleshooting
If Google sign-in fails, check:
1. Google Cloud Console OAuth configuration
2. Supabase Google provider settings
3. Network connectivity
4. App logs for specific error messages
