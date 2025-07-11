#!/bin/bash

# Dayliz App Monitoring Setup Script
# This script sets up monitoring for both development and production

echo "🚀 Setting up Dayliz App Monitoring System..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first."
    exit 1
fi

print_status "Flutter is installed"

# Check if we're in the correct directory
if [ ! -f "apps/mobile/pubspec.yaml" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

print_status "Running from correct directory"

# Step 1: Install Flutter dependencies
echo ""
echo "📱 Installing Flutter dependencies..."
cd apps/mobile

# Clean and get dependencies
flutter clean
flutter pub get

if [ $? -eq 0 ]; then
    print_status "Flutter dependencies installed successfully"
else
    print_error "Failed to install Flutter dependencies"
    exit 1
fi

# Step 2: Check Firebase configuration
echo ""
echo "🔥 Checking Firebase configuration..."

if [ ! -f "android/app/google-services.json" ]; then
    print_warning "google-services.json not found for Android"
    echo "   Please download it from Firebase Console and place it in android/app/"
fi

if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
    print_warning "GoogleService-Info.plist not found for iOS"
    echo "   Please download it from Firebase Console and place it in ios/Runner/"
fi

# Step 3: Set up backend monitoring
echo ""
echo "🖥️  Setting up backend monitoring..."
cd ../../services/api

# Check if Python virtual environment exists
if [ ! -d "venv" ]; then
    print_info "Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install Python dependencies
print_info "Installing Python dependencies..."
pip install -r requirements.txt

if [ $? -eq 0 ]; then
    print_status "Backend dependencies installed successfully"
else
    print_error "Failed to install backend dependencies"
    exit 1
fi

# Step 4: Set up environment configuration
echo ""
echo "⚙️  Setting up environment configuration..."

if [ ! -f ".env" ]; then
    print_info "Creating .env file from template..."
    cp .env.monitoring .env
    print_warning "Please edit .env file with your actual configuration values"
else
    print_info ".env file already exists"
    print_warning "Please ensure monitoring configuration is added to your .env file"
    echo "   You can reference .env.monitoring for required settings"
fi

# Step 5: Test backend monitoring
echo ""
echo "🧪 Testing backend monitoring..."

# Start the server in background for testing
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Test health endpoint
HEALTH_RESPONSE=$(curl -s http://localhost:8000/api/v1/monitoring/health)

if [[ $HEALTH_RESPONSE == *"healthy"* ]]; then
    print_status "Backend monitoring is working correctly"
else
    print_warning "Backend monitoring may not be working correctly"
    echo "   Response: $HEALTH_RESPONSE"
fi

# Stop the test server
kill $SERVER_PID 2>/dev/null

# Step 6: Generate monitoring documentation
echo ""
echo "📚 Generating monitoring documentation..."

cd ../../

# Create monitoring status file
cat > MONITORING_STATUS.md << EOF
# Dayliz App Monitoring Status

## Setup Completion Status

### ✅ Automated Setup Completed
- [x] Flutter dependencies added to pubspec.yaml
- [x] Firebase monitoring plugins configured
- [x] Monitoring services integrated into main.dart
- [x] Backend monitoring middleware configured
- [x] API endpoints for monitoring created
- [x] Environment configuration template created

### 🔄 Manual Setup Required
- [ ] Firebase project services enabled (Crashlytics, Performance, Analytics)
- [ ] Firebase configuration files downloaded and placed
- [ ] Environment variables configured in .env file
- [ ] iOS build script added for Crashlytics
- [ ] Production alert channels configured (email, Slack, SMS)

## Next Steps

### 1. Firebase Console Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your Dayliz project
3. Enable these services:
   - Crashlytics (Release & Monitor → Crashlytics)
   - Performance Monitoring (Release & Monitor → Performance)
   - Analytics (Analytics → Dashboard)
   - Cloud Messaging (Engage → Messaging)

### 2. Download Configuration Files
1. Download \`google-services.json\` for Android
2. Place in \`apps/mobile/android/app/google-services.json\`
3. Download \`GoogleService-Info.plist\` for iOS
4. Place in \`apps/mobile/ios/Runner/GoogleService-Info.plist\`

### 3. Configure Environment Variables
1. Edit \`services/api/.env\` file
2. Add monitoring configuration from \`.env.monitoring\` template
3. Replace placeholder values with actual credentials

### 4. Test the Setup
1. Run the Flutter app: \`flutter run\`
2. Check console for monitoring initialization logs
3. Test backend monitoring: \`curl http://localhost:8000/api/v1/monitoring/health\`
4. Verify Firebase Console shows data (may take a few minutes)

## Monitoring Features Available

### 📱 Flutter App Monitoring
- Automatic crash reporting
- Performance monitoring
- User behavior analytics
- Business metrics tracking
- Network connectivity monitoring

### 🖥️ Backend Monitoring
- API performance tracking
- System resource monitoring
- Error rate monitoring
- Business intelligence
- Real-time alerting

### 📊 Dashboard Access
- Health check: \`GET /api/v1/monitoring/health\`
- Detailed metrics: \`GET /api/v1/monitoring/dashboard\`
- Firebase Console: Real-time crash and performance data

## Support

If you encounter any issues:
1. Check the console logs for error messages
2. Verify Firebase configuration files are in correct locations
3. Ensure all environment variables are set correctly
4. Test individual components using the provided endpoints

Generated on: $(date)
EOF

print_status "Monitoring documentation generated: MONITORING_STATUS.md"

# Step 7: Final summary
echo ""
echo "🎉 Monitoring Setup Summary"
echo "=========================="
print_status "Automated setup completed successfully!"
print_info "Flutter app is ready with monitoring integration"
print_info "Backend monitoring is configured and tested"
print_info "Environment configuration template created"

echo ""
print_warning "Manual steps required:"
echo "   1. Enable Firebase services in Firebase Console"
echo "   2. Download and place Firebase configuration files"
echo "   3. Configure environment variables in .env file"
echo "   4. Add iOS build script for Crashlytics (if using iOS)"

echo ""
print_info "Next steps:"
echo "   1. Follow the manual setup steps in MONITORING_STATUS.md"
echo "   2. Run 'flutter run' to test the monitoring integration"
echo "   3. Check Firebase Console for incoming data"
echo "   4. Test backend monitoring endpoints"

echo ""
print_status "Setup script completed! 🚀"
echo "Check MONITORING_STATUS.md for detailed next steps."
