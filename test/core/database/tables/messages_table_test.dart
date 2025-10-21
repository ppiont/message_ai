import 'package:drift/drift.dart' hide isNull, isNotNull;
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

  group('Messages Table Schema', () {
    test('table is created with correct name', () {
      expect(database.messages.actualTableName, equals('messages'));
    });

    test('table has correct primary key', () {
      final primaryKey = database.messages.$primaryKey;
      expect(primaryKey.length, equals(1));
      expect(primaryKey.first.$name, equals('id'));
    });

    test('table has all required columns', () {
      final columns = database.messages.$columns;
      final columnNames = columns.map((c) => c.$name).toList();

      expect(columnNames, containsAll([
        'id',
        'conversation_id',
        'message_text',
        'sender_id',
        'sender_name',
        'timestamp',
        'message_type',
        'status',
        'detected_language',
        'translations',
        'reply_to',
        'metadata',
        'ai_analysis',
        'embedding',
        'sync_status',
        'retry_count',
        'temp_id',
        'last_sync_attempt',
      ]));
    });

    test('id column is non-nullable text', () {
      final idColumn = database.messages.$columns
          .firstWhere((c) => c.$name == 'id') as GeneratedColumn<String>;
      expect(idColumn.$nullable, isFalse);
      expect(idColumn.type, equals(DriftSqlType.string));
    });

    test('message_type has default value', () {
      final typeColumn = database.messages.$columns
          .firstWhere((c) => c.$name == 'message_type') as GeneratedColumn<String>;
      expect(typeColumn.defaultValue, isNotNull);
    });

    test('status has default value of sending', () {
      final statusColumn = database.messages.$columns
          .firstWhere((c) => c.$name == 'status') as GeneratedColumn<String>;
      expect(statusColumn.defaultValue, isNotNull);
    });

    test('sync_status has default value', () {
      final syncColumn = database.messages.$columns
          .firstWhere((c) => c.$name == 'sync_status') as GeneratedColumn<String>;
      expect(syncColumn.defaultValue, isNotNull);
    });

    test('retry_count has default value of 0', () {
      final retryColumn = database.messages.$columns
          .firstWhere((c) => c.$name == 'retry_count') as GeneratedColumn<int>;
      expect(retryColumn.defaultValue, isNotNull);
    });
  });

  group('Messages Table CRUD Operations', () {
    test('can insert a basic text message', () async {
      final now = DateTime.now();
      final message = MessagesCompanion.insert(
        id: 'msg-123',
        conversationId: 'conv-1',
        messageText: 'Hello World',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      );

      await database.into(database.messages).insert(message);

      final allMessages = await database.select(database.messages).get();
      expect(allMessages.length, equals(1));
      expect(allMessages.first.id, equals('msg-123'));
      expect(allMessages.first.messageText, equals('Hello World'));
    });

    test('can insert a message with all fields', () async {
      final now = DateTime.now();
      final message = MessagesCompanion.insert(
        id: 'msg-full',
        conversationId: 'conv-1',
        messageText: 'Comprehensive message',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        messageType: const Value('text'),
        status: const Value('sent'),
        detectedLanguage: const Value('en'),
        translations: const Value('{"es":"Mensaje completo"}'),
        replyTo: const Value('msg-parent'),
        metadata: const Value('{"edited":false}'),
        aiAnalysis: const Value('{"sentiment":"positive"}'),
        embedding: const Value('[0.1,0.2,0.3]'),
        syncStatus: const Value('synced'),
        retryCount: const Value(0),
        tempId: const Value('temp-123'),
        lastSyncAttempt: Value(now),
      );

      await database.into(database.messages).insert(message);

      final result = await (database.select(database.messages)
            ..where((tbl) => tbl.id.equals('msg-full')))
          .getSingle();

      expect(result.messageType, equals('text'));
      expect(result.status, equals('sent'));
      expect(result.detectedLanguage, equals('en'));
      expect(result.translations, equals('{"es":"Mensaje completo"}'));
      expect(result.syncStatus, equals('synced'));
    });

    test('can read a specific message by id', () async {
      final now = DateTime.now();

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-1',
        conversationId: 'conv-1',
        messageText: 'First message',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-2',
        conversationId: 'conv-1',
        messageText: 'Second message',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now,
      ));

      final result = await (database.select(database.messages)
            ..where((tbl) => tbl.id.equals('msg-2')))
          .getSingle();

      expect(result.id, equals('msg-2'));
      expect(result.messageText, equals('Second message'));
      expect(result.senderName, equals('Bob'));
    });

    test('can update a message status', () async {
      final now = DateTime.now();

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-update',
        conversationId: 'conv-1',
        messageText: 'Test message',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        status: const Value('sending'),
      ));

      // Update status to sent
      await (database.update(database.messages)
            ..where((tbl) => tbl.id.equals('msg-update')))
          .write(const MessagesCompanion(
        status: Value('sent'),
      ));

      final updated = await (database.select(database.messages)
            ..where((tbl) => tbl.id.equals('msg-update')))
          .getSingle();

      expect(updated.status, equals('sent'));
    });

    test('can update sync status and retry count', () async {
      final now = DateTime.now();

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-sync',
        conversationId: 'conv-1',
        messageText: 'Sync test',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      // Simulate failed sync
      await (database.update(database.messages)
            ..where((tbl) => tbl.id.equals('msg-sync')))
          .write(const MessagesCompanion(
        syncStatus: Value('failed'),
        retryCount: Value(1),
      ));

      final updated = await (database.select(database.messages)
            ..where((tbl) => tbl.id.equals('msg-sync')))
          .getSingle();

      expect(updated.syncStatus, equals('failed'));
      expect(updated.retryCount, equals(1));
    });

    test('can delete a message', () async {
      final now = DateTime.now();

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-delete',
        conversationId: 'conv-1',
        messageText: 'To delete',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      var allMessages = await database.select(database.messages).get();
      expect(allMessages.length, equals(1));

      await (database.delete(database.messages)
            ..where((tbl) => tbl.id.equals('msg-delete')))
          .go();

      allMessages = await database.select(database.messages).get();
      expect(allMessages.length, equals(0));
    });

    test('primary key constraint prevents duplicate ids', () async {
      final now = DateTime.now();
      final message1 = MessagesCompanion.insert(
        id: 'duplicate-id',
        conversationId: 'conv-1',
        messageText: 'First',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      );
      final message2 = MessagesCompanion.insert(
        id: 'duplicate-id',
        conversationId: 'conv-1',
        messageText: 'Second',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now,
      );

      await database.into(database.messages).insert(message1);

      expect(
        () => database.into(database.messages).insert(message2),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('Messages Table Queries', () {
    test('can query messages by conversation_id', () async {
      final now = DateTime.now();

      // Messages for conv-1
      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-conv1-1',
        conversationId: 'conv-1',
        messageText: 'Message 1',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-conv1-2',
        conversationId: 'conv-1',
        messageText: 'Message 2',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now,
      ));

      // Message for conv-2
      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-conv2-1',
        conversationId: 'conv-2',
        messageText: 'Different conversation',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      final conv1Messages = await (database.select(database.messages)
            ..where((tbl) => tbl.conversationId.equals('conv-1')))
          .get();

      expect(conv1Messages.length, equals(2));
      expect(conv1Messages.every((m) => m.conversationId == 'conv-1'), isTrue);
    });

    test('can query messages ordered by timestamp', () async {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(hours: 1));
      final latest = now.add(const Duration(hours: 1));

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-old',
        conversationId: 'conv-1',
        messageText: 'Old message',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: earlier,
      ));

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-newest',
        conversationId: 'conv-1',
        messageText: 'Newest message',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: latest,
      ));

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-middle',
        conversationId: 'conv-1',
        messageText: 'Middle message',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      final sortedMessages = await (database.select(database.messages)
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
          .get();

      expect(sortedMessages.length, equals(3));
      expect(sortedMessages[0].id, equals('msg-old'));
      expect(sortedMessages[1].id, equals('msg-middle'));
      expect(sortedMessages[2].id, equals('msg-newest'));
    });

    test('can query messages by status', () async {
      final now = DateTime.now();

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-sending-1',
        conversationId: 'conv-1',
        messageText: 'Sending 1',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        status: const Value('sending'),
      ));

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-sending-2',
        conversationId: 'conv-1',
        messageText: 'Sending 2',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        status: const Value('sending'),
      ));

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-sent',
        conversationId: 'conv-1',
        messageText: 'Sent',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now,
        status: const Value('sent'),
      ));

      final sendingMessages = await (database.select(database.messages)
            ..where((tbl) => tbl.status.equals('sending')))
          .get();

      expect(sendingMessages.length, equals(2));
      expect(sendingMessages.every((m) => m.status == 'sending'), isTrue);
    });

    test('can query messages by sync_status', () async {
      final now = DateTime.now();

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-pending-1',
        conversationId: 'conv-1',
        messageText: 'Pending 1',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        syncStatus: const Value('pending'),
      ));

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-pending-2',
        conversationId: 'conv-1',
        messageText: 'Pending 2',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        syncStatus: const Value('pending'),
      ));

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-synced',
        conversationId: 'conv-1',
        messageText: 'Synced',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now,
        syncStatus: const Value('synced'),
      ));

      final pendingMessages = await (database.select(database.messages)
            ..where((tbl) => tbl.syncStatus.equals('pending')))
          .get();

      expect(pendingMessages.length, equals(2));
      expect(pendingMessages.every((m) => m.syncStatus == 'pending'), isTrue);
    });

    test('can query messages with failed sync and retry count', () async {
      final now = DateTime.now();

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-failed-1',
        conversationId: 'conv-1',
        messageText: 'Failed once',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        syncStatus: const Value('failed'),
        retryCount: const Value(1),
      ));

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-failed-2',
        conversationId: 'conv-1',
        messageText: 'Failed twice',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        syncStatus: const Value('failed'),
        retryCount: const Value(2),
      ));

      final failedMessages = await (database.select(database.messages)
            ..where((tbl) => tbl.syncStatus.equals('failed')))
          .get();

      expect(failedMessages.length, equals(2));
      expect(failedMessages[0].retryCount, equals(1));
      expect(failedMessages[1].retryCount, equals(2));
    });

    test('can query messages with reply_to (threaded messages)', () async {
      final now = DateTime.now();

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-parent',
        conversationId: 'conv-1',
        messageText: 'Original message',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      ));

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-reply',
        conversationId: 'conv-1',
        messageText: 'Reply message',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now,
        replyTo: const Value('msg-parent'),
      ));

      final replies = await (database.select(database.messages)
            ..where((tbl) => tbl.replyTo.equals('msg-parent')))
          .get();

      expect(replies.length, equals(1));
      expect(replies.first.id, equals('msg-reply'));
      expect(replies.first.replyTo, equals('msg-parent'));
    });
  });

  group('Messages Table Data Integrity', () {
    test('null values are properly handled for optional fields', () async {
      final now = DateTime.now();
      final message = MessagesCompanion.insert(
        id: 'minimal-msg',
        conversationId: 'conv-1',
        messageText: 'Minimal',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      );

      await database.into(database.messages).insert(message);

      final result = await (database.select(database.messages)
            ..where((tbl) => tbl.id.equals('minimal-msg')))
          .getSingle();

      expect(result.detectedLanguage, isNull);
      expect(result.translations, isNull);
      expect(result.replyTo, isNull);
      expect(result.metadata, isNull);
      expect(result.aiAnalysis, isNull);
      expect(result.embedding, isNull);
      expect(result.tempId, isNull);
      expect(result.lastSyncAttempt, isNull);
    });

    test('default values are applied correctly', () async {
      final now = DateTime.now();
      final message = MessagesCompanion.insert(
        id: 'default-msg',
        conversationId: 'conv-1',
        messageText: 'Default values',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
      );

      await database.into(database.messages).insert(message);

      final result = await (database.select(database.messages)
            ..where((tbl) => tbl.id.equals('default-msg')))
          .getSingle();

      expect(result.messageType, equals('text')); // Default value
      expect(result.status, equals('sending')); // Default value
      expect(result.syncStatus, equals('pending')); // Default value
      expect(result.retryCount, equals(0)); // Default value
    });

    test('JSON fields can store complex data', () async {
      final now = DateTime.now();
      final translations = '{"es":"Hola","fr":"Bonjour","de":"Hallo"}';
      final metadata = '{"edited":true,"editedAt":"2024-01-01T00:00:00Z"}';
      final aiAnalysis = '{"sentiment":"positive","entities":["greeting"]}';
      final embedding = '[0.1,0.2,0.3,0.4,0.5]';

      final message = MessagesCompanion.insert(
        id: 'json-msg',
        conversationId: 'conv-1',
        messageText: 'Hello',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        translations: Value(translations),
        metadata: Value(metadata),
        aiAnalysis: Value(aiAnalysis),
        embedding: Value(embedding),
      );

      await database.into(database.messages).insert(message);

      final result = await (database.select(database.messages)
            ..where((tbl) => tbl.id.equals('json-msg')))
          .getSingle();

      expect(result.translations, equals(translations));
      expect(result.metadata, equals(metadata));
      expect(result.aiAnalysis, equals(aiAnalysis));
      expect(result.embedding, equals(embedding));
    });

    test('temp_id is used for optimistic updates', () async {
      final now = DateTime.now();
      final tempMessage = MessagesCompanion.insert(
        id: 'temp-123',
        conversationId: 'conv-1',
        messageText: 'Optimistic message',
        senderId: 'user-1',
        senderName: 'Alice',
        timestamp: now,
        tempId: const Value('temp-123'),
        syncStatus: const Value('pending'),
      );

      await database.into(database.messages).insert(tempMessage);

      // Verify temp message exists
      final tempExists = await (database.select(database.messages)
            ..where((tbl) => tbl.tempId.equals('temp-123')))
          .getSingleOrNull();
      expect(tempExists, isNotNull);
      expect(tempExists?.id, equals('temp-123'));

      // Simulate successful sync - delete temp and insert with real ID
      // In real implementation, we would:
      // 1. Get the temp message
      // 2. Delete it
      // 3. Insert with real server ID
      await (database.delete(database.messages)
            ..where((tbl) => tbl.id.equals('temp-123')))
          .go();

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'real-msg-id',
        conversationId: tempExists!.conversationId,
        messageText: tempExists.messageText,
        senderId: tempExists.senderId,
        senderName: tempExists.senderName,
        timestamp: tempExists.timestamp,
        syncStatus: const Value('synced'),
      ));

      // Verify temp message is gone
      final tempGone = await (database.select(database.messages)
            ..where((tbl) => tbl.tempId.equals('temp-123')))
          .getSingleOrNull();
      expect(tempGone, isNull);

      // Verify real message exists
      final realMessage = await (database.select(database.messages)
            ..where((tbl) => tbl.id.equals('real-msg-id')))
          .getSingleOrNull();
      expect(realMessage, isNotNull);
      expect(realMessage?.syncStatus, equals('synced'));
    });
  });

  group('Messages Table Complex Queries', () {
    test('can query messages for a conversation with pagination', () async {
      final now = DateTime.now();

      // Insert 10 messages
      for (int i = 0; i < 10; i++) {
        await database.into(database.messages).insert(MessagesCompanion.insert(
          id: 'msg-$i',
          conversationId: 'conv-1',
          messageText: 'Message $i',
          senderId: 'user-1',
          senderName: 'Alice',
          timestamp: now.add(Duration(minutes: i)),
        ));
      }

      // Get first 5 messages (page 1)
      final page1 = await (database.select(database.messages)
            ..where((tbl) => tbl.conversationId.equals('conv-1'))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)])
            ..limit(5))
          .get();

      expect(page1.length, equals(5));
      expect(page1.first.id, equals('msg-0'));

      // Get next 5 messages (page 2)
      final page2 = await (database.select(database.messages)
            ..where((tbl) => tbl.conversationId.equals('conv-1'))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)])
            ..limit(5, offset: 5))
          .get();

      expect(page2.length, equals(5));
      expect(page2.first.id, equals('msg-5'));
    });

    test('can count unread messages by conversation', () async {
      final now = DateTime.now();

      // Messages with different statuses
      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-delivered-1',
        conversationId: 'conv-1',
        messageText: 'Delivered 1',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now,
        status: const Value('delivered'),
      ));

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-delivered-2',
        conversationId: 'conv-1',
        messageText: 'Delivered 2',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now,
        status: const Value('delivered'),
      ));

      await database.into(database.messages).insert(MessagesCompanion.insert(
        id: 'msg-read',
        conversationId: 'conv-1',
        messageText: 'Read',
        senderId: 'user-2',
        senderName: 'Bob',
        timestamp: now,
        status: const Value('read'),
      ));

      final unreadCount = await (database.selectOnly(database.messages)
            ..addColumns([database.messages.id.count()])
            ..where(database.messages.conversationId.equals('conv-1') &
                database.messages.status.equals('delivered')))
          .map((row) => row.read(database.messages.id.count()) ?? 0)
          .getSingle();

      expect(unreadCount, equals(2));
    });
  });
}

