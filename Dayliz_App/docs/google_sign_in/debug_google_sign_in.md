# Debugging Google Sign-In

If you're experiencing issues with Google Sign-In in the Dayliz App, follow these steps to diagnose and fix the problem.

## Running the Debug Screen

There are three ways to access the Google Sign-In debug screen:

### 1. From the Login Screen

1. Launch the app
2. Go to the login screen
3. Tap the orange "Debug Google Sign-In" button at the bottom of the screen

### 2. Using the Direct URL

1. Launch the app
2. Navigate to `/debug/google-sign-in` (you can use deep linking or navigate programmatically)

### 3. Using the Debug Launcher (Recommended)

For the most direct approach:

1. Open your terminal/command prompt
2. Navigate to the project directory
3. Run the debug launcher directly:

```bash
flutter run -t lib/debug_launcher.dart
```

This will launch a simplified app that goes directly to the debug screen, bypassing any other initialization issues.

## Using the Debug Screen

The debug screen provides several useful features:

1. **Configuration Information**: Shows your current Supabase and Google Sign-In configuration
2. **Test Google Sign-In**: Tests the Google Sign-In flow and shows detailed error messages
3. **Enable Google Provider**: If Google provider is not enabled in Supabase, this button will try to enable it

## Common Issues and Solutions

### 1. "Google provider is not configured in Supabase"

**Solution**:
- Go to your Supabase dashboard
- Navigate to Authentication > Providers > Google
- Enable the Google provider
- Add your Web client ID and client secret
- Add `com.dayliz.dayliz_app://login` as a redirect URL

### 2. "Invalid client ID" or "Client ID not found"

**Solution**:
- Check your `.env` file to ensure `GOOGLE_CLIENT_ID` is set correctly
- Make sure you're using the Web client ID, not the Android client ID

### 3. "SHA-1 fingerprint mismatch"

**Solution**:
- Go to Google Cloud Console
- Navigate to APIs & Services > Credentials
- Edit your Android OAuth client
- Add your SHA-1 fingerprint: `8E:C5:58:DD:C3:58:FB:43:32:53:39:E7:F8:74:D8:A6:E4:AE:C6:18`

### 4. "Redirect URI mismatch"

**Solution**:
- In Google Cloud Console, add `https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback` to your Web client
- In Supabase URL Configuration, add `com.dayliz.dayliz_app://login` to the redirect URLs
- Set the Site URL to `com.dayliz.dayliz_app://login`

## Logs to Check

If you're still having issues, check the logs for the following tags:

- `[GoogleSignInService]`: Logs from the Google Sign-In service
- `[AuthSupabaseDataSource]`: Logs from the authentication data source
- `[SupabaseConfigChecker]`: Logs from the configuration checker

These logs will help identify where the authentication process is failing.
