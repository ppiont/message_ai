import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/messaging/data/models/conversation_model.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';

void main() {
  group('ConversationModel', () {
    final testTimestamp = DateTime(2024, 1, 1, 12, 30);

    final testConversationJson = {
      'documentId': 'conv-123',
      'type': 'direct',
      'participantIds': ['user-123', 'user-456'],
      'participants': [
        {
          'uid': 'user-123',
          'name': 'John Doe',
          'imageUrl': 'https://example.com/john.jpg',
          'preferredLanguage': 'en',
        },
        {
          'uid': 'user-456',
          'name': 'Jane Smith',
          'imageUrl': 'https://example.com/jane.jpg',
          'preferredLanguage': 'es',
        },
      ],
      'lastMessage': {
        'text': 'Hello!',
        'senderId': 'user-123',
        'senderName': 'John Doe',
        'timestamp': '2024-01-01T12:30:00.000',
        'type': 'text',
        'translations': {'es': '¡Hola!'},
      },
      'lastUpdatedAt': '2024-01-01T12:30:00.000',
      'initiatedAt': '2024-01-01T10:00:00.000',
      'unreadCount': {'user-123': 0, 'user-456': 3},
      'translationEnabled': true,
      'autoDetectLanguage': true,
      'groupName': 'Team Chat',
      'groupImage': 'https://example.com/group.jpg',
      'adminIds': ['user-123'],
    };

    group('fromJson', () {
      test('should deserialize from JSON with all fields', () {
        final model = ConversationModel.fromJson(testConversationJson);

        expect(model.documentId, 'conv-123');
        expect(model.type, 'direct');
        expect(model.participantIds, ['user-123', 'user-456']);
        expect(model.participants.length, 2);
        expect(model.participants[0].uid, 'user-123');
        expect(model.participants[0].name, 'John Doe');
        expect(model.participants[1].uid, 'user-456');
        expect(model.lastMessage, isNotNull);
        expect(model.lastMessage?.text, 'Hello!');
        expect(model.lastUpdatedAt, testTimestamp);
        expect(model.unreadCount, {'user-123': 0, 'user-456': 3});
        expect(model.translationEnabled, true);
        expect(model.autoDetectLanguage, true);
        expect(model.groupName, 'Team Chat');
        expect(model.groupImage, 'https://example.com/group.jpg');
        expect(model.adminIds, ['user-123']);
      });

      test('should deserialize from JSON with minimal fields', () {
        final minimalJson = {
          'documentId': 'conv-123',
          'type': 'direct',
          'participantIds': ['user-123', 'user-456'],
          'participants': [
            {'uid': 'user-123', 'name': 'John Doe', 'preferredLanguage': 'en'},
          ],
          'lastUpdatedAt': '2024-01-01T12:30:00.000',
          'initiatedAt': '2024-01-01T10:00:00.000',
          'unreadCount': {},
          'translationEnabled': false,
          'autoDetectLanguage': false,
        };

        final model = ConversationModel.fromJson(minimalJson);

        expect(model.documentId, 'conv-123');
        expect(model.lastMessage, isNull);
        expect(model.groupName, isNull);
        expect(model.groupImage, isNull);
        expect(model.adminIds, isNull);
      });

      test('should handle empty participant list', () {
        final jsonWithEmptyParticipants = {
          ...testConversationJson,
          'participants': [],
        };

        final model = ConversationModel.fromJson(jsonWithEmptyParticipants);

        expect(model.participants, isEmpty);
      });

      test('should handle empty unread count', () {
        final jsonWithEmptyUnreadCount = {
          ...testConversationJson,
          'unreadCount': <String, int>{},
        };

        final model = ConversationModel.fromJson(jsonWithEmptyUnreadCount);

        expect(model.unreadCount, isEmpty);
      });
    });

    group('toJson', () {
      test('should serialize to JSON with all fields', () {
        final model = ConversationModel.fromJson(testConversationJson);
        final json = model.toJson();

        expect(json['documentId'], 'conv-123');
        expect(json['type'], 'direct');
        expect(json['participantIds'], ['user-123', 'user-456']);
        expect(json['participants'], isA<List>());
        expect(json['lastMessage'], isA<Map<String, dynamic>>());
        expect(json['lastUpdatedAt'], '2024-01-01T12:30:00.000');
        expect(json['initiatedAt'], '2024-01-01T10:00:00.000');
        expect(json['unreadCount'], {'user-123': 0, 'user-456': 3});
        expect(json['translationEnabled'], true);
        expect(json['autoDetectLanguage'], true);
        expect(json['groupName'], 'Team Chat');
        expect(json['groupImage'], 'https://example.com/group.jpg');
        expect(json['adminIds'], ['user-123']);
      });

      test('should exclude null optional fields', () {
        final minimalModel = ConversationModel(
          documentId: 'conv-123',
          type: 'direct',
          participantIds: const ['user-123', 'user-456'],
          participants: const [
            ParticipantModel(
              uid: 'user-123',
              name: 'John Doe',
              preferredLanguage: 'en',
            ),
          ],
          lastUpdatedAt: testTimestamp,
          initiatedAt: testTimestamp,
          unreadCount: const {},
          translationEnabled: false,
          autoDetectLanguage: false,
        );

        final json = minimalModel.toJson();

        expect(json.containsKey('lastMessage'), false);
        expect(json.containsKey('groupName'), false);
        expect(json.containsKey('groupImage'), false);
        expect(json.containsKey('adminIds'), false);
      });

      test('should maintain data after round-trip serialization', () {
        final originalJson = testConversationJson;
        final model = ConversationModel.fromJson(originalJson);
        final serializedJson = model.toJson();
        final deserializedModel = ConversationModel.fromJson(serializedJson);

        expect(deserializedModel.documentId, model.documentId);
        expect(deserializedModel.type, model.type);
        expect(deserializedModel.participantIds, model.participantIds);
        expect(
          deserializedModel.participants.length,
          model.participants.length,
        );
        expect(deserializedModel.lastMessage?.text, model.lastMessage?.text);
        expect(deserializedModel.lastUpdatedAt, model.lastUpdatedAt);
        expect(deserializedModel.unreadCount, model.unreadCount);
      });
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        final entity = Conversation(
          documentId: 'conv-123',
          type: 'direct',
          participantIds: const ['user-123', 'user-456'],
          participants: const [
            Participant(
              uid: 'user-123',
              name: 'John Doe',
              preferredLanguage: 'en',
            ),
          ],
          lastUpdatedAt: testTimestamp,
          initiatedAt: testTimestamp,
          unreadCount: const {},
          translationEnabled: true,
          autoDetectLanguage: true,
        );

        final model = ConversationModel.fromEntity(entity);

        expect(model.documentId, entity.documentId);
        expect(model.type, entity.type);
        expect(model.participantIds, entity.participantIds);
        expect(model.participants, entity.participants);
      });
    });

    group('toEntity', () {
      test('should convert model to entity', () {
        final model = ConversationModel.fromJson(testConversationJson);
        final entity = model.toEntity();

        expect(entity, isA<Conversation>());
        expect(entity.documentId, model.documentId);
        expect(entity.type, model.type);
        expect(entity.participantIds, model.participantIds);
        expect(entity.participants, model.participants);
      });
    });

    group('copyWith', () {
      test('should create a copy with updated fields', () {
        final model = ConversationModel.fromJson(testConversationJson);
        final updated = model.copyWith(
          translationEnabled: false,
          groupName: 'Updated Team',
        );

        expect(updated, isA<ConversationModel>());
        expect(updated.translationEnabled, false);
        expect(updated.groupName, 'Updated Team');
        expect(updated.documentId, model.documentId);
        expect(updated.type, model.type);
      });
    });
  });

  group('ParticipantModel', () {
    const testParticipant = ParticipantModel(
      uid: 'user-123',
      name: 'John Doe',
      imageUrl: 'https://example.com/john.jpg',
      preferredLanguage: 'en',
    );

    final testParticipantJson = {
      'uid': 'user-123',
      'name': 'John Doe',
      'imageUrl': 'https://example.com/john.jpg',
      'preferredLanguage': 'en',
    };

    group('fromJson', () {
      test('should deserialize from JSON', () {
        final model = ParticipantModel.fromJson(testParticipantJson);

        expect(model.uid, 'user-123');
        expect(model.name, 'John Doe');
        expect(model.imageUrl, 'https://example.com/john.jpg');
        expect(model.preferredLanguage, 'en');
      });

      test('should handle null imageUrl', () {
        final jsonWithoutImage = {
          'uid': 'user-123',
          'name': 'John Doe',
          'preferredLanguage': 'en',
        };

        final model = ParticipantModel.fromJson(jsonWithoutImage);

        expect(model.imageUrl, isNull);
      });
    });

    group('toJson', () {
      test('should serialize to JSON', () {
        final json = testParticipant.toJson();

        expect(json['uid'], 'user-123');
        expect(json['name'], 'John Doe');
        expect(json['imageUrl'], 'https://example.com/john.jpg');
        expect(json['preferredLanguage'], 'en');
      });

      test('should exclude null imageUrl', () {
        const participantWithoutImage = ParticipantModel(
          uid: 'user-123',
          name: 'John Doe',
          preferredLanguage: 'en',
        );

        final json = participantWithoutImage.toJson();

        expect(json.containsKey('imageUrl'), false);
      });

      test('should maintain data after round-trip', () {
        final json = testParticipant.toJson();
        final deserialized = ParticipantModel.fromJson(json);

        expect(deserialized.uid, testParticipant.uid);
        expect(deserialized.name, testParticipant.name);
        expect(deserialized.imageUrl, testParticipant.imageUrl);
        expect(
          deserialized.preferredLanguage,
          testParticipant.preferredLanguage,
        );
      });
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        const entity = Participant(
          uid: 'user-123',
          name: 'John Doe',
          preferredLanguage: 'en',
        );

        final model = ParticipantModel.fromEntity(entity);

        expect(model.uid, entity.uid);
        expect(model.name, entity.name);
        expect(model.preferredLanguage, entity.preferredLanguage);
      });
    });

    group('toEntity', () {
      test('should convert model to entity', () {
        final entity = testParticipant.toEntity();

        expect(entity, isA<Participant>());
        expect(entity.uid, testParticipant.uid);
        expect(entity.name, testParticipant.name);
      });
    });
  });

  group('LastMessageModel', () {
    final testTimestamp = DateTime(2024, 1, 1, 12, 30);

    final testLastMessage = LastMessageModel(
      text: 'Hello!',
      senderId: 'user-123',
      timestamp: testTimestamp,
      type: 'text',
      translations: const {'es': '¡Hola!'},
    );

    final testLastMessageJson = {
      'text': 'Hello!',
      'senderId': 'user-123',
      'senderName': 'John Doe',
      'timestamp': '2024-01-01T12:30:00.000',
      'type': 'text',
      'translations': {'es': '¡Hola!'},
    };

    group('fromJson', () {
      test('should deserialize from JSON', () {
        final model = LastMessageModel.fromJson(testLastMessageJson);

        expect(model.text, 'Hello!');
        expect(model.senderId, 'user-123');
        expect(model.senderName, 'John Doe');
        expect(model.timestamp, testTimestamp);
        expect(model.type, 'text');
        expect(model.translations, {'es': '¡Hola!'});
      });

      test('should handle null translations', () {
        final jsonWithoutTranslations = {
          'text': 'Hello!',
          'senderId': 'user-123',
          'senderName': 'John Doe',
          'timestamp': '2024-01-01T12:30:00.000',
          'type': 'text',
        };

        final model = LastMessageModel.fromJson(jsonWithoutTranslations);

        expect(model.translations, isNull);
      });
    });

    group('toJson', () {
      test('should serialize to JSON', () {
        final json = testLastMessage.toJson();

        expect(json['text'], 'Hello!');
        expect(json['senderId'], 'user-123');
        expect(json['senderName'], 'John Doe');
        expect(json['timestamp'], '2024-01-01T12:30:00.000');
        expect(json['type'], 'text');
        expect(json['translations'], {'es': '¡Hola!'});
      });

      test('should exclude null translations', () {
        final lastMessageWithoutTranslations = LastMessageModel(
          text: 'Hello!',
          senderId: 'user-123',
          timestamp: testTimestamp,
          type: 'text',
        );

        final json = lastMessageWithoutTranslations.toJson();

        expect(json.containsKey('translations'), false);
      });

      test('should maintain data after round-trip', () {
        final json = testLastMessage.toJson();
        final deserialized = LastMessageModel.fromJson(json);

        expect(deserialized.text, testLastMessage.text);
        expect(deserialized.senderId, testLastMessage.senderId);
        expect(deserialized.timestamp, testLastMessage.timestamp);
      });
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        final entity = LastMessage(
          text: 'Hello!',
          senderId: 'user-123',
          timestamp: testTimestamp,
          type: 'text',
        );

        final model = LastMessageModel.fromEntity(entity);

        expect(model.text, entity.text);
        expect(model.senderId, entity.senderId);
        expect(model.timestamp, entity.timestamp);
      });
    });

    group('toEntity', () {
      test('should convert model to entity', () {
        final entity = testLastMessage.toEntity();

        expect(entity, isA<LastMessage>());
        expect(entity.text, testLastMessage.text);
        expect(entity.senderId, testLastMessage.senderId);
      });
    });
  });
}
