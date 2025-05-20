# Future Cleanup Tasks

This document tracks pending cleanup tasks for the Dayliz App project. It serves as a reference for future work to gradually remove legacy code and complete the migration to clean architecture.

## Legend

- ✅ Completed - Task has been fully implemented
- 🔄 In Progress - Work has started but is not yet complete
- 📝 Planned - Task is planned but not yet started

## Progress Summary

| Category | Status | Completed Tasks | Total Tasks | Progress |
|----------|--------|-----------------|-------------|----------|
| Address Implementation | 🔄 In Progress | 8 | 11 | 73% |
| Authentication | 🔄 In Progress | 1 | 4 | 25% |
| Product Management | 🔄 In Progress | 1 | 4 | 25% |
| Cart Management | ✅ Completed | 3 | 3 | 100% |
| Checkout Management | ✅ Completed | 3 | 3 | 100% |
| Main Screen | ✅ Completed | 3 | 3 | 100% |
| Order Confirmation | ✅ Completed | 3 | 3 | 100% |
| Order Management | 📝 Planned | 0 | 3 | 0% |
| User Profile | ✅ Completed | 3 | 3 | 100% |
| General Code Cleanup | 🔄 Ongoing | 0 | 5 | 0% |
| Database Schema Alignment | 🔄 In Progress | 1 | 3 | 33% |
| Testing | 📝 Planned | 0 | 3 | 0% |
| Documentation | 🔄 In Progress | 1 | 3 | 33% |
| **Overall** | 🔄 In Progress | **19** | **46** | **41%** |

## Address Implementation (Legacy → Clean) - 🔄 In Progress

### Completed Improvements

1. **Remove address label field completely** ✅
   - Description: Removed the redundant label field since we already have address type
   - Changes made:
     - Removed label field from Address entity
     - Updated address form to not use label field
     - Updated all data sources to not use label field
     - Updated address card to display address type instead of label

2. **Hide City, State, Country, Postal Code fields** ✅
   - Description: These fields are now hidden from the UI but still stored in the database
   - Changes made:
     - Wrapped fields in a Visibility widget with visible: false
     - Maintained state for these fields to ensure they're still saved to the database
     - Removed validation requirements for these hidden fields

3. **Rename placeholder fields** ✅
   - Description: Updated field labels to be more user-friendly
   - Changes made:
     - Changed "Address Line 1" to "Area/Street"
     - Changed "Address Line 2 (Optional)" to "House no/Building/Floor"
     - Changed "Phone Number (Optional)" to "Recipient Number"
     - Changed "Landmark (Near...)" to "Landmark"
     - Updated validation messages to match new field names

4. **Remove "Additional Information" field** ✅
   - Description: Removed this optional field from the UI
   - Changes made:
     - Removed the field from the UI
     - Set the value to null when saving the address
     - Maintained backward compatibility with existing addresses

5. **Replace Address Type Dropdown with Buttons** ✅
   - Description: Replaced dropdown with three selectable buttons for better UX
   - Changes made:
     - Created three buttons for Home, Work, and Other address types
     - Added visual indication for the selected button
     - Implemented custom validation for address type selection
     - Added icons to make the buttons more intuitive

6. **Rearrange and Improve Address Form Fields** ✅
   - Description: Rearranged fields in a more logical order and improved labels
   - Changes made:
     - Reordered fields: Recipient Name → Recipient Phone → Address Type → House No → Area/Street → Landmark
     - Renamed "Recipient Number" to "Recipient Phone" for clarity
     - Enhanced "House No/Building/Floor" hint text for better understanding
     - Made Landmark explicitly optional in the UI
     - Made address type buttons more compact with horizontal icon and text alignment

7. **Create Common Back Button Widget** ✅
   - Description: Created a reusable back button widget for consistent navigation
   - Changes made:
     - Implemented BackButtonWidget with configurable options
     - Added AppBar extension for easy integration
     - Added back button to Address List Screen
     - Created documentation for usage throughout the app
     - Fixed deprecated withOpacity method in Address List Screen

### Remaining Tasks

1. **Remove Legacy Address Model**
   - File: `lib/models/address.dart`
   - Description: This model class is still referenced in some parts of the codebase but has been replaced by the clean architecture Address entity.
   - Dependencies to update before removal:
     - `lib/main.dart` - Update route conversion logic
     - `lib/widgets/address_selection_widget.dart` - Replace with clean architecture widget
     - `lib/screens/checkout/checkout_screen.dart` - Update to use clean architecture components

2. **Remove Legacy Address Service**
   - File: `lib/services/address_service.dart`
   - Description: Contains references to both clean architecture and legacy implementations.
   - Action: Either remove completely or update to use only clean architecture repositories.

3. **Remove Legacy Address Provider**
   - File: `lib/providers/address_provider.dart`
   - Description: State management for legacy address implementation.
   - Action: Remove after ensuring all screens use clean architecture providers.

4. **Update Address Selection Widget in Legacy Screens** ✅
   - Files: Any remaining screens that use the legacy address selection widget
   - Description: Replace with `CleanAddressSelectionWidget` to ensure consistent UI and behavior.
   - Status: Completed - Created and implemented CleanAddressSelectionWidget

### Completion Criteria

- All references to legacy address models are removed
- All address-related functionality uses clean architecture components
- No imports of legacy address files remain in the codebase
- All address-related UI components use the clean architecture implementation

## Authentication (Legacy → Clean) - 🔄 In Progress

### Remaining Tasks

1. **Complete Google Sign-In Implementation**
   - Description: Implement Google authentication in the clean architecture auth screens.
   - Action: Configure Google client IDs properly and implement sign-in flow.

2. **Remove Legacy Auth Screens** ✅
   - Files:
     - `lib/screens/auth/login_screen.dart`
     - `lib/screens/auth/register_screen.dart`
     - `lib/screens/auth/forgot_password_screen.dart`
   - Description: These screens have been replaced by clean architecture implementations.
   - Status: Completed - Legacy auth screens have been removed

3. **Remove Legacy Auth Services**
   - File: `lib/services/auth_service.dart`
   - Description: Contains legacy authentication logic that has been replaced.

4. **Update Auth State Management**
   - Description: Ensure all parts of the app use the clean architecture auth providers.
   - Action: Check for any remaining references to legacy auth state.

### Completion Criteria

- All authentication flows use clean architecture implementation
- Google Sign-In works properly with Supabase
- No legacy auth screens or services remain in the codebase
- All auth state management uses clean architecture providers

## Product Management (Legacy → Clean) - 🔄 In Progress

### Remaining Tasks

1. **Remove Product Attributes** ✅
   - Files:
     - `lib/models/product_color.dart`
     - `lib/models/product_size.dart`
   - Description: These entities are being removed from the clean architecture implementation.
   - Status: Completed - Product attributes have been removed from clean architecture

2. **Update Product Detail Screen**
   - File: `lib/screens/product/product_detail_screen.dart`
   - Description: Replace with clean architecture implementation.

3. **Update Product List Screen**
   - File: `lib/screens/product/product_list_screen.dart`
   - Description: Replace with clean architecture implementation.

4. **Remove Legacy Product Service**
   - File: `lib/services/product_service.dart`
   - Description: Contains legacy product management logic.

### Completion Criteria

- All product-related functionality uses clean architecture components
- Product attributes are completely removed from the codebase
- All product screens use clean architecture implementations

## Cart Management (Legacy → Clean) - ✅ Completed

### Completed Tasks

1. **Update Cart Screen** ✅
   - File: `lib/screens/cart_screen.dart`
   - Description: Replaced with clean architecture implementation.
   - Status: Completed - Legacy cart screen has been removed

2. **Remove Legacy Cart Service** ✅
   - File: `lib/services/cart_service.dart`
   - Description: Contains legacy cart management logic.
   - Status: Completed - Using clean architecture cart services

3. **Update Cart Provider** ✅
   - File: `lib/providers/cart_provider.dart`
   - Description: Replace with clean architecture providers.
   - Status: Completed - Using clean architecture cart providers

### Completion Criteria

- All cart-related functionality uses clean architecture components
- Cart state management uses clean architecture providers
- Cart UI uses clean architecture components

## Checkout Management (Legacy → Clean) - ✅ Completed

### Completed Tasks

1. **Update Checkout Screen** ✅
   - File: `lib/screens/checkout/checkout_screen.dart`
   - Description: Replaced with clean architecture implementation.
   - Status: Completed - Legacy checkout screen has been removed

2. **Remove Legacy Checkout Service** ✅
   - Description: Contains legacy checkout management logic.
   - Status: Completed - Using clean architecture checkout services

3. **Update Checkout Provider** ✅
   - Description: Replace with clean architecture providers.
   - Status: Completed - Using clean architecture checkout providers

### Completion Criteria

- All checkout-related functionality uses clean architecture components
- Checkout state management uses clean architecture providers
- Checkout UI uses clean architecture components

## Main Screen (Legacy → Clean) - ✅ Completed

### Completed Tasks

1. **Update Main Screen** ✅
   - File: `lib/screens/home/main_screen.dart`
   - Description: Replaced with clean architecture implementation.
   - Status: Completed - Legacy main screen has been removed

2. **Update Navigation Routes** ✅
   - Description: Updated routes in main.dart to use CleanMainScreen.
   - Status: Completed - All routes now use clean architecture screens
   - Made CleanMainScreen the default route in the app

3. **Update Home Screen** ✅
   - File: `lib/screens/home/home_screen.dart`
   - Description: Simplified to redirect to clean architecture implementation.
   - Status: Completed - Legacy home screen now redirects to CleanHomeScreen

### Completion Criteria

- ✅ Main screen uses clean architecture implementation
- ✅ Navigation between screens works correctly with bottom navigation
- ✅ Default route in the app points to CleanMainScreen

## Order Confirmation (Legacy → Clean) - ✅ Completed

### Completed Tasks

1. **Create Clean Order Confirmation Screen** ✅
   - File: `lib/presentation/screens/orders/clean_order_confirmation_screen.dart`
   - Description: Created a new clean architecture implementation with enhanced UI.
   - Status: Completed - New screen includes confetti animation and detailed order information

2. **Remove Legacy Order Confirmation Screen** ✅
   - File: `lib/screens/order_confirmation_screen.dart`
   - Description: Removed legacy implementation.
   - Status: Completed - Legacy screen has been removed

3. **Update Navigation Routes** ✅
   - Description: Updated routes in main.dart to use CleanOrderConfirmationScreen.
   - Status: Completed - All routes now use clean architecture implementation
   - Added redirect from legacy route to clean architecture route

### Completion Criteria

- ✅ Order confirmation uses clean architecture implementation
- ✅ Enhanced UI with animations and better user experience
- ✅ Proper integration with order providers and entities

## Order Management (Legacy → Clean) - 📝 Planned

### Remaining Tasks

1. **Update Order History Screen**
   - File: `lib/screens/order/order_history_screen.dart`
   - Description: Replace with clean architecture implementation.

2. **Update Order Detail Screen**
   - File: `lib/screens/order/order_detail_screen.dart`
   - Description: Replace with clean architecture implementation.

3. **Remove Legacy Order Service**
   - File: `lib/services/order_service.dart`
   - Description: Contains legacy order management logic.

### Completion Criteria

- All order-related functionality uses clean architecture components
- Order history and details use clean architecture implementations
- Order state management uses clean architecture providers

## User Profile (Legacy → Clean) - ✅ Completed

### Completed Tasks

1. **Update Profile Screen** ✅
   - File: `lib/screens/profile/profile_screen.dart`
   - Description: Replaced with clean architecture implementation.
   - Status: Completed - Legacy profile screen has been removed and replaced with CleanUserProfileScreen

2. **Update Profile Edit Screen** ✅
   - Description: Profile editing functionality has been integrated into the CleanUserProfileScreen.
   - Status: Completed - Edit functionality is now part of the clean user profile screen

3. **Remove Legacy Profile Service** ✅
   - Description: Legacy profile management logic has been removed.
   - Status: Completed - All profile management now uses clean architecture components

4. **Add Navigation Routes** ✅
   - Description: Added routes for profile-related screens.
   - Status: Completed - Routes for profile, addresses, preferences, orders, and payment methods have been added

5. **Add Back Button to Profile Screen** ✅
   - Description: Added a back button to the profile screen for better navigation.
   - Status: Completed - Profile screen now has a back button that navigates to the home screen

### Completion Criteria

- ✅ All profile-related functionality uses clean architecture components
- ✅ Profile screens use clean architecture implementations
- ✅ Profile state management uses clean architecture providers
- ✅ Navigation between profile-related screens works correctly
- ✅ UI follows the design guidelines with proper spacing, icons, and layout

### Completed Additional Features

- ✅ Orders screen implementation
- ✅ Payment Methods screen implementation

### Pending Features

- ⏳ Wallet, Support, and Wishlist functionality
- ⏳ Privacy Policy screen implementation
- ⏳ Account deletion functionality

## General Code Cleanup - 🔄 Ongoing

### Remaining Tasks

1. **Remove Unused Imports**
   - Description: Several files contain unused imports that should be removed.
   - Action: Run a linter to identify and remove unused imports.

2. **Fix Deprecation Warnings**
   - Description: Some code uses deprecated APIs (e.g., `withOpacity` instead of `withValues`).
   - Action: Update code to use current APIs.

3. **Standardize Widget Construction**
   - Description: Some widgets have the `child` parameter not as the last parameter.
   - Action: Reorder parameters to follow Flutter conventions.

4. **Remove Unused Methods**
   - Description: Some files contain methods that are no longer used.
   - Action: Identify and remove unused methods.

5. **Optimize Imports**
   - Description: Organize imports to follow a consistent pattern.
   - Action: Run import organizer on all files.

### Completion Criteria

- No unused imports in the codebase
- No deprecation warnings
- Widget construction follows Flutter conventions
- No unused methods in the codebase
- Imports are organized consistently

## Database Schema Alignment - 🔄 In Progress

### Remaining Tasks

1. **Align Entity Models with Supabase Schema**
   - Description: Ensure all entity models match the Supabase database schema.
   - Action: Review and update entity models as needed.

2. **Update Data Sources**
   - Description: Ensure all data sources correctly map between entity models and Supabase tables.
   - Action: Review and update data sources as needed.

3. **Implement Row-Level Security Policies** ✅
   - Description: Configure proper RLS policies for all tables in Supabase.
   - Action: Review and update RLS policies as needed.
   - Status: Completed - RLS policies have been configured for addresses table

### Completion Criteria

- All entity models match the Supabase database schema
- All data sources correctly map between entity models and Supabase tables
- Proper RLS policies are configured for all tables

## Testing - 📝 Planned

### Remaining Tasks

1. **Write Unit Tests for Address Use Cases**
   - Description: Create unit tests for all address-related use cases.
   - Action: Write tests for each use case.

2. **Write Unit Tests for User Profile Repository**
   - Description: Create unit tests for the user profile repository (address methods).
   - Action: Write tests for each repository method.

3. **Write Widget Tests for Address UI Components**
   - Description: Create widget tests for address-related UI components.
   - Action: Write tests for each UI component.

### Completion Criteria

- Unit tests exist for all address use cases
- Unit tests exist for all user profile repository methods
- Widget tests exist for all address UI components
- All tests pass

## Documentation - 🔄 In Progress

### Remaining Tasks

1. **Update API Documentation**
   - Description: Document all API endpoints and data models.
   - Action: Create comprehensive API documentation.

2. **Create Architecture Overview** ✅
   - Description: Document the overall architecture of the application.
   - Action: Create architecture diagrams and explanations.
   - Status: Completed - Clean architecture overview documented in migration plan

3. **Document Database Schema**
   - Description: Document the database schema and relationships.
   - Action: Create database schema diagrams and explanations.

### Completion Criteria

- Comprehensive API documentation exists
- Architecture overview exists
- Database schema documentation exists
