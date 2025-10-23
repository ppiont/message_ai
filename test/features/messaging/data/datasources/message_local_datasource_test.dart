/// Tests for message local data source
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/features/messaging/data/datasources/message_local_datasource.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';

void main() {
  late AppDatabase database;
  late MessageLocalDataSource dataSource;

  // Test data
  const conversationId = 'conv-1';
  final testMessage = Message(
    id: 'msg-1',
    text: 'Hello world',
    senderId: 'user-1',
    timestamp: DateTime(2024, 1, 1, 12),
    type: 'text',
    status: 'sent',
    metadata: MessageMetadata.defaultMetadata(),
  );

  setUp(() {
    database = AppDatabase.forTesting(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    dataSource = MessageLocalDataSourceImpl(messageDao: database.messageDao);
  });

  tearDown(() async {
    await database.close();
  });

  group('Basic CRUD Operations', () {
    group('createMessage', () {
      test('should successfully create a message', () async {
        // Act
        final result = await dataSource.createMessage(
          conversationId,
          testMessage,
        );

        // Assert
        expect(result, testMessage);

        // Verify message was saved to database
        final saved = await dataSource.getMessage(testMessage.id);
        expect(saved, isNotNull);
        expect(saved!.id, testMessage.id);
        expect(saved.text, testMessage.text);
      });

      test(
        'should throw RecordAlreadyExistsException for duplicate ID',
        () async {
          // Arrange - Create message first time
          await dataSource.createMessage(conversationId, testMessage);

          // Act & Assert - Try to create again with same ID
          expect(
            () => dataSource.createMessage(conversationId, testMessage),
            throwsA(isA<RecordAlreadyExistsException>()),
          );
        },
      );

      test('should create message with all fields correctly', () async {
        // Arrange
        final complexMessage = Message(
          id: 'msg-complex',
          text: 'Complex message',
          senderId: 'user-1',
          timestamp: DateTime(2024, 1, 1, 12),
          type: 'text',
          status: 'sent',
          detectedLanguage: 'en',
          translations: const {'es': 'Mensaje complejo'},
          replyTo: 'msg-0',
          metadata: const MessageMetadata(
            edited: true,
            deleted: false,
            priority: 'high',
            hasIdioms: false,
          ),
          aiAnalysis: const MessageAIAnalysis(
            priority: 'high',
            actionItems: ['Review this'],
            sentiment: 'positive',
          ),
        );

        // Act
        await dataSource.createMessage(conversationId, complexMessage);
        final saved = await dataSource.getMessage(complexMessage.id);

        // Assert
        expect(saved, isNotNull);
        expect(saved!.detectedLanguage, 'en');
        expect(saved.translations, isNotNull);
        expect(saved.replyTo, 'msg-0');
        expect(saved.metadata.edited, true);
        expect(saved.metadata.priority, 'high');
      });
    });

    group('getMessage', () {
      test('should retrieve existing message', () async {
        // Arrange
        await dataSource.createMessage(conversationId, testMessage);

        // Act
        final result = await dataSource.getMessage(testMessage.id);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, testMessage.id);
        expect(result.text, testMessage.text);
        expect(result.senderId, testMessage.senderId);
      });

      test('should return null for non-existent message', () async {
        // Act
        final result = await dataSource.getMessage('non-existent-id');

        // Assert
        expect(result, isNull);
      });
    });

    group('updateMessage', () {
      test('should successfully update message', () async {
        // Arrange
        await dataSource.createMessage(conversationId, testMessage);
        final updatedMessage = Message(
          id: testMessage.id,
          text: 'Updated text',
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: 'delivered',
          metadata: testMessage.metadata,
        );

        // Act
        await dataSource.updateMessage(conversationId, updatedMessage);
        final result = await dataSource.getMessage(testMessage.id);

        // Assert
        expect(result, isNotNull);
        expect(result!.text, 'Updated text');
        expect(result.status, 'delivered');
      });

      test(
        'should throw RecordNotFoundException for non-existent message',
        () async {
          // Arrange
          final nonExistentMessage = Message(
            id: 'non-existent',
            text: 'Text',
            senderId: 'user-1',
            timestamp: DateTime.now(),
            type: 'text',
            status: 'sent',
            metadata: MessageMetadata.defaultMetadata(),
          );

          // Act & Assert
          expect(
            () => dataSource.updateMessage(conversationId, nonExistentMessage),
            throwsA(isA<RecordNotFoundException>()),
          );
        },
      );
    });

    group('deleteMessage', () {
      test('should successfully delete existing message', () async {
        // Arrange
        await dataSource.createMessage(conversationId, testMessage);

        // Act
        final result = await dataSource.deleteMessage(testMessage.id);

        // Assert
        expect(result, true);

        // Verify message was deleted
        final deleted = await dataSource.getMessage(testMessage.id);
        expect(deleted, isNull);
      });

      test('should return false for non-existent message', () async {
        // Act
        final result = await dataSource.deleteMessage('non-existent-id');

        // Assert
        expect(result, false);
      });
    });

    group('deleteMessagesInConversation', () {
      test('should delete all messages in a conversation', () async {
        // Arrange
        final message1 = testMessage;
        final message2 = Message(
          id: 'msg-2',
          text: 'Second message',
          senderId: 'user-2',
          timestamp: DateTime(2024, 1, 1, 12, 1),
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );

        await dataSource.createMessage(conversationId, message1);
        await dataSource.createMessage(conversationId, message2);

        // Act
        final count = await dataSource.deleteMessagesInConversation(
          conversationId,
        );

        // Assert
        expect(count, 2);

        // Verify messages were deleted
        final msg1 = await dataSource.getMessage(message1.id);
        final msg2 = await dataSource.getMessage(message2.id);
        expect(msg1, isNull);
        expect(msg2, isNull);
      });

      test('should return 0 for conversation with no messages', () async {
        // Act
        final count = await dataSource.deleteMessagesInConversation(
          'empty-conv',
        );

        // Assert
        expect(count, 0);
      });
    });
  });

  group('Query Operations', () {
    group('getMessages', () {
      test('should retrieve messages for a conversation', () async {
        // Arrange
        final message1 = testMessage;
        final message2 = Message(
          id: 'msg-2',
          text: 'Second message',
          senderId: 'user-2',
          timestamp: DateTime(2024, 1, 1, 12, 1),
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );

        await dataSource.createMessage(conversationId, message1);
        await dataSource.createMessage(conversationId, message2);

        // Act
        final messages = await dataSource.getMessages(
          conversationId: conversationId,
        );

        // Assert
        expect(messages.length, 2);
      });

      test('should support pagination', () async {
        // Arrange - Create 5 messages
        for (var i = 1; i <= 5; i++) {
          final message = Message(
            id: 'msg-$i',
            text: 'Message $i',
            senderId: 'user-1',
            timestamp: DateTime(2024, 1, 1, 12, i),
            type: 'text',
            status: 'sent',
            metadata: MessageMetadata.defaultMetadata(),
          );
          await dataSource.createMessage(conversationId, message);
        }

        // Act - Get first 3 messages
        final page1 = await dataSource.getMessages(
          conversationId: conversationId,
          limit: 3,
        );

        // Get next 2 messages
        final page2 = await dataSource.getMessages(
          conversationId: conversationId,
          limit: 3,
          offset: 3,
        );

        // Assert
        expect(page1.length, 3);
        expect(page2.length, 2);
      });

      test(
        'should return empty list for conversation with no messages',
        () async {
          // Act
          final messages = await dataSource.getMessages(
            conversationId: 'empty-conv',
          );

          // Assert
          expect(messages, isEmpty);
        },
      );
    });

    group('watchMessages', () {
      test('should emit stream of messages', () async {
        // Arrange
        await dataSource.createMessage(conversationId, testMessage);

        // Act
        final stream = dataSource.watchMessages(conversationId: conversationId);

        // Assert
        await expectLater(
          stream.first,
          completion(
            predicate<List<Message>>(
              (messages) =>
                  messages.length == 1 && messages.first.id == testMessage.id,
            ),
          ),
        );
      });

      test('should emit updates when messages change', () async {
        // Arrange
        await dataSource.createMessage(conversationId, testMessage);

        final stream = dataSource.watchMessages(conversationId: conversationId);

        // Act & Assert
        final expectation = expectLater(
          stream.map((msgs) => msgs.length),
          emitsInOrder([1, 2]),
        );

        // Add another message
        await Future.delayed(const Duration(milliseconds: 100));
        final message2 = Message(
          id: 'msg-2',
          text: 'Second message',
          senderId: 'user-2',
          timestamp: DateTime(2024, 1, 1, 12, 1),
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );
        await dataSource.createMessage(conversationId, message2);

        await expectation;
      });
    });

    group('getLastMessage', () {
      test('should retrieve the most recent message', () async {
        // Arrange
        final message1 = testMessage;
        final message2 = Message(
          id: 'msg-2',
          text: 'Latest message',
          senderId: 'user-2',
          timestamp: DateTime(2024, 1, 1, 12, 5), // Most recent
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );

        await dataSource.createMessage(conversationId, message1);
        await dataSource.createMessage(conversationId, message2);

        // Act
        final lastMessage = await dataSource.getLastMessage(conversationId);

        // Assert
        expect(lastMessage, isNotNull);
        expect(lastMessage!.id, 'msg-2');
        expect(lastMessage.text, 'Latest message');
      });

      test('should return null for conversation with no messages', () async {
        // Act
        final lastMessage = await dataSource.getLastMessage('empty-conv');

        // Assert
        expect(lastMessage, isNull);
      });
    });

    group('searchMessages', () {
      test('should find messages by text content', () async {
        // Arrange
        final message1 = Message(
          id: 'msg-1',
          text: 'Hello world',
          senderId: 'user-1',
          timestamp: DateTime(2024, 1, 1, 12),
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );
        final message2 = Message(
          id: 'msg-2',
          text: 'Goodbye world',
          senderId: 'user-1',
          timestamp: DateTime(2024, 1, 1, 12, 1),
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );
        final message3 = Message(
          id: 'msg-3',
          text: 'Something else',
          senderId: 'user-1',
          timestamp: DateTime(2024, 1, 1, 12, 2),
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );

        await dataSource.createMessage(conversationId, message1);
        await dataSource.createMessage(conversationId, message2);
        await dataSource.createMessage(conversationId, message3);

        // Act
        final results = await dataSource.searchMessages('world');

        // Assert
        expect(results.length, 2);
        expect(results.any((m) => m.id == 'msg-1'), true);
        expect(results.any((m) => m.id == 'msg-2'), true);
      });

      test('should return empty list when no matches found', () async {
        // Arrange
        await dataSource.createMessage(conversationId, testMessage);

        // Act
        final results = await dataSource.searchMessages('nonexistent');

        // Assert
        expect(results, isEmpty);
      });
    });

    group('countMessages', () {
      test('should count all messages in a conversation', () async {
        // Arrange
        for (var i = 1; i <= 5; i++) {
          final message = Message(
            id: 'msg-$i',
            text: 'Message $i',
            senderId: 'user-1',
            timestamp: DateTime(2024, 1, 1, 12, i),
            type: 'text',
            status: 'sent',
            metadata: MessageMetadata.defaultMetadata(),
          );
          await dataSource.createMessage(conversationId, message);
        }

        // Act
        final count = await dataSource.countMessages(conversationId);

        // Assert
        expect(count, 5);
      });

      test('should return 0 for conversation with no messages', () async {
        // Act
        final count = await dataSource.countMessages('empty-conv');

        // Assert
        expect(count, 0);
      });
    });

    group('countUnreadMessages', () {
      test('should count unread messages for a user', () async {
        // Arrange - Create messages with different statuses
        final message1 = Message(
          id: 'msg-1',
          text: 'Delivered message',
          senderId: 'user-2', // Not current user
          timestamp: DateTime(2024, 1, 1, 12),
          type: 'text',
          status: 'delivered', // Unread
          metadata: MessageMetadata.defaultMetadata(),
        );
        final message2 = Message(
          id: 'msg-2',
          text: 'Read message',
          senderId: 'user-2',
          timestamp: DateTime(2024, 1, 1, 12, 1),
          type: 'text',
          status: 'read', // Read
          metadata: MessageMetadata.defaultMetadata(),
        );
        final message3 = Message(
          id: 'msg-3',
          text: 'My message',
          senderId: 'user-1', // Current user
          timestamp: DateTime(2024, 1, 1, 12, 2),
          type: 'text',
          status: 'delivered', // Shouldn't count
          metadata: MessageMetadata.defaultMetadata(),
        );

        await dataSource.createMessage(conversationId, message1);
        await dataSource.createMessage(conversationId, message2);
        await dataSource.createMessage(conversationId, message3);

        // Act
        final count = await dataSource.countUnreadMessages(
          conversationId: conversationId,
          userId: 'user-1',
        );

        // Assert
        expect(count, 1); // Only message1 should count
      });
    });
  });

  group('Sync Operations', () {
    group('updateSyncStatus', () {
      test('should update sync status successfully', () async {
        // Arrange
        await dataSource.createMessage(conversationId, testMessage);

        // Act
        final result = await dataSource.updateSyncStatus(
          messageId: testMessage.id,
          syncStatus: 'synced',
          lastSyncAttempt: DateTime.now(),
          retryCount: 0,
        );

        // Assert
        expect(result, true);
      });

      test('should return false for non-existent message', () async {
        // Act
        final result = await dataSource.updateSyncStatus(
          messageId: 'non-existent',
          syncStatus: 'synced',
        );

        // Assert
        expect(result, false);
      });
    });

    group('getUnsyncedMessages', () {
      test('should retrieve messages with pending or failed status', () async {
        // Arrange - All new messages start as 'pending'
        await dataSource.createMessage(conversationId, testMessage);

        // Act
        final unsynced = await dataSource.getUnsyncedMessages();

        // Assert
        expect(unsynced.length, 1);
        expect(unsynced.first.id, testMessage.id);
      });

      test('should not include synced messages', () async {
        // Arrange
        await dataSource.createMessage(conversationId, testMessage);
        await dataSource.updateSyncStatus(
          messageId: testMessage.id,
          syncStatus: 'synced',
        );

        // Act
        final unsynced = await dataSource.getUnsyncedMessages();

        // Assert
        expect(unsynced, isEmpty);
      });
    });
  });

  group('Batch Operations', () {
    group('insertMessages', () {
      test('should insert multiple messages at once', () async {
        // Arrange
        final messages = List.generate(
          5,
          (i) => Message(
            id: 'msg-$i',
            text: 'Message $i',
            senderId: 'user-1',
            timestamp: DateTime(2024, 1, 1, 12, i),
            type: 'text',
            status: 'sent',
            metadata: MessageMetadata.defaultMetadata(),
          ),
        );

        // Act
        await dataSource.insertMessages(conversationId, messages);

        // Assert
        final count = await dataSource.countMessages(conversationId);
        expect(count, 5);
      });
    });

    group('batchUpdateStatus', () {
      test('should update status for multiple messages', () async {
        // Arrange
        final message1 = testMessage;
        final message2 = Message(
          id: 'msg-2',
          text: 'Second message',
          senderId: 'user-2',
          timestamp: DateTime(2024, 1, 1, 12, 1),
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );

        await dataSource.createMessage(conversationId, message1);
        await dataSource.createMessage(conversationId, message2);

        // Act
        await dataSource.batchUpdateStatus(
          messageIds: [message1.id, message2.id],
          status: 'read',
        );

        // Assert
        final msg1 = await dataSource.getMessage(message1.id);
        final msg2 = await dataSource.getMessage(message2.id);
        expect(msg1!.status, 'read');
        expect(msg2!.status, 'read');
      });
    });

    group('batchDeleteMessages', () {
      test('should delete multiple messages at once', () async {
        // Arrange
        final message1 = testMessage;
        final message2 = Message(
          id: 'msg-2',
          text: 'Second message',
          senderId: 'user-2',
          timestamp: DateTime(2024, 1, 1, 12, 1),
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );

        await dataSource.createMessage(conversationId, message1);
        await dataSource.createMessage(conversationId, message2);

        // Act
        await dataSource.batchDeleteMessages([message1.id, message2.id]);

        // Assert
        final msg1 = await dataSource.getMessage(message1.id);
        final msg2 = await dataSource.getMessage(message2.id);
        expect(msg1, isNull);
        expect(msg2, isNull);
      });
    });
  });

  group('Special Operations', () {
    group('updateMessageStatus', () {
      test('should update message status', () async {
        // Arrange
        await dataSource.createMessage(conversationId, testMessage);

        // Act
        final result = await dataSource.updateMessageStatus(
          testMessage.id,
          'read',
        );

        // Assert
        expect(result, true);
        final updated = await dataSource.getMessage(testMessage.id);
        expect(updated!.status, 'read');
      });
    });

    group('getMessagesInRange', () {
      test('should retrieve messages in a time range', () async {
        // Arrange
        for (var i = 1; i <= 5; i++) {
          final message = Message(
            id: 'msg-$i',
            text: 'Message $i',
            senderId: 'user-1',
            timestamp: DateTime(2024, 1, i, 12),
            type: 'text',
            status: 'sent',
            metadata: MessageMetadata.defaultMetadata(),
          );
          await dataSource.createMessage(conversationId, message);
        }

        // Act - Get messages from Jan 2-4
        final messages = await dataSource.getMessagesInRange(
          conversationId: conversationId,
          startTime: DateTime(2024, 1, 2),
          endTime: DateTime(2024, 1, 4, 23, 59),
        );

        // Assert
        expect(messages.length, 3); // Days 2, 3, 4
      });
    });

    group('getMessagesBySender', () {
      test('should retrieve messages from a specific sender', () async {
        // Arrange
        final message1 = Message(
          id: 'msg-1',
          text: 'From user 1',
          senderId: 'user-1',
          timestamp: DateTime(2024, 1, 1, 12),
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );
        final message2 = Message(
          id: 'msg-2',
          text: 'From user 2',
          senderId: 'user-2',
          timestamp: DateTime(2024, 1, 1, 12, 1),
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );
        final message3 = Message(
          id: 'msg-3',
          text: 'From user 1 again',
          senderId: 'user-1',
          timestamp: DateTime(2024, 1, 1, 12, 2),
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );

        await dataSource.createMessage(conversationId, message1);
        await dataSource.createMessage(conversationId, message2);
        await dataSource.createMessage(conversationId, message3);

        // Act
        final messages = await dataSource.getMessagesBySender(
          conversationId: conversationId,
          senderId: 'user-1',
        );

        // Assert
        expect(messages.length, 2);
        expect(messages.every((m) => m.senderId == 'user-1'), true);
      });
    });

    group('getReplies', () {
      test('should retrieve replies to a specific message', () async {
        // Arrange
        final parentMessage = testMessage;
        final reply1 = Message(
          id: 'reply-1',
          text: 'Reply 1',
          senderId: 'user-2',
          timestamp: DateTime(2024, 1, 1, 12, 1),
          type: 'text',
          status: 'sent',
          replyTo: parentMessage.id,
          metadata: MessageMetadata.defaultMetadata(),
        );
        final reply2 = Message(
          id: 'reply-2',
          text: 'Reply 2',
          senderId: 'user-3',
          timestamp: DateTime(2024, 1, 1, 12, 2),
          type: 'text',
          status: 'sent',
          replyTo: parentMessage.id,
          metadata: MessageMetadata.defaultMetadata(),
        );

        await dataSource.createMessage(conversationId, parentMessage);
        await dataSource.createMessage(conversationId, reply1);
        await dataSource.createMessage(conversationId, reply2);

        // Act
        final replies = await dataSource.getReplies(parentMessage.id);

        // Assert
        expect(replies.length, 2);
        expect(replies.every((r) => r.replyTo == parentMessage.id), true);
      });
    });

    group('watchReplies', () {
      test('should watch replies to a message', () async {
        // Arrange
        final parentMessage = testMessage;
        await dataSource.createMessage(conversationId, parentMessage);

        final stream = dataSource.watchReplies(parentMessage.id);

        // Act & Assert
        final expectation = expectLater(
          stream.map((replies) => replies.length),
          emitsInOrder([0, 1]),
        );

        // Add a reply
        await Future.delayed(const Duration(milliseconds: 100));
        final reply = Message(
          id: 'reply-1',
          text: 'Reply',
          senderId: 'user-2',
          timestamp: DateTime(2024, 1, 1, 12, 1),
          type: 'text',
          status: 'sent',
          replyTo: parentMessage.id,
          metadata: MessageMetadata.defaultMetadata(),
        );
        await dataSource.createMessage(conversationId, reply);

        await expectation;
      });
    });
  });

  group('Conflict Resolution', () {
    group('hasConflict', () {
      test('should detect no conflict for identical messages', () async {
        // Arrange
        final localMessage = testMessage;
        final remoteMessage = testMessage;

        // Act
        final hasConflict = await dataSource.hasConflict(
          localMessage: localMessage,
          remoteMessage: remoteMessage,
        );

        // Assert
        expect(hasConflict, false);
      });

      test('should detect conflict when text differs', () async {
        // Arrange
        final localMessage = testMessage;
        final remoteMessage = Message(
          id: testMessage.id,
          text: 'Different text',
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: testMessage.status,
          metadata: testMessage.metadata,
        );

        // Act
        final hasConflict = await dataSource.hasConflict(
          localMessage: localMessage,
          remoteMessage: remoteMessage,
        );

        // Assert
        expect(hasConflict, true);
      });

      test('should not detect conflict for status progression', () async {
        // Arrange
        final localMessage = Message(
          id: testMessage.id,
          text: testMessage.text,
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: 'sent',
          metadata: testMessage.metadata,
        );
        final remoteMessage = Message(
          id: testMessage.id,
          text: testMessage.text,
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: 'delivered',
          metadata: testMessage.metadata,
        );

        // Act
        final hasConflict = await dataSource.hasConflict(
          localMessage: localMessage,
          remoteMessage: remoteMessage,
        );

        // Assert
        expect(hasConflict, false); // Progression is not a conflict
      });

      test(
        'should detect conflict when timestamp differs significantly',
        () async {
          // Arrange
          final localMessage = testMessage;
          final remoteMessage = Message(
            id: testMessage.id,
            text: testMessage.text,
            senderId: testMessage.senderId,
            timestamp: testMessage.timestamp.add(const Duration(minutes: 5)),
            type: testMessage.type,
            status: testMessage.status,
            metadata: testMessage.metadata,
          );

          // Act
          final hasConflict = await dataSource.hasConflict(
            localMessage: localMessage,
            remoteMessage: remoteMessage,
          );

          // Assert
          expect(hasConflict, true);
        },
      );

      test('should detect conflict when metadata differs', () async {
        // Arrange
        final localMessage = testMessage;
        final remoteMessage = Message(
          id: testMessage.id,
          text: testMessage.text,
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: testMessage.status,
          metadata: const MessageMetadata(
            edited: true, // Different from local
            deleted: false,
            priority: 'medium',
            hasIdioms: false,
          ),
        );

        // Act
        final hasConflict = await dataSource.hasConflict(
          localMessage: localMessage,
          remoteMessage: remoteMessage,
        );

        // Assert
        expect(hasConflict, true);
      });
    });

    group('resolveConflict', () {
      test('should resolve with server-wins strategy', () async {
        // Arrange
        final localMessage = testMessage;
        final remoteMessage = Message(
          id: testMessage.id,
          text: 'Remote text',
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: 'delivered',
          metadata: testMessage.metadata,
        );

        await dataSource.createMessage(conversationId, localMessage);

        // Act
        final resolved = await dataSource.resolveConflict(
          conversationId: conversationId,
          localMessage: localMessage,
          remoteMessage: remoteMessage,
        );

        // Assert
        expect(resolved.text, 'Remote text');
        expect(resolved.status, 'delivered');

        // Verify database was updated
        final updated = await dataSource.getMessage(testMessage.id);
        expect(updated!.text, 'Remote text');
      });

      test('should resolve with client-wins strategy', () async {
        // Arrange
        final localMessage = Message(
          id: testMessage.id,
          text: 'Local text',
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: 'sent',
          metadata: testMessage.metadata,
        );
        final remoteMessage = Message(
          id: testMessage.id,
          text: 'Remote text',
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: 'delivered',
          metadata: testMessage.metadata,
        );

        await dataSource.createMessage(conversationId, localMessage);

        // Act
        final resolved = await dataSource.resolveConflict(
          conversationId: conversationId,
          localMessage: localMessage,
          remoteMessage: remoteMessage,
          strategy: 'client-wins',
        );

        // Assert
        expect(resolved.text, 'Local text');
        expect(resolved.status, 'sent');
      });

      test('should resolve with merge strategy', () async {
        // Arrange
        final localMessage = Message(
          id: testMessage.id,
          text: 'Original text',
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: 'read', // Local is further along
          translations: const {'es': 'Texto local'},
          metadata: testMessage.metadata,
        );
        final remoteMessage = Message(
          id: testMessage.id,
          text: 'Original text',
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: 'delivered',
          translations: const {'fr': 'Texte distant'},
          metadata: testMessage.metadata,
        );

        await dataSource.createMessage(conversationId, localMessage);

        // Act
        final resolved = await dataSource.resolveConflict(
          conversationId: conversationId,
          localMessage: localMessage,
          remoteMessage: remoteMessage,
          strategy: 'merge',
        );

        // Assert
        expect(resolved.status, 'read'); // Most advanced status
        expect(resolved.translations, isNotNull);
        expect(resolved.translations!.length, 2); // Both translations merged
        expect(resolved.translations!['es'], 'Texto local');
        expect(resolved.translations!['fr'], 'Texte distant');
      });

      test('should throw ValidationException for invalid strategy', () async {
        // Arrange
        await dataSource.createMessage(conversationId, testMessage);

        // Act & Assert
        expect(
          () => dataSource.resolveConflict(
            conversationId: conversationId,
            localMessage: testMessage,
            remoteMessage: testMessage,
            strategy: 'invalid-strategy',
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('mergeMessages', () {
      test('should merge translations from both versions', () async {
        // Arrange
        final localMessage = Message(
          id: testMessage.id,
          text: testMessage.text,
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: testMessage.status,
          translations: const {'es': 'Hola mundo', 'fr': 'Bonjour monde'},
          metadata: testMessage.metadata,
        );
        final remoteMessage = Message(
          id: testMessage.id,
          text: testMessage.text,
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: testMessage.status,
          translations: const {'de': 'Hallo Welt'},
          metadata: testMessage.metadata,
        );

        // Act
        final merged = dataSource.mergeMessages(
          localMessage: localMessage,
          remoteMessage: remoteMessage,
        );

        // Assert
        expect(merged.translations, isNotNull);
        expect(merged.translations!.length, 3);
        expect(merged.translations!['es'], 'Hola mundo');
        expect(merged.translations!['fr'], 'Bonjour monde');
        expect(merged.translations!['de'], 'Hallo Welt');
      });

      test('should use most advanced status', () async {
        // Arrange
        final localMessage = Message(
          id: testMessage.id,
          text: testMessage.text,
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: 'read',
          metadata: testMessage.metadata,
        );
        final remoteMessage = Message(
          id: testMessage.id,
          text: testMessage.text,
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: 'sent',
          metadata: testMessage.metadata,
        );

        // Act
        final merged = dataSource.mergeMessages(
          localMessage: localMessage,
          remoteMessage: remoteMessage,
        );

        // Assert
        expect(merged.status, 'read');
      });

      test('should merge AI analysis action items', () async {
        // Arrange
        final localMessage = Message(
          id: testMessage.id,
          text: testMessage.text,
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: testMessage.status,
          metadata: testMessage.metadata,
          aiAnalysis: const MessageAIAnalysis(
            priority: 'medium',
            actionItems: ['Local action 1', 'Local action 2'],
            sentiment: 'neutral',
          ),
        );
        final remoteMessage = Message(
          id: testMessage.id,
          text: testMessage.text,
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: testMessage.status,
          metadata: testMessage.metadata,
          aiAnalysis: const MessageAIAnalysis(
            priority: 'high',
            actionItems: ['Remote action 1'],
            sentiment: 'positive',
          ),
        );

        // Act
        final merged = dataSource.mergeMessages(
          localMessage: localMessage,
          remoteMessage: remoteMessage,
        );

        // Assert
        expect(merged.aiAnalysis, isNotNull);
        expect(merged.aiAnalysis!.priority, 'high'); // Remote wins
        expect(merged.aiAnalysis!.sentiment, 'positive'); // Remote wins
        expect(merged.aiAnalysis!.actionItems.length, 3); // All merged
      });

      test('should merge metadata with OR logic for booleans', () async {
        // Arrange
        final localMessage = Message(
          id: testMessage.id,
          text: testMessage.text,
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: testMessage.status,
          metadata: const MessageMetadata(
            edited: true,
            deleted: false,
            priority: 'low',
            hasIdioms: false,
          ),
        );
        final remoteMessage = Message(
          id: testMessage.id,
          text: testMessage.text,
          senderId: testMessage.senderId,
          timestamp: testMessage.timestamp,
          type: testMessage.type,
          status: testMessage.status,
          metadata: const MessageMetadata(
            edited: false,
            deleted: false,
            priority: 'high',
            hasIdioms: true,
          ),
        );

        // Act
        final merged = dataSource.mergeMessages(
          localMessage: localMessage,
          remoteMessage: remoteMessage,
        );

        // Assert
        expect(merged.metadata.edited, true); // OR of true and false
        expect(merged.metadata.deleted, false); // OR of false and false
        expect(merged.metadata.priority, 'high'); // Higher priority wins
        expect(merged.metadata.hasIdioms, true); // OR of false and true
      });
    });
  });
}
