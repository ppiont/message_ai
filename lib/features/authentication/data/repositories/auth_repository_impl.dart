import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:message_ai/core/error/error_mapper.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:message_ai/features/authentication/data/models/user_model.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository] using Firebase Authentication
///
/// Handles authentication operations and converts data source responses
/// to domain entities, mapping exceptions to failures.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  // ========== Email Authentication ==========

  @override
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final firebaseUser = await _remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
      );
      return Right(_mapFirebaseUserToEntity(firebaseUser));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(
        UnknownException(message: e.toString()),
      ));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final firebaseUser = await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return Right(_mapFirebaseUserToEntity(firebaseUser));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(
        UnknownException(message: e.toString()),
      ));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email: email);
      return const Right(unit);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(
        UnknownException(message: e.toString()),
      ));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendEmailVerification() async {
    try {
      await _remoteDataSource.sendEmailVerification();
      return const Right(unit);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(
        UnknownException(message: e.toString()),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    try {
      final isVerified = await _remoteDataSource.isEmailVerified();
      return Right(isVerified);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(
        UnknownException(message: e.toString()),
      ));
    }
  }

  // ========== Phone Authentication ==========

  @override
  Future<Either<Failure, Unit>> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(firebase_auth.PhoneAuthCredential credential)
        onVerificationCompleted,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      await _remoteDataSource.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onVerificationCompleted: onVerificationCompleted,
        timeout: timeout,
      );
      return const Right(unit);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(
        UnknownException(message: e.toString()),
      ));
    }
  }

  @override
  Future<Either<Failure, User>> verifyCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final firebaseUser = await _remoteDataSource.verifyCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return Right(_mapFirebaseUserToEntity(firebaseUser));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(
        UnknownException(message: e.toString()),
      ));
    }
  }

  @override
  Future<Either<Failure, Unit>> reauthenticateWithPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      await _remoteDataSource.reauthenticateWithPhone(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return const Right(unit);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(
        UnknownException(message: e.toString()),
      ));
    }
  }

  // ========== Common Operations ==========

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Right(unit);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(
        UnknownException(message: e.toString()),
      ));
    }
  }

  @override
  Either<Failure, User?> getCurrentUser() {
    try {
      final firebaseUser = _remoteDataSource.getCurrentUser();
      if (firebaseUser == null) {
        return const Right(null);
      }
      return Right(_mapFirebaseUserToEntity(firebaseUser));
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(
        UnknownException(message: e.toString()),
      ));
    }
  }

  @override
  Future<Either<Failure, String>> getIdToken() async {
    try {
      final token = await _remoteDataSource.getIdToken();
      return Right(token);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(
        UnknownException(message: e.toString()),
      ));
    }
  }

  @override
  Stream<User?> authStateChanges() {
    return _remoteDataSource.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _mapFirebaseUserToEntity(firebaseUser);
    });
  }

  // ========== Helper Methods ==========

  /// Maps a Firebase User to our domain User entity
  User _mapFirebaseUserToEntity(firebase_auth.User firebaseUser) {
    return User(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      phoneNumber: firebaseUser.phoneNumber,
      displayName: firebaseUser.displayName ?? '',
      photoURL: firebaseUser.photoURL,
      preferredLanguage: 'en', // Default, will be updated from Firestore
      createdAt:
          firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastSeen: DateTime.now(),
      isOnline: true,
      fcmTokens: [], // Will be populated from Firestore
    );
  }
}
