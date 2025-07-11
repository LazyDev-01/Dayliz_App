# 🚀 Dayliz App Monitoring Setup Guide

## 📋 **SETUP OVERVIEW**

This guide will help you complete the monitoring setup for both **development** and **production** environments.

### **✅ What's Already Done (Automated)**
- ✅ Flutter dependencies added to `pubspec.yaml`
- ✅ Firebase monitoring plugins configured in Android build files
- ✅ Monitoring services integrated into `main.dart`
- ✅ Backend monitoring middleware configured
- ✅ API endpoints for monitoring created
- ✅ Environment configuration template created

### **🔄 What You Need to Do (Manual)**
- 🔄 Enable Firebase services in Firebase Console
- 🔄 Download Firebase configuration files
- 🔄 Configure environment variables
- 🔄 Test the monitoring integration

---

## 🔥 **STEP 1: FIREBASE CONSOLE SETUP** (5 minutes)

### **1.1 Access Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **Dayliz project** (you mentioned you already have this set up)

### **1.2 Enable Required Services**
Enable these services in your Firebase project:

#### **Crashlytics** (Crash Reporting)
1. Go to **Release & Monitor** → **Crashlytics**
2. Click **"Enable Crashlytics"**
3. Follow the setup wizard

#### **Performance Monitoring**
1. Go to **Release & Monitor** → **Performance**
2. Click **"Get started"**
3. Enable performance monitoring

#### **Analytics** (User Behavior)
1. Go to **Analytics** → **Dashboard**
2. If not already enabled, click **"Enable Google Analytics"**

#### **Cloud Messaging** (For Alerts)
1. Go to **Engage** → **Messaging**
2. This should already be enabled from your previous setup

### **1.3 Verify Services Are Active**
You should see all these services listed in your Firebase project sidebar:
- ✅ Crashlytics
- ✅ Performance
- ✅ Analytics
- ✅ Cloud Messaging

---

## 📁 **STEP 2: DOWNLOAD CONFIGURATION FILES** (2 minutes)

### **2.1 Android Configuration**
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **"Your apps"** section
3. Find your **Android app**
4. Click **"Download google-services.json"**
5. **Place the file** in: `apps/mobile/android/app/google-services.json`

### **2.2 iOS Configuration** (if you plan to build for iOS)
1. In the same **"Your apps"** section
2. Find your **iOS app**
3. Click **"Download GoogleService-Info.plist"**
4. **Place the file** in: `apps/mobile/ios/Runner/GoogleService-Info.plist`

### **2.3 Verify File Placement**
Check that these files exist:
```
apps/mobile/android/app/google-services.json     ✅
apps/mobile/ios/Runner/GoogleService-Info.plist  ✅ (if using iOS)
```

---

## ⚙️ **STEP 3: CONFIGURE ENVIRONMENT VARIABLES** (3 minutes)

### **3.1 Backend Configuration**
1. Navigate to `services/api/`
2. Open the `.env` file (or create it if it doesn't exist)
3. Add these monitoring settings:

```env
# Monitoring Configuration
MONITORING_ENABLED=true

# Alert Configuration (Optional for development)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
ALERT_FROM_EMAIL=your_email@gmail.com
ALERT_TO_EMAIL=your_email@gmail.com

# Alert Thresholds
ERROR_RATE_THRESHOLD=0.05
RESPONSE_TIME_THRESHOLD=2000
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
```

### **3.2 For Development (Minimal Setup)**
If you just want to test monitoring in development, you only need:
```env
MONITORING_ENABLED=true
```

### **3.3 For Production (Full Setup)**
For production, you'll want to configure email alerts:
```env
MONITORING_ENABLED=true
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=alerts@yourdomain.com
SMTP_PASSWORD=your_secure_app_password
ALERT_FROM_EMAIL=alerts@yourdomain.com
ALERT_TO_EMAIL=admin@yourdomain.com
```

---

## 🧪 **STEP 4: TEST THE SETUP** (5 minutes)

### **4.1 Test Flutter App Monitoring**

1. **Install dependencies**:
   ```bash
   cd apps/mobile
   flutter pub get
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

3. **Check console output** for these messages:
   ```
   ✅ Firebase initialized successfully
   ✅ Monitoring system initialized successfully
   📱 Screen view: HomeScreen
   🔄 Connectivity: wifi
   ```

### **4.2 Test Backend Monitoring**

1. **Start the backend**:
   ```bash
   cd services/api
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

2. **Test health endpoint**:
   ```bash
   curl http://localhost:8000/api/v1/monitoring/health
   ```

3. **Expected response**:
   ```json
   {
     "status": "healthy",
     "timestamp": "2025-01-21T...",
     "uptime_seconds": 45,
     "version": "1.0.0"
   }
   ```

### **4.3 Test Firebase Integration**

1. **Trigger a test event** in your Flutter app (navigate between screens)
2. **Wait 2-3 minutes**
3. **Check Firebase Console**:
   - Go to **Analytics** → **Events** (should show screen views)
   - Go to **Performance** → **Dashboard** (should show app performance data)
   - **Crashlytics** will only show data if there are actual crashes

---

## 🎯 **STEP 5: VERIFY MONITORING IS WORKING**

### **5.1 Development Verification**
You should see these in your console:
```
✅ AppMonitoringIntegration initialized successfully
📊 Event: screen_view - HomeScreen
⚡ Performance: screen_load_time - 234ms
🔄 Connectivity: wifi
```

### **5.2 Backend Verification**
Test these endpoints:
```bash
# Basic health check
curl http://localhost:8000/api/v1/monitoring/health

# Detailed dashboard
curl http://localhost:8000/api/v1/monitoring/dashboard

# System metrics
curl http://localhost:8000/api/v1/monitoring/metrics/system
```

### **5.3 Firebase Console Verification**
- **Analytics**: Should show events and user activity
- **Performance**: Should show app performance metrics
- **Crashlytics**: Will show crash data when crashes occur

---

## 🚨 **TROUBLESHOOTING**

### **Common Issues & Solutions**

#### **Issue: "Firebase not initialized"**
**Solution**: Ensure `google-services.json` is in the correct location and `flutter pub get` was run.

#### **Issue: "Monitoring endpoints not responding"**
**Solution**: Check that the backend server is running and `MONITORING_ENABLED=true` in `.env`.

#### **Issue: "No data in Firebase Console"**
**Solution**: Wait 5-10 minutes for data to appear. Ensure the app is running and generating events.

#### **Issue: "Import errors in Flutter"**
**Solution**: Run `flutter clean && flutter pub get` to refresh dependencies.

### **Debug Commands**
```bash
# Check Flutter dependencies
flutter doctor

# Check backend health
curl http://localhost:8000/api/v1/monitoring/health

# View backend logs
python -m uvicorn app.main:app --log-level debug

# Check Firebase configuration
flutter packages get
```

---

## 🎉 **SUCCESS INDICATORS**

### **✅ You'll know it's working when:**

#### **Flutter App**
- Console shows monitoring initialization messages
- No import errors or crashes
- App runs smoothly with monitoring in background

#### **Backend**
- Health endpoint returns "healthy" status
- Dashboard endpoint returns metrics data
- Console shows monitoring middleware logs

#### **Firebase Console**
- Analytics shows user events and screen views
- Performance shows app performance data
- No configuration errors in Firebase Console

---

## 🚀 **NEXT STEPS AFTER SETUP**

### **Development Phase**
1. **Monitor console logs** to see real-time monitoring data
2. **Test different app flows** to generate monitoring events
3. **Use monitoring endpoints** to debug performance issues

### **Production Phase**
1. **Configure production alerts** (email, Slack, SMS)
2. **Set up monitoring dashboards** for your team
3. **Establish monitoring procedures** and escalation paths

---

## 📞 **NEED HELP?**

If you encounter any issues:

1. **Check the console logs** for specific error messages
2. **Verify file locations** for Firebase configuration files
3. **Test individual components** using the provided endpoints
4. **Review environment variables** in your `.env` file

**The monitoring system is designed to work seamlessly in both development and production with minimal configuration!** 🎯

---

**Setup Time**: ~15 minutes  
**Difficulty**: Easy  
**Result**: Enterprise-grade monitoring for your Dayliz app! 🚀
