# Location-First User Experience Test Plan

## 🎯 **Testing Objectives**

Validate the complete location-first workflow implementation to ensure:
1. **Primary Goal**: Never shows "detecting location" on home page when GPS is already on
2. **Native UX**: Professional Android permission handling
3. **Performance**: Smooth, fast user experience
4. **Edge Cases**: Proper handling of all location scenarios

## 🧪 **Test Scenarios**

### **Scenario 1: New User - GPS ON + Permission GRANTED**
**Expected Flow**: Seamless home screen access

#### **Test Steps**:
1. Fresh app install
2. Enable GPS in device settings
3. Launch app
4. **Expected**: Splash screen (3s) → Home screen with full content
5. **Verify**: No "detecting location" message on home screen
6. **Verify**: Location indicator shows "Delivery Location Set"

#### **Success Criteria**:
- ✅ GPS check completes during splash screen
- ✅ Home screen loads immediately with full content
- ✅ No location detection UI on home screen
- ✅ Location indicator displays correct status

### **Scenario 2: New User - GPS OFF**
**Expected Flow**: Native Android GPS settings

#### **Test Steps**:
1. Fresh app install
2. Disable GPS in device settings
3. Launch app
4. **Expected**: Splash screen → Location setup modal
5. Tap "Enable" button
6. **Expected**: Native Android location settings dialog
7. Enable GPS in settings
8. Return to app
9. **Expected**: Automatic permission request (if needed)

#### **Success Criteria**:
- ✅ Native Android GPS settings dialog (not custom)
- ✅ Automatic permission request after GPS enabled
- ✅ Smooth transition to home screen after setup

### **Scenario 3: New User - GPS ON + Permission DENIED**
**Expected Flow**: Native Android permission dialog

#### **Test Steps**:
1. Fresh app install
2. Enable GPS in device settings
3. Launch app
4. **Expected**: Splash screen → Location setup modal
5. Tap "Enable" button
6. **Expected**: Native Android permission dialog
7. Grant permission
8. **Expected**: Automatic zone validation and home screen

#### **Success Criteria**:
- ✅ Native Android permission dialog (not custom)
- ✅ No intermediate consent dialogs
- ✅ Immediate zone validation after permission granted

### **Scenario 4: User Outside Delivery Zone**
**Expected Flow**: Limited content with clear messaging

#### **Test Steps**:
1. GPS ON + Permission GRANTED
2. User location outside delivery zones
3. Launch app
4. **Expected**: Splash screen → Home screen with limited content
5. **Verify**: "Outside Delivery Zone" banner
6. **Verify**: Browse-only functionality
7. **Verify**: "Try Different Location" button

#### **Success Criteria**:
- ✅ Clear "outside zone" messaging
- ✅ Browse functionality available
- ✅ Option to try different location

### **Scenario 5: Returning User - Setup Complete**
**Expected Flow**: Instant home screen access

#### **Test Steps**:
1. User with completed location setup
2. Launch app
3. **Expected**: Splash screen → Instant home screen with full content
4. **Verify**: No location setup prompts
5. **Verify**: Location indicator shows "Delivery Location Set"

#### **Success Criteria**:
- ✅ Instant home screen access
- ✅ No redundant location setup
- ✅ Correct location indicator status

### **Scenario 6: Location Indicator Interaction**
**Expected Flow**: Easy access to location setup

#### **Test Steps**:
1. On home screen
2. Tap location indicator in app bar
3. **Expected**: Location setup modal or settings
4. **Verify**: Easy location change functionality

#### **Success Criteria**:
- ✅ Location indicator is tappable
- ✅ Provides access to location setup
- ✅ Clear visual feedback

## 🔧 **Technical Validation**

### **State Management Tests**

#### **Location Status Persistence**
```dart
// Test location setup completion persistence
final isCompleted = await ref.read(isLocationSetupCompletedUseCaseProvider)(NoParams());
expect(isCompleted.isRight(), true);
```

#### **GPS Status Detection**
```dart
// Test GPS status detection during splash
final locationService = RealLocationService();
final isEnabled = await locationService.isLocationServiceEnabled();
expect(isEnabled, true);
```

#### **Permission Status Checking**
```dart
// Test permission status checking
final permission = await locationService.checkLocationPermission();
expect(permission, LocationPermission.whileInUse);
```

### **UI State Tests**

#### **Home UI State Transitions**
```dart
// Test UI state based on location status
testWidgets('Home screen shows correct UI state', (tester) async {
  // Setup location status
  // Pump widget
  // Verify correct UI state
});
```

#### **Location Indicator Display**
```dart
// Test location indicator shows correct status
testWidgets('Location indicator displays correct status', (tester) async {
  // Setup location setup status
  // Pump app bar
  // Verify indicator text
});
```

## 📱 **Device Testing Matrix**

### **Android Versions**
- ✅ Android 10 (API 29)
- ✅ Android 11 (API 30)
- ✅ Android 12 (API 31)
- ✅ Android 13 (API 33)
- ✅ Android 14 (API 34)

### **Permission Scenarios**
- ✅ First-time permission request
- ✅ Permission denied then granted
- ✅ Permission permanently denied
- ✅ Permission revoked after granting

### **GPS Scenarios**
- ✅ GPS enabled before app launch
- ✅ GPS disabled before app launch
- ✅ GPS toggled while app is running
- ✅ GPS accuracy variations

## 🚀 **Performance Testing**

### **Startup Performance**
- **Target**: Splash screen completes in 3 seconds with GPS check
- **Measure**: Time from app launch to home screen
- **Verify**: No additional delays for location detection

### **Memory Usage**
- **Monitor**: Memory consumption during location operations
- **Verify**: Proper cleanup of timers and subscriptions
- **Check**: No memory leaks in location services

### **Battery Impact**
- **Monitor**: Battery usage during GPS operations
- **Verify**: Efficient location detection (3-5 seconds max)
- **Check**: Proper GPS service cleanup

## 🐛 **Edge Case Testing**

### **Network Conditions**
- ✅ No internet connection during zone validation
- ✅ Slow network during location setup
- ✅ Network timeout scenarios

### **App Lifecycle**
- ✅ App backgrounded during location setup
- ✅ App killed during GPS detection
- ✅ App resumed after permission grant

### **Device Conditions**
- ✅ Low battery mode
- ✅ Airplane mode toggle
- ✅ Location services disabled system-wide

## 📊 **Success Metrics**

### **Primary Metrics**
1. **Zero "detecting location" messages** on home screen when GPS is ON
2. **Native permission dialogs** used exclusively (no custom dialogs)
3. **Sub-3-second** home screen access for returning users
4. **100% success rate** for location setup completion

### **Secondary Metrics**
1. **User satisfaction** with permission flow
2. **Reduced support tickets** related to location setup
3. **Improved app store ratings** for UX
4. **Higher conversion rates** for location-dependent features

## 🔄 **Regression Testing**

### **Existing Functionality**
- ✅ Home screen content loading
- ✅ Product browsing and search
- ✅ Cart functionality
- ✅ User authentication flow

### **Location-Related Features**
- ✅ Address management
- ✅ Delivery zone detection
- ✅ Order placement with location
- ✅ Geofencing functionality

## 📝 **Test Execution Checklist**

### **Pre-Testing Setup**
- [ ] Fresh app installation
- [ ] Clear app data and cache
- [ ] Reset location permissions
- [ ] Configure test device GPS settings

### **During Testing**
- [ ] Record screen for UX validation
- [ ] Monitor console logs for errors
- [ ] Check network requests
- [ ] Verify state persistence

### **Post-Testing Validation**
- [ ] Verify no memory leaks
- [ ] Check error logs
- [ ] Validate performance metrics
- [ ] Document any issues found

---

**Test Plan Status**: 📋 **READY FOR EXECUTION**  
**Automation Coverage**: 🤖 **UNIT TESTS READY**  
**Manual Testing**: 👥 **SCENARIOS DEFINED**
