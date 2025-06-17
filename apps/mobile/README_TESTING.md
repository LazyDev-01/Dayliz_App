# Dayliz App - Testing Guide

## Overview
Dayliz is a Q-commerce grocery delivery app. This guide provides comprehensive instructions for testing the application using our organized test structure.

## Prerequisites
- Flutter SDK installed (version 3.32.0 or higher)
- Android Studio or VS Code with Flutter/Dart plugins
- An emulator or physical device for testing

## Test Structure

Our tests are organized following Flutter best practices:

```
test/
├── unit/                    # Unit tests for business logic
│   ├── core/               # Core functionality tests
│   ├── data/               # Data layer tests
│   ├── domain/             # Domain layer tests
│   └── presentation/       # Presentation layer tests
├── widget/                 # Widget tests for UI components
│   └── screens/           # Screen-specific widget tests
├── integration/            # Integration tests for complete flows
├── fixtures/               # Test data and mock objects
├── helpers/                # Test utilities and helpers
└── docs/                   # Test documentation
```

## Running Tests

### All Tests
```bash
# Run all tests
flutter test

# Or using workspace script
npm run mobile:test
```

### Specific Test Types
```bash
# Unit tests only
flutter test test/unit
npm run mobile:test:unit

# Widget tests only
flutter test test/widget
npm run mobile:test:widget

# Integration tests only
flutter test test/integration
npm run mobile:test:integration

# With coverage report
flutter test --coverage
npm run mobile:test:coverage
```

## Setup Instructions

### Running the App
1. Clone the repository
2. Navigate to the `apps/mobile` directory
3. Run one of the following commands:
   - Windows: `run_app.bat`
   - Mac/Linux: `sh run_app.sh`
   
Alternatively, you can manually run:
```bash
flutter pub get
flutter run
```

## Testing the Checkout Flow

### 1. Browse Products
- Launch the app
- Navigate through the product catalog
- Add items to your cart by tapping on a product and then "Add to Cart"

### 2. View Cart
- Tap on the Cart icon in the bottom navigation
- Review the items in your cart
- Adjust quantities as needed
- Tap "Proceed to Checkout"

### 3. Checkout Process
- Fill in your shipping information
- Proceed to the payment method selection
- Choose a payment method
- Review your order summary
- Complete the order

### 4. Order Confirmation
- View your order confirmation
- Verify that the order details are correct
- Tap "Continue Shopping" to return to the home screen

## Known Issues
- The app uses mock data for products and does not connect to a real backend
- Payment processing is simulated and no actual transactions occur

## Testing Account
You can use the following test account for login:
- Email: test@example.com
- Password: password123

## Feedback
If you encounter any issues during testing, please report them by creating an issue in the GitHub repository.

---

Created by [Your Name](https://github.com/LazyDev-01) 