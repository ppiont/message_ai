import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/usecases/find_or_create_direct_conversation.dart';
import 'package:mocktail/mocktail.dart';

class MockConversationRepository extends Mock
    implements ConversationRepository {}

class FakeConversation extends Fake implements Conversation {}

void main() {
  late FindOrCreateDirectConversation useCase;
  late MockConversationRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeConversation());
  });

  setUp(() {
    mockRepository = MockConversationRepository();
    useCase = FindOrCreateDirectConversation(mockRepository);
  });

  final participant1 = Participant(
    uid: 'user-1',
    name: 'User 1',
    preferredLanguage: 'en',
  );

  final participant2 = Participant(
    uid: 'user-2',
    name: 'User 2',
    preferredLanguage: 'en',
  );

  final testConversation = Conversation(
    documentId: 'conv-123',
    type: 'direct',
    participantIds: ['user-1', 'user-2'],
    participants: [participant1, participant2],
    lastUpdatedAt: DateTime(2024, 1, 1),
    initiatedAt: DateTime(2024, 1, 1),
    unreadCount: {'user-1': 0, 'user-2': 0},
    translationEnabled: false,
    autoDetectLanguage: false,
  );

  group('FindOrCreateDirectConversation', () {
    group('validation', () {
      test('should return ValidationFailure when userId1 is empty', () async {
        // Act
        final result = await useCase(
          userId1: '',
          userId2: 'user-2',
          user1Participant: participant1,
          user2Participant: participant2,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message,
                'User IDs cannot be empty');
          },
          (_) => fail('Should return failure'),
        );
      });

      test('should return ValidationFailure when user IDs are the same',
          () async {
        // Act
        final result = await useCase(
          userId1: 'user-1',
          userId2: 'user-1',
          user1Participant: participant1,
          user2Participant: participant1,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect((failure as ValidationFailure).message,
                'Cannot create conversation with yourself');
          },
          (_) => fail('Should return failure'),
        );
      });
    });

    group('when conversation exists', () {
      test('should return existing conversation', () async {
        // Arrange
        when(() =>
                mockRepository.findDirectConversation(any(), any()))
            .thenAnswer((_) async => Right(testConversation));

        // Act
        final result = await useCase(
          userId1: 'user-1',
          userId2: 'user-2',
          user1Participant: participant1,
          user2Participant: participant2,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return conversation'),
          (conversation) {
            expect(conversation.documentId, testConversation.documentId);
            expect(conversation.type, 'direct');
          },
        );

        verify(() => mockRepository.findDirectConversation('user-1', 'user-2'))
            .called(1);
        verifyNever(() => mockRepository.createConversation(any()));
      });
    });

    group('when conversation does not exist', () {
      test('should create new conversation', () async {
        // Arrange
        when(() =>
                mockRepository.findDirectConversation(any(), any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepository.createConversation(any()))
            .thenAnswer((_) async => Right(testConversation));

        // Act
        final result = await useCase(
          userId1: 'user-1',
          userId2: 'user-2',
          user1Participant: participant1,
          user2Participant: participant2,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return conversation'),
          (conversation) {
            expect(conversation.type, 'direct');
            expect(conversation.participants.length, 2);
          },
        );

        verify(() => mockRepository.findDirectConversation('user-1', 'user-2'))
            .called(1);
        verify(() => mockRepository.createConversation(any())).called(1);
      });

      test('should preserve participant ID order', () async {
        // Arrange
        when(() =>
                mockRepository.findDirectConversation(any(), any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepository.createConversation(any()))
            .thenAnswer((_) async => Right(testConversation));

        // Act - reversed order
        await useCase(
          userId1: 'user-2',
          userId2: 'user-1',
          user1Participant: participant2,
          user2Participant: participant1,
        );

        // Assert - verify conversation created with IDs in the same order as input
        final captured = verify(
          () => mockRepository.createConversation(captureAny()),
        ).captured;

        final createdConversation = captured.first as Conversation;
        expect(createdConversation.participantIds, ['user-2', 'user-1']);
      });
    });

    group('error cases', () {
      test('should return failure when find operation fails', () async {
        // Arrange
        when(() =>
                mockRepository.findDirectConversation(any(), any()))
            .thenAnswer(
                (_) async => const Left(ServerFailure(message: 'Find failed')));

        // Act
        final result = await useCase(
          userId1: 'user-1',
          userId2: 'user-2',
          user1Participant: participant1,
          user2Participant: participant2,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Should return failure'),
        );
      });

      test('should return failure when create operation fails', () async {
        // Arrange
        when(() =>
                mockRepository.findDirectConversation(any(), any()))
            .thenAnswer((_) async => const Right(null));
        when(() => mockRepository.createConversation(any())).thenAnswer(
            (_) async => const Left(DatabaseFailure(message: 'Create failed')));

        // Act
        final result = await useCase(
          userId1: 'user-1',
          userId2: 'user-2',
          user1Participant: participant1,
          user2Participant: participant2,
        );

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
