import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/usecases/watch_conversations.dart';
import 'package:mocktail/mocktail.dart';

class MockConversationRepository extends Mock
    implements ConversationRepository {}

void main() {
  late WatchConversations useCase;
  late MockConversationRepository mockRepository;

  setUp(() {
    mockRepository = MockConversationRepository();
    useCase = WatchConversations(mockRepository);
  });

  final testConversations = [
    Conversation(
      documentId: 'conv-1',
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
    ),
    Conversation(
      documentId: 'conv-2',
      type: 'direct',
      participantIds: ['user-1', 'user-3'],
      participants: [
        Participant(uid: 'user-1', name: 'User 1', preferredLanguage: 'en'),
        Participant(uid: 'user-3', name: 'User 3', preferredLanguage: 'en'),
      ],
      lastUpdatedAt: DateTime(2024, 1, 2),
      initiatedAt: DateTime(2024, 1, 2),
      unreadCount: {'user-1': 2, 'user-3': 0},
      translationEnabled: false,
      autoDetectLanguage: false,
    ),
  ];

  group('WatchConversations', () {
    group('validation', () {
      test('should return ValidationFailure when userId is empty', () async {
        // Act
        final stream = useCase(userId: '');

        // Assert
        await expectLater(
          stream.first,
          completion(
              predicate<Either<Failure, List<Conversation>>>((result) {
            return result.isLeft() &&
                result.fold((l) => l, (r) => null) is ValidationFailure;
          })),
        );
      });

      test('should return ValidationFailure when userId is only spaces',
          () async {
        // Act
        final stream = useCase(userId: '   ');

        // Assert
        await expectLater(
          stream.first,
          completion(
              predicate<Either<Failure, List<Conversation>>>((result) {
            return result.isLeft();
          })),
        );
      });
    });

    group('success cases', () {
      test('should return stream of conversations', () async {
        // Arrange
        when(() => mockRepository.watchConversationsForUser(any(),
                limit: any(named: 'limit')))
            .thenAnswer((_) => Stream.value(Right(testConversations)));

        // Act
        final stream = useCase(userId: 'user-1');

        // Assert
        await expectLater(
          stream.first,
          completion(
              predicate<Either<Failure, List<Conversation>>>((result) {
            return result.isRight() &&
                result.fold((l) => null, (r) => r)!.length == 2;
          })),
        );

        verify(() => mockRepository.watchConversationsForUser('user-1', limit: 50))
            .called(1);
      });

      test('should respect custom limit parameter', () async {
        // Arrange
        when(() => mockRepository.watchConversationsForUser(any(),
                limit: any(named: 'limit')))
            .thenAnswer((_) => Stream.value(Right(testConversations)));

        // Act
        final stream = useCase(userId: 'user-1', limit: 100);

        // Assert
        await expectLater(stream.first, completes);

        verify(() => mockRepository.watchConversationsForUser('user-1', limit: 100))
            .called(1);
      });

      test('should emit empty list when no conversations', () async {
        // Arrange
        when(() => mockRepository.watchConversationsForUser(any(),
                limit: any(named: 'limit')))
            .thenAnswer((_) => Stream.value(const Right([])));

        // Act
        final stream = useCase(userId: 'user-1');

        // Assert
        await expectLater(
          stream.first,
          completion(
              predicate<Either<Failure, List<Conversation>>>((result) {
            return result.isRight() &&
                result.fold((l) => null, (r) => r)!.isEmpty;
          })),
        );
      });
    });
  });
}
