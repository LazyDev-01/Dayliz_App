# Google OAuth Setup Guide for Dayliz App

This guide will walk you through the process of setting up Google OAuth for the Dayliz App, allowing users to sign in with their Google accounts.

## Step 1: Create OAuth Credentials in Google Cloud Console

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select your existing project
3. Navigate to "APIs & Services" > "Credentials"
4. Click "Create Credentials" > "OAuth client ID"
5. Select "Web application" as the application type
6. Add authorized redirect URIs:
   - For development: `http://localhost:54321/auth/v1/callback`
   - For production: `https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback`
7. Save and note your Client ID and Client Secret

## Step 2: Configure Supabase OAuth Provider

1. Go to your Supabase project dashboard
2. Navigate to "Authentication" > "Providers"
3. Find "Google" and enable it
4. Enter the Client ID and Client Secret from Google Cloud Console
5. Save the configuration

## Step 3: Configure Android Platform

For Android, you need to add the SHA-1 certificate fingerprint:

1. Get your SHA-1 certificate fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   For release builds, use your release keystore.

2. In the Google Cloud Console, go to your project
3. Navigate to "APIs & Services" > "Credentials"
4. Edit your OAuth 2.0 Client ID
5. Under "Android applications", click "ADD"
6. Enter your package name (e.g., `com.dayliz.app`)
7. Enter your SHA-1 certificate fingerprint
8. Save the changes

## Step 4: Configure iOS Platform

For iOS, you need to add your bundle identifier:

1. In the Google Cloud Console, go to your project
2. Navigate to "APIs & Services" > "Credentials"
3. Edit your OAuth 2.0 Client ID
4. Under "iOS applications", click "ADD"
5. Enter your bundle ID (e.g., `com.dayliz.app`)
6. Save the changes

## Step 5: Update Your Flutter App

1. Add the required dependencies to your `pubspec.yaml`:
   ```yaml
   dependencies:
     google_sign_in: ^6.1.0
   ```

2. For Android, update your `android/app/build.gradle`:
   ```gradle
   defaultConfig {
       // ...
       manifestPlaceholders += [
           'com.google.android.gms.client_id': 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'
       ]
   }
   ```

3. For iOS, update your `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```

## Step 6: Implement Google Sign-In in Your App

The code for Google sign-in has already been added to the app. Once you complete the setup above, the "Sign in with Google" button should work correctly.

## Troubleshooting

If you encounter issues with Google sign-in:

1. Check that your Client ID and Client Secret are correctly configured in Supabase
2. Verify that your redirect URIs are correctly set up in Google Cloud Console
3. For Android, ensure your SHA-1 fingerprint is correct
4. For iOS, ensure your bundle ID is correct
5. Check the app logs for any error messages

## Next Steps

After setting up Google OAuth, you may want to:

1. Test the sign-in flow on different devices and platforms
2. Add additional social login providers if needed
3. Customize the user profile data you collect from Google
4. Implement account linking if a user signs in with Google but already has an account with the same email
