# Supabase Dashboard Configuration Guide

## 🎯 **STEP-BY-STEP CONFIGURATION**

Follow these exact steps to configure your Supabase dashboard for password reset functionality.

## 📧 **STEP 1: Configure Email Templates**

### **1. Access Email Templates**
1. Open your Supabase dashboard: https://supabase.com/dashboard
2. Select your **Dayliz** project
3. Navigate to **Authentication** → **Email Templates**
4. Find **"Reset Password"** template

### **2. Update Reset Password Template**

#### **Template Settings:**
- **Template Name**: Reset Password
- **Subject**: `Reset your Dayliz password`

#### **HTML Body** (Copy this exactly):
```html
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9;">
  <div style="background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
    
    <!-- Header -->
    <div style="text-align: center; margin-bottom: 30px;">
      <h1 style="color: #4CAF50; margin: 0; font-size: 28px;">Dayliz</h1>
      <p style="color: #666; margin: 5px 0 0 0;">Your Grocery Delivery App</p>
    </div>
    
    <!-- Main Content -->
    <h2 style="color: #333; margin-bottom: 20px;">Reset Your Password</h2>
    
    <p style="color: #555; line-height: 1.6; margin-bottom: 20px;">
      Hi there,
    </p>
    
    <p style="color: #555; line-height: 1.6; margin-bottom: 20px;">
      Someone requested a password reset for your Dayliz account. If this was you, click the button below to reset your password:
    </p>
    
    <!-- Reset Button -->
    <div style="text-align: center; margin: 30px 0;">
      <a href="{{ .ConfirmationURL }}" 
         style="background-color: #4CAF50; 
                color: white; 
                padding: 15px 30px; 
                text-decoration: none; 
                border-radius: 6px; 
                display: inline-block; 
                font-weight: bold; 
                font-size: 16px;">
        Reset My Password
      </a>
    </div>
    
    <!-- Alternative Link -->
    <p style="color: #555; line-height: 1.6; margin-bottom: 20px; font-size: 14px;">
      If the button doesn't work, copy and paste this link into your browser:
    </p>
    
    <div style="background-color: #f5f5f5; padding: 15px; border-radius: 4px; margin-bottom: 20px; word-break: break-all;">
      <code style="color: #333; font-size: 12px;">{{ .ConfirmationURL }}</code>
    </div>
    
    <!-- Security Notice -->
    <div style="background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 4px; margin-bottom: 20px;">
      <p style="color: #856404; margin: 0; font-size: 14px;">
        <strong>⚠️ Security Notice:</strong> This link will expire in 1 hour for security reasons.
      </p>
    </div>
    
    <!-- Footer -->
    <p style="color: #555; line-height: 1.6; margin-bottom: 10px;">
      If you didn't request this password reset, you can safely ignore this email. Your password will remain unchanged.
    </p>
    
    <p style="color: #555; line-height: 1.6; margin-bottom: 0;">
      Thanks,<br>
      <strong>The Dayliz Team</strong>
    </p>
    
    <!-- Footer Links -->
    <div style="border-top: 1px solid #eee; margin-top: 30px; padding-top: 20px; text-align: center;">
      <p style="color: #999; font-size: 12px; margin: 0;">
        Need help? Contact us at support@dayliz.app
      </p>
    </div>
    
  </div>
</div>
```

#### **Redirect URL Configuration:**
In the template settings, set:
- **Redirect URL**: `dayliz://verify-email?type=reset_password`

### **3. Save Template**
Click **"Save"** to apply the changes.

## 🔗 **STEP 2: Configure URL Settings**

### **1. Access URL Configuration**
1. Go to **Authentication** → **URL Configuration**
2. Find **"Redirect URLs"** section

### **2. Add Redirect URLs**
Add these URLs one by one (click **"Add URL"** for each):

```
dayliz://verify-email
dayliz://verify-email?type=reset_password
dayliz://verify-email?type=verify_email
dayliz://app
https://dayliz.app
```

### **3. Site URL Configuration**
Set your **Site URL**:
```
https://dayliz.app
```

## 🔐 **STEP 3: Configure Security Settings**

### **1. Password Policy**
1. Go to **Authentication** → **Settings**
2. Scroll to **"Password Policy"** section
3. Configure these settings:

```
✅ Minimum password length: 8 characters
✅ Require uppercase letters: Yes
✅ Require lowercase letters: Yes  
✅ Require numbers: Yes
✅ Require special characters: Yes
```

### **2. Rate Limiting**
In the same **Settings** page, configure:

```
✅ Max password reset requests per hour: 5
✅ Max password reset requests per day: 10
✅ Max login attempts per hour: 20
```

### **3. Token Expiry**
Configure token expiry times:

```
✅ Reset token expiry: 3600 seconds (1 hour)
✅ Refresh token expiry: 2592000 seconds (30 days)
✅ Access token expiry: 3600 seconds (1 hour)
```

## 📱 **STEP 4: Test Configuration**

### **1. Test Email Template**
1. Go to **Authentication** → **Users**
2. Find a test user or create one
3. Click **"Send reset password email"**
4. Check if email is received with correct formatting

### **2. Test Deep Link**
1. Click the reset link in the email
2. Verify it opens your app (if installed)
3. Check if the URL format is correct: `dayliz://verify-email?type=reset_password&token=...`

### **3. Test Complete Flow**
1. Use the forgot password feature in your app
2. Receive email
3. Click link
4. Verify app opens to password reset screen
5. Reset password successfully
6. Login with new password

## 🚨 **TROUBLESHOOTING**

### **Common Issues & Solutions**

#### **Email Not Received**
- Check **Authentication** → **Settings** → **SMTP Settings**
- Verify email quota hasn't been exceeded
- Check spam folder
- Ensure email template is **enabled**

#### **Deep Link Not Working**
- Verify redirect URLs are correctly added
- Check app is installed on device
- Test with: `adb shell am start -W -a android.intent.action.VIEW -d "dayliz://verify-email?type=reset_password&token=test"`

#### **Token Invalid Error**
- Check token expiry settings (should be 3600 seconds)
- Verify redirect URL matches exactly
- Ensure user clicks link within 1 hour

#### **Password Policy Errors**
- Verify password policy settings match app validation
- Test with strong password: `MyNewPass123!`

## ✅ **VERIFICATION CHECKLIST**

### **Email Template**
- [ ] Subject line set correctly
- [ ] HTML template copied exactly
- [ ] Redirect URL configured: `dayliz://verify-email?type=reset_password`
- [ ] Template saved and enabled

### **URL Configuration**
- [ ] All redirect URLs added
- [ ] Site URL configured
- [ ] URLs saved successfully

### **Security Settings**
- [ ] Password policy configured
- [ ] Rate limiting set
- [ ] Token expiry times set
- [ ] Settings saved

### **Testing**
- [ ] Test email received
- [ ] Email formatting correct
- [ ] Deep link opens app
- [ ] Complete flow works
- [ ] Error handling works

## 🎉 **COMPLETION**

Once all steps are completed:

1. **Test thoroughly** on both Android and iOS
2. **Monitor logs** for any issues
3. **Document any platform-specific notes**
4. **Deploy to production**

**Your Supabase dashboard is now fully configured for password reset functionality! 🚀**

---

## 📞 **Support**

If you encounter any issues:
1. Check the troubleshooting section above
2. Verify all settings match exactly
3. Test with debug logging enabled
4. Contact Supabase support if needed

**Configuration complete - ready for production use! ✅**
