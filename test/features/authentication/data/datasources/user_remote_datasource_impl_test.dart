import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/features/authentication/data/datasources/user_remote_datasource.dart';
import 'package:message_ai/features/authentication/data/models/user_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UserRemoteDataSourceImpl dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = UserRemoteDataSourceImpl(firestore: fakeFirestore);
  });

  final testUserModel = UserModel(
    uid: 'test-uid',
    email: 'test@test.com',
    displayName: 'Test User',
    photoURL: null,
    preferredLanguage: 'en',
    createdAt: DateTime(2024, 1, 1),
    lastSeen: DateTime(2024, 1, 1),
    isOnline: true,
    fcmTokens: [],
  );

  group('UserRemoteDataSourceImpl', () {
    group('createUser', () {
      test('should create user successfully', () async {
        // Act
        final result = await dataSource.createUser(testUserModel);

        // Assert
        expect(result.uid, testUserModel.uid);
        expect(result.email, testUserModel.email);

        // Verify document exists in Firestore
        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .get();
        expect(doc.exists, true);
        expect(doc.data()?['email'], testUserModel.email);
      });

      test('should throw RecordAlreadyExistsException when user exists',
          () async {
        // Arrange - create user first
        await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .set(testUserModel.toJson());

        // Act & Assert
        expect(
          () => dataSource.createUser(testUserModel),
          throwsA(isA<RecordAlreadyExistsException>()),
        );
      });
    });

    group('getUserById', () {
      test('should return user when document exists', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .set(testUserModel.toJson());

        // Act
        final result = await dataSource.getUserById(testUserModel.uid);

        // Assert
        expect(result.uid, testUserModel.uid);
        expect(result.email, testUserModel.email);
        expect(result.displayName, testUserModel.displayName);
      });

      test('should throw RecordNotFoundException when user does not exist',
          () async {
        // Act & Assert
        expect(
          () => dataSource.getUserById('non-existent-id'),
          throwsA(isA<RecordNotFoundException>()),
        );
      });
    });

    group('getUserByEmail', () {
      test('should return user when email exists', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .set(testUserModel.toJson());

        // Act
        final result = await dataSource.getUserByEmail(testUserModel.email!);

        // Assert
        expect(result, isNotNull);
        expect(result!.email, testUserModel.email);
        expect(result.uid, testUserModel.uid);
      });

      test('should return null when email does not exist', () async {
        // Act
        final result = await dataSource.getUserByEmail('nonexistent@test.com');

        // Assert
        expect(result, isNull);
      });
    });

    group('getUserByPhoneNumber', () {
      test('should return user when phone number exists', () async {
        // Arrange
        final userWithPhone = testUserModel.copyWith(
          phoneNumber: '+1234567890',
        );
        await fakeFirestore
            .collection('users')
            .doc(userWithPhone.uid)
            .set(userWithPhone.toJson());

        // Act
        final result = await dataSource.getUserByPhoneNumber('+1234567890');

        // Assert
        expect(result, isNotNull);
        expect(result!.phoneNumber, '+1234567890');
        expect(result.uid, userWithPhone.uid);
      });

      test('should return null when phone number does not exist', () async {
        // Act
        final result = await dataSource.getUserByPhoneNumber('+9999999999');

        // Assert
        expect(result, isNull);
      });
    });

    group('updateUser', () {
      test('should update user successfully', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .set(testUserModel.toJson());

        final updatedUser = testUserModel.copyWith(
          displayName: 'Updated Name',
        );

        // Act
        final result = await dataSource.updateUser(updatedUser);

        // Assert
        expect(result.displayName, 'Updated Name');

        // Verify document was updated
        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .get();
        expect(doc.data()?['displayName'], 'Updated Name');
      });

      test('should throw RecordNotFoundException when user does not exist',
          () async {
        // Act & Assert
        expect(
          () => dataSource.updateUser(testUserModel),
          throwsA(isA<RecordNotFoundException>()),
        );
      });
    });

    group('updateUserOnlineStatus', () {
      test('should update online status successfully', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .set(testUserModel.toJson());

        // Act
        await dataSource.updateUserOnlineStatus(testUserModel.uid, false);

        // Assert
        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .get();
        expect(doc.data()?['isOnline'], false);
        expect(doc.data()?['lastSeen'], isNotNull);
      });
    });

    group('updateUserLastSeen', () {
      test('should update last seen timestamp', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .set(testUserModel.toJson());

        final newLastSeen = DateTime(2024, 2, 1);

        // Act
        await dataSource.updateUserLastSeen(testUserModel.uid, newLastSeen);

        // Assert
        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .get();
        expect(doc.data()?['lastSeen'], newLastSeen.toIso8601String());
      });
    });

    group('updateUserFcmToken', () {
      test('should add FCM token to array', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .set(testUserModel.toJson());

        const newToken = 'fcm-token-123';

        // Act
        await dataSource.updateUserFcmToken(testUserModel.uid, newToken);

        // Assert
        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .get();
        final tokens = doc.data()?['fcmTokens'] as List?;
        expect(tokens, contains(newToken));
      });
    });

    group('deleteUser', () {
      test('should soft delete user by setting flags', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .set(testUserModel.toJson());

        // Act
        await dataSource.deleteUser(testUserModel.uid);

        // Assert
        final doc = await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .get();
        expect(doc.data()?['isDeleted'], true);
        expect(doc.data()?['deletedAt'], isNotNull);
      });
    });

    group('watchUser', () {
      test('should emit user when document exists', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .set(testUserModel.toJson());

        // Act
        final stream = dataSource.watchUser(testUserModel.uid);

        // Assert
        await expectLater(
          stream.first,
          completion(predicate<UserModel>(
            (user) =>
                user.uid == testUserModel.uid &&
                user.displayName == 'Test User',
          )),
        );
      });
    });

    group('userExists', () {
      test('should return true when user exists', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(testUserModel.uid)
            .set(testUserModel.toJson());

        // Act
        final result = await dataSource.userExists(testUserModel.uid);

        // Assert
        expect(result, true);
      });

      test('should return false when user does not exist', () async {
        // Act
        final result = await dataSource.userExists('non-existent-id');

        // Assert
        expect(result, false);
      });
    });
  });
}
