# Google Sign-In Troubleshooting Guide

If you're experiencing issues with Google Sign-In in the Dayliz App, follow this troubleshooting guide to resolve common problems.

## Common Error: "Server error occurred"

This error typically appears when there's an issue with the OAuth configuration or when the app can't communicate with Google's authentication servers.

### Solution Steps:

1. **Check Google Cloud Console Configuration**:
   - Verify that your project is properly set up in Google Cloud Console
   - Ensure that the OAuth consent screen is configured
   - Check that the correct scopes are enabled (email, profile, openid)

2. **Verify Client ID**:
   - Make sure your Client ID is correctly set in the `.env` file
   - Check that the Client ID matches the one in Google Cloud Console
   - Ensure the Client ID is being properly loaded by the app

3. **Check SHA-1 Certificate Fingerprint**:
   - Verify that the correct SHA-1 fingerprint is added to your Google Cloud project
   - For debug builds, get the fingerprint with:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - For release builds, use your release keystore

4. **Verify Android Configuration**:
   - Check that the package name in Google Cloud Console matches your app's package name
   - Ensure the `web_client_id.xml` file has the correct Client ID
   - Verify that the build.gradle file has the correct manifestPlaceholders

5. **Check Supabase Configuration**:
   - Ensure Google OAuth is enabled in Supabase
   - Verify that the Client ID and Client Secret are correctly set
   - Check that the redirect URI is properly configured

## Debugging Steps

1. **Enable Verbose Logging**:
   - Add the following code to your app to see detailed logs:
     ```dart
     GoogleSignIn.enableDebugLogging(true);
     ```

2. **Check Logcat for Errors**:
   - Connect your device and run:
     ```bash
     adb logcat | grep -E "GoogleSignIn|Supabase|Auth"
     ```

3. **Test with a Different Google Account**:
   - Sometimes account-specific issues can occur
   - Try signing in with a different Google account

4. **Clear App Data**:
   - Go to Settings > Apps > Dayliz App > Storage > Clear Data
   - This will reset any cached authentication data

5. **Check Internet Connection**:
   - Ensure your device has a stable internet connection
   - Try connecting to a different network

## Common Error Messages and Solutions

### "The client ID provided is invalid"
- Double-check your Client ID in the `.env` file
- Ensure it matches the one in Google Cloud Console

### "Sign in failed. Is the Google Services file missing?"
- Make sure you've added the `google-services.json` file to your project
- Verify that the file contains the correct configuration

### "Error 10: Unknown error"
- This is a generic Google Play Services error
- Try updating Google Play Services on your device
- Restart your device and try again

### "Error 12500: Sign in failed"
- This usually means the user cancelled the sign-in process
- No action needed, but you might want to improve the UX

### "Error 12501: Sign in canceled"
- The user cancelled the sign-in process
- No action needed

## Still Having Issues?

If you're still experiencing problems after following these steps:

1. Check the Google Sign-In API documentation for any recent changes
2. Verify that all dependencies are up to date
3. Try implementing a minimal test app to isolate the issue
4. Check for any firewall or network restrictions that might be blocking Google authentication
5. Ensure your Google Cloud project has billing enabled (if required)

Remember to always check the logs for detailed error messages, as they often provide specific information about what's going wrong.
