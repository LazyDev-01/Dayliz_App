# Google Sign-In Troubleshooting Guide

This document provides comprehensive troubleshooting steps for Google Sign-In issues in the Dayliz App.

## Common Issues and Solutions

### 1. "Instance of 'ServerException'" Error

This generic error usually indicates a configuration issue between your app and Supabase.

**Solutions:**

1. **Check Supabase Configuration**:
   - Make sure the Google provider is enabled in Supabase
   - Verify that the correct Client ID and Client Secret are entered
   - Ensure the Callback URL is set to `https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback`

2. **Check URL Configuration**:
   - Set the Site URL to `com.dayliz.dayliz_app://login`
   - Add `com.dayliz.dayliz_app://login` to the Redirect URLs list

3. **Check Android Manifest**:
   - Ensure the deep link intent filter is properly configured
   - Make sure the package name matches your app's package name

### 2. Deep Link Handling Issues

If the app doesn't properly handle the redirect after Google authentication:

**Solutions:**

1. **Check AndroidManifest.xml**:
   - Make sure you have the correct intent filter for `com.dayliz.dayliz_app://login`
   - Ensure the `flutter_web_auth_2` CallbackActivity is properly configured

2. **Test Deep Link Handling**:
   - Use the "Test Deep Link" button in the debug screen
   - Check if your app responds to the deep link

3. **Check Google Cloud Console**:
   - Make sure the authorized redirect URIs include both:
     - `https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback`
     - `com.dayliz.dayliz_app://login`

### 3. Google Provider Not Configured

If the debug screen shows "Google Provider Not Configured":

**Solutions:**

1. **Enable Google Provider in Supabase**:
   - Go to Authentication > Providers > Google
   - Toggle "Enable Sign in with Google"
   - Enter your Client ID and Client Secret
   - Set the Callback URL to `https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback`

2. **Use the Debug Screen**:
   - Try the "Enable Google Provider" button
   - Check if the provider is enabled after refreshing

## Step-by-Step Verification

Follow these steps to systematically verify your configuration:

### 1. Verify Environment Variables

Make sure your `.env` file contains:

```
SUPABASE_URL=https://zdezerezpbeuebnompyj.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GOOGLE_CLIENT_ID=897976702780-qdgua0j0nj5jm98kl6nuvu2s0b7gg24i.apps.googleusercontent.com
GOOGLE_REDIRECT_URI=com.dayliz.dayliz_app://login
```

### 2. Verify Supabase Configuration

In Supabase dashboard:

1. **Authentication > URL Configuration**:
   - Site URL: `com.dayliz.dayliz_app://login`
   - Redirect URLs: Add `com.dayliz.dayliz_app://login`

2. **Authentication > Providers > Google**:
   - Enable Sign in with Google: ON
   - Client ID: `897976702780-qdgua0j0nj5jm98kl6nuvu2s0b7gg24i.apps.googleusercontent.com`
   - Client Secret: Your client secret
   - Callback URL: `https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback`

### 3. Verify Google Cloud Console Configuration

In Google Cloud Console:

1. **Web Client**:
   - Authorized JavaScript origins: `https://zdezerezpbeuebnompyj.supabase.co`
   - Authorized redirect URIs: `https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback`

2. **Android Client**:
   - Package name: `com.dayliz.dayliz_app`
   - SHA-1 certificate fingerprint: Your SHA-1 fingerprint

### 4. Verify Android Manifest

Check that your `AndroidManifest.xml` has:

```xml
<intent-filter android:label="flutter_web_auth_2">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="com.dayliz.dayliz_app"
        android:host="login" />
</intent-filter>
```

## Advanced Troubleshooting

If you're still experiencing issues:

1. **Clear App Data and Cache**:
   - Go to Settings > Apps > Dayliz > Storage
   - Clear data and cache
   - Restart the app

2. **Check Logs**:
   - Use the debug screen to see detailed error messages
   - Look for specific error codes or messages

3. **Try Direct OAuth Flow**:
   - The debug screen uses a direct OAuth flow
   - This can help identify if the issue is with the app or with Supabase

4. **Check Network Connectivity**:
   - Make sure your device has a stable internet connection
   - Try on both Wi-Fi and mobile data

## Getting Help

If you're still experiencing issues after trying all these steps, please contact support with:

1. Screenshots of the debug screen
2. Specific error messages
3. Steps you've already tried
4. Device and OS version information
