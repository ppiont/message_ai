import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/usecases/get_conversation_by_id.dart';
import 'package:mocktail/mocktail.dart';

class MockConversationRepository extends Mock
    implements ConversationRepository {}

void main() {
  late GetConversationById useCase;
  late MockConversationRepository mockRepository;

  setUp(() {
    mockRepository = MockConversationRepository();
    useCase = GetConversationById(mockRepository);
  });

  final testConversation = Conversation(
    documentId: 'conv-123',
    type: 'direct',
    participantIds: ['user-1', 'user-2'],
    participants: [
      Participant(uid: 'user-1', name: 'User 1', preferredLanguage: 'en'),
      Participant(uid: 'user-2', name: 'User 2', preferredLanguage: 'en'),
    ],
    lastUpdatedAt: DateTime(2024, 1, 1),
    initiatedAt: DateTime(2024, 1, 1),
    unreadCount: {'user-1': 0, 'user-2': 0},
    translationEnabled: false,
    autoDetectLanguage: false,
  );

  group('GetConversationById', () {
    group('validation', () {
      test('should return ValidationFailure when conversationId is empty',
          () async {
        // Act
        final result = await useCase('');

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
        verifyNever(() => mockRepository.getConversationById(any()));
      });

      test('should return ValidationFailure when conversationId is only spaces',
          () async {
        // Act
        final result = await useCase('   ');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });

    group('success cases', () {
      test('should return conversation when found', () async {
        // Arrange
        when(() => mockRepository.getConversationById(any()))
            .thenAnswer((_) async => Right(testConversation));

        // Act
        final result = await useCase('conv-123');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return conversation'),
          (conversation) {
            expect(conversation.documentId, 'conv-123');
            expect(conversation.type, 'direct');
            expect(conversation.participants.length, 2);
          },
        );

        verify(() => mockRepository.getConversationById('conv-123')).called(1);
      });
    });

    group('error cases', () {
      test('should return RecordNotFoundFailure when conversation not found',
          () async {
        // Arrange
        when(() => mockRepository.getConversationById(any())).thenAnswer(
            (_) async =>
                const Left(RecordNotFoundFailure(recordType: 'Conversation')));

        // Act
        final result = await useCase('non-existent');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<RecordNotFoundFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return ServerFailure when repository fails', () async {
        // Arrange
        when(() => mockRepository.getConversationById(any())).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Server error')));

        // Act
        final result = await useCase('conv-123');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });
    });
  });
}
