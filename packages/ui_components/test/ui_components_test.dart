import 'package:flutter_test/flutter_test.dart';
import 'package:ui_components/ui_components.dart';

void main() {
  group('UI Components Tests', () {
    test('DaylizButton should be exported', () {
      // Test that DaylizButton is accessible
      expect(DaylizButton, isNotNull);
    });

    test('DaylizTextField should be exported', () {
      // Test that DaylizTextField is accessible
      expect(DaylizTextField, isNotNull);
    });

    test('LoadingWidget should be exported', () {
      // Test that LoadingWidget is accessible
      expect(LoadingWidget, isNotNull);
    });

    test('ErrorDisplay should be exported', () {
      // Test that ErrorDisplay is accessible
      expect(ErrorDisplay, isNotNull);
    });
  });
}
