import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';
import 'package:message_ai/features/authentication/domain/usecases/watch_auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late WatchAuthState useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = WatchAuthState(mockRepository);
  });

  final testUser = User(
    uid: 'test-uid',
    email: 'test@example.com',
    displayName: 'Test User',
    preferredLanguage: 'en',
    createdAt: DateTime.now(),
    lastSeen: DateTime.now(),
    isOnline: true,
    fcmTokens: const [],
  );

  group('WatchAuthState', () {
    test('should emit user when signed in', () async {
      // Arrange
      when(
        () => mockRepository.authStateChanges(),
      ).thenAnswer((_) => Stream.value(testUser));

      // Act
      final stream = useCase();

      // Assert
      expectLater(stream, emits(testUser));
      verify(() => mockRepository.authStateChanges()).called(1);
    });

    test('should emit null when signed out', () async {
      // Arrange
      when(
        () => mockRepository.authStateChanges(),
      ).thenAnswer((_) => Stream.value(null));

      // Act
      final stream = useCase();

      // Assert
      expectLater(stream, emits(null));
      verify(() => mockRepository.authStateChanges()).called(1);
    });

    test('should emit multiple state changes', () async {
      // Arrange
      when(
        () => mockRepository.authStateChanges(),
      ).thenAnswer((_) => Stream.fromIterable([null, testUser, null]));

      // Act
      final stream = useCase();

      // Assert
      expectLater(stream, emitsInOrder([null, testUser, null]));
    });

    test('should emit user sign in and sign out flow', () async {
      // Arrange
      when(() => mockRepository.authStateChanges()).thenAnswer(
        (_) => Stream.fromIterable([
          null, // Initial state: not signed in
          testUser, // User signs in
          null, // User signs out
        ]),
      );

      // Act
      final stream = useCase();

      // Assert
      await expectLater(
        stream,
        emitsInOrder([
          null, // Not signed in
          testUser, // Signed in
          null, // Signed out
        ]),
      );
    });

    test('should propagate errors from repository stream', () async {
      // Arrange
      final error = Exception('Auth state error');
      when(
        () => mockRepository.authStateChanges(),
      ).thenAnswer((_) => Stream.error(error));

      // Act
      final stream = useCase();

      // Assert
      expectLater(stream, emitsError(error));
    });
  });
}
