import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';
import 'package:message_ai/features/messaging/domain/usecases/send_message.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}

class MockConversationRepository extends Mock
    implements ConversationRepository {}

class FakeMessage extends Fake implements Message {}

void main() {
  late SendMessage useCase;
  late MockMessageRepository mockMessageRepository;
  late MockConversationRepository mockConversationRepository;

  setUpAll(() {
    registerFallbackValue(FakeMessage());
  });

  setUp(() {
    mockMessageRepository = MockMessageRepository();
    mockConversationRepository = MockConversationRepository();
    useCase = SendMessage(
      messageRepository: mockMessageRepository,
      conversationRepository: mockConversationRepository,
    );
  });

  final testMessage = Message(
    id: 'msg-123',
    senderId: 'user-1',
    senderName: 'Test User',
    text: 'Hello, World!',
    timestamp: DateTime(2024, 1, 1),
    status: 'sent',
    type: 'text',
    metadata: MessageMetadata.defaultMetadata(),
  );

  group('SendMessage', () {
    group('validation', () {
      test('should return ValidationFailure when message text is empty',
          () async {
        // Arrange
        final emptyMessage = testMessage.copyWith(text: '');

        // Act
        final result = await useCase('conv-123', emptyMessage);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message,
                'Message cannot be empty');
          },
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockMessageRepository.createMessage(any(), any()));
      });

      test('should return ValidationFailure when message text is only spaces',
          () async {
        // Arrange
        final spacesMessage = testMessage.copyWith(text: '   ');

        // Act
        final result = await useCase('conv-123', spacesMessage);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
          },
          (_) => fail('Should return failure'),
        );
        verifyNever(() => mockMessageRepository.createMessage(any(), any()));
      });
    });

    group('success cases', () {
      test('should create message and update conversation', () async {
        // Arrange
        when(() => mockMessageRepository.createMessage(any(), any()))
            .thenAnswer((_) async => Right(testMessage));
        when(() => mockConversationRepository.updateLastMessage(
              any(),
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => const Right(null));

        // Act
        final result = await useCase('conv-123', testMessage);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return message'),
          (message) {
            expect(message.id, testMessage.id);
            expect(message.text, testMessage.text);
          },
        );

        verify(() => mockMessageRepository.createMessage('conv-123', testMessage))
            .called(1);
        verify(() => mockConversationRepository.updateLastMessage(
              'conv-123',
              testMessage.text,
              testMessage.senderId,
              testMessage.senderName,
              testMessage.timestamp,
            )).called(1);
      });

      test('should still succeed if conversation update fails', () async {
        // Arrange - message creation succeeds, conversation update fails
        when(() => mockMessageRepository.createMessage(any(), any()))
            .thenAnswer((_) async => Right(testMessage));
        when(() => mockConversationRepository.updateLastMessage(
              any(),
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Update failed')));

        // Act
        final result = await useCase('conv-123', testMessage);

        // Assert - should still succeed because conversation update is non-critical
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return message despite conversation update failure'),
          (message) => expect(message.id, testMessage.id),
        );
      });
    });

    group('error cases', () {
      test('should return ServerFailure when message creation fails', () async {
        // Arrange
        when(() => mockMessageRepository.createMessage(any(), any()))
            .thenAnswer(
                (_) async => const Left(ServerFailure(message: 'Create failed')));

        // Act
        final result = await useCase('conv-123', testMessage);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );

        // Conversation update should not be called if message creation fails
        verifyNever(() => mockConversationRepository.updateLastMessage(
            any(), any(), any(), any(), any()));
      });

      test('should return DatabaseFailure when database error occurs',
          () async {
        // Arrange
        when(() => mockMessageRepository.createMessage(any(), any()))
            .thenAnswer(
                (_) async => const Left(DatabaseFailure(message: 'DB error')));

        // Act
        final result = await useCase('conv-123', testMessage);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });
  });
}
