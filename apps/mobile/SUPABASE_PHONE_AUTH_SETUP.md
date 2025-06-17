# 📱 Supabase Phone Authentication Setup Guide

## 🎯 Overview

This guide will help you configure Supabase Phone Authentication for the Dayliz app. The implementation is already complete in the code - you just need to configure the Supabase dashboard and SMS provider.

## ✅ What's Already Implemented

- ✅ Phone auth screen with Supabase integration
- ✅ OTP verification screen with auto-verification
- ✅ User profile creation after successful auth
- ✅ Error handling for all phone auth scenarios
- ✅ Resend OTP functionality
- ✅ Auth state management in providers

## 🔧 Manual Setup Required

### **Step 1: Enable Phone Authentication in Supabase**

1. Go to your **Supabase Dashboard**
2. Navigate to **Authentication → Settings**
3. Scroll down to **Auth Providers**
4. Find **Phone** and click **Enable**

### **Step 2: Configure SMS Provider**

Choose one of these SMS providers (recommended for India: **Textlocal**):

#### **Option A: Textlocal (Recommended for India)**
```json
{
  "provider": "textlocal",
  "api_key": "YOUR_TEXTLOCAL_API_KEY",
  "sender": "DAYLIZ"
}
```

**Cost**: ₹0.15-0.25 per SMS
**Coverage**: Excellent in India
**Setup**: Get API key from textlocal.in

#### **Option B: Twilio (Global)**
```json
{
  "provider": "twilio",
  "account_sid": "YOUR_TWILIO_ACCOUNT_SID",
  "auth_token": "YOUR_TWILIO_AUTH_TOKEN",
  "from": "+1234567890"
}
```

**Cost**: ₹0.50-0.80 per SMS
**Coverage**: Global
**Setup**: Get credentials from twilio.com

#### **Option C: MessageBird (Europe/Asia)**
```json
{
  "provider": "messagebird",
  "api_key": "YOUR_MESSAGEBIRD_API_KEY",
  "originator": "DAYLIZ"
}
```

**Cost**: ₹0.30-0.50 per SMS
**Coverage**: Good for Europe/Asia
**Setup**: Get API key from messagebird.com

### **Step 3: Configure Phone Settings**

In Supabase Dashboard → Authentication → Settings:

1. **Phone confirmation**: Enable
2. **Phone change confirmation**: Enable  
3. **Phone rate limiting**: 
   - Max attempts: 5 per hour
   - Lockout duration: 1 hour
4. **OTP expiry**: 60 seconds (default)
5. **OTP length**: 6 digits (default)

### **Step 4: Set Up SMS Templates**

Navigate to **Authentication → Templates** and customize:

#### **Phone OTP Template**:
```
Your Dayliz verification code is: {{ .Token }}

This code expires in 60 seconds.
```

#### **Phone Change Template**:
```
Your Dayliz phone change verification code is: {{ .Token }}

If you didn't request this, please ignore this message.
```

### **Step 5: Configure Rate Limiting**

In **Authentication → Settings → Rate Limiting**:

```json
{
  "phone_signup": {
    "max_attempts": 3,
    "duration": "1h"
  },
  "phone_signin": {
    "max_attempts": 5,
    "duration": "1h"
  },
  "phone_otp_verify": {
    "max_attempts": 5,
    "duration": "15m"
  }
}
```

### **Step 6: Test Configuration**

1. **Test Phone Number**: Use your own number first
2. **Check SMS Delivery**: Verify SMS arrives within 30 seconds
3. **Test OTP Verification**: Ensure 6-digit codes work
4. **Test Error Scenarios**: Invalid numbers, expired codes, etc.

## 🚀 How It Works

### **User Flow**:
```
1. User enters: +91 9876543210
2. App calls: supabase.auth.signInWithOtp()
3. Supabase sends: SMS with 6-digit code
4. User enters: 123456
5. App calls: supabase.auth.verifyOTP()
6. Success: User authenticated & profile created
```

### **Code Integration**:
```dart
// Send OTP (already implemented)
await supabase.auth.signInWithOtp(
  phone: phoneNumber,
  shouldCreateUser: true,
);

// Verify OTP (already implemented)
await supabase.auth.verifyOTP(
  phone: phoneNumber,
  token: otpCode,
  type: OtpType.sms,
);
```

## 💰 Cost Estimation

### **For 1000 users/month**:
- **Textlocal**: ₹150-250/month
- **Twilio**: ₹500-800/month  
- **MessageBird**: ₹300-500/month

### **Supabase Pricing**:
- **Free Tier**: 10,000 MAU (Monthly Active Users)
- **Pro Tier**: ₹2,000/month for 100,000 MAU

## 🔒 Security Features

- ✅ **Rate Limiting**: Prevents spam/abuse
- ✅ **OTP Expiry**: Codes expire in 60 seconds
- ✅ **JWT Tokens**: Secure session management
- ✅ **User Validation**: Phone number format validation
- ✅ **Error Handling**: User-friendly error messages

## 🐛 Troubleshooting

### **SMS Not Received**:
1. Check SMS provider configuration
2. Verify phone number format (+91XXXXXXXXXX)
3. Check rate limiting settings
4. Test with different phone numbers

### **OTP Verification Fails**:
1. Check OTP expiry time
2. Verify code format (6 digits)
3. Test with fresh OTP codes
4. Check Supabase logs

### **User Profile Not Created**:
1. Check profiles table exists
2. Verify RLS policies allow inserts
3. Check Supabase logs for errors

## 📞 Support

If you encounter issues:
1. Check Supabase Dashboard logs
2. Review SMS provider delivery reports
3. Test with Supabase's test phone numbers
4. Contact SMS provider support if needed

## 🎉 Ready to Test!

Once configured, users can:
- ✅ Enter phone number on auth screen
- ✅ Receive SMS with 6-digit code
- ✅ Auto-verify when code is entered
- ✅ Get authenticated and navigate to home
- ✅ Resend OTP if needed
- ✅ Change phone number if needed

The phone authentication is now production-ready! 🚀
