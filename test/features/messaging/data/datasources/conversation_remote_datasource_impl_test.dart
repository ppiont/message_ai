import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/models/conversation_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ConversationRemoteDataSourceImpl dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = ConversationRemoteDataSourceImpl(firestore: fakeFirestore);
  });

  // Test data
  final testConversation = ConversationModel(
    documentId: 'conv-123',
    type: 'direct',
    participantIds: ['user-1', 'user-2'],
    participants: const [
      ParticipantModel(
        uid: 'user-1',
        name: 'User 1',
        preferredLanguage: 'en',
      ),
      ParticipantModel(
        uid: 'user-2',
        name: 'User 2',
        preferredLanguage: 'es',
      ),
    ],
    lastUpdatedAt: DateTime(2024, 1, 1, 12, 0),
    initiatedAt: DateTime(2024, 1, 1, 10, 0),
    unreadCount: const {'user-1': 0, 'user-2': 0},
    translationEnabled: false,
    autoDetectLanguage: false,
  );

  group('ConversationRemoteDataSourceImpl', () {
    group('createConversation', () {
      test('should create conversation document in Firestore', () async {
        // Act
        final result = await dataSource.createConversation(testConversation);

        // Assert
        expect(result.documentId, testConversation.documentId);

        // Verify in Firestore
        final doc = await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .get();

        expect(doc.exists, true);
        expect(doc.data()?['type'], 'direct');
        expect((doc.data()?['participantIds'] as List).length, 2);
      });

      test('should throw RecordAlreadyExistsException when conversation exists',
          () async {
        // Arrange - create conversation first
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .set(testConversation.toJson());

        // Act & Assert
        expect(
          () => dataSource.createConversation(testConversation),
          throwsA(isA<RecordAlreadyExistsException>()),
        );
      });
    });

    group('getConversationById', () {
      test('should return conversation when it exists', () async {
        // Arrange
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .set(testConversation.toJson());

        // Act
        final result = await dataSource.getConversationById('conv-123');

        // Assert
        expect(result.documentId, testConversation.documentId);
        expect(result.type, testConversation.type);
        expect(result.participantIds.length, 2);
      });

      test('should throw RecordNotFoundException when conversation does not exist',
          () async {
        // Act & Assert
        expect(
          () => dataSource.getConversationById('non-existent'),
          throwsA(isA<RecordNotFoundException>()),
        );
      });
    });

    group('getConversationsForUser', () {
      test('should return list of conversations for user', () async {
        // Arrange - create conversation
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .set(testConversation.toJson());

        // Act
        final result = await dataSource.getConversationsForUser('user-1');

        // Assert
        expect(result.length, 1);
        expect(result[0].documentId, 'conv-123');
        expect(result[0].participantIds, contains('user-1'));
      });

      test('should return empty list when no conversations exist', () async {
        // Act
        final result = await dataSource.getConversationsForUser('user-1');

        // Assert
        expect(result, isEmpty);
      });
    });

    group('updateConversation', () {
      test('should update conversation document in Firestore', () async {
        // Arrange - create conversation first
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .set(testConversation.toJson());

        // Create updated conversation
        final updatedConversation = testConversation.copyWith(
          translationEnabled: true,
          autoDetectLanguage: true,
        );

        // Act
        final result =
            await dataSource.updateConversation(updatedConversation);

        // Assert
        expect(result.translationEnabled, true);
        expect(result.autoDetectLanguage, true);

        // Verify in Firestore
        final doc = await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .get();

        expect(doc.data()?['translationEnabled'], true);
        expect(doc.data()?['autoDetectLanguage'], true);
      });

      test('should throw RecordNotFoundException when conversation does not exist',
          () async {
        // Act & Assert
        expect(
          () => dataSource.updateConversation(testConversation),
          throwsA(isA<RecordNotFoundException>()),
        );
      });
    });

    group('deleteConversation', () {
      test('should delete conversation document from Firestore', () async {
        // Arrange
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .set(testConversation.toJson());

        // Verify it exists
        var doc = await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .get();
        expect(doc.exists, true);

        // Act
        await dataSource.deleteConversation('conv-123');

        // Assert - document should be deleted
        doc = await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .get();
        expect(doc.exists, false);
      });
    });

    group('watchConversationsForUser', () {
      test('should emit list of conversations when they exist', () async {
        // Arrange
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .set(testConversation.toJson());

        // Act
        final stream = dataSource.watchConversationsForUser('user-1');

        // Assert
        await expectLater(
          stream.first,
          completion(predicate<List<ConversationModel>>((conversations) {
            return conversations.length == 1 &&
                conversations[0].documentId == 'conv-123';
          })),
        );
      });

      test('should emit empty list when no conversations exist', () async {
        // Act
        final stream = dataSource.watchConversationsForUser('user-1');

        // Assert
        await expectLater(
          stream.first,
          completion(predicate<List<ConversationModel>>((conversations) {
            return conversations.isEmpty;
          })),
        );
      });
    });

    group('findDirectConversation', () {
      test('should return conversation when it exists between two users',
          () async {
        // Arrange
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .set(testConversation.toJson());

        // Act - test both orderings
        final result1 =
            await dataSource.findDirectConversation('user-1', 'user-2');
        final result2 =
            await dataSource.findDirectConversation('user-2', 'user-1');

        // Assert - should find conversation regardless of order
        expect(result1, isNotNull);
        expect(result1!.documentId, 'conv-123');
        expect(result2, isNotNull);
        expect(result2!.documentId, 'conv-123');
      });

      test('should return null when conversation does not exist', () async {
        // Act
        final result =
            await dataSource.findDirectConversation('user-1', 'user-3');

        // Assert
        expect(result, isNull);
      });
    });

    group('updateLastMessage', () {
      test('should update lastMessage field in conversation', () async {
        // Arrange
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .set(testConversation.toJson());

        // Act
        await dataSource.updateLastMessage(
          'conv-123',
          'Hello!',
          'user-1',
          'User 1',
          DateTime(2024, 1, 1, 14, 0),
        );

        // Assert
        final doc = await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .get();

        final lastMessage = doc.data()?['lastMessage'] as Map<String, dynamic>;
        expect(lastMessage['text'], 'Hello!');
        expect(lastMessage['senderId'], 'user-1');
        expect(lastMessage['senderName'], 'User 1');
        expect(lastMessage['type'], 'text');
      });
    });

    group('updateUnreadCount', () {
      test('should update unread count for user', () async {
        // Arrange
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .set(testConversation.toJson());

        // Act
        await dataSource.updateUnreadCount('conv-123', 'user-1', 5);

        // Assert
        final doc = await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .get();

        final unreadCount = doc.data()?['unreadCount'] as Map<String, dynamic>;
        expect(unreadCount['user-1'], 5);
      });
    });
  });
}
