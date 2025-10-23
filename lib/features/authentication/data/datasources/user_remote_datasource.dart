/// Remote data source for user operations on Firestore
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/features/authentication/data/models/user_model.dart';

/// Abstract interface for user remote data source
abstract class UserRemoteDataSource {
  /// Create a new user document in Firestore
  Future<UserModel> createUser(UserModel user);

  /// Get a user by their ID
  Future<UserModel> getUserById(String userId);

  /// Get a user by their email
  Future<UserModel?> getUserByEmail(String email);

  /// Get a user by their phone number
  Future<UserModel?> getUserByPhoneNumber(String phoneNumber);

  /// Update a user document
  Future<UserModel> updateUser(UserModel user);

  /// Update user's online status
  Future<void> updateUserOnlineStatus(
    String userId, {
    required bool isOnline,
  });

  /// Update user's last seen timestamp
  Future<void> updateUserLastSeen(String userId, DateTime lastSeen);

  /// Update user's FCM token
  Future<void> updateUserFcmToken(String userId, String fcmToken);

  /// Delete a user document (soft delete by updating status)
  Future<void> deleteUser(String userId);

  /// Watch user changes in real-time
  Stream<UserModel> watchUser(String userId);

  /// Check if a user exists
  Future<bool> userExists(String userId);
}

/// Implementation of UserRemoteDataSource using Cloud Firestore
class UserRemoteDataSourceImpl implements UserRemoteDataSource {

  UserRemoteDataSourceImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;
  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';

  /// Get reference to users collection
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_usersCollection);

  @override
  Future<UserModel> createUser(UserModel user) async {
    try {
      final docRef = _usersRef.doc(user.uid);

      // Check if user already exists
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        throw RecordAlreadyExistsException(
          recordType: 'User',
          recordId: user.uid,
        );
      }

      // Create the user document
      await docRef.set(user.toJson());

      // Return the created user
      return user;
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to create user',
        originalError: e,
      );
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      final docSnapshot = await _usersRef.doc(userId).get();

      if (!docSnapshot.exists) {
        throw RecordNotFoundException(recordType: 'User', recordId: userId);
      }

      return UserModel.fromJson(docSnapshot.data()!);
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(message: 'Failed to get user', originalError: e);
    }
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _usersRef
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return UserModel.fromJson(querySnapshot.docs.first.data());
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to get user by email',
        originalError: e,
      );
    }
  }

  @override
  Future<UserModel?> getUserByPhoneNumber(String phoneNumber) async {
    try {
      final querySnapshot = await _usersRef
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return UserModel.fromJson(querySnapshot.docs.first.data());
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to get user by phone number',
        originalError: e,
      );
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final docRef = _usersRef.doc(user.uid);

      // Check if user exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw RecordNotFoundException(recordType: 'User', recordId: user.uid);
      }

      // Update the user document
      await docRef.update(user.toJson());

      // Return the updated user
      return user;
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException(
        message: 'Failed to update user',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateUserOnlineStatus(
    String userId, {
    required bool isOnline,
  }) async {
    try {
      await _usersRef.doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to update user online status',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateUserLastSeen(String userId, DateTime lastSeen) async {
    try {
      await _usersRef.doc(userId).update({
        'lastSeen': lastSeen.toIso8601String(),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to update user last seen',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateUserFcmToken(String userId, String fcmToken) async {
    try {
      await _usersRef.doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([fcmToken]),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to update user FCM token',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      // Soft delete by updating status (or you can hard delete with docRef.delete())
      await _usersRef.doc(userId).update({
        'isDeleted': true,
        'deletedAt': DateTime.now().toIso8601String(),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to delete user',
        originalError: e,
      );
    }
  }

  @override
  Stream<UserModel> watchUser(String userId) {
    try {
      return _usersRef.doc(userId).snapshots().map((docSnapshot) {
        if (!docSnapshot.exists) {
          throw RecordNotFoundException(recordType: 'User', recordId: userId);
        }
        return UserModel.fromJson(docSnapshot.data()!);
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(message: 'Failed to watch user', originalError: e);
    }
  }

  @override
  Future<bool> userExists(String userId) async {
    try {
      final docSnapshot = await _usersRef.doc(userId).get();
      return docSnapshot.exists;
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to check if user exists',
        originalError: e,
      );
    }
  }

  /// Map Firestore exceptions to app exceptions
  AppException _mapFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const UnauthorizedException(
          message: 'You do not have permission to access this resource',
        );
      case 'not-found':
        return const RecordNotFoundException(recordType: 'Document');
      case 'already-exists':
        return const RecordAlreadyExistsException(recordType: 'Document');
      case 'resource-exhausted':
        return const RateLimitExceededException();
      case 'failed-precondition':
        return const ConstraintViolationException(
          message: 'Operation failed due to constraint violation',
        );
      case 'aborted':
        return const ServerException(
          message: 'Operation was aborted. Please try again',
        );
      case 'out-of-range':
        return const ValidationException(
          message: 'Invalid range for operation',
          fieldErrors: {},
        );
      case 'unimplemented':
        return const NotImplementedException(
          message: 'This operation is not implemented',
        );
      case 'unavailable':
        return const NoInternetException();
      case 'deadline-exceeded':
        return const NetworkTimeoutException();
      default:
        return ServerException(message: 'Firestore error: ${e.message}');
    }
  }
}
