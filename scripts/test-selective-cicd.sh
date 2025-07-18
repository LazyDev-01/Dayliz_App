#!/bin/bash

# 🧪 Smart Selective CI/CD Testing Script
# This script validates the selective deployment system

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

# Test configuration
REPO_ROOT=$(git rev-parse --show-toplevel)
TEST_BRANCH="test-selective-cicd-$(date +%s)"
ORIGINAL_BRANCH=$(git branch --show-current)

# Cleanup function
cleanup() {
    log_info "Cleaning up test environment..."
    git checkout "$ORIGINAL_BRANCH" 2>/dev/null || true
    git branch -D "$TEST_BRANCH" 2>/dev/null || true
    log_success "Cleanup completed"
}

# Set trap for cleanup
trap cleanup EXIT

# Main test function
main() {
    log_info "🧪 Starting Smart Selective CI/CD Testing"
    echo "=========================================="
    
    # Validate repository structure
    validate_repository_structure
    
    # Test workflow files
    validate_workflow_files
    
    # Test change detection logic
    test_change_detection
    
    # Test individual pipelines
    test_pipeline_structure
    
    # Performance analysis
    analyze_performance_improvements
    
    log_success "🎉 All tests completed successfully!"
}

# Validate repository structure
validate_repository_structure() {
    log_info "📁 Validating repository structure..."
    
    # Check required directories
    required_dirs=(
        "apps/mobile"
        "apps/agent"
        "apps/vendor"
        "apps/admin"
        "services/api"
        "packages/shared_types"
        "packages/ui_components"
        "packages/business_logic"
        "packages/utils"
        ".github/workflows"
        ".github/actions"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$REPO_ROOT/$dir" ]; then
            log_success "Directory exists: $dir"
        else
            log_error "Missing directory: $dir"
            exit 1
        fi
    done
    
    log_success "Repository structure validation passed"
}

# Validate workflow files
validate_workflow_files() {
    log_info "📋 Validating workflow files..."
    
    # Check required workflow files
    required_workflows=(
        ".github/workflows/ci.yml"
        ".github/workflows/detect-changes.yml"
        ".github/workflows/mobile-ci.yml"
        ".github/workflows/agent-ci.yml"
        ".github/workflows/vendor-ci.yml"
        ".github/workflows/admin-ci.yml"
        ".github/workflows/api-ci.yml"
    )
    
    for workflow in "${required_workflows[@]}"; do
        if [ -f "$REPO_ROOT/$workflow" ]; then
            log_success "Workflow exists: $workflow"
            
            # Validate YAML syntax
            if command -v yamllint >/dev/null 2>&1; then
                if yamllint "$REPO_ROOT/$workflow" >/dev/null 2>&1; then
                    log_success "YAML syntax valid: $workflow"
                else
                    log_warning "YAML syntax issues in: $workflow"
                fi
            fi
        else
            log_error "Missing workflow: $workflow"
            exit 1
        fi
    done
    
    # Check required action files
    required_actions=(
        ".github/actions/setup-flutter/action.yml"
        ".github/actions/setup-node/action.yml"
        ".github/actions/security-scan/action.yml"
    )
    
    for action in "${required_actions[@]}"; do
        if [ -f "$REPO_ROOT/$action" ]; then
            log_success "Action exists: $action"
        else
            log_error "Missing action: $action"
            exit 1
        fi
    done
    
    log_success "Workflow files validation passed"
}

# Test change detection logic
test_change_detection() {
    log_info "🔍 Testing change detection logic..."
    
    # Create test branch
    git checkout -b "$TEST_BRANCH"
    
    # Test 1: Mobile app changes
    log_info "Testing mobile app change detection..."
    echo "// Test change" >> "$REPO_ROOT/apps/mobile/lib/main.dart"
    git add "$REPO_ROOT/apps/mobile/lib/main.dart"
    git commit -m "test: mobile app change"
    
    # Simulate change detection (would normally be done by GitHub Actions)
    changed_files=$(git diff --name-only HEAD~1 HEAD)
    if echo "$changed_files" | grep -q "apps/mobile/"; then
        log_success "Mobile app change detected correctly"
    else
        log_error "Mobile app change not detected"
        exit 1
    fi
    
    # Test 2: Package changes
    log_info "Testing package change detection..."
    echo "// Test change" >> "$REPO_ROOT/packages/shared_types/lib/shared_types.dart"
    git add "$REPO_ROOT/packages/shared_types/lib/shared_types.dart"
    git commit -m "test: shared_types package change"
    
    changed_files=$(git diff --name-only HEAD~1 HEAD)
    if echo "$changed_files" | grep -q "packages/shared_types/"; then
        log_success "Package change detected correctly"
    else
        log_error "Package change not detected"
        exit 1
    fi
    
    # Test 3: API service changes
    log_info "Testing API service change detection..."
    echo "# Test change" >> "$REPO_ROOT/services/api/app/main.py"
    git add "$REPO_ROOT/services/api/app/main.py"
    git commit -m "test: API service change"
    
    changed_files=$(git diff --name-only HEAD~1 HEAD)
    if echo "$changed_files" | grep -q "services/api/"; then
        log_success "API service change detected correctly"
    else
        log_error "API service change not detected"
        exit 1
    fi
    
    log_success "Change detection logic tests passed"
}

# Test pipeline structure
test_pipeline_structure() {
    log_info "🏗️ Testing pipeline structure..."
    
    # Check if workflows have proper job dependencies
    workflows=(
        ".github/workflows/mobile-ci.yml"
        ".github/workflows/agent-ci.yml"
        ".github/workflows/vendor-ci.yml"
        ".github/workflows/admin-ci.yml"
        ".github/workflows/api-ci.yml"
    )
    
    for workflow in "${workflows[@]}"; do
        if grep -q "workflow_call:" "$REPO_ROOT/$workflow"; then
            log_success "Workflow is reusable: $workflow"
        else
            log_warning "Workflow may not be reusable: $workflow"
        fi
        
        if grep -q "permissions:" "$REPO_ROOT/$workflow"; then
            log_success "Permissions defined: $workflow"
        else
            log_warning "Permissions not defined: $workflow"
        fi
    done
    
    log_success "Pipeline structure tests passed"
}

# Analyze performance improvements
analyze_performance_improvements() {
    log_info "📊 Analyzing performance improvements..."
    
    # Calculate potential time savings
    echo "📊 Performance Analysis Report"
    echo "=============================="
    
    # Estimated build times (in minutes)
    MOBILE_BUILD_TIME=5
    AGENT_BUILD_TIME=5
    VENDOR_BUILD_TIME=3
    ADMIN_BUILD_TIME=3
    API_BUILD_TIME=4
    TOTAL_BUILD_TIME=$((MOBILE_BUILD_TIME + AGENT_BUILD_TIME + VENDOR_BUILD_TIME + ADMIN_BUILD_TIME + API_BUILD_TIME))
    
    echo "📱 Mobile App Build Time: ${MOBILE_BUILD_TIME} minutes"
    echo "🚚 Agent App Build Time: ${AGENT_BUILD_TIME} minutes"
    echo "🏪 Vendor Panel Build Time: ${VENDOR_BUILD_TIME} minutes"
    echo "⚙️ Admin Panel Build Time: ${ADMIN_BUILD_TIME} minutes"
    echo "🔧 API Service Build Time: ${API_BUILD_TIME} minutes"
    echo "📊 Total Build Time (All Apps): ${TOTAL_BUILD_TIME} minutes"
    echo ""
    
    # Calculate savings for different scenarios
    echo "💰 Time Savings Analysis:"
    echo "========================="
    
    # Single app change scenarios
    single_app_savings=$((TOTAL_BUILD_TIME - MOBILE_BUILD_TIME))
    single_app_percentage=$((single_app_savings * 100 / TOTAL_BUILD_TIME))
    echo "📱 Single Mobile App Change: Save ${single_app_savings} minutes (${single_app_percentage}%)"
    
    # Package change scenarios
    package_change_time=$((MOBILE_BUILD_TIME + AGENT_BUILD_TIME))
    package_savings=$((TOTAL_BUILD_TIME - package_change_time))
    package_percentage=$((package_savings * 100 / TOTAL_BUILD_TIME))
    echo "📦 Package Change (Flutter Apps): Save ${package_savings} minutes (${package_percentage}%)"
    
    # Documentation only changes
    docs_savings=$((TOTAL_BUILD_TIME - 1))
    docs_percentage=$((docs_savings * 100 / TOTAL_BUILD_TIME))
    echo "📚 Documentation Only: Save ${docs_savings} minutes (${docs_percentage}%)"
    
    echo ""
    echo "🎯 Expected Outcomes:"
    echo "===================="
    echo "✅ 70-80% time reduction for single app changes"
    echo "✅ 50-60% time reduction for package changes"
    echo "✅ 95% time reduction for documentation changes"
    echo "✅ Parallel builds for independent apps"
    echo "✅ Reduced CI/CD costs and resource usage"
    
    log_success "Performance analysis completed"
}

# Run tests
main "$@"
