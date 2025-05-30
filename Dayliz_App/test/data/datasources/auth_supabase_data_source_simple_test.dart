import 'package:flutter_test/flutter_test.dart';
import 'package:dayliz_app/data/models/user_model.dart';

// This is a simple test that verifies the UserModel class
void main() {
  test('UserModel can be instantiated', () {
    // This test just verifies that the UserModel class can be instantiated without errors
    const userModel = UserModel(
      id: 'test-id',
      email: 'test@example.com',
      name: 'Test User',
      phone: '1234567890',
      isEmailVerified: false,
    );

    expect(userModel.id, equals('test-id'));
    expect(userModel.email, equals('test@example.com'));
    expect(userModel.name, equals('Test User'));
    expect(userModel.phone, equals('1234567890'));
    expect(userModel.isEmailVerified, equals(false));
  });
}
