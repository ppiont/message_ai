import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';
import 'package:message_ai/features/messaging/domain/usecases/mark_message_as_read.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late MarkMessageAsRead useCase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    useCase = MarkMessageAsRead(mockRepository);
  });

  group('MarkMessageAsRead', () {
    group('validation', () {
      test('should return ValidationFailure when conversationId is empty',
          () async {
        // Act
        final result = await useCase('', 'msg-123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message,
                'Conversation ID is required');
          },
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockRepository.markAsRead(any(), any()));
      });

      test('should return ValidationFailure when messageId is empty',
          () async {
        // Act
        final result = await useCase('conv-123', '');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message,
                'Message ID is required');
          },
          (_) => fail('Should return failure'),
        );
      });
    });

    group('success cases', () {
      test('should mark message as read successfully', () async {
        // Arrange
        when(() => mockRepository.markAsRead(any(), any()))
            .thenAnswer((_) async => const Right(null));

        // Act
        final result = await useCase('conv-123', 'msg-123');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockRepository.markAsRead('conv-123', 'msg-123'))
            .called(1);
      });
    });

    group('error cases', () {
      test('should return ServerFailure when repository fails', () async {
        // Arrange
        when(() => mockRepository.markAsRead(any(), any())).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Update failed')));

        // Act
        final result = await useCase('conv-123', 'msg-123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return RecordNotFoundFailure when message not found',
          () async {
        // Arrange
        when(() => mockRepository.markAsRead(any(), any())).thenAnswer(
            (_) async =>
                const Left(RecordNotFoundFailure(recordType: 'Message')));

        // Act
        final result = await useCase('conv-123', 'non-existent');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<RecordNotFoundFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });
  });
}
