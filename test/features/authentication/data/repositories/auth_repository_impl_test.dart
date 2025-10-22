import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:message_ai/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart'
    as domain;
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockPhoneAuthCredential extends Mock
    implements firebase_auth.PhoneAuthCredential {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockDataSource;
  late MockFirebaseAuth mockFirebaseAuth;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(const Duration(seconds: 60));
    registerFallbackValue(MockPhoneAuthCredential());
  });

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockDataSource);

    // Set up mock Firebase Auth for user creation
    final mockUser = MockUser(
      uid: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
      phoneNumber: '+1234567890',
    );
    mockFirebaseAuth = MockFirebaseAuth(mockUser: mockUser);
  });

  group('Email Authentication', () {
    group('signUpWithEmail', () {
      test('should return User on successful sign up', () async {
        // Arrange
        final firebaseUser = await mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ).then((cred) => cred.user!);

        when(
          () => mockDataSource.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => firebaseUser);

        // Act
        final result = await repository.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (user) {
            expect(user.uid, isNotEmpty);
            expect(user.email, 'test@example.com');
          },
        );
        verify(
          () => mockDataSource.signUpWithEmail(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).called(1);
      });

      test('should return Failure when data source throws ValidationException',
          () async {
        // Arrange
        when(
          () => mockDataSource.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          const ValidationException(
            message: 'Email already in use',
            fieldErrors: {'email': 'Email already registered'},
          ),
        );

        // Act
        final result = await repository.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('Email already in use'));
          },
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    group('signInWithEmail', () {
      test('should return User on successful sign in', () async {
        // Arrange
        final firebaseUser = await mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ).then((cred) => cred.user!);

        when(
          () => mockDataSource.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => firebaseUser);

        // Act
        final result = await repository.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (user) {
            expect(user.uid, isNotEmpty);
            expect(user.email, 'test@example.com');
          },
        );
      });

      test('should return Failure when credentials are invalid', () async {
        // Arrange
        when(
          () => mockDataSource.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          const ValidationException(
            message: 'Invalid credentials',
            fieldErrors: {'password': 'Incorrect password'},
          ),
        );

        // Act
        final result = await repository.signInWithEmail(
          email: 'test@example.com',
          password: 'wrong-password',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    group('sendPasswordResetEmail', () {
      test('should return Unit on success', () async {
        // Arrange
        when(
          () => mockDataSource.sendPasswordResetEmail(
            email: any(named: 'email'),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.sendPasswordResetEmail(
          email: 'test@example.com',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (value) => expect(value, unit),
        );
      });

      test('should return Failure on error', () async {
        // Arrange
        when(
          () => mockDataSource.sendPasswordResetEmail(
            email: any(named: 'email'),
          ),
        ).thenThrow(
          const ServerException(message: 'Network error'),
        );

        // Act
        final result = await repository.sendPasswordResetEmail(
          email: 'test@example.com',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    group('sendEmailVerification', () {
      test('should return Unit on success', () async {
        // Arrange
        when(() => mockDataSource.sendEmailVerification())
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.sendEmailVerification();

        // Assert
        expect(result.isRight(), true);
      });

      test('should return Failure when no user is signed in', () async {
        // Arrange
        when(() => mockDataSource.sendEmailVerification()).thenThrow(
          const UnauthorizedException(message: 'No user signed in'),
        );

        // Act
        final result = await repository.sendEmailVerification();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    group('isEmailVerified', () {
      test('should return true when email is verified', () async {
        // Arrange
        when(() => mockDataSource.isEmailVerified())
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.isEmailVerified();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (isVerified) => expect(isVerified, true),
        );
      });

      test('should return false when email is not verified', () async {
        // Arrange
        when(() => mockDataSource.isEmailVerified())
            .thenAnswer((_) async => false);

        // Act
        final result = await repository.isEmailVerified();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (isVerified) => expect(isVerified, false),
        );
      });
    });
  });

  group('Phone Authentication', () {
    group('verifyPhoneNumber', () {
      test('should return Unit on successful verification start', () async {
        // Arrange
        void onCodeSent(String verificationId, int? resendToken) {}
        void onVerificationCompleted(
            firebase_auth.PhoneAuthCredential credential) {}

        when(
          () => mockDataSource.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            onCodeSent: any(named: 'onCodeSent'),
            onVerificationCompleted: any(named: 'onVerificationCompleted'),
            timeout: any(named: 'timeout'),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.verifyPhoneNumber(
          phoneNumber: '+1234567890',
          onCodeSent: onCodeSent,
          onVerificationCompleted: onVerificationCompleted,
        );

        // Assert
        expect(result.isRight(), true);
      });

      test('should return Failure on invalid phone number', () async {
        // Arrange
        void onCodeSent(String verificationId, int? resendToken) {}
        void onVerificationCompleted(
            firebase_auth.PhoneAuthCredential credential) {}

        when(
          () => mockDataSource.verifyPhoneNumber(
            phoneNumber: any(named: 'phoneNumber'),
            onCodeSent: any(named: 'onCodeSent'),
            onVerificationCompleted: any(named: 'onVerificationCompleted'),
            timeout: any(named: 'timeout'),
          ),
        ).thenThrow(
          const ValidationException(
            message: 'Invalid phone number',
            fieldErrors: {'phoneNumber': 'Invalid format'},
          ),
        );

        // Act
        final result = await repository.verifyPhoneNumber(
          phoneNumber: 'invalid',
          onCodeSent: onCodeSent,
          onVerificationCompleted: onVerificationCompleted,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    group('verifyCode', () {
      test('should return User on successful code verification', () async {
        // Arrange
        final firebaseUser = await mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ).then((cred) => cred.user!);

        when(
          () => mockDataSource.verifyCode(
            verificationId: 'verification-id',
            smsCode: '123456',
          ),
        ).thenAnswer((_) async => firebaseUser);

        // Act
        final result = await repository.verifyCode(
          verificationId: 'verification-id',
          smsCode: '123456',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (user) => expect(user.uid, isNotEmpty),
        );
      });

      test('should return Failure on invalid code', () async {
        // Arrange
        when(
          () => mockDataSource.verifyCode(
            verificationId: 'verification-id',
            smsCode: 'wrong-code',
          ),
        ).thenThrow(
          const ValidationException(
            message: 'Invalid verification code',
            fieldErrors: {'smsCode': 'Code is incorrect'},
          ),
        );

        // Act
        final result = await repository.verifyCode(
          verificationId: 'verification-id',
          smsCode: 'wrong-code',
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    group('reauthenticateWithPhone', () {
      test('should return Unit on successful reauthentication', () async {
        // Arrange
        when(
          () => mockDataSource.reauthenticateWithPhone(
            verificationId: 'verification-id',
            smsCode: '123456',
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.reauthenticateWithPhone(
          verificationId: 'verification-id',
          smsCode: '123456',
        );

        // Assert
        expect(result.isRight(), true);
      });
    });
  });

  group('Common Operations', () {
    group('signOut', () {
      test('should return Unit on successful sign out', () async {
        // Arrange
        when(() => mockDataSource.signOut())
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (value) => expect(value, unit),
        );
        verify(() => mockDataSource.signOut()).called(1);
      });

      test('should return Failure on error', () async {
        // Arrange
        when(() => mockDataSource.signOut()).thenThrow(
          const ServerException(message: 'Sign out failed'),
        );

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    group('getCurrentUser', () {
      test('should return User when user is signed in', () {
        // Arrange
        final mockUser = MockUser(
          uid: 'test-uid',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        when(() => mockDataSource.getCurrentUser()).thenReturn(mockUser);

        // Act
        final result = repository.getCurrentUser();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (user) {
            expect(user, isNotNull);
            expect(user?.uid, isNotEmpty);
            expect(user?.email, 'test@example.com');
          },
        );
      });

      test('should return null when no user is signed in', () {
        // Arrange
        when(() => mockDataSource.getCurrentUser()).thenReturn(null);

        // Act
        final result = repository.getCurrentUser();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (user) => expect(user, isNull),
        );
      });
    });

    group('getIdToken', () {
      test('should return token on success', () async {
        // Arrange
        when(() => mockDataSource.getIdToken())
            .thenAnswer((_) async => 'test-token');

        // Act
        final result = await repository.getIdToken();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (token) => expect(token, 'test-token'),
        );
      });

      test('should return Failure when no user is signed in', () async {
        // Arrange
        when(() => mockDataSource.getIdToken()).thenThrow(
          const UnauthorizedException(message: 'No user signed in'),
        );

        // Act
        final result = await repository.getIdToken();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<UnauthorizedFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    group('authStateChanges', () {
      test('should emit User when auth state changes', () async {
        // Arrange
        final mockUser = MockUser(
          uid: 'test-uid',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        when(() => mockDataSource.authStateChanges())
            .thenAnswer((_) => Stream.value(mockUser));

        // Act
        final stream = repository.authStateChanges();

        // Assert
        await expectLater(
          stream,
          emits(predicate<domain.User>((user) => user.uid.isNotEmpty)),
        );
      });

      test('should emit null when user signs out', () async {
        // Arrange
        when(() => mockDataSource.authStateChanges())
            .thenAnswer((_) => Stream.value(null));

        // Act
        final stream = repository.authStateChanges();

        // Assert
        await expectLater(stream, emits(null));
      });
    });
  });
}
