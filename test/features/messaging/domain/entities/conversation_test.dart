import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';

void main() {
  group('Conversation', () {
    final testTimestamp = DateTime(2024, 1, 1, 12, 30);
    final testParticipants = [
      const Participant(
        uid: 'user-123',
        name: 'John Doe',
        imageUrl: 'https://example.com/john.jpg',
        preferredLanguage: 'en',
      ),
      const Participant(
        uid: 'user-456',
        name: 'Jane Smith',
        imageUrl: 'https://example.com/jane.jpg',
        preferredLanguage: 'es',
      ),
    ];

    test('should create a direct conversation with required fields', () {
      final conversation = Conversation(
        documentId: 'conv-123',
        type: 'direct',
        participantIds: ['user-123', 'user-456'],
        participants: testParticipants,
        lastUpdatedAt: testTimestamp,
        initiatedAt: testTimestamp,
        unreadCount: {'user-123': 0, 'user-456': 3},
        translationEnabled: true,
        autoDetectLanguage: true,
      );

      expect(conversation.documentId, 'conv-123');
      expect(conversation.type, 'direct');
      expect(conversation.participantIds, ['user-123', 'user-456']);
      expect(conversation.participants, testParticipants);
      expect(conversation.lastUpdatedAt, testTimestamp);
      expect(conversation.initiatedAt, testTimestamp);
      expect(conversation.unreadCount, {'user-123': 0, 'user-456': 3});
      expect(conversation.translationEnabled, true);
      expect(conversation.autoDetectLanguage, true);
      expect(conversation.lastMessage, isNull);
      expect(conversation.groupName, isNull);
      expect(conversation.groupImage, isNull);
      expect(conversation.adminIds, isNull);
    });

    test('should create a group conversation with all fields', () {
      final lastMessage = LastMessage(
        text: 'Hello everyone!',
        senderId: 'user-123',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
        translations: const {'es': '¡Hola a todos!'},
      );

      final conversation = Conversation(
        documentId: 'conv-789',
        type: 'group',
        participantIds: ['user-123', 'user-456', 'user-789'],
        participants: testParticipants,
        lastMessage: lastMessage,
        lastUpdatedAt: testTimestamp,
        initiatedAt: testTimestamp,
        unreadCount: {'user-123': 0, 'user-456': 2, 'user-789': 5},
        translationEnabled: false,
        autoDetectLanguage: false,
        groupName: 'Project Team',
        groupImage: 'https://example.com/group.jpg',
        adminIds: ['user-123'],
      );

      expect(conversation.type, 'group');
      expect(conversation.groupName, 'Project Team');
      expect(conversation.groupImage, 'https://example.com/group.jpg');
      expect(conversation.adminIds, ['user-123']);
      expect(conversation.lastMessage, lastMessage);
    });

    test('should support equality comparison', () {
      final conversation1 = Conversation(
        documentId: 'conv-123',
        type: 'direct',
        participantIds: ['user-123', 'user-456'],
        participants: testParticipants,
        lastUpdatedAt: testTimestamp,
        initiatedAt: testTimestamp,
        unreadCount: {'user-123': 0},
        translationEnabled: true,
        autoDetectLanguage: true,
      );

      final conversation2 = Conversation(
        documentId: 'conv-123',
        type: 'direct',
        participantIds: ['user-123', 'user-456'],
        participants: testParticipants,
        lastUpdatedAt: testTimestamp,
        initiatedAt: testTimestamp,
        unreadCount: {'user-123': 0},
        translationEnabled: true,
        autoDetectLanguage: true,
      );

      expect(conversation1, equals(conversation2));
    });

    test('should not be equal when fields differ', () {
      final conversation1 = Conversation(
        documentId: 'conv-123',
        type: 'direct',
        participantIds: ['user-123', 'user-456'],
        participants: testParticipants,
        lastUpdatedAt: testTimestamp,
        initiatedAt: testTimestamp,
        unreadCount: {},
        translationEnabled: true,
        autoDetectLanguage: true,
      );

      final conversation2 = Conversation(
        documentId: 'conv-456',
        type: 'direct',
        participantIds: ['user-123', 'user-456'],
        participants: testParticipants,
        lastUpdatedAt: testTimestamp,
        initiatedAt: testTimestamp,
        unreadCount: {},
        translationEnabled: true,
        autoDetectLanguage: true,
      );

      expect(conversation1, isNot(equals(conversation2)));
    });

    test('copyWith should create a new conversation with updated fields', () {
      final original = Conversation(
        documentId: 'conv-123',
        type: 'direct',
        participantIds: ['user-123', 'user-456'],
        participants: testParticipants,
        lastUpdatedAt: testTimestamp,
        initiatedAt: testTimestamp,
        unreadCount: {'user-123': 0},
        translationEnabled: false,
        autoDetectLanguage: false,
      );

      final updated = original.copyWith(
        translationEnabled: true,
        autoDetectLanguage: true,
      );

      expect(updated.documentId, original.documentId);
      expect(updated.translationEnabled, true);
      expect(updated.autoDetectLanguage, true);
      expect(updated.type, original.type);
    });

    test('isDirect should return true for direct conversations', () {
      final conversation = Conversation(
        documentId: 'conv-123',
        type: 'direct',
        participantIds: ['user-123', 'user-456'],
        participants: testParticipants,
        lastUpdatedAt: testTimestamp,
        initiatedAt: testTimestamp,
        unreadCount: {},
        translationEnabled: true,
        autoDetectLanguage: true,
      );

      expect(conversation.isDirect, true);
      expect(conversation.isGroup, false);
    });

    test('isGroup should return true for group conversations', () {
      final conversation = Conversation(
        documentId: 'conv-123',
        type: 'group',
        participantIds: ['user-123', 'user-456', 'user-789'],
        participants: testParticipants,
        lastUpdatedAt: testTimestamp,
        initiatedAt: testTimestamp,
        unreadCount: {},
        translationEnabled: true,
        autoDetectLanguage: true,
      );

      expect(conversation.isGroup, true);
      expect(conversation.isDirect, false);
    });

    test('getUnreadCountForUser should return correct count', () {
      final conversation = Conversation(
        documentId: 'conv-123',
        type: 'direct',
        participantIds: ['user-123', 'user-456'],
        participants: testParticipants,
        lastUpdatedAt: testTimestamp,
        initiatedAt: testTimestamp,
        unreadCount: {'user-123': 0, 'user-456': 5},
        translationEnabled: true,
        autoDetectLanguage: true,
      );

      expect(conversation.getUnreadCountForUser('user-123'), 0);
      expect(conversation.getUnreadCountForUser('user-456'), 5);
    });

    test('getUnreadCountForUser should return 0 for unknown user', () {
      final conversation = Conversation(
        documentId: 'conv-123',
        type: 'direct',
        participantIds: ['user-123', 'user-456'],
        participants: testParticipants,
        lastUpdatedAt: testTimestamp,
        initiatedAt: testTimestamp,
        unreadCount: {'user-123': 0},
        translationEnabled: true,
        autoDetectLanguage: true,
      );

      expect(conversation.getUnreadCountForUser('user-999'), 0);
    });
  });

  group('Participant', () {
    test('should create a participant with all fields', () {
      const participant = Participant(
        uid: 'user-123',
        name: 'John Doe',
        imageUrl: 'https://example.com/john.jpg',
        preferredLanguage: 'en',
      );

      expect(participant.uid, 'user-123');
      expect(participant.name, 'John Doe');
      expect(participant.imageUrl, 'https://example.com/john.jpg');
      expect(participant.preferredLanguage, 'en');
    });

    test('should create a participant without image URL', () {
      const participant = Participant(
        uid: 'user-123',
        name: 'John Doe',
        preferredLanguage: 'en',
      );

      expect(participant.imageUrl, isNull);
    });

    test('should support equality comparison', () {
      const participant1 = Participant(
        uid: 'user-123',
        name: 'John Doe',
        preferredLanguage: 'en',
      );

      const participant2 = Participant(
        uid: 'user-123',
        name: 'John Doe',
        preferredLanguage: 'en',
      );

      expect(participant1, equals(participant2));
    });

    test('copyWith should update specified fields', () {
      const original = Participant(
        uid: 'user-123',
        name: 'John Doe',
        preferredLanguage: 'en',
      );

      final updated = original.copyWith(
        name: 'John Smith',
        imageUrl: 'https://example.com/john.jpg',
      );

      expect(updated.uid, original.uid);
      expect(updated.name, 'John Smith');
      expect(updated.imageUrl, 'https://example.com/john.jpg');
      expect(updated.preferredLanguage, original.preferredLanguage);
    });
  });

  group('LastMessage', () {
    final testTimestamp = DateTime(2024, 1, 1, 12, 30);

    test('should create a last message with all fields', () {
      final lastMessage = LastMessage(
        text: 'Hello, World!',
        senderId: 'user-123',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
        translations: const {'es': 'Hola, Mundo!'},
      );

      expect(lastMessage.text, 'Hello, World!');
      expect(lastMessage.senderId, 'user-123');
      expect(lastMessage.senderName, 'John Doe');
      expect(lastMessage.timestamp, testTimestamp);
      expect(lastMessage.type, 'text');
      expect(lastMessage.translations, {'es': 'Hola, Mundo!'});
    });

    test('should create a last message without translations', () {
      final lastMessage = LastMessage(
        text: 'Hello',
        senderId: 'user-123',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
      );

      expect(lastMessage.translations, isNull);
    });

    test('should support equality comparison', () {
      final lastMessage1 = LastMessage(
        text: 'Hello',
        senderId: 'user-123',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
      );

      final lastMessage2 = LastMessage(
        text: 'Hello',
        senderId: 'user-123',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
      );

      expect(lastMessage1, equals(lastMessage2));
    });

    test('copyWith should update specified fields', () {
      final original = LastMessage(
        text: 'Hello',
        senderId: 'user-123',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
      );

      final updated = original.copyWith(
        text: 'Hello, updated!',
        translations: const {'es': 'Hola, actualizado!'},
      );

      expect(updated.text, 'Hello, updated!');
      expect(updated.translations, {'es': 'Hola, actualizado!'});
      expect(updated.senderId, original.senderId);
      expect(updated.timestamp, original.timestamp);
    });
  });
}
