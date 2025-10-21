import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/messaging/data/models/message_model.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';

void main() {
  group('MessageModel', () {
    final testTimestamp = DateTime(2024, 1, 1, 12, 30);

    final testMessageJson = {
      'id': 'msg-123',
      'text': 'Hello, World!',
      'senderId': 'user-456',
      'senderName': 'John Doe',
      'timestamp': '2024-01-01T12:30:00.000',
      'type': 'text',
      'status': 'delivered',
      'detectedLanguage': 'en',
      'translations': {'es': 'Hola, Mundo!', 'fr': 'Bonjour, Monde!'},
      'replyTo': 'msg-122',
      'metadata': {
        'edited': false,
        'deleted': false,
        'priority': 'medium',
        'hasIdioms': false,
      },
      'embedding': [0.1, 0.2, 0.3],
      'aiAnalysis': {
        'priority': 'high',
        'actionItems': ['Review document', 'Send reply'],
        'sentiment': 'positive',
      },
    };

    final testMessageModel = MessageModel(
      id: 'msg-123',
      text: 'Hello, World!',
      senderId: 'user-456',
      senderName: 'John Doe',
      timestamp: testTimestamp,
      type: 'text',
      status: 'delivered',
      detectedLanguage: 'en',
      translations: const {'es': 'Hola, Mundo!', 'fr': 'Bonjour, Monde!'},
      replyTo: 'msg-122',
      metadata: const MessageMetadataModel(
        edited: false,
        deleted: false,
        priority: 'medium',
        hasIdioms: false,
      ),
      embedding: const [0.1, 0.2, 0.3],
      aiAnalysis: const MessageAIAnalysisModel(
        priority: 'high',
        actionItems: ['Review document', 'Send reply'],
        sentiment: 'positive',
      ),
    );

    group('fromJson', () {
      test('should deserialize from JSON with all fields', () {
        final model = MessageModel.fromJson(testMessageJson);

        expect(model.id, 'msg-123');
        expect(model.text, 'Hello, World!');
        expect(model.senderId, 'user-456');
        expect(model.senderName, 'John Doe');
        expect(model.timestamp, testTimestamp);
        expect(model.type, 'text');
        expect(model.status, 'delivered');
        expect(model.detectedLanguage, 'en');
        expect(model.translations, {'es': 'Hola, Mundo!', 'fr': 'Bonjour, Monde!'});
        expect(model.replyTo, 'msg-122');
        expect(model.metadata.edited, false);
        expect(model.metadata.priority, 'medium');
        expect(model.embedding, [0.1, 0.2, 0.3]);
        expect(model.aiAnalysis?.priority, 'high');
        expect(model.aiAnalysis?.actionItems, ['Review document', 'Send reply']);
        expect(model.aiAnalysis?.sentiment, 'positive');
      });

      test('should deserialize from JSON with minimal fields', () {
        final minimalJson = {
          'id': 'msg-123',
          'text': 'Hello',
          'senderId': 'user-456',
          'senderName': 'John Doe',
          'timestamp': '2024-01-01T12:30:00.000',
          'type': 'text',
          'status': 'sent',
          'metadata': {
            'edited': false,
            'deleted': false,
            'priority': 'low',
            'hasIdioms': false,
          },
        };

        final model = MessageModel.fromJson(minimalJson);

        expect(model.id, 'msg-123');
        expect(model.text, 'Hello');
        expect(model.detectedLanguage, isNull);
        expect(model.translations, isNull);
        expect(model.replyTo, isNull);
        expect(model.embedding, isNull);
        expect(model.aiAnalysis, isNull);
      });

      test('should handle empty translations map', () {
        final jsonWithEmptyTranslations = {
          ...testMessageJson,
          'translations': <String, String>{},
        };

        final model = MessageModel.fromJson(jsonWithEmptyTranslations);

        expect(model.translations, isEmpty);
      });

      test('should handle empty embedding list', () {
        final jsonWithEmptyEmbedding = {
          ...testMessageJson,
          'embedding': <double>[],
        };

        final model = MessageModel.fromJson(jsonWithEmptyEmbedding);

        expect(model.embedding, isEmpty);
      });

      test('should convert numeric embedding values to double', () {
        final jsonWithIntEmbedding = {
          ...testMessageJson,
          'embedding': [1, 2, 3], // Integers
        };

        final model = MessageModel.fromJson(jsonWithIntEmbedding);

        expect(model.embedding, [1.0, 2.0, 3.0]);
      });
    });

    group('toJson', () {
      test('should serialize to JSON with all fields', () {
        final json = testMessageModel.toJson();

        expect(json['id'], 'msg-123');
        expect(json['text'], 'Hello, World!');
        expect(json['senderId'], 'user-456');
        expect(json['senderName'], 'John Doe');
        expect(json['timestamp'], '2024-01-01T12:30:00.000');
        expect(json['type'], 'text');
        expect(json['status'], 'delivered');
        expect(json['detectedLanguage'], 'en');
        expect(json['translations'], {'es': 'Hola, Mundo!', 'fr': 'Bonjour, Monde!'});
        expect(json['replyTo'], 'msg-122');
        expect(json['metadata'], isA<Map<String, dynamic>>());
        expect(json['embedding'], [0.1, 0.2, 0.3]);
        expect(json['aiAnalysis'], isA<Map<String, dynamic>>());
      });

      test('should exclude null optional fields', () {
        final minimalModel = MessageModel(
          id: 'msg-123',
          text: 'Hello',
          senderId: 'user-456',
          senderName: 'John Doe',
          timestamp: testTimestamp,
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );

        final json = minimalModel.toJson();

        expect(json.containsKey('detectedLanguage'), false);
        expect(json.containsKey('translations'), false);
        expect(json.containsKey('replyTo'), false);
        expect(json.containsKey('embedding'), false);
        expect(json.containsKey('aiAnalysis'), false);
      });

      test('should maintain data after round-trip serialization', () {
        final originalJson = testMessageJson;
        final model = MessageModel.fromJson(originalJson);
        final serializedJson = model.toJson();
        final deserializedModel = MessageModel.fromJson(serializedJson);

        expect(deserializedModel.id, model.id);
        expect(deserializedModel.text, model.text);
        expect(deserializedModel.senderId, model.senderId);
        expect(deserializedModel.senderName, model.senderName);
        expect(deserializedModel.timestamp, model.timestamp);
        expect(deserializedModel.type, model.type);
        expect(deserializedModel.status, model.status);
        expect(deserializedModel.detectedLanguage, model.detectedLanguage);
        expect(deserializedModel.translations, model.translations);
        expect(deserializedModel.replyTo, model.replyTo);
        expect(deserializedModel.embedding, model.embedding);
      });
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        final entity = Message(
          id: 'msg-123',
          text: 'Hello',
          senderId: 'user-456',
          senderName: 'John Doe',
          timestamp: testTimestamp,
          type: 'text',
          status: 'sent',
          metadata: MessageMetadata.defaultMetadata(),
        );

        final model = MessageModel.fromEntity(entity);

        expect(model.id, entity.id);
        expect(model.text, entity.text);
        expect(model.senderId, entity.senderId);
        expect(model.senderName, entity.senderName);
        expect(model.timestamp, entity.timestamp);
        expect(model.type, entity.type);
        expect(model.status, entity.status);
        expect(model.metadata, entity.metadata);
      });

      test('should preserve all entity fields including optional ones', () {
        final entity = Message(
          id: 'msg-123',
          text: 'Hello',
          senderId: 'user-456',
          senderName: 'John Doe',
          timestamp: testTimestamp,
          type: 'text',
          status: 'sent',
          detectedLanguage: 'en',
          translations: const {'es': 'Hola'},
          metadata: MessageMetadata.defaultMetadata(),
        );

        final model = MessageModel.fromEntity(entity);

        expect(model.detectedLanguage, entity.detectedLanguage);
        expect(model.translations, entity.translations);
      });
    });

    group('toEntity', () {
      test('should convert model to entity', () {
        final entity = testMessageModel.toEntity();

        expect(entity, isA<Message>());
        expect(entity.id, testMessageModel.id);
        expect(entity.text, testMessageModel.text);
        expect(entity.senderId, testMessageModel.senderId);
        expect(entity.senderName, testMessageModel.senderName);
        expect(entity.timestamp, testMessageModel.timestamp);
        expect(entity.type, testMessageModel.type);
        expect(entity.status, testMessageModel.status);
        expect(entity.detectedLanguage, testMessageModel.detectedLanguage);
        expect(entity.translations, testMessageModel.translations);
        expect(entity.replyTo, testMessageModel.replyTo);
        expect(entity.metadata, testMessageModel.metadata);
        expect(entity.embedding, testMessageModel.embedding);
        expect(entity.aiAnalysis, testMessageModel.aiAnalysis);
      });
    });

    group('copyWith', () {
      test('should create a copy with updated fields', () {
        final updated = testMessageModel.copyWith(
          status: 'read',
          text: 'Updated text',
        );

        expect(updated, isA<MessageModel>());
        expect(updated.status, 'read');
        expect(updated.text, 'Updated text');
        expect(updated.id, testMessageModel.id);
        expect(updated.senderId, testMessageModel.senderId);
      });
    });
  });

  group('MessageMetadataModel', () {
    const testMetadata = MessageMetadataModel(
      edited: true,
      deleted: false,
      priority: 'high',
      hasIdioms: true,
    );

    final testMetadataJson = {
      'edited': true,
      'deleted': false,
      'priority': 'high',
      'hasIdioms': true,
    };

    group('fromJson', () {
      test('should deserialize from JSON', () {
        final model = MessageMetadataModel.fromJson(testMetadataJson);

        expect(model.edited, true);
        expect(model.deleted, false);
        expect(model.priority, 'high');
        expect(model.hasIdioms, true);
      });
    });

    group('toJson', () {
      test('should serialize to JSON', () {
        final json = testMetadata.toJson();

        expect(json['edited'], true);
        expect(json['deleted'], false);
        expect(json['priority'], 'high');
        expect(json['hasIdioms'], true);
      });

      test('should maintain data after round-trip', () {
        final json = testMetadata.toJson();
        final deserialized = MessageMetadataModel.fromJson(json);

        expect(deserialized.edited, testMetadata.edited);
        expect(deserialized.deleted, testMetadata.deleted);
        expect(deserialized.priority, testMetadata.priority);
        expect(deserialized.hasIdioms, testMetadata.hasIdioms);
      });
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        const entity = MessageMetadata(
          edited: false,
          deleted: true,
          priority: 'low',
          hasIdioms: false,
        );

        final model = MessageMetadataModel.fromEntity(entity);

        expect(model.edited, entity.edited);
        expect(model.deleted, entity.deleted);
        expect(model.priority, entity.priority);
        expect(model.hasIdioms, entity.hasIdioms);
      });
    });

    group('toEntity', () {
      test('should convert model to entity', () {
        final entity = testMetadata.toEntity();

        expect(entity, isA<MessageMetadata>());
        expect(entity.edited, testMetadata.edited);
        expect(entity.deleted, testMetadata.deleted);
        expect(entity.priority, testMetadata.priority);
        expect(entity.hasIdioms, testMetadata.hasIdioms);
      });
    });
  });

  group('MessageAIAnalysisModel', () {
    const testAnalysis = MessageAIAnalysisModel(
      priority: 'urgent',
      actionItems: ['Task 1', 'Task 2', 'Task 3'],
      sentiment: 'negative',
    );

    final testAnalysisJson = {
      'priority': 'urgent',
      'actionItems': ['Task 1', 'Task 2', 'Task 3'],
      'sentiment': 'negative',
    };

    group('fromJson', () {
      test('should deserialize from JSON', () {
        final model = MessageAIAnalysisModel.fromJson(testAnalysisJson);

        expect(model.priority, 'urgent');
        expect(model.actionItems, ['Task 1', 'Task 2', 'Task 3']);
        expect(model.sentiment, 'negative');
      });

      test('should handle empty action items', () {
        final jsonWithEmptyActions = {
          'priority': 'low',
          'actionItems': <String>[],
          'sentiment': 'neutral',
        };

        final model = MessageAIAnalysisModel.fromJson(jsonWithEmptyActions);

        expect(model.actionItems, isEmpty);
      });
    });

    group('toJson', () {
      test('should serialize to JSON', () {
        final json = testAnalysis.toJson();

        expect(json['priority'], 'urgent');
        expect(json['actionItems'], ['Task 1', 'Task 2', 'Task 3']);
        expect(json['sentiment'], 'negative');
      });

      test('should maintain data after round-trip', () {
        final json = testAnalysis.toJson();
        final deserialized = MessageAIAnalysisModel.fromJson(json);

        expect(deserialized.priority, testAnalysis.priority);
        expect(deserialized.actionItems, testAnalysis.actionItems);
        expect(deserialized.sentiment, testAnalysis.sentiment);
      });
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        const entity = MessageAIAnalysis(
          priority: 'medium',
          actionItems: ['Action'],
          sentiment: 'positive',
        );

        final model = MessageAIAnalysisModel.fromEntity(entity);

        expect(model.priority, entity.priority);
        expect(model.actionItems, entity.actionItems);
        expect(model.sentiment, entity.sentiment);
      });
    });

    group('toEntity', () {
      test('should convert model to entity', () {
        final entity = testAnalysis.toEntity();

        expect(entity, isA<MessageAIAnalysis>());
        expect(entity.priority, testAnalysis.priority);
        expect(entity.actionItems, testAnalysis.actionItems);
        expect(entity.sentiment, testAnalysis.sentiment);
      });
    });
  });
}
