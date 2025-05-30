import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dayliz_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Tests', () {
    testWidgets('Register with new email should succeed and navigate to home',
        (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to register screen
      // First check if we're on the splash screen
      if (find.text('Login').evaluate().isNotEmpty) {
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();
      } else {
        // We might be on the splash screen, wait for it to finish
        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        
        // Now try to find the login screen
        if (find.text('Login').evaluate().isNotEmpty) {
          await tester.tap(find.text('Create Account'));
          await tester.pumpAndSettle();
        }
      }

      // Verify we're on the register screen
      expect(find.text('Create Account'), findsAtLeastNWidgets(1));

      // Generate a unique email to avoid conflicts
      final uniqueEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      // Fill in registration form
      await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
      await tester.enterText(find.byKey(const Key('email_field')), uniqueEmail);
      await tester.enterText(find.byKey(const Key('password_field')), 'Password123!');
      await tester.enterText(find.byKey(const Key('confirm_password_field')), 'Password123!');
      
      // Submit form
      await tester.tap(find.text('Create Account').last);
      
      // Wait for registration to complete and navigation to occur
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Verify we're on the home screen
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Register with existing email should show error',
        (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to register screen
      // First check if we're on the splash screen
      if (find.text('Login').evaluate().isNotEmpty) {
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();
      } else {
        // We might be on the splash screen, wait for it to finish
        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        
        // Now try to find the login screen
        if (find.text('Login').evaluate().isNotEmpty) {
          await tester.tap(find.text('Create Account'));
          await tester.pumpAndSettle();
        }
      }

      // Verify we're on the register screen
      expect(find.text('Create Account'), findsAtLeastNWidgets(1));
      
      // Use a known existing email
      const existingEmail = 'test@example.com';
      
      // Fill in registration form
      await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
      await tester.enterText(find.byKey(const Key('email_field')), existingEmail);
      await tester.enterText(find.byKey(const Key('password_field')), 'Password123!');
      await tester.enterText(find.byKey(const Key('confirm_password_field')), 'Password123!');
      
      // Submit form
      await tester.tap(find.text('Create Account').last);
      
      // Wait for error to appear
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Verify error message is shown
      expect(find.text('Email id already exists!'), findsOneWidget);
    });

    testWidgets('Login with valid credentials should navigate to home',
        (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to login screen if needed
      // First check if we're on the splash screen
      if (find.text('Login').evaluate().isEmpty) {
        // We might be on the splash screen, wait for it to finish
        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();
      }

      // Verify we're on the login screen
      expect(find.text('Login'), findsAtLeastNWidgets(1));
      
      // Use valid credentials
      const validEmail = 'test@example.com';
      const validPassword = 'Password123!';
      
      // Fill in login form
      await tester.enterText(find.byKey(const Key('email_field')), validEmail);
      await tester.enterText(find.byKey(const Key('password_field')), validPassword);
      
      // Submit form
      await tester.tap(find.text('Login').last);
      
      // Wait for login to complete and navigation to occur
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      // Verify we're on the home screen
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
