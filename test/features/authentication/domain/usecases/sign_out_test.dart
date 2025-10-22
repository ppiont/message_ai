import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';
import 'package:message_ai/features/authentication/domain/usecases/sign_out.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignOut useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignOut(mockRepository);
  });

  group('SignOut', () {
    test('should sign out user successfully', () async {
      // Arrange
      when(
        () => mockRepository.signOut(),
      ).thenAnswer((_) async => const Right(unit));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Right(unit));
      verify(() => mockRepository.signOut()).called(1);
    });

    test('should return failure when sign out fails', () async {
      // Arrange
      const failure = ServerFailure(message: 'Sign out failed');
      when(
        () => mockRepository.signOut(),
      ).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.signOut()).called(1);
    });
  });
}
