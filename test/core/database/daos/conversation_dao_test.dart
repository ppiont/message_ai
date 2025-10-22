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

  group('ConversationDao - Basic CRUD', () {
    test('insertConversation inserts a conversation successfully', () async {
      final now = DateTime.now();
      final conversation = ConversationsCompanion.insert(
        documentId: 'conv-1',
        conversationType: 'direct',
        participantIds: '["user1","user2"]',
        participants: '[]',
        unreadCount: '{"user1":0,"user2":0}',
        lastUpdatedAt: now,
        initiatedAt: now,
      );

      await database.conversationDao.insertConversation(conversation);

      final retrieved = await database.conversationDao
          .getConversationById('conv-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.conversationType, equals('direct'));
    });

    test('upsertConversation updates existing conversation', () async {
      final now = DateTime.now();
      final conversation = ConversationsCompanion.insert(
        documentId: 'conv-1',
        conversationType: 'direct',
        participantIds: '["user1","user2"]',
        participants: '[]',
        unreadCount: '{"user1":0,"user2":0}',
        lastUpdatedAt: now,
        initiatedAt: now,
      );

      await database.conversationDao.insertConversation(conversation);

      // Upsert with same ID
      await database.conversationDao.upsertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-1',
          conversationType: 'group',
          participantIds: '["user1","user2","user3"]',
          participants: '[]',
          unreadCount: '{"user1":0,"user2":0,"user3":0}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      final retrieved = await database.conversationDao
          .getConversationById('conv-1');
      expect(retrieved!.conversationType, equals('group'));
    });

    test('updateConversation updates specific conversation', () async {
      final now = DateTime.now();
      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-1',
          conversationType: 'direct',
          participantIds: '["user1","user2"]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      final updated = await database.conversationDao.updateConversation(
        'conv-1',
        const ConversationsCompanion(
          groupName: Value('Updated Name'),
        ),
      );

      expect(updated, isTrue);
      final retrieved = await database.conversationDao
          .getConversationById('conv-1');
      expect(retrieved!.groupName, equals('Updated Name'));
    });

    test('deleteConversation removes conversation', () async {
      final now = DateTime.now();
      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-1',
          conversationType: 'direct',
          participantIds: '["user1","user2"]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      final deleted = await database.conversationDao
          .deleteConversation('conv-1');
      expect(deleted, equals(1));

      final retrieved = await database.conversationDao
          .getConversationById('conv-1');
      expect(retrieved, isNull);
    });
  });

  group('ConversationDao - Query Operations', () {
    test('getAllConversations returns conversations ordered by lastUpdatedAt',
        () async {
      final now = DateTime.now();

      // Insert conversations in random order
      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-2',
          conversationType: 'direct',
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now.add(const Duration(minutes: 1)),
          initiatedAt: now,
        ),
      );

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-1',
          conversationType: 'direct',
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-3',
          conversationType: 'direct',
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now.add(const Duration(minutes: 2)),
          initiatedAt: now,
        ),
      );

      final conversations = await database.conversationDao
          .getAllConversations();

      expect(conversations.length, equals(3));
      // Should be ordered newest first
      expect(conversations[0].documentId, equals('conv-3'));
      expect(conversations[1].documentId, equals('conv-2'));
      expect(conversations[2].documentId, equals('conv-1'));
    });

    test('getAllConversations supports pagination', () async {
      final now = DateTime.now();

      // Insert 10 conversations
      for (var i = 0; i < 10; i++) {
        await database.conversationDao.insertConversation(
          ConversationsCompanion.insert(
            documentId: 'conv-$i',
            conversationType: 'direct',
            participantIds: '[]',
            participants: '[]',
            unreadCount: '{}',
            lastUpdatedAt: now.add(Duration(minutes: i)),
            initiatedAt: now,
          ),
        );
      }

      // Get first page
      final page1 = await database.conversationDao.getAllConversations(
        limit: 5,
      );
      expect(page1.length, equals(5));
      expect(page1.first.documentId, equals('conv-9')); // Newest

      // Get second page
      final page2 = await database.conversationDao.getAllConversations(
        limit: 5,
        offset: 5,
      );
      expect(page2.length, equals(5));
      expect(page2.first.documentId, equals('conv-4'));
    });

    test('watchAllConversations emits updates', () async {
      final now = DateTime.now();

      // Insert a conversation first
      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-1',
          conversationType: 'direct',
          participantIds: '["user1","user2"]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      // Start watching after insert
      final stream = database.conversationDao.watchAllConversations();

      // Should emit the existing conversation
      await expectLater(
        stream,
        emits(predicate<List<ConversationEntity>>(
          (convs) => convs.length == 1 && convs.first.documentId == 'conv-1',
        )),
      );
    });

    test('getConversationsByParticipant filters by user', () async {
      final now = DateTime.now();

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-user1',
          conversationType: 'direct',
          participantIds: '["user1","user2"]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-user3',
          conversationType: 'direct',
          participantIds: '["user2","user3"]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      final user1Conversations = await database.conversationDao
          .getConversationsByParticipant('user1');

      expect(user1Conversations.length, equals(1));
      expect(user1Conversations.first.documentId, equals('conv-user1'));
    });

    test('getConversationsByType filters correctly', () async {
      final now = DateTime.now();

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-direct',
          conversationType: 'direct',
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-group',
          conversationType: 'group',
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      final directConvs = await database.conversationDao
          .getConversationsByType('direct');
      expect(directConvs.length, equals(1));
      expect(directConvs.first.conversationType, equals('direct'));
    });

    test('getDirectConversation finds 1-to-1 conversation', () async {
      final now = DateTime.now();

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-12',
          conversationType: 'direct',
          participantIds: '["user1","user2"]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-13',
          conversationType: 'direct',
          participantIds: '["user1","user3"]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      final conversation = await database.conversationDao
          .getDirectConversation('user1', 'user2');

      expect(conversation, isNotNull);
      expect(conversation!.documentId, equals('conv-12'));
    });

    test('countConversations returns correct count', () async {
      final now = DateTime.now();

      for (var i = 0; i < 5; i++) {
        await database.conversationDao.insertConversation(
          ConversationsCompanion.insert(
            documentId: 'conv-$i',
            conversationType: 'direct',
            participantIds: '[]',
            participants: '[]',
            unreadCount: '{}',
            lastUpdatedAt: now,
            initiatedAt: now,
          ),
        );
      }

      final count = await database.conversationDao.countConversations();
      expect(count, equals(5));
    });
  });

  group('ConversationDao - Last Message Updates', () {
    test('updateLastMessage updates conversation metadata', () async {
      final now = DateTime.now();
      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-1',
          conversationType: 'direct',
          participantIds: '["user1","user2"]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      final messageTime = now.add(const Duration(minutes: 5));
      await database.conversationDao.updateLastMessage(
        documentId: 'conv-1',
        messageText: 'Hello World',
        senderId: 'user1',
        senderName: 'Alice',
        timestamp: messageTime,
        messageType: 'text',
      );

      final conversation = await database.conversationDao
          .getConversationById('conv-1');

      expect(conversation!.lastMessageText, equals('Hello World'));
      expect(conversation.lastMessageSenderId, equals('user1'));
      expect(conversation.lastMessageSenderName, equals('Alice'));
      expect(conversation.lastMessageType, equals('text'));
    });
  });

  group('ConversationDao - Unread Count Management', () {
    test('incrementUnreadCount increases count for non-senders', () async {
      final now = DateTime.now();
      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-1',
          conversationType: 'direct',
          participantIds: '["user1","user2"]',
          participants: '[]',
          unreadCount: '{"user1":0,"user2":0}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      await database.conversationDao.incrementUnreadCount(
        documentId: 'conv-1',
        senderId: 'user1',
        participantIds: ['user1', 'user2'],
      );

      final conversation = await database.conversationDao
          .getConversationById('conv-1');

      // user2 should have 1 unread, user1 should have 0
      expect(conversation!.unreadCount.contains('"user2":1'), isTrue);
    });

    test('resetUnreadCount sets count to 0 for user', () async {
      final now = DateTime.now();
      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-1',
          conversationType: 'direct',
          participantIds: '["user1","user2"]',
          participants: '[]',
          unreadCount: '{"user1":5,"user2":3}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      await database.conversationDao.resetUnreadCount(
        documentId: 'conv-1',
        userId: 'user1',
      );

      final conversation = await database.conversationDao
          .getConversationById('conv-1');

      expect(conversation!.unreadCount.contains('"user1":0'), isTrue);
      expect(conversation.unreadCount.contains('"user2":3'), isTrue);
    });
  });

  group('ConversationDao - Batch Operations', () {
    test('insertConversations inserts multiple conversations', () async {
      final now = DateTime.now();
      final conversations = List.generate(
        5,
        (i) => ConversationsCompanion.insert(
          documentId: 'conv-$i',
          conversationType: 'direct',
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      await database.conversationDao.insertConversations(conversations);

      final count = await database.conversationDao.countConversations();
      expect(count, equals(5));
    });

    test('batchDeleteConversations removes multiple conversations', () async {
      final now = DateTime.now();

      for (var i = 0; i < 5; i++) {
        await database.conversationDao.insertConversation(
          ConversationsCompanion.insert(
            documentId: 'conv-$i',
            conversationType: 'direct',
            participantIds: '[]',
            participants: '[]',
            unreadCount: '{}',
            lastUpdatedAt: now,
            initiatedAt: now,
          ),
        );
      }

      await database.conversationDao.batchDeleteConversations(
        ['conv-0', 'conv-2', 'conv-4'],
      );

      final remaining = await database.conversationDao.getAllConversations();
      expect(remaining.length, equals(2));
      expect(remaining.any((c) => c.documentId == 'conv-1'), isTrue);
      expect(remaining.any((c) => c.documentId == 'conv-3'), isTrue);
    });
  });

  group('ConversationDao - Special Queries', () {
    test('searchConversationsByName finds conversations', () async {
      final now = DateTime.now();

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-1',
          conversationType: 'group',
          groupName: const Value('Project Team'),
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-2',
          conversationType: 'group',
          groupName: const Value('Family Chat'),
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      final results = await database.conversationDao
          .searchConversationsByName('Project');

      expect(results.length, equals(1));
      expect(results.first.groupName, equals('Project Team'));
    });

    test('getConversationsUpdatedAfter returns recent conversations',
        () async {
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(minutes: 10));

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-old',
          conversationType: 'direct',
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: cutoff.subtract(const Duration(minutes: 5)),
          initiatedAt: now,
        ),
      );

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-new',
          conversationType: 'direct',
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      final recent = await database.conversationDao
          .getConversationsUpdatedAfter(cutoff);

      expect(recent.length, equals(1));
      expect(recent.first.documentId, equals('conv-new'));
    });

    test('getGroupsWhereUserIsAdmin filters by admin', () async {
      final now = DateTime.now();

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-admin',
          conversationType: 'group',
          participantIds: '["user1","user2","user3"]',
          participants: '[]',
          adminIds: const Value('["user1"]'),
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-member',
          conversationType: 'group',
          participantIds: '["user1","user2"]',
          participants: '[]',
          adminIds: const Value('["user2"]'),
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      final adminConvs = await database.conversationDao
          .getGroupsWhereUserIsAdmin('user1');

      expect(adminConvs.length, equals(1));
      expect(adminConvs.first.documentId, equals('conv-admin'));
    });

    test('getActiveConversations returns recent activity', () async {
      final now = DateTime.now();

      // Old conversation
      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-old',
          conversationType: 'direct',
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now.subtract(const Duration(days: 30)),
          initiatedAt: now,
        ),
      );

      // Recent conversation
      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-recent',
          conversationType: 'direct',
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      final active = await database.conversationDao
          .getActiveConversations();

      expect(active.length, equals(1));
      expect(active.first.documentId, equals('conv-recent'));
    });

    test('getConversationsWithTranslation filters by translation flag',
        () async {
      final now = DateTime.now();

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-translated',
          conversationType: 'direct',
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          translationEnabled: const Value(true),
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      await database.conversationDao.insertConversation(
        ConversationsCompanion.insert(
          documentId: 'conv-no-translation',
          conversationType: 'direct',
          participantIds: '[]',
          participants: '[]',
          unreadCount: '{}',
          translationEnabled: const Value(false),
          lastUpdatedAt: now,
          initiatedAt: now,
        ),
      );

      final translated = await database.conversationDao
          .getConversationsWithTranslation();

      expect(translated.length, equals(1));
      expect(translated.first.documentId, equals('conv-translated'));
    });
  });
}
