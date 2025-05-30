import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dayliz_app/core/errors/exceptions.dart';
import 'package:dayliz_app/data/datasources/auth_supabase_data_source_new.dart';
import 'package:dayliz_app/data/models/user_model.dart';

// Create mock classes for Supabase
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockSession extends Mock implements Session {}
class MockUserResponse extends Mock implements AuthResponse {}
class MockPostgrestBuilder extends Mock implements PostgrestBuilder {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}

@GenerateMocks([])
void main() {
  late AuthSupabaseDataSource dataSource;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;
  late MockSession mockSession;
  late MockUserResponse mockUserResponse;
  late MockPostgrestBuilder mockPostgrestBuilder;
  late MockPostgrestFilterBuilder mockPostgrestFilterBuilder;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();
    mockSession = MockSession();
    mockUserResponse = MockUserResponse();
    mockPostgrestBuilder = MockPostgrestBuilder();
    mockPostgrestFilterBuilder = MockPostgrestFilterBuilder();
    
    when(mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    
    dataSource = AuthSupabaseDataSource(
      supabaseClient: mockSupabaseClient,
    );
  });

  final tEmail = 'test@example.com';
  final tPassword = 'Password123!';
  final tName = 'Test User';
  final tPhone = '1234567890';
  final tUserId = 'test-user-id';

  void setupMockSupabaseSignUpSuccess() {
    when(mockUser.id).thenReturn(tUserId);
    when(mockUser.email).thenReturn(tEmail);
    when(mockUserResponse.user).thenReturn(mockUser);
    when(mockUserResponse.session).thenReturn(mockSession);
    
    when(mockGoTrueClient.signUp(
      email: anyNamed('email'),
      password: anyNamed('password'),
      data: anyNamed('data'),
    )).thenAnswer((_) async => mockUserResponse);
    
    // Mock the from() method for creating user profile
    when(mockSupabaseClient.from(any)).thenReturn(mockPostgrestBuilder);
    when(mockPostgrestBuilder.upsert(any)).thenReturn(mockPostgrestFilterBuilder);
    when(mockPostgrestFilterBuilder.execute()).thenAnswer((_) async => null);
  }

  void setupMockSupabaseSignUpFailure() {
    when(mockGoTrueClient.signUp(
      email: anyNamed('email'),
      password: anyNamed('password'),
      data: anyNamed('data'),
    )).thenThrow(AuthException('Registration failed'));
  }

  void setupMockEmailExistsCheck(bool exists) {
    // Mock the from() method for checking if email exists
    when(mockSupabaseClient.from(any)).thenReturn(mockPostgrestBuilder);
    when(mockPostgrestBuilder.select(any)).thenReturn(mockPostgrestBuilder);
    when(mockPostgrestBuilder.eq(any, any)).thenReturn(mockPostgrestFilterBuilder);
    
    if (exists) {
      when(mockPostgrestFilterBuilder.maybeSingle()).thenAnswer((_) async => {'email': tEmail});
    } else {
      when(mockPostgrestFilterBuilder.maybeSingle()).thenAnswer((_) async => null);
    }
  }

  group('register', () {
    test('should register a new user when email does not exist', () async {
      // arrange
      setupMockEmailExistsCheck(false);
      setupMockSupabaseSignUpSuccess();
      
      // act
      final result = await dataSource.register(tEmail, tPassword, tName, phone: tPhone);
      
      // assert
      expect(result, isA<UserModel>());
      expect(result.id, equals(tUserId));
      expect(result.email, equals(tEmail));
      expect(result.name, equals(tName));
      expect(result.phone, equals(tPhone));
      
      verify(mockGoTrueClient.signUp(
        email: tEmail,
        password: tPassword,
        data: {'name': tName, 'phone': tPhone},
      ));
    });

    test('should throw ServerException when email already exists', () async {
      // arrange
      setupMockEmailExistsCheck(true);
      
      // act & assert
      expect(
        () => dataSource.register(tEmail, tPassword, tName, phone: tPhone),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw ServerException when registration fails', () async {
      // arrange
      setupMockEmailExistsCheck(false);
      setupMockSupabaseSignUpFailure();
      
      // act & assert
      expect(
        () => dataSource.register(tEmail, tPassword, tName, phone: tPhone),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
