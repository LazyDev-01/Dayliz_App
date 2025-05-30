# 🚀 Google Sign-In Setup Guide for Dayliz App

## ✅ Current Status
- ✅ **Google OAuth Client ID**: Configured (`897976702780-qdgua0j0nj5jm98kl6nuvu2s0b7gg24i.apps.googleusercontent.com`)
- ✅ **Android Configuration**: Complete (`google-services.json` configured)
- ✅ **Flutter Code**: Fully implemented and functional
- ✅ **Login Screen**: Google button now enabled and functional
- ✅ **Sign-up Screen**: Google button functional
- ❌ **Supabase Google Provider**: Not configured (THIS IS THE ISSUE!)

## 🎯 The Problem
The Google sign-in popup works (shows account selection) but fails after account selection because **Supabase Google provider is not enabled/configured**.

## 🛠️ SOLUTION: Configure Supabase Google Provider

### Step 1: Get Google Client Secret
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **dayliz-app-456806**
3. Navigate to: **APIs & Services → Credentials**
4. Find OAuth 2.0 Client ID: `897976702780-qdgua0j0nj5jm98kl6nuvu2s0b7gg24i.apps.googleusercontent.com`
5. Click on it and **copy the Client Secret**

### Step 2: Configure Supabase
1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/zdezerezpbeuebnompyj)
2. Navigate to: **Authentication → Providers**
3. Find **Google** in the list
4. **Enable** the Google provider
5. Enter the following:
   - **Client ID**: `897976702780-qdgua0j0nj5jm98kl6nuvu2s0b7gg24i.apps.googleusercontent.com`
   - **Client Secret**: [Paste the secret you copied from Step 1]
   - **Redirect URL**: `https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback`
6. **Save** the configuration

### Step 3: Update Environment Variables (Optional)
Update your `.env` file:
```env
GOOGLE_CLIENT_SECRET=your_actual_client_secret_here
```

### Step 4: Test the Implementation
1. **Run your app**
2. **Try Google sign-in** from either login or sign-up screen
3. **Check console logs** for detailed error messages
4. **Verify success**: User should appear in Supabase Authentication → Users

## 🧪 Expected Flow
1. User clicks "Sign in/up with Google"
2. Google OAuth popup opens ✅ (This works)
3. User selects Google account ✅ (This works)
4. Google redirects to Supabase ❌ (This fails - needs Step 2)
5. Supabase creates/authenticates user
6. App receives authenticated user
7. User navigates to home screen

## 🔍 Troubleshooting

### If Google sign-in still fails after configuration:

1. **Check Supabase Logs**:
   - Go to Supabase Dashboard → Logs
   - Look for authentication errors

2. **Check Console Logs**:
   - Look for specific error messages
   - Common errors:
     - `ServerException`: Supabase configuration issue
     - `AuthException`: Google OAuth issue
     - `NetworkFailure`: Internet connectivity

3. **Verify Google Cloud Console**:
   - Ensure OAuth consent screen is configured
   - Check authorized redirect URIs include: `https://zdezerezpbeuebnompyj.supabase.co/auth/v1/callback`

4. **Test with Different Account**:
   - Try with different Google accounts
   - Check if specific accounts are blocked

## 🎉 After Successful Setup
Once configured, Google sign-in will work on:
- ✅ **Login screen** (now enabled)
- ✅ **Sign-up screen** (already functional)
- ✅ **Both Android and Web** (when you build for web)

## 📞 Need Help?
If you encounter issues:
1. Check the console logs for specific error messages
2. Share the exact error message for targeted help
3. Verify each step was completed correctly

The code is ready - you just need to complete the Supabase configuration! 🚀
