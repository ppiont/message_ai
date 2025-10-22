import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';
import 'package:message_ai/features/authentication/domain/usecases/sign_up_with_email.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignUpWithEmail useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignUpWithEmail(mockRepository);
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

  group('SignUpWithEmail', () {
    test('should sign up user with valid email and password', () async {
      // Arrange
      when(
        () => mockRepository.signUpWithEmail(
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
        () => mockRepository.signUpWithEmail(
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
          () => mockRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      });

      test(
        'should return ValidationFailure for invalid email format',
        () async {
          // Act
          final result = await useCase(
            email: 'invalid-email',
            password: 'password123',
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('Invalid email format'));
          }, (_) => fail('Expected Left but got Right'));
          verifyNever(
            () => mockRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          );
        },
      );

      test('should accept valid email formats', () async {
        // Arrange
        when(
          () => mockRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        final validEmails = [
          'test@example.com',
          'user.name@example.com',
          'user+tag@example.co.uk',
          'test123@test-domain.com',
        ];

        for (final email in validEmails) {
          // Act
          final result = await useCase(email: email, password: 'password123');

          // Assert
          expect(result.isRight(), true, reason: 'Failed for email: $email');
        }
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

      test(
        'should return ValidationFailure when password is too short',
        () async {
          // Act
          final result = await useCase(
            email: 'test@example.com',
            password: '12345', // 5 characters, minimum is 6
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('Password is too short'));
          }, (_) => fail('Expected Left but got Right'));
        },
      );

      test('should accept password with exactly 6 characters', () async {
        // Arrange
        when(
          () => mockRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        // Act
        final result = await useCase(
          email: 'test@example.com',
          password: '123456', // Exactly 6 characters
        );

        // Assert
        expect(result.isRight(), true);
      });
    });

    group('Repository Error Handling', () {
      test('should return failure from repository', () async {
        // Arrange
        const failure = ValidationFailure(
          message: 'Email already in use',
          fieldErrors: {'email': 'This email is already registered'},
        );
        when(
          () => mockRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        final result = await useCase(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, const Left(failure));
      });

      test('should return ServerFailure from repository', () async {
        // Arrange
        const failure = ServerFailure(message: 'Network error');
        when(
          () => mockRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        final result = await useCase(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, const Left(failure));
      });
    });
  });
}
