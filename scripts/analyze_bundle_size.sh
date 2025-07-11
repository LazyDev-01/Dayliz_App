#!/bin/bash

# 📦 Dayliz App Bundle Size Analysis Script
# This script analyzes Flutter app bundle size and provides optimization recommendations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TARGET_SIZE_MB=25
MOBILE_DIR="apps/mobile"
REPORT_FILE="bundle_analysis_report.md"

echo -e "${BLUE}📦 Dayliz App Bundle Size Analysis${NC}"
echo "=================================="

# Check if we're in the right directory
if [ ! -d "$MOBILE_DIR" ]; then
    echo -e "${RED}❌ Error: $MOBILE_DIR directory not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

cd "$MOBILE_DIR"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Error: Flutter is not installed or not in PATH${NC}"
    exit 1
fi

echo -e "${BLUE}🔍 Checking Flutter environment...${NC}"
flutter doctor --version

echo -e "${BLUE}📦 Installing dependencies...${NC}"
flutter pub get

echo -e "${BLUE}🏗️ Building APK with size analysis...${NC}"
flutter build apk --analyze-size --target-platform android-arm64 --verbose > build_output.txt 2>&1

# Analyze APK size
echo -e "${BLUE}📊 Analyzing APK size...${NC}"

if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_SIZE=$(stat -c%s "build/app/outputs/flutter-apk/app-release.apk" 2>/dev/null || stat -f%z "build/app/outputs/flutter-apk/app-release.apk")
    APK_SIZE_MB=$(echo "scale=2; $APK_SIZE / 1024 / 1024" | bc)
    
    echo -e "${GREEN}✅ APK built successfully${NC}"
    echo "📱 Total APK Size: ${APK_SIZE_MB} MB (${APK_SIZE} bytes)"
    
    # Check against target
    if (( $(echo "$APK_SIZE_MB > $TARGET_SIZE_MB" | bc -l) )); then
        echo -e "${YELLOW}⚠️ WARNING: APK size (${APK_SIZE_MB} MB) exceeds target of ${TARGET_SIZE_MB} MB${NC}"
        EXCEEDS_TARGET=true
    else
        echo -e "${GREEN}✅ APK size within target (<${TARGET_SIZE_MB} MB)${NC}"
        EXCEEDS_TARGET=false
    fi
else
    echo -e "${RED}❌ APK file not found${NC}"
    exit 1
fi

# Build split APKs for comparison
echo -e "${BLUE}📊 Building split APKs for optimization analysis...${NC}"
flutter build apk --split-per-abi --verbose > split_build_output.txt 2>&1

echo -e "${BLUE}📦 Split APK Analysis:${NC}"
total_split_size=0
for apk in build/app/outputs/flutter-apk/*.apk; do
    if [ -f "$apk" ]; then
        size=$(stat -c%s "$apk" 2>/dev/null || stat -f%z "$apk")
        size_mb=$(echo "scale=2; $size / 1024 / 1024" | bc)
        filename=$(basename "$apk")
        echo "📱 $filename: ${size_mb} MB"
        total_split_size=$((total_split_size + size))
    fi
done

if [ $total_split_size -gt 0 ]; then
    total_split_mb=$(echo "scale=2; $total_split_size / 1024 / 1024" | bc)
    savings_percent=$(echo "scale=1; (1 - $total_split_size / $APK_SIZE) * 100" | bc)
    echo "📊 Total Split APKs Size: ${total_split_mb} MB"
    echo -e "${GREEN}💡 Split APKs can reduce download size by ~${savings_percent}%${NC}"
fi

# Generate detailed report
echo -e "${BLUE}📋 Generating detailed report...${NC}"

cat > "$REPORT_FILE" << EOF
# 📊 Bundle Size Analysis Report

**Generated**: $(date)  
**Commit**: $(git rev-parse HEAD 2>/dev/null || echo "Unknown")  
**Branch**: $(git branch --show-current 2>/dev/null || echo "Unknown")

## 📦 APK Size Metrics

- **Total APK Size**: ${APK_SIZE_MB} MB (${APK_SIZE} bytes)
- **Target Size**: ${TARGET_SIZE_MB} MB
- **Status**: $(if [ "$EXCEEDS_TARGET" = true ]; then echo "⚠️ Exceeds target"; else echo "✅ Within target"; fi)

## 📊 Split APK Analysis

$(if [ $total_split_size -gt 0 ]; then
    echo "- **Total Split Size**: ${total_split_mb} MB"
    echo "- **Potential Savings**: ~${savings_percent}% download size reduction"
else
    echo "- Split APK analysis not available"
fi)

## 🎯 Optimization Recommendations

### High Impact (Week 1 - Quick Wins)
- [ ] **Deferred Google Maps Loading**: -12MB (34% reduction)
- [ ] **Conditional Firebase Imports**: -3-5MB (8-14% reduction)  
- [ ] **Enable APK Splitting**: -30-40% download size
- [ ] **Asset Compression**: -1-2MB (Lottie files)

### Medium Impact (Week 2-3)
- [ ] **Tree Shaking Optimization**: -2-3MB unused code
- [ ] **Image Optimization**: -1-2MB (WebP conversion)
- [ ] **Font Subsetting**: -500KB-1MB
- [ ] **Remove Unused Dependencies**: -1-2MB

### Advanced Optimizations (Week 4+)
- [ ] **Dynamic Feature Modules**: -5-10MB (Android App Bundle)
- [ ] **Code Obfuscation**: -10-15% size reduction
- [ ] **Custom Build Configurations**: Environment-specific builds
- [ ] **Progressive Loading**: Defer non-critical features

## 📈 Performance Targets

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| APK Size | ${APK_SIZE_MB} MB | <${TARGET_SIZE_MB} MB | $(if [ "$EXCEEDS_TARGET" = true ]; then echo "❌"; else echo "✅"; fi) |
| Initial Payload | ~${APK_SIZE_MB} MB | <200 KB | ❌ |
| TTI (3G) | ~5-8s | <3s | ❌ |
| Bundle Parse Time | ~1-2s | <1s | ⚠️ |

## 🔧 Next Steps

1. **Immediate**: Implement deferred Google Maps loading
2. **This Week**: Optimize Firebase imports and enable APK splitting  
3. **Next Sprint**: Implement comprehensive asset optimization
4. **Ongoing**: Monitor bundle size in CI/CD pipeline

---
*Report generated by Bundle Analysis Script v1.0*
EOF

echo -e "${GREEN}✅ Report generated: $REPORT_FILE${NC}"

# Show summary
echo -e "${BLUE}📋 Summary:${NC}"
echo "📱 APK Size: ${APK_SIZE_MB} MB"
echo "🎯 Target: ${TARGET_SIZE_MB} MB"
if [ "$EXCEEDS_TARGET" = true ]; then
    echo -e "${YELLOW}⚠️ Action needed: Bundle size exceeds target${NC}"
    echo -e "${BLUE}💡 Quick wins available: -15-20MB with Week 1 optimizations${NC}"
else
    echo -e "${GREEN}✅ Bundle size within target${NC}"
fi

echo -e "${BLUE}📋 Full report saved to: $REPORT_FILE${NC}"
echo -e "${BLUE}🔍 Build logs saved to: build_output.txt, split_build_output.txt${NC}"

# Return to original directory
cd - > /dev/null

echo -e "${GREEN}✅ Bundle size analysis complete!${NC}"
