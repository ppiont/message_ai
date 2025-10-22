import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';
import 'package:message_ai/features/authentication/domain/usecases/update_user_profile.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeUser extends Fake implements User {}

void main() {
  late UpdateUserProfile useCase;
  late MockAuthRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = UpdateUserProfile(mockRepository);
  });

  final testUser = User(
    uid: 'test-uid',
    email: 'test@test.com',
    displayName: 'Updated User',
    photoURL: 'https://example.com/photo.jpg',
    preferredLanguage: 'en',
    createdAt: DateTime(2024, 1, 1),
    lastSeen: DateTime(2024, 1, 1),
    isOnline: true,
    fcmTokens: [],
  );

  group('UpdateUserProfile', () {
    group('with valid inputs', () {
      test('should update display name successfully', () async {
        // Arrange
        const displayName = 'Updated User';
        when(() => mockRepository.updateUserProfile(
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async => Right(testUser));

        // Act
        final result = await useCase(displayName: displayName);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRepository.updateUserProfile(displayName: displayName))
            .called(1);

        result.fold(
          (failure) => fail('Should return user'),
          (user) {
            expect(user.displayName, displayName);
          },
        );
      });

      test('should update photo URL successfully', () async {
        // Arrange
        const photoURL = 'https://example.com/photo.jpg';
        when(() => mockRepository.updateUserProfile(
              photoURL: any(named: 'photoURL'),
            )).thenAnswer((_) async => Right(testUser));

        // Act
        final result = await useCase(photoURL: photoURL);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRepository.updateUserProfile(photoURL: photoURL))
            .called(1);

        result.fold(
          (failure) => fail('Should return user'),
          (user) {
            expect(user.photoURL, photoURL);
          },
        );
      });

      test('should update both display name and photo URL', () async {
        // Arrange
        const displayName = 'Updated User';
        const photoURL = 'https://example.com/photo.jpg';
        when(() => mockRepository.updateUserProfile(
              displayName: any(named: 'displayName'),
              photoURL: any(named: 'photoURL'),
            )).thenAnswer((_) async => Right(testUser));

        // Act
        final result =
            await useCase(displayName: displayName, photoURL: photoURL);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRepository.updateUserProfile(
            displayName: displayName, photoURL: photoURL)).called(1);

        result.fold(
          (failure) => fail('Should return user'),
          (user) {
            expect(user.displayName, displayName);
            expect(user.photoURL, photoURL);
          },
        );
      });
    });

    group('validation', () {
      test('should return ValidationFailure when display name is empty',
          () async {
        // Act
        final result = await useCase(displayName: '');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message,
                'Display name cannot be empty');
          },
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockRepository.updateUserProfile(
            displayName: any(named: 'displayName')));
      });

      test('should return ValidationFailure when display name is only spaces',
          () async {
        // Act
        final result = await useCase(displayName: '   ');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message,
                'Display name cannot be empty');
          },
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockRepository.updateUserProfile(
            displayName: any(named: 'displayName')));
      });

      test('should allow empty photo URL (passes through to repository)', () async {
        // Arrange
        const photoURL = '';
        when(() => mockRepository.updateUserProfile(
              photoURL: any(named: 'photoURL'),
            )).thenAnswer((_) async => Right(testUser));

        // Act
        final result = await useCase(photoURL: photoURL);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRepository.updateUserProfile(photoURL: photoURL))
            .called(1);
      });

      test('should return ValidationFailure when no parameters provided',
          () async {
        // Act
        final result = await useCase();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message,
                'At least one field must be provided for update');
          },
          (_) => fail('Should return failure'),
        );
      });
    });

    group('error cases', () {
      test('should return ServerFailure when repository fails', () async {
        // Arrange
        const displayName = 'Updated User';
        when(() => mockRepository.updateUserProfile(
              displayName: any(named: 'displayName'),
            )).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Update failed')));

        // Act
        final result = await useCase(displayName: displayName);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return AuthenticationFailure when user not authenticated', () async {
        // Arrange
        const displayName = 'Updated User';
        when(() => mockRepository.updateUserProfile(
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async =>
            const Left(AuthenticationFailure(message: 'User not authenticated')));

        // Act
        final result = await useCase(displayName: displayName);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });
  });
}
