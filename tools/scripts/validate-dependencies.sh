#!/bin/bash

# 🔍 Dayliz App Dependency Validation Script
# This script validates Flutter dependencies and environment setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Main validation function
main() {
    log_info "Starting Dayliz App dependency validation..."
    
    # Check if we're in the right directory
    if [ ! -f "workspace.json" ]; then
        log_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Navigate to mobile app directory
    cd apps/mobile
    
    # Validate Flutter installation
    validate_flutter_installation
    
    # Validate pubspec.yaml
    validate_pubspec
    
    # Check dependency compatibility
    check_dependency_compatibility
    
    # Validate environment setup
    validate_environment
    
    # Test dependency resolution
    test_dependency_resolution
    
    log_success "All validations completed successfully!"
}

# Validate Flutter installation
validate_flutter_installation() {
    log_info "Validating Flutter installation..."
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    FLUTTER_VERSION=$(flutter --version | head -n 1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    DART_VERSION=$(dart --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    
    log_success "Flutter version: $FLUTTER_VERSION"
    log_success "Dart version: $DART_VERSION"
    
    # Check if versions match CI requirements
    EXPECTED_FLUTTER="3.24.5"
    if [ "$FLUTTER_VERSION" != "$EXPECTED_FLUTTER" ]; then
        log_warning "Flutter version mismatch. Expected: $EXPECTED_FLUTTER, Found: $FLUTTER_VERSION"
    fi
    
    # Run Flutter doctor
    log_info "Running Flutter doctor..."
    flutter doctor -v
}

# Validate pubspec.yaml
validate_pubspec() {
    log_info "Validating pubspec.yaml..."
    
    if [ ! -f "pubspec.yaml" ]; then
        log_error "pubspec.yaml not found in apps/mobile directory"
        exit 1
    fi
    
    # Check for required sections
    if ! grep -q "^dependencies:" pubspec.yaml; then
        log_error "Dependencies section not found in pubspec.yaml"
        exit 1
    fi
    
    if ! grep -q "^dev_dependencies:" pubspec.yaml; then
        log_error "Dev dependencies section not found in pubspec.yaml"
        exit 1
    fi
    
    # Check environment constraints
    SDK_CONSTRAINT=$(grep -A 1 "environment:" pubspec.yaml | grep "sdk:" | sed 's/.*sdk: //' | tr -d "'\"")
    log_info "SDK constraint: $SDK_CONSTRAINT"
    
    log_success "pubspec.yaml validation completed"
}

# Check dependency compatibility
check_dependency_compatibility() {
    log_info "Checking dependency compatibility..."
    
    # Create a temporary file for dependency analysis
    TEMP_FILE=$(mktemp)
    
    # Run pub deps to check for conflicts
    if flutter pub deps --style=compact > "$TEMP_FILE" 2>&1; then
        log_success "No dependency conflicts detected"
    else
        log_error "Dependency conflicts detected:"
        cat "$TEMP_FILE"
        rm "$TEMP_FILE"
        exit 1
    fi
    
    # Check for outdated packages
    log_info "Checking for outdated packages..."
    flutter pub outdated || log_warning "Some packages may be outdated"
    
    rm "$TEMP_FILE"
}

# Validate environment setup
validate_environment() {
    log_info "Validating environment setup..."
    
    # Check for .env file
    if [ -f ".env" ]; then
        log_success ".env file found"
    else
        log_warning ".env file not found - creating minimal version"
        echo "# Minimal environment configuration" > .env
        echo "# Add your environment variables here" >> .env
    fi
    
    # Check for required directories
    REQUIRED_DIRS=("assets/images" "assets/icons" "assets/animations")
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            log_success "Directory exists: $dir"
        else
            log_warning "Directory missing: $dir"
            mkdir -p "$dir"
            log_info "Created directory: $dir"
        fi
    done
    
    # Check for Android configuration
    if [ -f "android/app/build.gradle" ]; then
        log_success "Android configuration found"
    else
        log_warning "Android configuration may be incomplete"
    fi
}

# Test dependency resolution
test_dependency_resolution() {
    log_info "Testing dependency resolution..."
    
    # Backup existing pubspec.lock
    if [ -f "pubspec.lock" ]; then
        cp pubspec.lock pubspec.lock.backup
        log_info "Backed up existing pubspec.lock"
    fi
    
    # Clean pub cache
    log_info "Cleaning pub cache..."
    flutter pub cache clean
    
    # Remove pubspec.lock to force fresh resolution
    rm -f pubspec.lock
    
    # Attempt dependency resolution with retries
    MAX_ATTEMPTS=3
    for attempt in $(seq 1 $MAX_ATTEMPTS); do
        log_info "Dependency resolution attempt $attempt/$MAX_ATTEMPTS..."
        
        if flutter pub get --verbose; then
            log_success "Dependencies resolved successfully on attempt $attempt"
            break
        else
            if [ $attempt -eq $MAX_ATTEMPTS ]; then
                log_error "Dependency resolution failed after $MAX_ATTEMPTS attempts"
                
                # Restore backup if available
                if [ -f "pubspec.lock.backup" ]; then
                    mv pubspec.lock.backup pubspec.lock
                    log_info "Restored pubspec.lock backup"
                fi
                
                exit 1
            else
                log_warning "Attempt $attempt failed, retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done
    
    # Clean up backup
    rm -f pubspec.lock.backup
    
    # Verify resolution
    if [ -f "pubspec.lock" ]; then
        PACKAGE_COUNT=$(grep -c "^  [a-zA-Z]" pubspec.lock)
        log_success "Successfully resolved $PACKAGE_COUNT packages"
    else
        log_error "pubspec.lock was not generated"
        exit 1
    fi
}

# Run main function
main "$@"
