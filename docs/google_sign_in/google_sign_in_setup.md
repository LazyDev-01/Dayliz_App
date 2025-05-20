# Google Sign-In Setup Guide for Dayliz App

This document provides detailed instructions for setting up Google Sign-In with Supabase in the Dayliz App.

## Current Configuration

The app is currently configured with the following Google client IDs:

- **Web Client ID**: `your_web_client_id`
- **Android Client ID**: `your_android_client_id`
- **Project ID**: `your_project_id`

## Setup Steps

### 1. Supabase Configuration

1. Go to your Supabase project dashboard
2. Navigate to Authentication > Providers
3. Enable the Google provider
4. Enter the following credentials:
   - **Client ID**: `your_web_client_id` (Web client ID)
   - **Client Secret**: `your_client_secret`
5. Add the following Authorized Redirect URIs:
   - `https://your-supabase-project.supabase.co/auth/v1/callback`
   - `com.dayliz.dayliz_app://login`
6. Save changes

### 2. Google Cloud Platform Configuration

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to "APIs & Services" > "Credentials"
4. Find the Android OAuth client ID and edit it
5. Make sure the package name is set to `com.dayliz.dayliz_app`
6. Use the following SHA-1 certificate fingerprint for your development environment:
   ```
   SHA-1: YOUR_SHA1_FINGERPRINT
   ```
7. Add this SHA-1 fingerprint to the Android OAuth client
8. Find the Web OAuth client ID and edit it
9. Add the following authorized redirect URIs:
   - `https://your-supabase-project.supabase.co/auth/v1/callback`
   - `com.dayliz.dayliz_app://login`
10. Save changes

### 3. App Configuration

The app has been configured with the following files:

1. **google-services.json**: Located in `android/app/` with the correct client IDs and SHA-1 certificate fingerprint
2. **.env**: Contains the correct Google client IDs and redirect URIs
3. **AndroidManifest.xml**: Contains the proper intent filters for handling OAuth redirects
4. **GoogleRedirectActivity.kt**: Handles OAuth redirects from Supabase

> **Important**: Make sure your SHA-1 certificate fingerprint is added to both the google-services.json file and your Google Cloud Console project.

## Troubleshooting

### Common Issues

1. **"Server error occurred" message**
   - Make sure the Google OAuth provider is enabled in Supabase
   - Verify that the client IDs and client secret in Supabase match those in Google Cloud Console
   - Check that the SHA-1 fingerprint in Google Cloud Console matches your development environment
   - Ensure the package name in Google Cloud Console matches `com.dayliz.dayliz_app`

2. **Google Sign-In dialog appears but immediately closes**
   - This is often due to a SHA-1 fingerprint mismatch
   - Generate a new SHA-1 fingerprint and update it in Google Cloud Console

3. **Authentication works in debug but not in release**
   - You need to add the release SHA-1 fingerprint to Google Cloud Console
   - Generate it using:
     ```bash
     keytool -list -v -keystore your_release_keystore_path -alias your_key_alias
     ```

## Testing

To test Google Sign-In:

1. Run the app in debug mode
2. Navigate to the login screen
3. Tap the Google Sign-In button
4. Select a Google account
5. The app should successfully authenticate with Supabase

## Logs to Check

If you encounter issues, check the logs for the following tags:

- `[GoogleSignInService]`: Logs from the Google Sign-In service
- `[AuthService]`: Logs from the authentication service
- `GoogleRedirectActivity`: Logs from the Android redirect activity

These logs will help identify where the authentication process is failing.
