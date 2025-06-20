# 🔧 CI/CD Pipeline Troubleshooting Guide

## 📋 Overview

This guide provides comprehensive troubleshooting steps for the Dayliz App CI/CD pipeline failures and solutions for common issues.

## 🚨 Common Pipeline Failures

### 1. **Dependency Resolution Failures**

**Symptoms:**
- `flutter pub get` fails in CI
- "Version solving failed" errors
- Package compatibility issues

**Solutions:**

#### A. Version Compatibility Check
```bash
# Check Flutter/Dart version compatibility
flutter --version
dart --version

# Verify pubspec.yaml constraints
grep -A 5 "environment:" apps/mobile/pubspec.yaml
```

#### B. Clear and Retry
```bash
# Clear pub cache
flutter pub cache clean

# Remove pubspec.lock and retry
rm apps/mobile/pubspec.lock
cd apps/mobile && flutter pub get
```

#### C. Dependency Audit
```bash
# Check for conflicting dependencies
cd apps/mobile
flutter pub deps --style=compact
flutter pub outdated
```

### 2. **Network Connectivity Issues**

**Symptoms:**
- Timeout errors during `pub get`
- Cannot reach pub.dev
- SSL/TLS errors

**Solutions:**

#### A. Network Diagnostics
```bash
# Test connectivity
curl -I https://pub.dev/
ping pub.dev

# Check DNS resolution
nslookup pub.dev
```

#### B. Retry with Exponential Backoff
```bash
# Implemented in enhanced CI workflow
for attempt in 1 2 3; do
  if flutter pub get; then break; fi
  sleep $((attempt * 5))
done
```

### 3. **Environment Configuration Issues**

**Symptoms:**
- Missing environment variables
- API key validation failures
- Build configuration errors

**Solutions:**

#### A. Environment Validation
```bash
# Check required environment variables
echo "GOOGLE_MAPS_API_KEY: ${GOOGLE_MAPS_API_KEY:-NOT_SET}"

# Validate .env file
if [ -f "apps/mobile/.env" ]; then
  echo "✅ .env file exists"
else
  echo "❌ .env file missing"
fi
```

#### B. Secret Configuration
1. Go to GitHub repository settings
2. Navigate to Secrets and variables > Actions
3. Add required secrets:
   - `GOOGLE_MAPS_API_KEY`
   - `GOOGLE_MAPS_API_KEY_PROD`
   - `FIREBASE_APP_ID_STAGING`
   - `FIREBASE_SERVICE_ACCOUNT`

## 🔍 Debugging Steps

### 1. **Local Reproduction**

```bash
# Clone and setup locally
git clone <repository>
cd Project_dayliz/apps/mobile

# Reproduce CI environment
flutter --version  # Should match CI version (3.24.5)
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

### 2. **CI Logs Analysis**

**Key areas to check:**
- Dependency resolution step logs
- Flutter doctor output
- Network connectivity tests
- Environment variable validation

### 3. **Dependency Validation Script**

```bash
#!/bin/bash
# Save as scripts/validate-dependencies.sh

echo "🔍 Validating Flutter dependencies..."

cd apps/mobile

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | head -n 1)
echo "Flutter Version: $FLUTTER_VERSION"

# Check Dart SDK version
DART_VERSION=$(dart --version)
echo "Dart Version: $DART_VERSION"

# Validate pubspec.yaml
if [ ! -f "pubspec.yaml" ]; then
  echo "❌ pubspec.yaml not found"
  exit 1
fi

# Check for version conflicts
echo "🔍 Checking for dependency conflicts..."
flutter pub deps --style=compact > deps_output.txt 2>&1

if grep -q "version solving failed" deps_output.txt; then
  echo "❌ Version solving conflicts detected"
  cat deps_output.txt
  exit 1
fi

echo "✅ Dependency validation completed"
```

## 🛠️ Enhanced CI Features

### 1. **Retry Mechanisms**
- Automatic retry for transient failures
- Exponential backoff for network issues
- Pub cache clearing and regeneration

### 2. **Enhanced Debugging**
- Verbose logging for all operations
- Environment validation checks
- Network connectivity tests
- Detailed error reporting

### 3. **Fallback Strategies**
- Continue on non-critical failures
- Alternative build configurations
- Graceful degradation for optional features

## 📊 Monitoring and Alerts

### 1. **Pipeline Health Metrics**
- Success/failure rates
- Build duration trends
- Dependency resolution times

### 2. **Automated Notifications**
- Slack/email alerts for failures
- Daily health reports
- Security scan summaries

## 🔧 Maintenance Tasks

### 1. **Weekly Tasks**
- Review dependency updates
- Check for security vulnerabilities
- Update Flutter/Dart versions

### 2. **Monthly Tasks**
- Audit CI/CD performance
- Review and update secrets
- Clean up old artifacts

## 📞 Support and Escalation

### 1. **Self-Service**
- Check this troubleshooting guide
- Review recent commits for breaking changes
- Validate local environment setup

### 2. **Team Escalation**
- Create GitHub issue with:
  - Pipeline run URL
  - Error logs
  - Environment details
  - Steps already attempted

## 🔗 Useful Resources

- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Pub.dev Package Management](https://dart.dev/tools/pub)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)

---

**Last Updated:** 2025-06-20
**Version:** 1.0.0
**Maintainer:** Dayliz Development Team
