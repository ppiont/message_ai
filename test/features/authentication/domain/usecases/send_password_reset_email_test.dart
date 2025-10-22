import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';
import 'package:message_ai/features/authentication/domain/usecases/send_password_reset_email.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SendPasswordResetEmail useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SendPasswordResetEmail(mockRepository);
  });

  group('SendPasswordResetEmail', () {
    test('should send password reset email successfully', () async {
      // Arrange
      when(
        () => mockRepository.sendPasswordResetEmail(email: any(named: 'email')),
      ).thenAnswer((_) async => const Right(unit));

      // Act
      final result = await useCase(email: 'test@example.com');

      // Assert
      expect(result, const Right(unit));
      verify(
        () => mockRepository.sendPasswordResetEmail(email: 'test@example.com'),
      ).called(1);
    });

    group('Email Validation', () {
      test('should return ValidationFailure when email is empty', () async {
        // Act
        final result = await useCase(email: '');

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Email is required'));
        }, (_) => fail('Expected Left but got Right'));
        verifyNever(
          () =>
              mockRepository.sendPasswordResetEmail(email: any(named: 'email')),
        );
      });

      test(
        'should return ValidationFailure for invalid email format',
        () async {
          // Act
          final result = await useCase(email: 'invalid-email');

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('Invalid email format'));
          }, (_) => fail('Expected Left but got Right'));
          verifyNever(
            () => mockRepository.sendPasswordResetEmail(
              email: any(named: 'email'),
            ),
          );
        },
      );

      test('should accept valid email formats', () async {
        // Arrange
        when(
          () =>
              mockRepository.sendPasswordResetEmail(email: any(named: 'email')),
        ).thenAnswer((_) async => const Right(unit));

        final validEmails = [
          'test@example.com',
          'user.name@example.com',
          'user+tag@example.co.uk',
        ];

        for (final email in validEmails) {
          // Act
          final result = await useCase(email: email);

          // Assert
          expect(result.isRight(), true, reason: 'Failed for email: $email');
        }
      });
    });

    group('Repository Error Handling', () {
      test('should return failure when user not found', () async {
        // Arrange
        const failure = ValidationFailure(
          message: 'User not found',
          fieldErrors: {'email': 'No user found with this email'},
        );
        when(
          () =>
              mockRepository.sendPasswordResetEmail(email: any(named: 'email')),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        final result = await useCase(email: 'nonexistent@example.com');

        // Assert
        expect(result, const Left(failure));
      });

      test('should return ServerFailure on network error', () async {
        // Arrange
        const failure = ServerFailure(message: 'Network error');
        when(
          () =>
              mockRepository.sendPasswordResetEmail(email: any(named: 'email')),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        final result = await useCase(email: 'test@example.com');

        // Assert
        expect(result, const Left(failure));
      });
    });
  });
}
