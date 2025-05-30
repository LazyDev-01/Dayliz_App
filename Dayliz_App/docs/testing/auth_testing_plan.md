# Authentication Testing Plan

This document outlines the testing strategy for the authentication system in the Dayliz App, with a focus on the registration functionality.

## Test Types

### 1. Unit Tests

Unit tests verify that individual components work as expected in isolation.

#### Domain Layer Tests
- `RegisterUseCase`: Test that it properly delegates to the repository and handles success/failure cases
- `LoginUseCase`: Test that it properly delegates to the repository and handles success/failure cases
- Other auth-related use cases

#### Data Layer Tests
- `AuthRepositoryImpl`: Test that it properly delegates to data sources, handles network connectivity, and transforms data
- `AuthSupabaseDataSource`: Test that it properly interacts with Supabase, handles errors, and transforms data
- `AuthLocalDataSource`: Test that it properly caches and retrieves user data

#### Presentation Layer Tests
- `AuthNotifier`: Test that it properly updates state based on use case results
- Other auth-related providers

### 2. Widget Tests

Widget tests verify that UI components render correctly and respond appropriately to user interactions.

- `CleanRegisterScreen`: Test form validation, error messages, and navigation
- `CleanLoginScreen`: Test form validation, error messages, and navigation
- Other auth-related screens

### 3. Integration Tests

Integration tests verify that multiple components work together correctly.

- Registration flow: Test the complete registration process from UI to data source
- Login flow: Test the complete login process from UI to data source
- Error handling: Test how errors propagate through the system

### 4. End-to-End Tests

End-to-end tests verify that the entire application works correctly from a user's perspective.

- Registration with new email: Test that a user can register with a new email and navigate to the home screen
- Registration with existing email: Test that appropriate error messages are shown
- Login with valid credentials: Test that a user can log in and navigate to the home screen
- Login with invalid credentials: Test that appropriate error messages are shown

## Test Coverage Goals

- Domain Layer: 90%+ coverage
- Data Layer: 80%+ coverage
- Presentation Layer: 70%+ coverage
- Overall: 80%+ coverage

## Test Environment

- Unit and Widget Tests: Local development environment
- Integration Tests: Local development environment with Supabase emulator or test instance
- End-to-End Tests: Test environment with real Supabase instance

## Test Data

- Test Users:
  - New user: Generated with unique email for each test run
  - Existing user: `test@example.com` / `Password123!`

## Test Execution

### Running Unit and Widget Tests

```bash
flutter test
```

### Running Integration Tests

```bash
flutter test integration_test/auth_flow_test.dart
```

## Test Maintenance

- Tests should be updated whenever the authentication system changes
- Test data should be refreshed periodically to ensure it remains valid
- Failed tests should be investigated promptly

## Specific Test Cases for Registration

1. **Valid Registration**
   - Input: Valid name, email, password, and phone
   - Expected: User is registered and navigated to home screen

2. **Email Already Exists**
   - Input: Valid name, existing email, valid password, and phone
   - Expected: Error message "Email id already exists!" is shown

3. **Invalid Email Format**
   - Input: Valid name, invalid email format, valid password, and phone
   - Expected: Validation error for email field

4. **Password Requirements Not Met**
   - Input: Valid name, valid email, password without required characters, and phone
   - Expected: Validation error for password field

5. **Passwords Don't Match**
   - Input: Valid name, valid email, valid password, different confirm password
   - Expected: Error message "Passwords do not match" is shown

6. **Network Error During Registration**
   - Input: Valid name, email, password, and phone, but no network connection
   - Expected: Error message about network connectivity is shown

7. **Server Error During Registration**
   - Input: Valid name, email, password, and phone, but server returns error
   - Expected: Error message about server error is shown

## Regression Testing

After fixing bugs or implementing new features, the following regression tests should be run:

1. Registration with new email
2. Registration with existing email
3. Login with valid credentials
4. Login with invalid credentials
5. Password reset flow
6. Email verification flow
7. Session persistence
8. Logout
