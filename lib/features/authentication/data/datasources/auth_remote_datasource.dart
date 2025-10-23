import 'package:firebase_auth/firebase_auth.dart';
import 'package:message_ai/core/error/exceptions.dart';

/// Remote datasource for Firebase Authentication operations
///
/// Handles email and phone authentication, verification, and auth state management.
abstract class AuthRemoteDataSource {
  // ========== Email Authentication ==========

  /// Creates a new user account with email and password
  ///
  /// [email] must be a valid email address
  /// [password] must be at least 6 characters
  /// Returns the authenticated [User] on success
  /// Throws [AuthenticationException] on failure
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Signs in an existing user with email and password
  ///
  /// [email] user's email address
  /// [password] user's password
  /// Returns the authenticated [User] on success
  /// Throws [AuthenticationException] on failure
  Future<User> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sends a password reset email to the provided email address
  ///
  /// [email] user's email address
  /// Throws [AuthenticationException] if email is not registered
  Future<void> sendPasswordResetEmail({required String email});

  /// Sends an email verification link to the current user
  ///
  /// Must be called when a user is signed in
  /// Throws [UnauthorizedException] if no user is signed in
  Future<void> sendEmailVerification();

  /// Checks if the current user's email is verified
  ///
  /// Returns false if no user is signed in
  Future<bool> isEmailVerified();

  // ========== Phone Authentication ==========

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
  /// Throws [AuthenticationException] on failure
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

  /// Updates the current user's profile
  ///
  /// [displayName] optional new display name
  /// [photoURL] optional new photo URL
  /// Returns the updated [User]
  /// Throws [UnauthorizedException] if no user is signed in
  Future<User> updateUserProfile({String? displayName, String? photoURL});

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
  AuthRemoteDataSourceImpl(this._firebaseAuth);
  final FirebaseAuth _firebaseAuth;

  // ========== Email Authentication Implementation ==========

  @override
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const UnauthorizedException(
          message: 'Sign up failed - no user returned',
        );
      }

      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Failed to sign up: $e');
    }
  }

  @override
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
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
      throw ServerException(message: 'Failed to sign in: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw ServerException(message: 'Failed to send password reset email: $e');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UnauthorizedException(message: 'No user signed in');
      }

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Failed to send email verification: $e');
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    // Reload user to get fresh email verification status
    await user.reload();
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  // ========== Phone Authentication Implementation ==========

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
      throw ServerException(message: 'Failed to verify phone number: $e');
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
      throw ServerException(message: 'Failed to verify code: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(message: 'Failed to sign out: $e');
    }
  }

  @override
  User? getCurrentUser() => _firebaseAuth.currentUser;

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

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
      throw ServerException(message: 'Failed to get ID token: $e');
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
      throw ServerException(message: 'Failed to reauthenticate: $e');
    }
  }

  @override
  Future<User> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const UnauthorizedException(message: 'No user signed in');
      }

      // Update the profile
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Reload user to get updated data
      await user.reload();
      final updatedUser = _firebaseAuth.currentUser;

      if (updatedUser == null) {
        throw const UnauthorizedException(message: 'User session expired');
      }

      return updatedUser;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Failed to update profile: $e');
    }
  }

  /// Maps Firebase Auth exceptions to our app exceptions
  AppException _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      // Email-specific errors
      case 'email-already-in-use':
        return const ValidationException(
          message: 'Email address is already in use',
          fieldErrors: {'email': 'This email is already registered'},
        );
      case 'invalid-email':
        return const ValidationException(
          message: 'Invalid email address',
          fieldErrors: {'email': 'Please enter a valid email address'},
        );
      case 'weak-password':
        return const ValidationException(
          message: 'Password is too weak',
          fieldErrors: {'password': 'Password must be at least 6 characters'},
        );
      case 'wrong-password':
        return const ValidationException(
          message: 'Incorrect password',
          fieldErrors: {'password': 'The password is incorrect'},
        );
      case 'user-not-found':
        return const ValidationException(
          message: 'No user found with this email',
          fieldErrors: {'email': 'This email is not registered'},
        );
      case 'too-many-requests':
        return const ServerException(
          message: 'Too many failed attempts. Please try again later.',
          statusCode: 429,
        );

      // Phone-specific errors
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
