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

  group('Conversations Table Schema', () {
    test('table is created with correct name', () {
      expect(database.conversations.actualTableName, equals('conversations'));
    });

    test('table has correct primary key', () {
      final primaryKey = database.conversations.$primaryKey;
      expect(primaryKey.length, equals(1));
      expect(primaryKey.first.$name, equals('document_id'));
    });

    test('table has all required columns', () {
      final columns = database.conversations.$columns;
      final columnNames = columns.map((c) => c.$name).toList();

      expect(columnNames, containsAll([
        'document_id',
        'conversation_type',
        'group_name',
        'group_image',
        'participant_ids',
        'participants',
        'admin_ids',
        'last_message_text',
        'last_message_sender_id',
        'last_message_sender_name',
        'last_message_timestamp',
        'last_message_type',
        'last_message_translations',
        'last_updated_at',
        'initiated_at',
        'unread_count',
        'translation_enabled',
        'auto_detect_language',
      ]));
    });

    test('documentId column is non-nullable text', () {
      final docIdColumn = database.conversations.$columns
          .firstWhere((c) => c.$name == 'document_id') as GeneratedColumn<String>;
      expect(docIdColumn.$nullable, isFalse);
      expect(docIdColumn.type, equals(DriftSqlType.string));
    });

    test('conversationType column is non-nullable text', () {
      final typeColumn = database.conversations.$columns
          .firstWhere((c) => c.$name == 'conversation_type') as GeneratedColumn<String>;
      expect(typeColumn.$nullable, isFalse);
      expect(typeColumn.type, equals(DriftSqlType.string));
    });

    test('translation_enabled has default value of true', () {
      final translationColumn = database.conversations.$columns
          .firstWhere((c) => c.$name == 'translation_enabled') as GeneratedColumn<bool>;
      expect(translationColumn.defaultValue, isNotNull);
    });

    test('auto_detect_language has default value of true', () {
      final autoDetectColumn = database.conversations.$columns
          .firstWhere((c) => c.$name == 'auto_detect_language') as GeneratedColumn<bool>;
      expect(autoDetectColumn.defaultValue, isNotNull);
    });
  });

  group('Conversations Table CRUD Operations', () {
    test('can insert a direct conversation', () async {
      final now = DateTime.now();
      final conversation = ConversationsCompanion.insert(
        documentId: 'conv-123',
        conversationType: 'direct',
        participantIds: '["user1", "user2"]',
        participants: '[]',
        unreadCount: '{"user1": 0, "user2": 0}',
        lastUpdatedAt: now,
        initiatedAt: now,
      );

      await database.into(database.conversations).insert(conversation);

      final allConversations = await database.select(database.conversations).get();
      expect(allConversations.length, equals(1));
      expect(allConversations.first.documentId, equals('conv-123'));
      expect(allConversations.first.conversationType, equals('direct'));
    });

    test('can insert a group conversation with all fields', () async {
      final now = DateTime.now();
      final conversation = ConversationsCompanion.insert(
        documentId: 'group-456',
        conversationType: 'group',
        groupName: const Value('Engineering Team'),
        groupImage: const Value('https://example.com/group.jpg'),
        participantIds: '["user1", "user2", "user3"]',
        participants: '[{"uid":"user1","name":"Alice"}]',
        adminIds: const Value('["user1"]'),
        lastMessageText: const Value('Welcome to the group!'),
        lastMessageSenderId: const Value('user1'),
        lastMessageSenderName: const Value('Alice'),
        lastMessageTimestamp: Value(now),
        lastMessageType: const Value('text'),
        lastMessageTranslations: const Value('{"es":"¡Bienvenido al grupo!"}'),
        unreadCount: '{"user1": 0, "user2": 5, "user3": 3}',
        lastUpdatedAt: now,
        initiatedAt: now,
        translationEnabled: const Value(true),
        autoDetectLanguage: const Value(true),
      );

      await database.into(database.conversations).insert(conversation);

      final result = await (database.select(database.conversations)
            ..where((tbl) => tbl.documentId.equals('group-456')))
          .getSingle();

      expect(result.conversationType, equals('group'));
      expect(result.groupName, equals('Engineering Team'));
      expect(result.groupImage, equals('https://example.com/group.jpg'));
      expect(result.lastMessageText, equals('Welcome to the group!'));
      expect(result.translationEnabled, isTrue);
    });

    test('can read a specific conversation by documentId', () async {
      final now = DateTime.now();
      
      await database.into(database.conversations).insert(ConversationsCompanion.insert(
        documentId: 'conv-1',
        conversationType: 'direct',
        participantIds: '["user1", "user2"]',
        participants: '[]',
        unreadCount: '{}',
        lastUpdatedAt: now,
        initiatedAt: now,
      ));

      await database.into(database.conversations).insert(ConversationsCompanion.insert(
        documentId: 'conv-2',
        conversationType: 'group',
        participantIds: '["user1", "user2", "user3"]',
        participants: '[]',
        unreadCount: '{}',
        lastUpdatedAt: now,
        initiatedAt: now,
      ));

      final result = await (database.select(database.conversations)
            ..where((tbl) => tbl.documentId.equals('conv-2')))
          .getSingle();

      expect(result.documentId, equals('conv-2'));
      expect(result.conversationType, equals('group'));
    });

    test('can update a conversation', () async {
      final now = DateTime.now();
      final later = now.add(const Duration(minutes: 5));

      await database.into(database.conversations).insert(ConversationsCompanion.insert(
        documentId: 'conv-update',
        conversationType: 'direct',
        participantIds: '["user1", "user2"]',
        participants: '[]',
        unreadCount: '{"user1": 0, "user2": 0}',
        lastUpdatedAt: now,
        initiatedAt: now,
      ));

      // Update the conversation with a new message
      await (database.update(database.conversations)
            ..where((tbl) => tbl.documentId.equals('conv-update')))
          .write(ConversationsCompanion(
        lastMessageText: const Value('New message'),
        lastMessageSenderId: const Value('user1'),
        lastMessageSenderName: const Value('Alice'),
        lastMessageTimestamp: Value(later),
        lastMessageType: const Value('text'),
        lastUpdatedAt: Value(later),
        unreadCount: const Value('{"user1": 0, "user2": 1}'),
      ));

      final updated = await (database.select(database.conversations)
            ..where((tbl) => tbl.documentId.equals('conv-update')))
          .getSingle();

      expect(updated.lastMessageText, equals('New message'));
      expect(updated.lastMessageSenderId, equals('user1'));
      expect(updated.unreadCount, equals('{"user1": 0, "user2": 1}'));
    });

    test('can delete a conversation', () async {
      final now = DateTime.now();
      
      await database.into(database.conversations).insert(ConversationsCompanion.insert(
        documentId: 'conv-delete',
        conversationType: 'direct',
        participantIds: '["user1", "user2"]',
        participants: '[]',
        unreadCount: '{}',
        lastUpdatedAt: now,
        initiatedAt: now,
      ));

      var allConversations = await database.select(database.conversations).get();
      expect(allConversations.length, equals(1));

      await (database.delete(database.conversations)
            ..where((tbl) => tbl.documentId.equals('conv-delete')))
          .go();

      allConversations = await database.select(database.conversations).get();
      expect(allConversations.length, equals(0));
    });

    test('primary key constraint prevents duplicate documentIds', () async {
      final now = DateTime.now();
      final conversation1 = ConversationsCompanion.insert(
        documentId: 'duplicate-id',
        conversationType: 'direct',
        participantIds: '[]',
        participants: '[]',
        unreadCount: '{}',
        lastUpdatedAt: now,
        initiatedAt: now,
      );
      final conversation2 = ConversationsCompanion.insert(
        documentId: 'duplicate-id',
        conversationType: 'group',
        participantIds: '[]',
        participants: '[]',
        unreadCount: '{}',
        lastUpdatedAt: now,
        initiatedAt: now,
      );

      await database.into(database.conversations).insert(conversation1);

      expect(
        () => database.into(database.conversations).insert(conversation2),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('Conversations Table Queries', () {
    test('can query conversations by type', () async {
      final now = DateTime.now();

      // Insert direct conversations
      await database.into(database.conversations).insert(ConversationsCompanion.insert(
        documentId: 'direct-1',
        conversationType: 'direct',
        participantIds: '[]',
        participants: '[]',
        unreadCount: '{}',
        lastUpdatedAt: now,
        initiatedAt: now,
      ));

      await database.into(database.conversations).insert(ConversationsCompanion.insert(
        documentId: 'direct-2',
        conversationType: 'direct',
        participantIds: '[]',
        participants: '[]',
        unreadCount: '{}',
        lastUpdatedAt: now,
        initiatedAt: now,
      ));

      // Insert group conversation
      await database.into(database.conversations).insert(ConversationsCompanion.insert(
        documentId: 'group-1',
        conversationType: 'group',
        participantIds: '[]',
        participants: '[]',
        unreadCount: '{}',
        lastUpdatedAt: now,
        initiatedAt: now,
      ));

      final directConversations = await (database.select(database.conversations)
            ..where((tbl) => tbl.conversationType.equals('direct')))
          .get();

      expect(directConversations.length, equals(2));
      expect(directConversations.every((c) => c.conversationType == 'direct'), isTrue);
    });

    test('can query conversations ordered by lastUpdatedAt', () async {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(hours: 1));
      final latest = now.add(const Duration(hours: 1));

      await database.into(database.conversations).insert(ConversationsCompanion.insert(
        documentId: 'conv-old',
        conversationType: 'direct',
        participantIds: '[]',
        participants: '[]',
        unreadCount: '{}',
        lastUpdatedAt: earlier,
        initiatedAt: earlier,
      ));

      await database.into(database.conversations).insert(ConversationsCompanion.insert(
        documentId: 'conv-newest',
        conversationType: 'direct',
        participantIds: '[]',
        participants: '[]',
        unreadCount: '{}',
        lastUpdatedAt: latest,
        initiatedAt: now,
      ));

      await database.into(database.conversations).insert(ConversationsCompanion.insert(
        documentId: 'conv-middle',
        conversationType: 'direct',
        participantIds: '[]',
        participants: '[]',
        unreadCount: '{}',
        lastUpdatedAt: now,
        initiatedAt: now,
      ));

      final sortedConversations = await (database.select(database.conversations)
            ..orderBy([(t) => OrderingTerm.desc(t.lastUpdatedAt)]))
          .get();

      expect(sortedConversations.length, equals(3));
      expect(sortedConversations[0].documentId, equals('conv-newest'));
      expect(sortedConversations[1].documentId, equals('conv-middle'));
      expect(sortedConversations[2].documentId, equals('conv-old'));
    });

    test('can query conversations with translation enabled', () async {
      final now = DateTime.now();

      await database.into(database.conversations).insert(ConversationsCompanion.insert(
        documentId: 'translation-on',
        conversationType: 'direct',
        participantIds: '[]',
        participants: '[]',
        unreadCount: '{}',
        translationEnabled: const Value(true),
        lastUpdatedAt: now,
        initiatedAt: now,
      ));

      await database.into(database.conversations).insert(ConversationsCompanion.insert(
        documentId: 'translation-off',
        conversationType: 'direct',
        participantIds: '[]',
        participants: '[]',
        unreadCount: '{}',
        translationEnabled: const Value(false),
        lastUpdatedAt: now,
        initiatedAt: now,
      ));

      final translatedConversations = await (database.select(database.conversations)
            ..where((tbl) => tbl.translationEnabled.equals(true)))
          .get();

      expect(translatedConversations.length, equals(1));
      expect(translatedConversations.first.documentId, equals('translation-on'));
    });
  });

  group('Conversations Table Data Integrity', () {
    test('null values are properly handled for optional fields', () async {
      final now = DateTime.now();
      final conversation = ConversationsCompanion.insert(
        documentId: 'minimal-conv',
        conversationType: 'direct',
        participantIds: '[]',
        participants: '[]',
        unreadCount: '{}',
        lastUpdatedAt: now,
        initiatedAt: now,
      );

      await database.into(database.conversations).insert(conversation);

      final result = await (database.select(database.conversations)
            ..where((tbl) => tbl.documentId.equals('minimal-conv')))
          .getSingle();

      expect(result.groupName, isNull);
      expect(result.groupImage, isNull);
      expect(result.adminIds, isNull);
      expect(result.lastMessageText, isNull);
      expect(result.lastMessageSenderId, isNull);
      expect(result.lastMessageTimestamp, isNull);
    });

    test('default values are applied correctly', () async {
      final now = DateTime.now();
      final conversation = ConversationsCompanion.insert(
        documentId: 'default-values',
        conversationType: 'direct',
        participantIds: '[]',
        participants: '[]',
        unreadCount: '{}',
        lastUpdatedAt: now,
        initiatedAt: now,
      );

      await database.into(database.conversations).insert(conversation);

      final result = await (database.select(database.conversations)
            ..where((tbl) => tbl.documentId.equals('default-values')))
          .getSingle();

      expect(result.translationEnabled, isTrue); // Default value
      expect(result.autoDetectLanguage, isTrue); // Default value
    });

    test('JSON fields can store complex data', () async {
      final now = DateTime.now();
      final participants = '[{"uid":"user1","name":"Alice"},{"uid":"user2","name":"Bob"}]';
      final unreadCount = '{"user1": 0, "user2": 5}';
      final translations = '{"es":"Hola","fr":"Bonjour"}';

      final conversation = ConversationsCompanion.insert(
        documentId: 'json-data',
        conversationType: 'group',
        participantIds: '["user1","user2"]',
        participants: participants,
        unreadCount: unreadCount,
        lastMessageTranslations: Value(translations),
        lastUpdatedAt: now,
        initiatedAt: now,
      );

      await database.into(database.conversations).insert(conversation);

      final result = await (database.select(database.conversations)
            ..where((tbl) => tbl.documentId.equals('json-data')))
          .getSingle();

      expect(result.participants, equals(participants));
      expect(result.unreadCount, equals(unreadCount));
      expect(result.lastMessageTranslations, equals(translations));
    });
  });
}

