import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/data/datasources/user_remote_datasource.dart';
import 'package:message_ai/features/authentication/data/models/user_model.dart';
import 'package:message_ai/features/authentication/data/repositories/user_repository_impl.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}

class FakeUserModel extends Fake implements UserModel {}

void main() {
  late UserRepositoryImpl repository;
  late MockUserRemoteDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(FakeUserModel());
  });

  setUp(() {
    mockDataSource = MockUserRemoteDataSource();
    repository = UserRepositoryImpl(remoteDataSource: mockDataSource);
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

  final testUserModel = UserModel(
    uid: 'test-uid',
    email: 'test@test.com',
    displayName: 'Test User',
    preferredLanguage: 'en',
    createdAt: DateTime(2024, 1, 1),
    lastSeen: DateTime(2024, 1, 1),
    isOnline: true,
    fcmTokens: [],
  );

  group('UserRepositoryImpl', () {
    group('createUser', () {
      test('should return User entity when creation succeeds', () async {
        // Arrange
        when(() => mockDataSource.createUser(any()))
            .thenAnswer((_) async => testUserModel);

        // Act
        final result = await repository.createUser(testUser);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return user'),
          (user) {
            expect(user.uid, testUser.uid);
            expect(user.email, testUser.email);
          },
        );
        verify(() => mockDataSource.createUser(any())).called(1);
      });

      test('should return DatabaseFailure when RecordAlreadyExistsException thrown',
          () async {
        // Arrange
        when(() => mockDataSource.createUser(any()))
            .thenThrow(const RecordAlreadyExistsException(recordType: 'User'));

        // Act
        final result = await repository.createUser(testUser);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return ServerFailure when ServerException thrown', () async {
        // Arrange
        when(() => mockDataSource.createUser(any()))
            .thenThrow(const ServerException(message: 'Server error'));

        // Act
        final result = await repository.createUser(testUser);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getUserById', () {
      test('should return User entity when found', () async {
        // Arrange
        when(() => mockDataSource.getUserById(any()))
            .thenAnswer((_) async => testUserModel);

        // Act
        final result = await repository.getUserById('test-uid');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return user'),
          (user) {
            expect(user.uid, testUser.uid);
            expect(user.email, testUser.email);
          },
        );
        verify(() => mockDataSource.getUserById('test-uid')).called(1);
      });

      test('should return DatabaseFailure when RecordNotFoundException thrown',
          () async {
        // Arrange
        when(() => mockDataSource.getUserById(any()))
            .thenThrow(const RecordNotFoundException(recordType: 'User'));

        // Act
        final result = await repository.getUserById('non-existent-id');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<RecordNotFoundFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getUserByEmail', () {
      test('should return User entity when found', () async {
        // Arrange
        when(() => mockDataSource.getUserByEmail(any()))
            .thenAnswer((_) async => testUserModel);

        // Act
        final result = await repository.getUserByEmail('test@test.com');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return user'),
          (user) {
            expect(user, isNotNull);
            expect(user!.email, testUser.email);
          },
        );
        verify(() => mockDataSource.getUserByEmail('test@test.com')).called(1);
      });

      test('should return null when user not found', () async {
        // Arrange
        when(() => mockDataSource.getUserByEmail(any()))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getUserByEmail('notfound@test.com');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return null'),
          (user) => expect(user, isNull),
        );
      });

      test('should return ServerFailure when ServerException thrown', () async {
        // Arrange
        when(() => mockDataSource.getUserByEmail(any()))
            .thenThrow(const ServerException(message: 'Server error'));

        // Act
        final result = await repository.getUserByEmail('test@test.com');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('getUserByPhoneNumber', () {
      test('should return User entity when found', () async {
        // Arrange
        when(() => mockDataSource.getUserByPhoneNumber(any()))
            .thenAnswer((_) async => testUserModel);

        // Act
        final result = await repository.getUserByPhoneNumber('+1234567890');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return user'),
          (user) {
            expect(user, isNotNull);
            expect(user!.uid, testUser.uid);
          },
        );
        verify(() => mockDataSource.getUserByPhoneNumber('+1234567890'))
            .called(1);
      });

      test('should return null when user not found', () async {
        // Arrange
        when(() => mockDataSource.getUserByPhoneNumber(any()))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getUserByPhoneNumber('+9999999999');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return null'),
          (user) => expect(user, isNull),
        );
      });
    });

    group('updateUser', () {
      test('should return updated User entity', () async {
        // Arrange
        final updatedModel = testUserModel.copyWith(
          displayName: 'Updated Name',
        );
        when(() => mockDataSource.updateUser(any()))
            .thenAnswer((_) async => updatedModel);

        // Act
        final result = await repository.updateUser(testUser);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return user'),
          (user) => expect(user.displayName, 'Updated Name'),
        );
        verify(() => mockDataSource.updateUser(any())).called(1);
      });

      test('should return DatabaseFailure when RecordNotFoundException thrown',
          () async {
        // Arrange
        when(() => mockDataSource.updateUser(any()))
            .thenThrow(const RecordNotFoundException(recordType: 'User'));

        // Act
        final result = await repository.updateUser(testUser);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<RecordNotFoundFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('updateUserOnlineStatus', () {
      test('should return Right(null) on success', () async {
        // Arrange
        when(() => mockDataSource.updateUserOnlineStatus(any(), any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.updateUserOnlineStatus('test-uid', true);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDataSource.updateUserOnlineStatus('test-uid', true))
            .called(1);
      });

      test('should return ServerFailure when exception thrown', () async {
        // Arrange
        when(() => mockDataSource.updateUserOnlineStatus(any(), any()))
            .thenThrow(const ServerException(message: 'Update failed'));

        // Act
        final result =
            await repository.updateUserOnlineStatus('test-uid', false);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('updateUserLastSeen', () {
      test('should return Right(null) on success', () async {
        // Arrange
        final lastSeen = DateTime(2024, 2, 1);
        when(() => mockDataSource.updateUserLastSeen(any(), any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.updateUserLastSeen('test-uid', lastSeen);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDataSource.updateUserLastSeen('test-uid', lastSeen))
            .called(1);
      });
    });

    group('updateUserFcmToken', () {
      test('should return Right(null) on success', () async {
        // Arrange
        when(() => mockDataSource.updateUserFcmToken(any(), any()))
            .thenAnswer((_) async => {});

        // Act
        final result =
            await repository.updateUserFcmToken('test-uid', 'fcm-token-123');

        // Assert
        expect(result.isRight(), true);
        verify(() =>
                mockDataSource.updateUserFcmToken('test-uid', 'fcm-token-123'))
            .called(1);
      });
    });

    group('deleteUser', () {
      test('should return Right(null) on success', () async {
        // Arrange
        when(() => mockDataSource.deleteUser(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.deleteUser('test-uid');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockDataSource.deleteUser('test-uid')).called(1);
      });

      test('should return ServerFailure when exception thrown', () async {
        // Arrange
        when(() => mockDataSource.deleteUser(any()))
            .thenThrow(const ServerException(message: 'Delete failed'));

        // Act
        final result = await repository.deleteUser('test-uid');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('watchUser', () {
      test('should return stream of User entities', () async {
        // Arrange
        when(() => mockDataSource.watchUser(any()))
            .thenAnswer((_) => Stream.value(testUserModel));

        // Act
        final stream = repository.watchUser('test-uid');

        // Assert
        await expectLater(
          stream.first,
          completion(predicate<Either<Failure, User>>((result) {
            return result.isRight() &&
                result
                    .fold((l) => null, (r) => r)!
                    .uid ==
                    testUser.uid;
          })),
        );
        verify(() => mockDataSource.watchUser('test-uid')).called(1);
      });
    });

    group('userExists', () {
      test('should return true when user exists', () async {
        // Arrange
        when(() => mockDataSource.userExists(any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.userExists('test-uid');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return true'),
          (exists) => expect(exists, true),
        );
        verify(() => mockDataSource.userExists('test-uid')).called(1);
      });

      test('should return false when user does not exist', () async {
        // Arrange
        when(() => mockDataSource.userExists(any()))
            .thenAnswer((_) async => false);

        // Act
        final result = await repository.userExists('non-existent-id');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return false'),
          (exists) => expect(exists, false),
        );
      });

      test('should return ServerFailure when exception thrown', () async {
        // Arrange
        when(() => mockDataSource.userExists(any()))
            .thenThrow(const ServerException(message: 'Check failed'));

        // Act
        final result = await repository.userExists('test-uid');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });
  });
}
