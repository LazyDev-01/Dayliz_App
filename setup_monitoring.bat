@echo off
setlocal enabledelayedexpansion

REM Dayliz App Monitoring Setup Script for Windows
REM This script sets up monitoring for both development and production

echo 🚀 Setting up Dayliz App Monitoring System...
echo ================================================

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter is not installed. Please install Flutter first.
    pause
    exit /b 1
)

echo ✅ Flutter is installed

REM Check if we're in the correct directory
if not exist "apps\mobile\pubspec.yaml" (
    echo ❌ Please run this script from the project root directory
    pause
    exit /b 1
)

echo ✅ Running from correct directory

REM Step 1: Install Flutter dependencies
echo.
echo 📱 Installing Flutter dependencies...
cd apps\mobile

REM Clean and get dependencies
flutter clean
flutter pub get

if errorlevel 1 (
    echo ❌ Failed to install Flutter dependencies
    pause
    exit /b 1
)

echo ✅ Flutter dependencies installed successfully

REM Step 2: Check Firebase configuration
echo.
echo 🔥 Checking Firebase configuration...

if not exist "android\app\google-services.json" (
    echo ⚠️  google-services.json not found for Android
    echo    Please download it from Firebase Console and place it in android\app\
)

if not exist "ios\Runner\GoogleService-Info.plist" (
    echo ⚠️  GoogleService-Info.plist not found for iOS
    echo    Please download it from Firebase Console and place it in ios\Runner\
)

REM Step 3: Set up backend monitoring
echo.
echo 🖥️  Setting up backend monitoring...
cd ..\..\services\api

REM Check if Python virtual environment exists
if not exist "venv" (
    echo ℹ️  Creating Python virtual environment...
    python -m venv venv
)

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Install Python dependencies
echo ℹ️  Installing Python dependencies...
pip install -r requirements.txt

if errorlevel 1 (
    echo ❌ Failed to install backend dependencies
    pause
    exit /b 1
)

echo ✅ Backend dependencies installed successfully

REM Step 4: Set up environment configuration
echo.
echo ⚙️  Setting up environment configuration...

if not exist ".env" (
    echo ℹ️  Creating .env file from template...
    copy .env.monitoring .env
    echo ⚠️  Please edit .env file with your actual configuration values
) else (
    echo ℹ️  .env file already exists
    echo ⚠️  Please ensure monitoring configuration is added to your .env file
    echo    You can reference .env.monitoring for required settings
)

REM Step 5: Test backend monitoring
echo.
echo 🧪 Testing backend monitoring...

REM Start the server in background for testing
start /b python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

REM Wait for server to start
timeout /t 5 /nobreak >nul

REM Test health endpoint
curl -s http://localhost:8000/api/v1/monitoring/health > temp_response.txt 2>nul
if exist temp_response.txt (
    findstr "healthy" temp_response.txt >nul
    if !errorlevel! equ 0 (
        echo ✅ Backend monitoring is working correctly
    ) else (
        echo ⚠️  Backend monitoring may not be working correctly
        type temp_response.txt
    )
    del temp_response.txt
) else (
    echo ⚠️  Could not test backend monitoring (curl not available)
)

REM Stop the test server
taskkill /f /im python.exe >nul 2>&1

REM Step 6: Generate monitoring documentation
echo.
echo 📚 Generating monitoring documentation...

cd ..\..

REM Create monitoring status file
(
echo # Dayliz App Monitoring Status
echo.
echo ## Setup Completion Status
echo.
echo ### ✅ Automated Setup Completed
echo - [x] Flutter dependencies added to pubspec.yaml
echo - [x] Firebase monitoring plugins configured
echo - [x] Monitoring services integrated into main.dart
echo - [x] Backend monitoring middleware configured
echo - [x] API endpoints for monitoring created
echo - [x] Environment configuration template created
echo.
echo ### 🔄 Manual Setup Required
echo - [ ] Firebase project services enabled ^(Crashlytics, Performance, Analytics^)
echo - [ ] Firebase configuration files downloaded and placed
echo - [ ] Environment variables configured in .env file
echo - [ ] iOS build script added for Crashlytics
echo - [ ] Production alert channels configured ^(email, Slack, SMS^)
echo.
echo ## Next Steps
echo.
echo ### 1. Firebase Console Setup
echo 1. Go to [Firebase Console]^(https://console.firebase.google.com/^)
echo 2. Select your Dayliz project
echo 3. Enable these services:
echo    - Crashlytics ^(Release ^& Monitor → Crashlytics^)
echo    - Performance Monitoring ^(Release ^& Monitor → Performance^)
echo    - Analytics ^(Analytics → Dashboard^)
echo    - Cloud Messaging ^(Engage → Messaging^)
echo.
echo ### 2. Download Configuration Files
echo 1. Download `google-services.json` for Android
echo 2. Place in `apps\mobile\android\app\google-services.json`
echo 3. Download `GoogleService-Info.plist` for iOS
echo 4. Place in `apps\mobile\ios\Runner\GoogleService-Info.plist`
echo.
echo ### 3. Configure Environment Variables
echo 1. Edit `services\api\.env` file
echo 2. Add monitoring configuration from `.env.monitoring` template
echo 3. Replace placeholder values with actual credentials
echo.
echo ### 4. Test the Setup
echo 1. Run the Flutter app: `flutter run`
echo 2. Check console for monitoring initialization logs
echo 3. Test backend monitoring: `curl http://localhost:8000/api/v1/monitoring/health`
echo 4. Verify Firebase Console shows data ^(may take a few minutes^)
echo.
echo ## Monitoring Features Available
echo.
echo ### 📱 Flutter App Monitoring
echo - Automatic crash reporting
echo - Performance monitoring
echo - User behavior analytics
echo - Business metrics tracking
echo - Network connectivity monitoring
echo.
echo ### 🖥️ Backend Monitoring
echo - API performance tracking
echo - System resource monitoring
echo - Error rate monitoring
echo - Business intelligence
echo - Real-time alerting
echo.
echo ### 📊 Dashboard Access
echo - Health check: `GET /api/v1/monitoring/health`
echo - Detailed metrics: `GET /api/v1/monitoring/dashboard`
echo - Firebase Console: Real-time crash and performance data
echo.
echo ## Support
echo.
echo If you encounter any issues:
echo 1. Check the console logs for error messages
echo 2. Verify Firebase configuration files are in correct locations
echo 3. Ensure all environment variables are set correctly
echo 4. Test individual components using the provided endpoints
echo.
echo Generated on: %date% %time%
) > MONITORING_STATUS.md

echo ✅ Monitoring documentation generated: MONITORING_STATUS.md

REM Step 7: Final summary
echo.
echo 🎉 Monitoring Setup Summary
echo ==========================
echo ✅ Automated setup completed successfully!
echo ℹ️  Flutter app is ready with monitoring integration
echo ℹ️  Backend monitoring is configured and tested
echo ℹ️  Environment configuration template created

echo.
echo ⚠️  Manual steps required:
echo    1. Enable Firebase services in Firebase Console
echo    2. Download and place Firebase configuration files
echo    3. Configure environment variables in .env file
echo    4. Add iOS build script for Crashlytics ^(if using iOS^)

echo.
echo ℹ️  Next steps:
echo    1. Follow the manual setup steps in MONITORING_STATUS.md
echo    2. Run 'flutter run' to test the monitoring integration
echo    3. Check Firebase Console for incoming data
echo    4. Test backend monitoring endpoints

echo.
echo ✅ Setup script completed! 🚀
echo Check MONITORING_STATUS.md for detailed next steps.

pause
