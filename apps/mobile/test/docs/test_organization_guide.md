# Test Organization Guide

## Overview

This document outlines the test organization structure for the Dayliz App, following Flutter best practices and clean architecture principles.

## Directory Structure

```
test/
├── unit/                    # Unit tests for isolated components
│   ├── core/               # Core functionality (services, utils, etc.)
│   ├── data/               # Data layer (repositories, data sources, models)
│   ├── domain/             # Domain layer (entities, use cases)
│   └── presentation/       # Presentation layer (providers, state management)
├── widget/                 # Widget tests for UI components
│   ├── screens/           # Screen-specific widget tests
│   ├── widgets/           # Individual widget tests
│   └── common/            # Common widget tests
├── integration/            # Integration tests for complete user flows
│   ├── auth_flow_test.dart
│   ├── checkout_flow_test.dart
│   └── geofencing_demo_test.dart
├── fixtures/               # Test data and mock objects
│   ├── test_subcategories.dart
│   ├── mock_data/
│   └── sample_responses/
├── helpers/                # Test utilities and helper functions
│   ├── test_helpers.dart
│   ├── mock_providers.dart
│   └── test_constants.dart
└── docs/                   # Test documentation
    ├── test_organization_guide.md (this file)
    ├── testing_best_practices.md
    └── context7_test.md
```

## Test Types

### 1. Unit Tests (`test/unit/`)

Test individual functions, methods, and classes in isolation.

**Examples:**
- Repository implementations
- Use case logic
- Entity validation
- Service methods
- Utility functions

**Naming Convention:** `*_test.dart`

**Location:** Mirror the `lib/` directory structure

### 2. Widget Tests (`test/widget/`)

Test individual widgets and their interactions.

**Examples:**
- Screen layouts
- Widget behavior
- User interactions
- State changes
- Navigation

**Naming Convention:** `*_widget_test.dart`

### 3. Integration Tests (`test/integration/`)

Test complete user flows and feature interactions.

**Examples:**
- Authentication flow
- Checkout process
- Search functionality
- Cart operations

**Naming Convention:** `*_integration_test.dart`

## File Organization Rules

### 1. Mirror Source Structure
Test files should mirror the structure of the `lib/` directory:

```
lib/data/repositories/auth_repository_impl.dart
→ test/unit/data/repositories/auth_repository_impl_test.dart

lib/presentation/screens/home/home_screen.dart
→ test/widget/screens/home/home_screen_widget_test.dart
```

### 2. Naming Conventions

- **Unit tests:** `{class_name}_test.dart`
- **Widget tests:** `{widget_name}_widget_test.dart`
- **Integration tests:** `{feature_name}_integration_test.dart`
- **Mock files:** `{class_name}_test.mocks.dart`

### 3. Test Data Location

- **Fixtures:** `test/fixtures/` - Static test data
- **Mocks:** `test/helpers/` - Mock implementations
- **Sample responses:** `test/fixtures/sample_responses/` - API response samples

## Best Practices

### 1. Test Organization
- Group related tests using `group()` blocks
- Use descriptive test names that explain the expected behavior
- Keep tests focused on a single behavior or outcome

### 2. Test Data Management
- Use fixtures for consistent test data
- Create helper functions for common test setups
- Avoid hardcoded values in tests

### 3. Mock Management
- Use the `mockito` package for creating mocks
- Store mock implementations in `test/helpers/`
- Create provider overrides for testing Riverpod providers

### 4. Test Helpers
- Create reusable test utilities in `test/helpers/`
- Use helper functions for common widget testing patterns
- Provide utilities for authentication and state setup

## Running Tests

### Command Line
```bash
# All tests
flutter test

# Specific test types
flutter test test/unit
flutter test test/widget
flutter test test/integration

# Specific test file
flutter test test/unit/data/repositories/auth_repository_impl_test.dart

# With coverage
flutter test --coverage
```

### Workspace Scripts
```bash
npm run mobile:test           # All tests
npm run mobile:test:unit      # Unit tests only
npm run mobile:test:widget    # Widget tests only
npm run mobile:test:integration # Integration tests only
npm run mobile:test:coverage  # With coverage report
```

## Debug vs Test Code

### Debug Code Location
Debug screens and utilities are located in:
- `lib/debug/` - Debug-only code that should not be in production
- `lib/presentation/screens/debug/` - Legacy debug screens (to be moved)

### Test Code Location
All test-related code should be in:
- `test/` - All test files
- Never in `lib/` directory

## Migration Checklist

When moving test files to the new structure:

- [ ] Move test files from root to appropriate test subdirectories
- [ ] Update import paths in test files
- [ ] Remove test files from `lib/` directory
- [ ] Update test documentation
- [ ] Verify all tests still pass
- [ ] Update CI/CD scripts if necessary

## Maintenance

### Regular Tasks
1. Review and update test organization quarterly
2. Remove obsolete test files
3. Update test documentation
4. Ensure test coverage meets project standards (target: 80%+)

### Code Review Guidelines
- Ensure new tests follow the organization structure
- Verify test files are in correct directories
- Check that test names are descriptive
- Confirm proper use of test helpers and fixtures
