import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';
import 'package:message_ai/features/messaging/domain/usecases/watch_messages.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late WatchMessages useCase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    useCase = WatchMessages(mockRepository);
  });

  final testMessages = [
    Message(
      id: 'msg-1',
      senderId: 'user-1',
      senderName: 'User 1',
      text: 'Hello',
      timestamp: DateTime(2024, 1, 1),
      status: 'sent',
      type: 'text',
      metadata: MessageMetadata.defaultMetadata(),
    ),
    Message(
      id: 'msg-2',
      senderId: 'user-2',
      senderName: 'User 2',
      text: 'Hi',
      timestamp: DateTime(2024, 1, 1, 1),
      status: 'delivered',
      type: 'text',
      metadata: MessageMetadata.defaultMetadata(),
    ),
  ];

  group('WatchMessages', () {
    group('validation', () {
      test(
        'should return ValidationFailure when conversationId is empty',
        () async {
          // Act
          final stream = useCase(conversationId: '', currentUserId: 'user-123');

          // Assert
          await expectLater(
            stream.first,
            completion(
              predicate<Either<Failure, List<Message>>>((result) {
                return result.isLeft() &&
                    result.fold((l) => l, (r) => null) is ValidationFailure;
              }),
            ),
          );
        },
      );

      test(
        'should return ValidationFailure when conversationId is only spaces',
        () async {
          // Act
          final stream = useCase(
            conversationId: '   ',
            currentUserId: 'user-123',
          );

          // Assert
          await expectLater(
            stream.first,
            completion(
              predicate<Either<Failure, List<Message>>>((result) {
                return result.isLeft();
              }),
            ),
          );
        },
      );
    });

    group('success cases', () {
      test('should return stream of messages', () async {
        // Arrange
        when(
          () => mockRepository.watchMessages(
            conversationId: any(named: 'conversationId'), currentUserId: any(named: 'currentUserId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) => Stream.value(Right(testMessages)));

        // Act
        final stream = useCase(conversationId: 'conv-123', currentUserId: 'user-123');

        // Assert
        await expectLater(
          stream.first,
          completion(
            predicate<Either<Failure, List<Message>>>((result) {
              return result.isRight() &&
                  result.fold((l) => null, (r) => r)!.length == 2;
            }),
          ),
        );

        verify(
          () => mockRepository.watchMessages(
            conversationId: 'conv-123',
            limit: 50,
          ),
        ).called(1);
      });

      test('should respect custom limit parameter', () async {
        // Arrange
        when(
          () => mockRepository.watchMessages(
            conversationId: any(named: 'conversationId'), currentUserId: any(named: 'currentUserId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) => Stream.value(Right(testMessages)));

        // Act
        final stream = useCase(conversationId: 'conv-123', currentUserId: 'user-123', limit: 100);

        // Assert
        await expectLater(stream.first, completes);

        verify(
          () => mockRepository.watchMessages(
            conversationId: 'conv-123',
            limit: 100,
          ),
        ).called(1);
      });

      test('should emit empty list when no messages', () async {
        // Arrange
        when(
          () => mockRepository.watchMessages(
            conversationId: any(named: 'conversationId'), currentUserId: any(named: 'currentUserId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) => Stream.value(const Right([])));

        // Act
        final stream = useCase(conversationId: 'conv-123', currentUserId: 'user-123');

        // Assert
        await expectLater(
          stream.first,
          completion(
            predicate<Either<Failure, List<Message>>>((result) {
              return result.isRight() &&
                  result.fold((l) => null, (r) => r)!.isEmpty;
            }),
          ),
        );
      });
    });
  });
}
