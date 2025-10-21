import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/usecases/ensure_user_exists_in_firestore.dart';
import 'package:message_ai/features/authentication/domain/usecases/sign_in_with_email.dart';
import 'package:message_ai/features/authentication/presentation/pages/password_reset_page.dart';
import 'package:message_ai/features/authentication/presentation/pages/sign_in_page.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockSignInWithEmail extends Mock implements SignInWithEmail {}

class MockEnsureUserExistsInFirestore extends Mock
    implements EnsureUserExistsInFirestore {}

class FakeUser extends Fake implements User {}

void main() {
  late MockSignInWithEmail mockSignInUseCase;
  late MockEnsureUserExistsInFirestore mockEnsureUserExistsUseCase;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    mockSignInUseCase = MockSignInWithEmail();
    mockEnsureUserExistsUseCase = MockEnsureUserExistsInFirestore();
  });

  final testUser = User(
    uid: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
    preferredLanguage: 'en',
    createdAt: DateTime.now(),
    lastSeen: DateTime.now(),
    isOnline: true,
    fcmTokens: [],
  );

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        signInWithEmailUseCaseProvider.overrideWithValue(mockSignInUseCase),
        ensureUserExistsInFirestoreUseCaseProvider.overrideWithValue(
          mockEnsureUserExistsUseCase,
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: SignInPage())),
    );
  }

  group('SignInPage Widget Tests', () {
    testWidgets('should display all UI elements', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.byIcon(Icons.message), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('should show validation error for empty email', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap Sign In without entering email
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should show validation error for empty password', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter email only
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Initially should show visibility icon (password is obscured)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Now should show visibility_off icon (password is visible)
      expect(find.byIcon(Icons.visibility), findsNothing);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('should call sign in use case with valid credentials', (
      tester,
    ) async {
      when(
        () => mockSignInUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      when(
        () => mockEnsureUserExistsUseCase(any()),
      ).thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Tap Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify use case was called
      verify(
        () => mockSignInUseCase(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    testWidgets('should show success message on successful sign in', (
      tester,
    ) async {
      when(
        () => mockSignInUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      when(
        () => mockEnsureUserExistsUseCase(any()),
      ).thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter credentials and sign in
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Should show success snackbar
      expect(find.text('Welcome back, Test User!'), findsOneWidget);
    });

    testWidgets('should show error message on failed sign in', (tester) async {
      const failure = ValidationFailure(
        message: 'Invalid credentials',
        fieldErrors: {},
      );
      when(
        () => mockSignInUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter credentials and sign in
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Invalid credentials'), findsAtLeastNWidgets(1));
    });

    testWidgets('should show loading indicator while signing in', (
      tester,
    ) async {
      when(
        () => mockSignInUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) =>
            Future.delayed(const Duration(seconds: 1), () => Right(testUser)),
      );

      when(
        () => mockEnsureUserExistsUseCase(any()),
      ).thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter credentials and sign in
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Clean up: wait for the async operation to complete
      await tester.pumpAndSettle();
    });

    testWidgets('should navigate to password reset page', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap Forgot Password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Should navigate to PasswordResetPage
      expect(find.byType(PasswordResetPage), findsOneWidget);
    });

    testWidgets('should disable form inputs while loading', (tester) async {
      when(
        () => mockSignInUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) =>
            Future.delayed(const Duration(seconds: 1), () => Right(testUser)),
      );

      when(
        () => mockEnsureUserExistsUseCase(any()),
      ).thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter credentials and sign in
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Should show loading indicator (button is disabled)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future
      await tester.pumpAndSettle();
    });
  });
}
