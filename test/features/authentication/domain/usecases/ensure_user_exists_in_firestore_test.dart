import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/user_repository.dart';
import 'package:message_ai/features/authentication/domain/usecases/ensure_user_exists_in_firestore.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

class FakeUser extends Fake implements User {}

void main() {
  late EnsureUserExistsInFirestore useCase;
  late MockUserRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    mockRepository = MockUserRepository();
    useCase = EnsureUserExistsInFirestore(mockRepository);
  });

  final testUser = User(
    uid: 'test-uid',
    email: 'test@test.com',
    displayName: 'Test User',
    preferredLanguage: 'en',
    createdAt: DateTime(2024, 1, 1),
    lastSeen: DateTime(2024, 1, 1),
    isOnline: true,
    fcmTokens: [],
  );

  group('EnsureUserExistsInFirestore', () {
    group('when user does not exist', () {
      test('should create new user and return it', () async {
        // Arrange
        when(() => mockRepository.userExists(any()))
            .thenAnswer((_) async => const Right(false));
        when(() => mockRepository.createUser(any()))
            .thenAnswer((_) async => Right(testUser));

        // Act
        final result = await useCase(testUser);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRepository.userExists(testUser.uid)).called(1);
        verify(() => mockRepository.createUser(testUser)).called(1);

        result.fold(
          (failure) => fail('Should return user'),
          (user) {
            expect(user, isNotNull);
            expect(user!.uid, testUser.uid);
            expect(user.email, testUser.email);
          },
        );
      });

      test('should return ServerFailure when creation fails', () async {
        // Arrange
        when(() => mockRepository.userExists(any()))
            .thenAnswer((_) async => const Right(false));
        when(() => mockRepository.createUser(any())).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Creation failed')));

        // Act
        final result = await useCase(testUser);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('when user already exists', () {
      test('should return null (no action needed)', () async {
        // Arrange
        when(() => mockRepository.userExists(any()))
            .thenAnswer((_) async => const Right(true));

        // Act
        final result = await useCase(testUser);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRepository.userExists(testUser.uid)).called(1);
        verifyNever(() => mockRepository.createUser(any()));

        result.fold(
          (failure) => fail('Should return null'),
          (user) => expect(user, isNull),
        );
      });
    });

    group('error cases', () {
      test('should return ServerFailure when userExists check fails', () async {
        // Arrange
        when(() => mockRepository.userExists(any())).thenAnswer((_) async =>
            const Left(ServerFailure(message: 'Failed to check existence')));

        // Act
        final result = await useCase(testUser);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockRepository.createUser(any()));
      });
    });
  });
}
