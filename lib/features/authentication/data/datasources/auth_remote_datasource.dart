import 'package:firebase_auth/firebase_auth.dart';
import 'package:message_ai/core/error/exceptions.dart';

/// Remote datasource for Firebase Authentication operations
///
/// Handles phone authentication, verification, and auth state management.
abstract class AuthRemoteDataSource {
  /// Sends a verification code to the provided phone number
  ///
  /// [phoneNumber] must be in E.164 format (e.g., +1234567890)
  /// [onCodeSent] callback triggered when code is sent with verification ID
  /// [onVerificationCompleted] callback for auto-verification (Android only)
  /// [timeout] maximum time to wait for SMS auto-retrieval
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(PhoneAuthCredential credential)
    onVerificationCompleted,
    Duration timeout = const Duration(seconds: 60),
  });

  /// Verifies the SMS code and signs in the user
  ///
  /// [verificationId] received from [verifyPhoneNumber]
  /// [smsCode] the 6-digit code entered by the user
  /// Returns the authenticated [User] on success
  /// Throws [AuthException] on failure
  Future<User> verifyCode({
    required String verificationId,
    required String smsCode,
  });

  /// Signs out the current user
  ///
  /// Clears authentication state and token
  Future<void> signOut();

  /// Gets the currently signed-in user
  ///
  /// Returns null if no user is signed in
  User? getCurrentUser();

  /// Stream of authentication state changes
  ///
  /// Emits whenever the user signs in or out
  Stream<User?> authStateChanges();

  /// Gets the current user's ID token
  ///
  /// Used for authenticating with Firebase services
  /// Throws [UnauthorizedException] if no user is signed in
  Future<String> getIdToken();

  /// Re-authenticates the current user with phone credentials
  ///
  /// Used when user needs to re-verify their identity
  Future<void> reauthenticateWithPhone({
    required String verificationId,
    required String smsCode,
  });
}

/// Implementation of [AuthRemoteDataSource] using Firebase Auth
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;

  AuthRemoteDataSourceImpl(this._firebaseAuth);

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(PhoneAuthCredential credential)
    onVerificationCompleted,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: timeout,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: (FirebaseAuthException e) {
          throw _mapAuthException(e);
        },
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout - no action needed
        },
      );
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw ServerException(
        message: 'Failed to verify phone number: ${e.toString()}',
      );
    }
  }

  @override
  Future<User> verifyCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        throw const UnauthorizedException(
          message: 'Sign in failed - no user returned',
        );
      }

      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Failed to verify code: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(message: 'Failed to sign out: ${e.toString()}');
    }
  }

  @override
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  @override
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  @override
  Future<String> getIdToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UnauthorizedException(message: 'No user signed in');
      }

      final token = await user.getIdToken();
      if (token == null) {
        throw const UnauthorizedException(message: 'Failed to get ID token');
      }

      return token;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Failed to get ID token: ${e.toString()}');
    }
  }

  @override
  Future<void> reauthenticateWithPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UnauthorizedException(message: 'No user signed in');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'Failed to reauthenticate: ${e.toString()}',
      );
    }
  }

  /// Maps Firebase Auth exceptions to our app exceptions
  AppException _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return const ValidationException(
          message: 'Invalid phone number format',
          fieldErrors: {'phoneNumber': 'Invalid phone number format'},
        );
      case 'invalid-verification-code':
        return const ValidationException(
          message: 'Invalid verification code',
          fieldErrors: {'smsCode': 'Invalid verification code'},
        );
      case 'invalid-verification-id':
        return const ValidationException(
          message: 'Invalid verification ID',
          fieldErrors: {'verificationId': 'Invalid verification ID'},
        );
      case 'session-expired':
        return const UnauthorizedException(
          message: 'Verification session expired. Please request a new code.',
        );
      case 'too-many-requests':
        return const ServerException(
          message: 'Too many requests. Please try again later.',
          statusCode: 429,
        );
      case 'user-disabled':
        return const UnauthorizedException(
          message: 'This account has been disabled',
        );
      case 'operation-not-allowed':
        return const ServerException(
          message: 'Phone authentication is not enabled',
          statusCode: 403,
        );
      case 'network-request-failed':
        return const NoInternetException();
      case 'requires-recent-login':
        return const UnauthorizedException(
          message: 'Please sign in again to continue',
        );
      case 'quota-exceeded':
        return const ServerException(
          message: 'SMS quota exceeded. Please try again later.',
          statusCode: 429,
        );
      default:
        return UnknownException(
          message: e.message ?? 'Authentication error',
          originalError: e,
        );
    }
  }
}
