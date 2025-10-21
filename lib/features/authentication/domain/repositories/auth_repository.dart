import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';

/// Repository interface for authentication operations
///
/// Defines all authentication-related operations that can be performed.
/// Implementations handle both email and phone authentication methods.
abstract class AuthRepository {
  // ========== Email Authentication ==========

  /// Signs up a new user with email and password
  ///
  /// Returns [Right(User)] on success or [Left(Failure)] on error
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Signs in an existing user with email and password
  ///
  /// Returns [Right(User)] on success or [Left(Failure)] on error
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sends a password reset email
  ///
  /// Returns [Right(Unit)] on success or [Left(Failure)] on error
  Future<Either<Failure, Unit>> sendPasswordResetEmail({
    required String email,
  });

  /// Sends an email verification link to the current user
  ///
  /// Returns [Right(Unit)] on success or [Left(Failure)] on error
  Future<Either<Failure, Unit>> sendEmailVerification();

  /// Checks if the current user's email is verified
  ///
  /// Returns [Right(bool)] with verification status or [Left(Failure)] on error
  Future<Either<Failure, bool>> isEmailVerified();

  // ========== Phone Authentication ==========

  /// Verifies a phone number and triggers SMS code sending
  ///
  /// [onCodeSent] is called when the code is successfully sent
  /// [onVerificationCompleted] is called on auto-verification (Android only)
  /// Returns [Right(Unit)] when process starts or [Left(Failure)] on error
  Future<Either<Failure, Unit>> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(firebase_auth.PhoneAuthCredential credential)
        onVerificationCompleted,
    Duration timeout = const Duration(seconds: 60),
  });

  /// Verifies the SMS code and signs in the user
  ///
  /// Returns [Right(User)] on success or [Left(Failure)] on error
  Future<Either<Failure, User>> verifyCode({
    required String verificationId,
    required String smsCode,
  });

  /// Reauthenticates the current user with phone credentials
  ///
  /// Returns [Right(Unit)] on success or [Left(Failure)] on error
  Future<Either<Failure, Unit>> reauthenticateWithPhone({
    required String verificationId,
    required String smsCode,
  });

  // ========== Common Operations ==========

  /// Signs out the current user
  ///
  /// Returns [Right(Unit)] on success or [Left(Failure)] on error
  Future<Either<Failure, Unit>> signOut();

  /// Gets the current signed-in user
  ///
  /// Returns [Right(User)] if signed in, [Right(null)] if not signed in,
  /// or [Left(Failure)] on error
  Either<Failure, User?> getCurrentUser();

  /// Gets the ID token for the current user
  ///
  /// Returns [Right(String)] with token or [Left(Failure)] on error
  Future<Either<Failure, String>> getIdToken();

  /// Stream of authentication state changes
  ///
  /// Emits [User?] whenever the authentication state changes
  Stream<User?> authStateChanges();
}
