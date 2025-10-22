import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';
import 'package:message_ai/features/authentication/domain/usecases/sign_in_with_email.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithEmail useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInWithEmail(mockRepository);
  });

  final testUser = User(
    uid: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
    preferredLanguage: 'en',
    createdAt: DateTime.now(),
    lastSeen: DateTime.now(),
    isOnline: true,
    fcmTokens: [],
  );

  group('SignInWithEmail', () {
    test('should sign in user with valid credentials', () async {
      // Arrange
      when(
        () => mockRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      // Act
      final result = await useCase(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(result, Right(testUser));
      verify(
        () => mockRepository.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    group('Email Validation', () {
      test('should return ValidationFailure when email is empty', () async {
        // Act
        final result = await useCase(email: '', password: 'password123');

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Email is required'));
        }, (_) => fail('Expected Left but got Right'));
        verifyNever(
          () => mockRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      });
    });

    group('Password Validation', () {
      test('should return ValidationFailure when password is empty', () async {
        // Act
        final result = await useCase(email: 'test@example.com', password: '');

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Password is required'));
        }, (_) => fail('Expected Left but got Right'));
      });
    });

    group('Repository Error Handling', () {
      test('should return failure for invalid credentials', () async {
        // Arrange
        const failure = ValidationFailure(
          message: 'Invalid credentials',
          fieldErrors: {'password': 'Incorrect password'},
        );
        when(
          () => mockRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        final result = await useCase(
          email: 'test@example.com',
          password: 'wrong-password',
        );

        // Assert
        expect(result, const Left(failure));
      });

      test('should return failure for non-existent user', () async {
        // Arrange
        const failure = ValidationFailure(
          message: 'User not found',
          fieldErrors: {'email': 'This email is not registered'},
        );
        when(
          () => mockRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        final result = await useCase(
          email: 'nonexistent@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, const Left(failure));
      });
    });
  });
}
