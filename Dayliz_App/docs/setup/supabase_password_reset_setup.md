# Supabase Password Reset Setup Guide

## 🎯 **REQUIRED CONFIGURATION**

To complete the password reset functionality, you need to configure Supabase dashboard settings.

## 📧 **STEP 1: Configure Email Templates**

### **1. Access Email Templates**
1. Go to your Supabase dashboard
2. Navigate to `Authentication > Email Templates`
3. Find "Reset Password" template

### **2. Update Reset Password Template**
Replace the default template with:

#### **Subject:**
```
Reset your Dayliz password
```

#### **Body (HTML):**
```html
<h2>Reset your password</h2>
<p>Hi there,</p>
<p>Someone requested a password reset for your Dayliz account.</p>
<p>If this was you, click the button below to reset your password:</p>
<p><a href="{{ .ConfirmationURL }}" style="background-color: #4CAF50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; display: inline-block;">Reset Password</a></p>
<p>If the button doesn't work, copy and paste this link into your browser:</p>
<p>{{ .ConfirmationURL }}</p>
<p>This link will expire in 1 hour for security reasons.</p>
<p>If you didn't request this password reset, you can safely ignore this email.</p>
<p>Thanks,<br>The Dayliz Team</p>
```

### **3. Configure Redirect URL**
In the "Reset Password" template settings:
- **Redirect URL**: `dayliz://verify-email?type=reset_password`

## 🔗 **STEP 2: Configure URL Settings**

### **1. Access URL Configuration**
1. Go to `Authentication > URL Configuration`
2. Find "Redirect URLs" section

### **2. Add Redirect URLs**
Add these URLs to the allowed redirect URLs:
```
dayliz://verify-email
dayliz://verify-email?type=reset_password
dayliz://verify-email?type=verify_email
```

### **3. Site URL Configuration**
Set your site URL (for web fallback):
```
https://your-app-domain.com
```

## 📱 **STEP 3: Configure Deep Linking**

### **Android Configuration**

#### **File**: `android/app/src/main/AndroidManifest.xml`
Add this inside the `<activity>` tag:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme">
    
    <!-- Existing intent filters -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    
    <!-- Add this new intent filter for deep linking -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="dayliz" />
    </intent-filter>
    
</activity>
```

### **iOS Configuration**

#### **File**: `ios/Runner/Info.plist`
Add this inside the `<dict>` tag:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>dayliz.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>dayliz</string>
        </array>
    </dict>
</array>
```

## 🔐 **STEP 4: Security Settings**

### **1. Password Policy**
In `Authentication > Settings`:
- **Minimum password length**: 8 characters
- **Require uppercase**: Recommended
- **Require lowercase**: Recommended  
- **Require numbers**: Recommended
- **Require special characters**: Recommended

### **2. Rate Limiting**
Configure rate limiting for password reset:
- **Max requests per hour**: 5 (recommended)
- **Max requests per day**: 10 (recommended)

### **3. Token Expiry**
- **Reset token expiry**: 1 hour (default)
- **Refresh token expiry**: 30 days (default)

## 🧪 **STEP 5: Testing Configuration**

### **1. Test Email Delivery**
1. Use the forgot password feature
2. Check if email is received
3. Verify email template formatting
4. Test link functionality

### **2. Test Deep Linking**
1. Click reset link in email
2. Verify app opens correctly
3. Check if token is passed properly
4. Test on both Android and iOS

### **3. Test Complete Flow**
1. Request password reset
2. Receive email
3. Click link
4. App opens to reset screen
5. Enter new password
6. Verify reset success
7. Login with new password

## 🚨 **TROUBLESHOOTING**

### **Common Issues**

#### **Email Not Received**
- Check spam folder
- Verify email template is enabled
- Check Supabase email quota
- Verify SMTP configuration

#### **Deep Link Not Working**
- Verify intent filter configuration
- Check URL scheme spelling
- Test with `adb shell am start -W -a android.intent.action.VIEW -d "dayliz://verify-email?type=reset_password&token=test"`

#### **Token Invalid Error**
- Check token expiry settings
- Verify redirect URL configuration
- Check if token is being passed correctly

#### **App Not Opening**
- Verify deep link configuration
- Check if app is installed
- Test with browser fallback

## 📋 **VERIFICATION CHECKLIST**

### **Supabase Dashboard**
- [ ] Email template configured
- [ ] Redirect URLs added
- [ ] Password policy set
- [ ] Rate limiting configured

### **App Configuration**
- [ ] Android manifest updated
- [ ] iOS Info.plist updated
- [ ] Deep link handling implemented
- [ ] Token processing working

### **End-to-End Testing**
- [ ] Email delivery working
- [ ] Deep links opening app
- [ ] Password reset successful
- [ ] Error handling working
- [ ] New password login working

## 🎉 **COMPLETION**

Once all steps are completed:
1. **Deploy your app** with deep link configuration
2. **Test thoroughly** on both platforms
3. **Monitor logs** for any issues
4. **Update documentation** with any platform-specific notes

**Your password reset functionality is now fully configured and ready for production! 🚀**
