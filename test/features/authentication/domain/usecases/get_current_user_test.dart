import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';
import 'package:message_ai/features/authentication/domain/usecases/get_current_user.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetCurrentUser useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetCurrentUser(mockRepository);
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

  group('GetCurrentUser', () {
    test('should return current user when signed in', () {
      // Arrange
      when(() => mockRepository.getCurrentUser()).thenReturn(Right(testUser));

      // Act
      final result = useCase();

      // Assert
      expect(result, Right(testUser));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('should return null when not signed in', () {
      // Arrange
      when(() => mockRepository.getCurrentUser()).thenReturn(const Right(null));

      // Act
      final result = useCase();

      // Assert
      expect(result, const Right(null));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('should return failure when repository fails', () {
      // Arrange
      const failure = ServerFailure(message: 'Failed to get user');
      when(
        () => mockRepository.getCurrentUser(),
      ).thenReturn(const Left(failure));

      // Act
      final result = useCase();

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });
  });
}
