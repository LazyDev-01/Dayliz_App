# 🎯 Dayliz Agent App - Testing Credentials

## ✅ **READY FOR TESTING - AUTHENTICATION WORKING**

The Dayliz Agent App authentication system is fully functional and ready for testing.

---

## 🔑 **TEST CREDENTIALS**

### **✅ Primary Test Agent**

**Login Method**: Email/Phone + Password

**Credentials**:
- **Email**: `testuser@gmail.com`
- **Phone**: `+91-9876543210` (alternative login)
- **Password**: `test123`

**Agent Details**:
- **Agent ID**: `DLZ-AG-GHY-00001`
- **Full Name**: Test Agent
- **Status**: Active ✅
- **Verified**: Yes ✅
- **Zone**: Guwahati Zone 1

---

## 🧪 **HOW TO TEST**

### **Step 1: Launch the Agent App**
```bash
cd apps/agent
flutter run --debug
```

### **Step 2: Login Process**
1. Open the agent app
2. Tap "Login as Existing Agent" 
3. Enter credentials:
   - **Email/Phone**: `testuser@gmail.com` OR `+91-9876543210`
   - **Password**: `test123`
4. Tap "Login"

### **Step 3: Expected Result**
- ✅ Successful login
- ✅ Navigate to agent dashboard
- ✅ See welcome message: "Login successful! Welcome back."
- ✅ Dashboard shows agent details and mock orders

---

## 🔧 **AUTHENTICATION FLOW**

The app supports **dual login methods**:

1. **Email Login**: `testuser@gmail.com`
2. **Phone Login**: `+91-9876543210`

Both methods use the same password: `test123`

The authentication service automatically:
- Detects if input is email or phone
- Converts phone to email format for Supabase auth
- Fetches agent data from agents table
- Validates agent status (active/verified)

---

## 🛠️ **TROUBLESHOOTING**

### **If Login Fails:**

1. **Check Network Connection**
   - Ensure device has internet access
   - Supabase connection requires internet

2. **Verify Credentials**
   - Email: `testuser@gmail.com`
   - Password: `test123` (case-sensitive)

3. **Check Agent Status**
   - Agent must be `active` and `verified`
   - Check database if needed

4. **Clear App Data** (if needed)
   - Stop the app
   - Clear app data/cache
   - Restart the app

### **Common Error Messages:**

- **"Invalid credentials"**: Wrong email/password
- **"Agent not found"**: Agent record missing in database
- **"Account suspended/inactive"**: Agent status issue
- **"Network error"**: Internet connection problem

---

## 📱 **TESTING CHECKLIST**

- [ ] App launches successfully
- [ ] Login screen displays correctly
- [ ] Email login works: `testuser@gmail.com`
- [ ] Phone login works: `+91-9876543210`
- [ ] Password validation works
- [ ] Successful login navigates to dashboard
- [ ] Dashboard shows agent information
- [ ] Logout functionality works
- [ ] Error handling displays properly

---

## 🔄 **ADDITIONAL TEST SCENARIOS**

### **Test Invalid Credentials:**
- Wrong email: `wrong@email.com`
- Wrong password: `wrongpass`
- Expected: Error message displayed

### **Test Network Issues:**
- Disable internet connection
- Try to login
- Expected: Network error message

### **Test Form Validation:**
- Empty email field
- Empty password field
- Invalid email format
- Expected: Validation errors shown

---

## 📊 **DATABASE VERIFICATION**

To verify the test agent in database:

```sql
-- Check agent record
SELECT agent_id, full_name, email, status, is_verified 
FROM agents 
WHERE agent_id = 'DLZ-AG-GHY-00001';

-- Check auth user
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'testuser@gmail.com';
```

---

## 🚀 **NEXT STEPS AFTER LOGIN TESTING**

Once login is working:

1. **Dashboard Testing**: Verify agent dashboard displays correctly
2. **Order Management**: Test order assignment and status updates
3. **Profile Management**: Test agent profile viewing/editing
4. **Real-time Features**: Test order notifications and updates
5. **Logout Testing**: Verify logout clears session properly

---

## 📞 **SUPPORT**

If you encounter any issues:

1. Check this credentials file for correct login details
2. Verify internet connection
3. Check app logs for detailed error messages
4. Ensure Supabase project is accessible

**Test Agent Created**: ✅ Ready for testing  
**Last Updated**: January 5, 2025  
**Status**: Active and Verified
