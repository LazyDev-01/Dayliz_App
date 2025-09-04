# 🚀 Google Sign-In v7.x Setup & Configuration Guide

## ✅ Current Status After v7.x Migration

- ✅ **Google Sign-In v7.x API**: Fully implemented with proper authentication flow
- ✅ **Manual State Management**: Implemented to replace removed `currentUser` property
- ✅ **Error Handling**: Updated for new `GoogleSignInException` types
- ✅ **Authorization Flow**: Implemented separate authentication and authorization steps
- ❌ **Google Cloud Console**: OAuth client configuration missing (CRITICAL)
- ❌ **Environment Variables**: Android Client ID not configured

## 🎯 Critical Issues to Fix

### 1. Missing OAuth Client Configuration
The `google-services.json` file has an empty `oauth_client` array, which prevents Google Sign-In from working.

### 2. Missing Android Client ID
The `.env` file has `GOOGLE_ANDROID_CLIENT_ID=REPLACE_WITH_NEW_GOOGLE_ANDROID_CLIENT_ID`

## 🛠️ Step-by-Step Configuration

### Step 1: Configure Google Cloud Console

1. **Go to Google Cloud Console**:
   - Visit: https://console.cloud.google.com/
   - Select your project: `dayliz-mobile-services`

2. **Enable Google Sign-In API**:
   - Go to "APIs & Services" > "Library"
   - Search for "Google Sign-In API" 
   - Click "Enable" if not already enabled

3. **Configure OAuth Consent Screen**:
   - Go to "APIs & Services" > "OAuth consent screen"
   - Choose "External" user type
   - Fill in required fields:
     - App name: `Dayliz`
     - User support email: `dayliz.business@gmail.com`
     - Developer contact: `dayliz.business@gmail.com`
   - Add scopes: `email`, `profile`
   - Save and continue

4. **Create/Update OAuth 2.0 Client ID**:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client ID"
   - Application type: "Android"
   - Name: `Dayliz Android App`
   - Package name: `com.dayliz.app`
   - SHA-1 certificate fingerprint: (see Step 2 below)

### Step 2: Get SHA-1 Certificate Fingerprint

Run this command in your project root:

```bash
# For debug certificate (development)
cd apps/mobile/android
./gradlew signingReport

# Look for the SHA1 fingerprint under "Variant: debug"
# Copy the SHA1 value (format: XX:XX:XX:XX:...)
```

### Step 3: Update google-services.json

1. **Download New Configuration**:
   - In Google Cloud Console, go to "Project Settings"
   - Download the updated `google-services.json`
   - Replace `apps/mobile/android/app/google-services.json`

2. **Verify OAuth Client Configuration**:
   The new file should have an `oauth_client` array like this:
   ```json
   {
     "oauth_client": [
       {
         "client_id": "YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com",
         "client_type": 1,
         "android_info": {
           "package_name": "com.dayliz.app",
           "certificate_hash": "YOUR_SHA1_HASH"
         }
       }
     ]
   }
   ```

### Step 4: Update Environment Variables

Update `apps/mobile/.env`:

```env
# Replace with the Android client ID from google-services.json
GOOGLE_ANDROID_CLIENT_ID=YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com

# Keep existing web client ID for Supabase
GOOGLE_CLIENT_ID=897976702780-qdgua0j0nj5jm98kl6nuvu2s0b7gg24i.apps.googleusercontent.com
```

### Step 5: Configure Supabase Google Provider

1. **Go to Supabase Dashboard**:
   - Project: dayliz-dev (for development)
   - Go to Authentication > Providers

2. **Enable Google Provider**:
   - Toggle "Enable Sign in with Google"
   - Client ID: Use the **Web Client ID** (not Android)
   - Client Secret: `[Your Web Client Secret from Google Cloud Console]`
   - Redirect URL: `https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback`

### Step 6: Test the Implementation

1. **Clean and Rebuild**:
   ```bash
   cd apps/mobile
   flutter clean
   flutter pub get
   cd android
   ./gradlew clean
   cd ..
   flutter run
   ```

2. **Test Google Sign-In**:
   - Tap the Google Sign-In button
   - Should show Google account picker
   - Should authenticate successfully
   - Check logs for any errors

## 🔧 v7.x API Changes Implemented

### Key Changes Made:

1. **Initialization**: Added `await GoogleSignIn.instance.initialize()`
2. **Authentication**: Replaced `signIn()` with `authenticate(scopeHint: ['email', 'profile'])`
3. **State Management**: Manual tracking with `_currentUser` variable
4. **Authorization**: Separate authorization flow using `authorizationClient`
5. **Error Handling**: Updated for `GoogleSignInException` types
6. **Token Access**: Authentication tokens are now synchronous (no `await`)

### Error Handling:

The implementation now handles these specific v7.x errors:
- `GoogleSignInExceptionCode.canceled` - User cancellation
- `GoogleSignInExceptionCode.interrupted` - Process interrupted
- `GoogleSignInExceptionCode.clientConfigurationError` - Configuration issues
- `GoogleSignInExceptionCode.providerConfigurationError` - Provider not configured
- `GoogleSignInExceptionCode.uiUnavailable` - UI not available
- `GoogleSignInExceptionCode.userMismatch` - Account mismatch
- `GoogleSignInExceptionCode.unknownError` - Unknown errors

## 🚨 Troubleshooting

### Common Issues:

1. **"Platform does not support authenticate() method"**
   - Check if running on supported platform
   - Ensure proper initialization

2. **"Google Sign-In configuration error"**
   - Verify google-services.json has oauth_client configuration
   - Check SHA-1 fingerprint matches

3. **"Failed to get Google access token"**
   - Check authorization flow implementation
   - Verify scopes are properly requested

4. **"Supabase authentication failed"**
   - Verify Supabase Google provider is enabled
   - Check client ID and secret configuration

### Debug Commands:

```bash
# Check current SHA-1 fingerprint
cd apps/mobile/android && ./gradlew signingReport

# Check package name
grep applicationId apps/mobile/android/app/build.gradle

# Verify google-services.json
cat apps/mobile/android/app/google-services.json | grep -A 10 oauth_client
```

## 📋 Configuration Checklist

- [ ] Google Cloud Console OAuth 2.0 Client ID created for Android
- [ ] SHA-1 certificate fingerprint added to OAuth client
- [ ] Updated google-services.json downloaded and replaced
- [ ] GOOGLE_ANDROID_CLIENT_ID updated in .env file
- [ ] Supabase Google provider enabled with correct credentials
- [ ] App cleaned and rebuilt
- [ ] Google Sign-In tested successfully

## 🎯 Next Steps

1. **Complete the configuration** following steps 1-6 above
2. **Test thoroughly** on both debug and release builds
3. **Monitor logs** for any remaining issues
4. **Update production** environment when ready

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all configuration steps are completed
3. Check Flutter and Google Sign-In package versions
4. Review Google Cloud Console audit logs for API calls
