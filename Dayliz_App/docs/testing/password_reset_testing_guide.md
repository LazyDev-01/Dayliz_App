# Password Reset Testing Guide

## 🧪 **COMPREHENSIVE TESTING CHECKLIST**

Use this guide to thoroughly test the password reset functionality after configuration.

## 📱 **TESTING ENVIRONMENT SETUP**

### **Prerequisites**
- [ ] Supabase dashboard configured
- [ ] App installed on test device
- [ ] Deep linking configured
- [ ] Debug logging enabled
- [ ] Test email account accessible

### **Test Accounts**
Create these test accounts in Supabase:
```
1. valid-user@test.com (verified email)
2. unverified-user@test.com (unverified email)
3. nonexistent@test.com (doesn't exist)
```

## 🔄 **TEST SCENARIOS**

### **SCENARIO 1: Successful Password Reset Flow**

#### **Test Steps:**
1. **Open app** → Navigate to login screen
2. **Click "Forgot Password?"** → Should navigate to `/reset-password`
3. **Enter valid email**: `valid-user@test.com`
4. **Click "Reset Password"** → Should show success message
5. **Check email inbox** → Should receive reset email within 2 minutes
6. **Click reset link in email** → Should open app automatically
7. **Verify navigation** → Should be on password reset screen
8. **Enter new password**: `NewPassword123!`
9. **Click "Reset Password"** → Should show success message
10. **Navigate to login** → Click "Go to Login"
11. **Login with new password** → Should succeed

#### **Expected Results:**
- ✅ Each step completes successfully
- ✅ Email received with correct formatting
- ✅ Deep link opens app correctly
- ✅ Password reset successful
- ✅ Login with new password works

#### **Debug Console Logs:**
```
🔄 [AuthNotifier] Starting forgot password for email: valid-user@test.com
✅ [AuthSupabaseDataSource] Password reset email sent successfully
🔄 [VerifyTokenHandler] Processing password reset token
➡️ [VerifyTokenHandler] Redirecting to update password screen
🔄 [AuthNotifier] Starting password reset
✅ [AuthSupabaseDataSource] Password reset successful
```

### **SCENARIO 2: Invalid Email Address**

#### **Test Steps:**
1. **Navigate to forgot password screen**
2. **Enter invalid email**: `nonexistent@test.com`
3. **Click "Reset Password"**

#### **Expected Results:**
- ❌ Should show error: "No account found with this email address."
- ❌ No email should be sent

#### **Debug Console Logs:**
```
🔄 [AuthNotifier] Starting forgot password for email: nonexistent@test.com
❌ [AuthSupabaseDataSource] AuthException in forgotPassword: User not found
🔍 [AuthNotifier] Returning auth failure message: No account found with this email address.
```

### **SCENARIO 3: Rate Limiting**

#### **Test Steps:**
1. **Request password reset** 6 times in quick succession
2. **Check 6th request response**

#### **Expected Results:**
- ❌ Should show error: "Too many reset requests. Please wait before trying again."

### **SCENARIO 4: Expired Token**

#### **Test Steps:**
1. **Request password reset** → Get email
2. **Wait 2 hours** (or modify token expiry to 1 minute for testing)
3. **Click expired link**
4. **Try to reset password**

#### **Expected Results:**
- ❌ Should show error: "Reset link has expired. Please request a new password reset."

### **SCENARIO 5: Weak Password**

#### **Test Steps:**
1. **Complete reset flow** until password entry
2. **Enter weak password**: `123`
3. **Click "Reset Password"**

#### **Expected Results:**
- ❌ Should show error: "Password must be at least 8 characters long..."

### **SCENARIO 6: Deep Link Testing**

#### **Manual Deep Link Test (Android):**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "dayliz://verify-email?type=reset_password&token=test123"
```

#### **Expected Results:**
- ✅ App should open
- ✅ Should navigate to password reset screen
- ✅ Token should be processed

#### **Manual Deep Link Test (iOS):**
```bash
xcrun simctl openurl booted "dayliz://verify-email?type=reset_password&token=test123"
```

## 🔍 **ERROR TESTING**

### **Network Error Testing**
1. **Disable internet** → Try password reset
2. **Expected**: Network error message

### **Server Error Testing**
1. **Use invalid Supabase URL** → Try password reset
2. **Expected**: Server error message

### **Authentication Error Testing**
1. **Use malformed token** → Try password reset
2. **Expected**: Invalid token error

## 📊 **PERFORMANCE TESTING**

### **Email Delivery Time**
- **Target**: < 2 minutes
- **Test**: Measure time from request to email receipt
- **Record**: Average delivery time over 10 tests

### **App Launch Time**
- **Target**: < 3 seconds from link click to app open
- **Test**: Measure deep link response time
- **Record**: Average launch time over 10 tests

### **Password Reset Time**
- **Target**: < 5 seconds for password update
- **Test**: Measure time from form submission to success
- **Record**: Average reset time over 10 tests

## 🔧 **DEBUGGING TOOLS**

### **Enable Debug Logging**
Ensure these debug prints are visible in console:
```
🔄 - Process started
✅ - Success
❌ - Error
🔍 - Debug info
➡️ - Navigation
🎯 - Specific action
```

### **Supabase Dashboard Monitoring**
1. **Go to**: Authentication → Logs
2. **Monitor**: Real-time auth events
3. **Check**: Error rates and patterns

### **Flutter Inspector**
1. **Enable**: Flutter Inspector in IDE
2. **Monitor**: Widget tree and state changes
3. **Debug**: Navigation and state issues

## 📱 **PLATFORM-SPECIFIC TESTING**

### **Android Testing**
- [ ] Test on Android 8+ devices
- [ ] Verify intent filter handling
- [ ] Test with different launchers
- [ ] Check notification permissions

### **iOS Testing**
- [ ] Test on iOS 12+ devices
- [ ] Verify URL scheme handling
- [ ] Test with different browsers
- [ ] Check universal links

## 📋 **REGRESSION TESTING**

### **Existing Functionality**
- [ ] Normal login still works
- [ ] Google sign-in still works
- [ ] Registration still works
- [ ] Logout still works
- [ ] Change password (authenticated) still works

### **Navigation**
- [ ] All routes still work
- [ ] Back button behavior correct
- [ ] Deep links don't break navigation

## 🎯 **ACCEPTANCE CRITERIA**

### **Must Pass All:**
- ✅ **Happy Path**: Complete reset flow works
- ✅ **Error Handling**: All error scenarios handled gracefully
- ✅ **Security**: Weak passwords rejected, tokens expire
- ✅ **Performance**: All operations complete within target times
- ✅ **Cross-Platform**: Works on both Android and iOS
- ✅ **Regression**: Existing features unaffected

### **Success Metrics:**
- **Email Delivery**: 100% success rate
- **Deep Link Success**: 100% success rate
- **Password Reset Success**: 100% success rate
- **Error Handling**: 100% appropriate error messages
- **Performance**: All targets met

## 🚀 **PRODUCTION READINESS**

### **Final Checklist:**
- [ ] All test scenarios pass
- [ ] Performance targets met
- [ ] Error handling comprehensive
- [ ] Debug logging can be disabled
- [ ] Documentation complete
- [ ] Team trained on troubleshooting

### **Go-Live Criteria:**
- [ ] 100% test pass rate
- [ ] No critical bugs
- [ ] Performance acceptable
- [ ] Monitoring in place
- [ ] Rollback plan ready

**Testing complete - ready for production deployment! 🎉**
