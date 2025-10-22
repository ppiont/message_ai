import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('MessageDao - Basic CRUD', () {
    test('insertMessage inserts a message successfully', () async {
      final now = DateTime.now();
      final message = MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'Hello World',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      );

      await database.messageDao.insertMessage(message);

      final retrieved = await database.messageDao.getMessageById('msg-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.messageText, equals('Hello World'));
    });

    test('upsertMessage updates existing message', () async {
      final now = DateTime.now();
      final message = MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'Original',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      );

      await database.messageDao.insertMessage(message);

      // Upsert with same ID
      await database.messageDao.upsertMessage(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'Updated',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      final retrieved = await database.messageDao.getMessageById('msg-1');
      expect(retrieved!.messageText, equals('Updated'));
    });

    test('updateMessage updates specific message', () async {
      final now = DateTime.now();
      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'Original',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      final updated = await database.messageDao.updateMessage(
        'msg-1',
        const MessagesCompanion(messageText: Value('Modified')),
      );

      expect(updated, isTrue);
      final retrieved = await database.messageDao.getMessageById('msg-1');
      expect(retrieved!.messageText, equals('Modified'));
    });

    test('deleteMessage removes message', () async {
      final now = DateTime.now();
      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'To delete',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      final deleted = await database.messageDao.deleteMessage('msg-1');
      expect(deleted, equals(1));

      final retrieved = await database.messageDao.getMessageById('msg-1');
      expect(retrieved, isNull);
    });
  });

  group('MessageDao - Conversation Queries', () {
    test('getMessagesForConversation returns messages ordered by timestamp',
        () async {
      final now = DateTime.now();

      // Insert messages in random order
      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-2',
        conversationId: 'conv-1',
        messageText: 'Second',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now.add(const Duration(minutes: 1)),
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'First',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-3',
        conversationId: 'conv-1',
        messageText: 'Third',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now.add(const Duration(minutes: 2)),
      ));

      final messages = await database.messageDao.getMessagesForConversation('conv-1');

      expect(messages.length, equals(3));
      // Should be ordered newest first
      expect(messages[0].id, equals('msg-3'));
      expect(messages[1].id, equals('msg-2'));
      expect(messages[2].id, equals('msg-1'));
    });

    test('getMessagesForConversation supports pagination', () async {
      final now = DateTime.now();

      // Insert 10 messages
      for (var i = 0; i < 10; i++) {
        await database.messageDao.insertMessage(MessagesCompanion.insert(
          id: 'msg-$i',
          conversationId: 'conv-1',
          messageText: 'Message $i',
          senderId: 'user-1',
          senderName: 'Alice',
          timestamp: now.add(Duration(minutes: i)),
        ));
      }

      // Get first page
      final page1 = await database.messageDao.getMessagesForConversation(
        'conv-1',
        limit: 5,
      );
      expect(page1.length, equals(5));
      expect(page1.first.id, equals('msg-9')); // Newest

      // Get second page
      final page2 = await database.messageDao.getMessagesForConversation(
        'conv-1',
        limit: 5,
        offset: 5,
      );
      expect(page2.length, equals(5));
      expect(page2.first.id, equals('msg-4'));
    });

    test('watchMessagesForConversation emits updates', () async {
      final now = DateTime.now();

      // Insert a message first
      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'First',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      // Start watching after insert
      final stream = database.messageDao.watchMessagesForConversation('conv-1');

      // Should emit the existing message
      await expectLater(
        stream,
        emits(predicate<List<MessageEntity>>(
          (messages) => messages.length == 1 && messages.first.id == 'msg-1',
        )),
      );
    });

    test('getLastMessage returns most recent message', () async {
      final now = DateTime.now();

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'First',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-2',
        conversationId: 'conv-1',
        messageText: 'Latest',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now.add(const Duration(minutes: 5)),
      ));

      final lastMessage = await database.messageDao.getLastMessage('conv-1');
      expect(lastMessage, isNotNull);
      expect(lastMessage!.id, equals('msg-2'));
      expect(lastMessage.messageText, equals('Latest'));
    });

    test('countMessagesInConversation returns correct count', () async {
      final now = DateTime.now();

      for (var i = 0; i < 5; i++) {
        await database.messageDao.insertMessage(MessagesCompanion.insert(
          id: 'msg-$i',
          conversationId: 'conv-1',
          messageText: 'Message $i',
          senderId: 'user-1',
          senderName: 'Alice',
          timestamp: now.add(Duration(minutes: i)),
        ));
      }

      final count = await database.messageDao.countMessagesInConversation('conv-1');
      expect(count, equals(5));
    });

    test('deleteMessagesInConversation removes all messages', () async {
      final now = DateTime.now();

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'Message 1',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-2',
        conversationId: 'conv-1',
        messageText: 'Message 2',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      final deleted = await database.messageDao.deleteMessagesInConversation('conv-1');
      expect(deleted, equals(2));

      final count = await database.messageDao.countMessagesInConversation('conv-1');
      expect(count, equals(0));
    });
  });

  group('MessageDao - Sync Operations', () {
    test('getUnsyncedMessages returns pending and failed messages', () async {
      final now = DateTime.now();

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-pending',
        conversationId: 'conv-1',
        messageText: 'Pending',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        syncStatus: const Value('pending'),
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-failed',
        conversationId: 'conv-1',
        messageText: 'Failed',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        syncStatus: const Value('failed'),
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-synced',
        conversationId: 'conv-1',
        messageText: 'Synced',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        syncStatus: const Value('synced'),
      ));

      final unsynced = await database.messageDao.getUnsyncedMessages();
      expect(unsynced.length, equals(2));
      expect(unsynced.any((m) => m.id == 'msg-pending'), isTrue);
      expect(unsynced.any((m) => m.id == 'msg-failed'), isTrue);
    });

    test('updateSyncStatus updates message sync state', () async {
      final now = DateTime.now();

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'Test',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        syncStatus: const Value('pending'),
      ));

      final updated = await database.messageDao.updateSyncStatus(
        messageId: 'msg-1',
        syncStatus: 'synced',
        lastSyncAttempt: now,
        retryCount: 0,
      );

      expect(updated, isTrue);

      final message = await database.messageDao.getMessageById('msg-1');
      expect(message!.syncStatus, equals('synced'));
      // Drift stores timestamps without microseconds, so compare only to seconds
      expect(
        message.lastSyncAttempt!.millisecondsSinceEpoch ~/ 1000,
        equals(now.millisecondsSinceEpoch ~/ 1000),
      );
    });

    test('replaceTempId replaces temp message with real ID', () async {
      final now = DateTime.now();

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'temp-123',
        conversationId: 'conv-1',
        messageText: 'Optimistic message',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        tempId: const Value('temp-123'),
        syncStatus: const Value('pending'),
      ));

      final replaced = await database.messageDao.replaceTempId(
        tempId: 'temp-123',
        realId: 'real-456',
      );

      expect(replaced, isTrue);

      final tempMessage = await database.messageDao.getMessageById('temp-123');
      expect(tempMessage, isNull);

      final realMessage = await database.messageDao.getMessageById('real-456');
      expect(realMessage, isNotNull);
      expect(realMessage!.messageText, equals('Optimistic message'));
      expect(realMessage.syncStatus, equals('synced'));
    });

    test('getFailedMessagesForRetry filters by retry count', () async {
      final now = DateTime.now();

      // Failed with 1 retry
      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-retry-1',
        conversationId: 'conv-1',
        messageText: 'Retry 1',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        syncStatus: const Value('failed'),
        retryCount: const Value(1),
      ));

      // Failed with 5 retries (max exceeded)
      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-retry-5',
        conversationId: 'conv-1',
        messageText: 'Retry 5',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        syncStatus: const Value('failed'),
        retryCount: const Value(5),
      ));

      final retryable = await database.messageDao.getFailedMessagesForRetry(

      );

      expect(retryable.length, equals(1));
      expect(retryable.first.id, equals('msg-retry-1'));
    });
  });

  group('MessageDao - Batch Operations', () {
    test('insertMessages inserts multiple messages efficiently', () async {
      final now = DateTime.now();
      final messages = List.generate(
        10,
        (i) => MessagesCompanion.insert(
          id: 'msg-$i',
          conversationId: 'conv-1',
          messageText: 'Message $i',
          senderId: 'user-1',
          senderName: 'Alice',
          timestamp: now.add(Duration(minutes: i)),
        ),
      );

      await database.messageDao.insertMessages(messages);

      final count = await database.messageDao.countMessagesInConversation('conv-1');
      expect(count, equals(10));
    });

    test('batchUpdateStatus updates multiple message statuses', () async {
      final now = DateTime.now();

      for (var i = 0; i < 3; i++) {
        await database.messageDao.insertMessage(MessagesCompanion.insert(
          id: 'msg-$i',
          conversationId: 'conv-1',
          messageText: 'Message $i',
          senderId: 'user-1',
          senderName: 'Alice',
          timestamp: now,
          status: const Value('delivered'),
        ));
      }

      await database.messageDao.batchUpdateStatus(
        messageIds: ['msg-0', 'msg-1', 'msg-2'],
        status: 'read',
      );

      for (var i = 0; i < 3; i++) {
        final message = await database.messageDao.getMessageById('msg-$i');
        expect(message!.status, equals('read'));
      }
    });

    test('batchDeleteMessages removes multiple messages', () async {
      final now = DateTime.now();

      for (var i = 0; i < 5; i++) {
        await database.messageDao.insertMessage(MessagesCompanion.insert(
          id: 'msg-$i',
          conversationId: 'conv-1',
          messageText: 'Message $i',
          senderId: 'user-1',
          senderName: 'Alice',
          timestamp: now,
        ));
      }

      await database.messageDao.batchDeleteMessages(['msg-0', 'msg-2', 'msg-4']);

      final remaining = await database.messageDao.getMessagesForConversation('conv-1');
      expect(remaining.length, equals(2));
      expect(remaining.any((m) => m.id == 'msg-1'), isTrue);
      expect(remaining.any((m) => m.id == 'msg-3'), isTrue);
    });
  });

  group('MessageDao - Special Queries', () {
    test('searchMessages finds messages by text content', () async {
      final now = DateTime.now();

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'Hello world',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-2',
        conversationId: 'conv-1',
        messageText: 'Goodbye moon',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      final results = await database.messageDao.searchMessages('world');
      expect(results.length, equals(1));
      expect(results.first.id, equals('msg-1'));
    });

    test('getMessagesInRange returns messages within time range', () async {
      final now = DateTime.now();
      final startTime = now;
      final endTime = now.add(const Duration(hours: 2));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-before',
        conversationId: 'conv-1',
        messageText: 'Before',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now.subtract(const Duration(hours: 1)),
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-during',
        conversationId: 'conv-1',
        messageText: 'During',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now.add(const Duration(hours: 1)),
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-after',
        conversationId: 'conv-1',
        messageText: 'After',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now.add(const Duration(hours: 3)),
      ));

      final inRange = await database.messageDao.getMessagesInRange(
        conversationId: 'conv-1',
        startTime: startTime,
        endTime: endTime,
      );

      expect(inRange.length, equals(1));
      expect(inRange.first.id, equals('msg-during'));
    });

    test('getMessagesBySender filters by sender', () async {
      final now = DateTime.now();

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-alice-1',
        conversationId: 'conv-1',
        messageText: 'From Alice',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-bob-1',
        conversationId: 'conv-1',
        messageText: 'From Bob',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now,
      ));

      final aliceMessages = await database.messageDao.getMessagesBySender(
        conversationId: 'conv-1',
        senderId: 'user-1',
      );

      expect(aliceMessages.length, equals(1));
      expect(aliceMessages.first.senderId, equals('user-1'));
    });

    test('getReplies returns threaded messages', () async {
      final now = DateTime.now();

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-parent',
        conversationId: 'conv-1',
        messageText: 'Original message',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-reply-1',
        conversationId: 'conv-1',
        messageText: 'Reply 1',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now.add(const Duration(minutes: 1)),
        replyTo: const Value('msg-parent'),
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-reply-2',
        conversationId: 'conv-1',
        messageText: 'Reply 2',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now.add(const Duration(minutes: 2)),
        replyTo: const Value('msg-parent'),
      ));

      final replies = await database.messageDao.getReplies('msg-parent');
      expect(replies.length, equals(2));
      expect(replies.every((m) => m.replyTo == 'msg-parent'), isTrue);
    });

    test('countUnreadMessages counts messages for specific user', () async {
      final now = DateTime.now();

      // Messages from user-2 (unread for user-1)
      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'Unread 1',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now,
        status: const Value('delivered'),
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-2',
        conversationId: 'conv-1',
        messageText: 'Unread 2',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now,
        status: const Value('delivered'),
      ));

      // Message from user-1 (shouldn't count)
      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-3',
        conversationId: 'conv-1',
        messageText: 'Own message',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        status: const Value('delivered'),
      ));

      final unreadCount = await database.messageDao.countUnreadMessages(
        'conv-1',
        'user-1',
      );

      expect(unreadCount, equals(2));
    });
  });

  group('MessageDao - Message Status', () {
    test('updateMessageStatus updates message status', () async {
      final now = DateTime.now();

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'Test',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        status: const Value('sending'),
      ));

      final updated = await database.messageDao.updateMessageStatus('msg-1', 'sent');
      expect(updated, isTrue);

      final message = await database.messageDao.getMessageById('msg-1');
      expect(message!.status, equals('sent'));
    });

    test('getMessagesByStatus filters by sync status', () async {
      final now = DateTime.now();

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-pending',
        conversationId: 'conv-1',
        messageText: 'Pending',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        syncStatus: const Value('pending'),
      ));

      await database.messageDao.insertMessage(MessagesCompanion.insert(
        id: 'msg-synced',
        conversationId: 'conv-1',
        messageText: 'Synced',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        syncStatus: const Value('synced'),
      ));

      final pendingMessages = await database.messageDao.getMessagesByStatus('pending');
      expect(pendingMessages.length, equals(1));
      expect(pendingMessages.first.id, equals('msg-pending'));
    });
  });
}
