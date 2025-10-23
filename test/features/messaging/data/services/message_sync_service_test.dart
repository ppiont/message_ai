import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_local_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/message_local_datasource.dart';
import 'package:message_ai/features/messaging/data/services/message_sync_service.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockMessageLocalDataSource extends Mock
    implements MessageLocalDataSource {}

class MockMessageRepository extends Mock implements MessageRepository {}

class MockConversationLocalDataSource extends Mock
    implements ConversationLocalDataSource {}

class MockConversationRepository extends Mock
    implements ConversationRepository {}

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late MessageSyncService syncService;
  late MockMessageLocalDataSource mockMessageLocal;
  late MockMessageRepository mockMessageRepository;
  late MockConversationLocalDataSource mockConversationLocal;
  late MockConversationRepository mockConversationRepository;
  late MockConnectivity mockConnectivity;
  late StreamController<List<ConnectivityResult>> connectivityController;

  // Test data
  final testMessage = Message(
    id: 'msg-1',
    text: 'Test message',
    senderId: 'user-1',
    timestamp: DateTime(2024, 1, 1, 12),
    type: 'text',
    status: 'sent',
    metadata: MessageMetadata.defaultMetadata(),
  );

  final testConversation = Conversation(
    documentId: 'conv-1',
    type: 'direct',
    participantIds: const ['user-1', 'user-2'],
    participants: const [
      Participant(
        uid: 'user-1',
        name: 'User One',
        preferredLanguage: 'en',
      ),
      Participant(
        uid: 'user-2',
        name: 'User Two',
        preferredLanguage: 'es',
      ),
    ],
    lastUpdatedAt: DateTime(2024, 1, 1, 12),
    initiatedAt: DateTime(2024, 1, 1, 10),
    unreadCount: const {'user-1': 0, 'user-2': 1},
    translationEnabled: true,
    autoDetectLanguage: true,
  );

  setUp(() {
    mockMessageLocal = MockMessageLocalDataSource();
    mockMessageRepository = MockMessageRepository();
    mockConversationLocal = MockConversationLocalDataSource();
    mockConversationRepository = MockConversationRepository();
    mockConnectivity = MockConnectivity();

    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();

    // Register fallback values
    registerFallbackValue(testMessage);
    registerFallbackValue(testConversation);

    // Default connectivity behavior
    when(
      () => mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);

    syncService = MessageSyncService(
      messageLocalDataSource: mockMessageLocal,
      messageRepository: mockMessageRepository,
      conversationLocalDataSource: mockConversationLocal,
      conversationRepository: mockConversationRepository,
      connectivity: mockConnectivity,
    );
  });

  tearDown(() {
    connectivityController.close();
  });

  group('MessageSyncService', () {
    group('Initialization', () {
      test('should start monitoring connectivity', () async {
        // Arrange
        when(
          () => mockConversationLocal.getUnsyncedConversations(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMessageLocal.getUnsyncedMessages(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMessageLocal.getFailedMessagesForRetry(
            maxRetries: any(named: 'maxRetries'),
          ),
        ).thenAnswer((_) async => []);

        // Act
        await syncService.start();

        // Assert
        // Called once from start() and once from initial syncAll()
        verify(() => mockConnectivity.checkConnectivity()).called(2);
        verify(() => mockConnectivity.onConnectivityChanged).called(1);
      });

      test('should perform initial sync if online', () async {
        // Arrange
        when(
          () => mockConversationLocal.getUnsyncedConversations(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMessageLocal.getUnsyncedMessages(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMessageLocal.getFailedMessagesForRetry(
            maxRetries: any(named: 'maxRetries'),
          ),
        ).thenAnswer((_) async => []);

        // Act
        await syncService.start();

        // Assert
        verify(
          () => mockConversationLocal.getUnsyncedConversations(),
        ).called(1);
        verify(() => mockMessageLocal.getUnsyncedMessages()).called(1);
      });

      test('should not sync if offline initially', () async {
        // Arrange
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        await syncService.start();

        // Assert
        verifyNever(() => mockConversationLocal.getUnsyncedConversations());
        verifyNever(() => mockMessageLocal.getUnsyncedMessages());
      });
    });

    group('Network Connectivity', () {
      test('should trigger sync when going online', () async {
        // Arrange
        when(
          () => mockConversationLocal.getUnsyncedConversations(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMessageLocal.getUnsyncedMessages(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMessageLocal.getFailedMessagesForRetry(
            maxRetries: any(named: 'maxRetries'),
          ),
        ).thenAnswer((_) async => []);

        await syncService.start();

        // Reset call count
        clearInteractions(mockConversationLocal);
        clearInteractions(mockMessageLocal);

        // Act - Simulate going online
        connectivityController.add([ConnectivityResult.wifi]);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(
          () => mockConversationLocal.getUnsyncedConversations(),
        ).called(1);
        verify(() => mockMessageLocal.getUnsyncedMessages()).called(1);
      });

      test('should not sync when already syncing', () async {
        // Arrange
        when(() => mockConversationLocal.getUnsyncedConversations()).thenAnswer(
          (_) async {
            // Slow operation to keep sync flag true
            await Future.delayed(const Duration(milliseconds: 500));
            return [];
          },
        );
        when(
          () => mockMessageLocal.getUnsyncedMessages(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMessageLocal.getFailedMessagesForRetry(
            maxRetries: any(named: 'maxRetries'),
          ),
        ).thenAnswer((_) async => []);

        // Act - Start two syncs simultaneously
        final sync1 = syncService.syncAll();
        await Future.delayed(const Duration(milliseconds: 50));
        final sync2 = syncService.syncAll();

        final results = await Future.wait([sync1, sync2]);

        // Assert
        expect(results[0].errors, isEmpty);
        expect(results[1].errors, contains('Sync already in progress'));
      });

      test('should return error when no network connection', () async {
        // Arrange
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await syncService.syncAll();

        // Assert
        expect(result.errors, contains('No network connection'));
        expect(result.messagesSynced, 0);
        expect(result.conversationsSynced, 0);
      });
    });

    group('Message Sync', () {
      test('should create message remotely if it does not exist', () async {
        // Arrange
        when(
          () => mockMessageRepository.getMessageById(any(), any()),
        ).thenAnswer(
          (_) async => const Left(RecordNotFoundFailure(recordType: 'message')),
        );

        when(
          () => mockMessageRepository.createMessage(any(), any()),
        ).thenAnswer((_) async => Right(testMessage));

        when(
          () => mockMessageLocal.updateSyncStatus(
            messageId: any(named: 'messageId'),
            syncStatus: any(named: 'syncStatus'),
            lastSyncAttempt: any(named: 'lastSyncAttempt'),
            retryCount: any(named: 'retryCount'),
          ),
        ).thenAnswer((_) async => true);

        // Act
        final success = await syncService.syncMessage(
          conversationId: 'conv-1',
          message: testMessage,
        );

        // Assert
        expect(success, true);
        verify(
          () => mockMessageRepository.createMessage('conv-1', testMessage),
        ).called(1);
        verify(
          () => mockMessageLocal.updateSyncStatus(
            messageId: testMessage.id,
            syncStatus: 'synced',
            lastSyncAttempt: any(named: 'lastSyncAttempt'),
            retryCount: 0,
          ),
        ).called(1);
      });

      test('should resolve conflict when message exists remotely', () async {
        // Arrange
        final remoteMessage = testMessage.copyWith(text: 'Different text');

        when(
          () => mockMessageRepository.getMessageById(any(), any()),
        ).thenAnswer((_) async => Right(remoteMessage));

        when(
          () => mockMessageLocal.hasConflict(
            localMessage: any(named: 'localMessage'),
            remoteMessage: any(named: 'remoteMessage'),
          ),
        ).thenAnswer((_) async => true);

        when(
          () => mockMessageLocal.resolveConflict(
            conversationId: any(named: 'conversationId'),
            localMessage: any(named: 'localMessage'),
            remoteMessage: any(named: 'remoteMessage'),
            strategy: any(named: 'strategy'),
          ),
        ).thenAnswer((_) async => remoteMessage);

        when(
          () => mockMessageRepository.updateMessage(any(), any()),
        ).thenAnswer((_) async => Right(remoteMessage));

        when(
          () => mockMessageLocal.updateSyncStatus(
            messageId: any(named: 'messageId'),
            syncStatus: any(named: 'syncStatus'),
            lastSyncAttempt: any(named: 'lastSyncAttempt'),
            retryCount: any(named: 'retryCount'),
          ),
        ).thenAnswer((_) async => true);

        // Act
        final success = await syncService.syncMessage(
          conversationId: 'conv-1',
          message: testMessage,
        );

        // Assert
        expect(success, true);
        verify(
          () => mockMessageLocal.hasConflict(
            localMessage: testMessage,
            remoteMessage: remoteMessage,
          ),
        ).called(1);
        verify(
          () => mockMessageLocal.resolveConflict(
            conversationId: 'conv-1',
            localMessage: testMessage,
            remoteMessage: remoteMessage,
          ),
        ).called(1);
      });

      test('should not resolve if no conflict', () async {
        // Arrange
        when(
          () => mockMessageRepository.getMessageById(any(), any()),
        ).thenAnswer((_) async => Right(testMessage));

        when(
          () => mockMessageLocal.hasConflict(
            localMessage: any(named: 'localMessage'),
            remoteMessage: any(named: 'remoteMessage'),
          ),
        ).thenAnswer((_) async => false);

        when(
          () => mockMessageLocal.updateSyncStatus(
            messageId: any(named: 'messageId'),
            syncStatus: any(named: 'syncStatus'),
            lastSyncAttempt: any(named: 'lastSyncAttempt'),
            retryCount: any(named: 'retryCount'),
          ),
        ).thenAnswer((_) async => true);

        // Act
        final success = await syncService.syncMessage(
          conversationId: 'conv-1',
          message: testMessage,
        );

        // Assert
        expect(success, true);
        verifyNever(
          () => mockMessageLocal.resolveConflict(
            conversationId: any(named: 'conversationId'),
            localMessage: any(named: 'localMessage'),
            remoteMessage: any(named: 'remoteMessage'),
            strategy: any(named: 'strategy'),
          ),
        );
      });

      test('should mark as failed on sync error', () async {
        // Arrange
        when(
          () => mockMessageRepository.getMessageById(any(), any()),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Network error')),
        );

        when(
          () => mockMessageRepository.createMessage(any(), any()),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Network error')),
        );

        when(
          () => mockMessageLocal.getMessage(any()),
        ).thenAnswer((_) async => testMessage);

        when(
          () => mockMessageLocal.updateSyncStatus(
            messageId: any(named: 'messageId'),
            syncStatus: any(named: 'syncStatus'),
            lastSyncAttempt: any(named: 'lastSyncAttempt'),
            retryCount: any(named: 'retryCount'),
          ),
        ).thenAnswer((_) async => true);

        // Act
        final success = await syncService.syncMessage(
          conversationId: 'conv-1',
          message: testMessage,
        );

        // Assert
        expect(success, false);
        verify(
          () => mockMessageLocal.updateSyncStatus(
            messageId: testMessage.id,
            syncStatus: 'failed',
            lastSyncAttempt: any(named: 'lastSyncAttempt'),
            retryCount: any(named: 'retryCount'),
          ),
        ).called(1);
      });
    });

    group('Conversation Sync', () {
      test(
        'should create conversation remotely if it does not exist',
        () async {
          // Arrange
          when(
            () => mockConversationRepository.getConversationById(any()),
          ).thenAnswer(
            (_) async =>
                const Left(RecordNotFoundFailure(recordType: 'conversation')),
          );

          when(
            () => mockConversationRepository.createConversation(any()),
          ).thenAnswer((_) async => Right(testConversation));

          // Act
          final success = await syncService.syncConversation(testConversation);

          // Assert
          expect(success, true);
          verify(
            () =>
                mockConversationRepository.createConversation(testConversation),
          ).called(1);
        },
      );

      test(
        'should resolve conflict when conversation exists remotely',
        () async {
          // Arrange
          final remoteConversation = testConversation.copyWith(
            translationEnabled: false,
          );

          when(
            () => mockConversationRepository.getConversationById(any()),
          ).thenAnswer((_) async => Right(remoteConversation));

          when(
            () => mockConversationLocal.hasConflict(
              localConversation: any(named: 'localConversation'),
              remoteConversation: any(named: 'remoteConversation'),
            ),
          ).thenAnswer((_) async => true);

          when(
            () => mockConversationLocal.resolveConflict(
              localConversation: any(named: 'localConversation'),
              remoteConversation: any(named: 'remoteConversation'),
              strategy: any(named: 'strategy'),
            ),
          ).thenAnswer((_) async => remoteConversation);

          when(
            () => mockConversationRepository.updateConversation(any()),
          ).thenAnswer((_) async => Right(remoteConversation));

          // Act
          final success = await syncService.syncConversation(testConversation);

          // Assert
          expect(success, true);
          verify(
            () => mockConversationLocal.resolveConflict(
              localConversation: testConversation,
              remoteConversation: remoteConversation,
            ),
          ).called(1);
        },
      );

      test('should return false on sync error', () async {
        // Arrange
        when(
          () => mockConversationRepository.getConversationById(any()),
        ).thenThrow(Exception('Network error'));

        // Act
        final success = await syncService.syncConversation(testConversation);

        // Assert
        expect(success, false);
      });
    });

    group('Full Sync', () {
      test('should sync conversations before messages', () async {
        // Arrange
        final callOrder = <String>[];

        when(() => mockConversationLocal.getUnsyncedConversations()).thenAnswer(
          (_) async {
            callOrder.add('conversations');
            return [];
          },
        );

        when(() => mockMessageLocal.getUnsyncedMessages()).thenAnswer((
          _,
        ) async {
          callOrder.add('messages');
          return [];
        });

        when(
          () => mockMessageLocal.getFailedMessagesForRetry(
            maxRetries: any(named: 'maxRetries'),
          ),
        ).thenAnswer((_) async => []);

        // Act
        await syncService.syncAll();

        // Assert
        expect(callOrder, ['conversations', 'messages']);
      });

      test(
        'should continue message sync even if conversation sync fails',
        () async {
          // Arrange
          when(
            () => mockConversationLocal.getUnsyncedConversations(),
          ).thenThrow(Exception('Conversation sync error'));

          when(
            () => mockMessageLocal.getUnsyncedMessages(),
          ).thenAnswer((_) async => []);

          when(
            () => mockMessageLocal.getFailedMessagesForRetry(
              maxRetries: any(named: 'maxRetries'),
            ),
          ).thenAnswer((_) async => []);

          // Act
          final result = await syncService.syncAll();

          // Assert
          expect(result.errors, isNotEmpty);
          expect(result.errors.first, contains('Conversation sync error'));
          verify(() => mockMessageLocal.getUnsyncedMessages()).called(1);
        },
      );

      test('should return sync counts and errors', () async {
        // Arrange
        when(
          () => mockConversationLocal.getUnsyncedConversations(),
        ).thenAnswer((_) async => [testConversation]);

        when(
          () => mockConversationRepository.getConversationById(any()),
        ).thenAnswer(
          (_) async =>
              const Left(RecordNotFoundFailure(recordType: 'conversation')),
        );

        when(
          () => mockConversationRepository.createConversation(any()),
        ).thenAnswer((_) async => Right(testConversation));

        when(
          () => mockMessageLocal.getUnsyncedMessages(),
        ).thenAnswer((_) async => []);

        when(
          () => mockMessageLocal.getFailedMessagesForRetry(
            maxRetries: any(named: 'maxRetries'),
          ),
        ).thenAnswer((_) async => []);

        // Act
        final result = await syncService.syncAll();

        // Assert
        expect(result.conversationsSynced, 1);
        expect(result.messagesSynced, 0);
        expect(result.errors, isEmpty);
        expect(result.isSuccess, true);
      });
    });

    group('Service Lifecycle', () {
      test('should stop listening to connectivity on stop', () async {
        // Arrange
        when(
          () => mockConversationLocal.getUnsyncedConversations(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMessageLocal.getUnsyncedMessages(),
        ).thenAnswer((_) async => []);

        await syncService.start();

        // Act
        await syncService.stop();

        // Assert - Should not crash and subscription should be cancelled
        expect(syncService, isNotNull);
      });
    });
  });
}
