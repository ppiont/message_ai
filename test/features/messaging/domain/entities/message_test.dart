import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';

void main() {
  group('Message', () {
    final testTimestamp = DateTime(2024, 1, 1, 12, 30);
    final testMetadata = MessageMetadata.defaultMetadata();

    test('should create a Message with required fields', () {
      final message = Message(
        id: 'msg-123',
        text: 'Hello, World!',
        senderId: 'user-456',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
        status: 'delivered',
        metadata: testMetadata,
      );

      expect(message.id, 'msg-123');
      expect(message.text, 'Hello, World!');
      expect(message.senderId, 'user-456');
      expect(message.senderName, 'John Doe');
      expect(message.timestamp, testTimestamp);
      expect(message.type, 'text');
      expect(message.status, 'delivered');
      expect(message.metadata, testMetadata);
      expect(message.detectedLanguage, isNull);
      expect(message.translations, isNull);
      expect(message.replyTo, isNull);
      expect(message.embedding, isNull);
      expect(message.aiAnalysis, isNull);
    });

    test('should create a Message with all fields', () {
      const analysis = MessageAIAnalysis(
        priority: 'high',
        actionItems: ['Review document', 'Send reply'],
        sentiment: 'positive',
      );

      final message = Message(
        id: 'msg-123',
        text: 'Hello, World!',
        senderId: 'user-456',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
        status: 'delivered',
        detectedLanguage: 'en',
        translations: const {'es': 'Hola, Mundo!'},
        replyTo: 'msg-122',
        metadata: testMetadata,
        embedding: const [0.1, 0.2, 0.3],
        aiAnalysis: analysis,
      );

      expect(message.detectedLanguage, 'en');
      expect(message.translations, {'es': 'Hola, Mundo!'});
      expect(message.replyTo, 'msg-122');
      expect(message.embedding, [0.1, 0.2, 0.3]);
      expect(message.aiAnalysis, analysis);
    });

    test('should support equality comparison', () {
      final message1 = Message(
        id: 'msg-123',
        text: 'Hello',
        senderId: 'user-456',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
        status: 'sent',
        metadata: testMetadata,
      );

      final message2 = Message(
        id: 'msg-123',
        text: 'Hello',
        senderId: 'user-456',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
        status: 'sent',
        metadata: testMetadata,
      );

      expect(message1, equals(message2));
    });

    test('should not be equal when fields differ', () {
      final message1 = Message(
        id: 'msg-123',
        text: 'Hello',
        senderId: 'user-456',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
        status: 'sent',
        metadata: testMetadata,
      );

      final message2 = Message(
        id: 'msg-124',
        text: 'Hello',
        senderId: 'user-456',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
        status: 'sent',
        metadata: testMetadata,
      );

      expect(message1, isNot(equals(message2)));
    });

    test('copyWith should create a new message with updated fields', () {
      final original = Message(
        id: 'msg-123',
        text: 'Hello',
        senderId: 'user-456',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
        status: 'sent',
        metadata: testMetadata,
      );

      final updated = original.copyWith(
        status: 'delivered',
        text: 'Hello, updated!',
      );

      expect(updated.id, original.id);
      expect(updated.text, 'Hello, updated!');
      expect(updated.status, 'delivered');
      expect(updated.senderId, original.senderId);
      expect(updated.timestamp, original.timestamp);
    });

    test('copyWith should preserve original fields when not specified', () {
      final original = Message(
        id: 'msg-123',
        text: 'Hello',
        senderId: 'user-456',
        senderName: 'John Doe',
        timestamp: testTimestamp,
        type: 'text',
        status: 'sent',
        detectedLanguage: 'en',
        metadata: testMetadata,
      );

      final updated = original.copyWith(status: 'delivered');

      expect(updated.detectedLanguage, 'en');
      expect(updated.text, 'Hello');
      expect(updated.senderId, 'user-456');
    });
  });

  group('MessageMetadata', () {
    test('should create metadata with required fields', () {
      const metadata = MessageMetadata(
        edited: false,
        deleted: false,
        priority: 'medium',
        hasIdioms: false,
      );

      expect(metadata.edited, false);
      expect(metadata.deleted, false);
      expect(metadata.priority, 'medium');
      expect(metadata.hasIdioms, false);
    });

    test('should create default metadata', () {
      final metadata = MessageMetadata.defaultMetadata();

      expect(metadata.edited, false);
      expect(metadata.deleted, false);
      expect(metadata.priority, 'medium');
      expect(metadata.hasIdioms, false);
    });

    test('should support equality comparison', () {
      const metadata1 = MessageMetadata(
        edited: false,
        deleted: false,
        priority: 'high',
        hasIdioms: true,
      );

      const metadata2 = MessageMetadata(
        edited: false,
        deleted: false,
        priority: 'high',
        hasIdioms: true,
      );

      expect(metadata1, equals(metadata2));
    });

    test('copyWith should update specified fields', () {
      const original = MessageMetadata(
        edited: false,
        deleted: false,
        priority: 'medium',
        hasIdioms: false,
      );

      final updated = original.copyWith(
        edited: true,
        priority: 'high',
      );

      expect(updated.edited, true);
      expect(updated.priority, 'high');
      expect(updated.deleted, false);
      expect(updated.hasIdioms, false);
    });
  });

  group('MessageAIAnalysis', () {
    test('should create analysis with required fields', () {
      const analysis = MessageAIAnalysis(
        priority: 'high',
        actionItems: ['Review document', 'Send reply'],
        sentiment: 'positive',
      );

      expect(analysis.priority, 'high');
      expect(analysis.actionItems, ['Review document', 'Send reply']);
      expect(analysis.sentiment, 'positive');
    });

    test('should support equality comparison', () {
      const analysis1 = MessageAIAnalysis(
        priority: 'high',
        actionItems: ['Task 1'],
        sentiment: 'neutral',
      );

      const analysis2 = MessageAIAnalysis(
        priority: 'high',
        actionItems: ['Task 1'],
        sentiment: 'neutral',
      );

      expect(analysis1, equals(analysis2));
    });

    test('should handle empty action items', () {
      const analysis = MessageAIAnalysis(
        priority: 'low',
        actionItems: [],
        sentiment: 'neutral',
      );

      expect(analysis.actionItems, isEmpty);
    });

    test('copyWith should update specified fields', () {
      const original = MessageAIAnalysis(
        priority: 'medium',
        actionItems: ['Task 1'],
        sentiment: 'neutral',
      );

      final updated = original.copyWith(
        priority: 'high',
        sentiment: 'positive',
      );

      expect(updated.priority, 'high');
      expect(updated.sentiment, 'positive');
      expect(updated.actionItems, ['Task 1']);
    });
  });
}
