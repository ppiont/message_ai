import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/models/message_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MessageRemoteDataSourceImpl dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = MessageRemoteDataSourceImpl(firestore: fakeFirestore);
  });

  // Test data
  final testMessage = MessageModel(
    id: 'msg-123',
    senderId: 'user-1',
    senderName: 'Test User',
    text: 'Hello, world!',
    timestamp: DateTime(2024, 1, 1, 12),
    type: 'text',
    status: 'sent',
    metadata: const MessageMetadataModel(
      edited: false,
      deleted: false,
      priority: 'normal',
      hasIdioms: false,
    ),
  );

  final testMessage2 = MessageModel(
    id: 'msg-456',
    senderId: 'user-2',
    senderName: 'Test User 2',
    text: 'Hi there!',
    timestamp: DateTime(2024, 1, 1, 12, 5),
    type: 'text',
    status: 'sent',
    metadata: const MessageMetadataModel(
      edited: false,
      deleted: false,
      priority: 'normal',
      hasIdioms: false,
    ),
  );

  group('MessageRemoteDataSourceImpl', () {
    group('createMessage', () {
      test('should create message document in Firestore', () async {
        // Act
        final result = await dataSource.createMessage('conv-123', testMessage);

        // Assert
        expect(result, testMessage);

        // Verify in Firestore
        final doc = await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .get();

        expect(doc.exists, true);
        expect(doc.data()?['text'], 'Hello, world!');
        expect(doc.data()?['senderId'], 'user-1');
      });

      test('should throw RecordAlreadyExistsException when message exists',
          () async {
        // Arrange - create message first
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .set(testMessage.toJson());

        // Act & Assert
        expect(
          () => dataSource.createMessage('conv-123', testMessage),
          throwsA(isA<RecordAlreadyExistsException>()),
        );
      });
    });

    group('getMessageById', () {
      test('should return message when it exists', () async {
        // Arrange
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .set(testMessage.toJson());

        // Act
        final result = await dataSource.getMessageById('conv-123', 'msg-123');

        // Assert
        expect(result.id, testMessage.id);
        expect(result.text, testMessage.text);
        expect(result.senderId, testMessage.senderId);
      });

      test('should throw RecordNotFoundException when message does not exist',
          () async {
        // Act & Assert
        expect(
          () => dataSource.getMessageById('conv-123', 'non-existent'),
          throwsA(isA<RecordNotFoundException>()),
        );
      });
    });

    group('getMessages', () {
      test('should return list of messages ordered by timestamp descending',
          () async {
        // Arrange - create messages in order
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .set(testMessage.toJson());

        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-456')
            .set(testMessage2.toJson());

        // Act
        final result = await dataSource.getMessages(conversationId: 'conv-123');

        // Assert
        expect(result.length, 2);
        // Should be ordered by timestamp descending (most recent first)
        expect(result[0].id, 'msg-456'); // Later timestamp
        expect(result[1].id, 'msg-123'); // Earlier timestamp
      });

      test('should return empty list when no messages exist', () async {
        // Act
        final result = await dataSource.getMessages(conversationId: 'conv-123');

        // Assert
        expect(result, isEmpty);
      });

      test('should respect limit parameter', () async {
        // Arrange - create 3 messages
        for (var i = 0; i < 3; i++) {
          await fakeFirestore
              .collection('conversations')
              .doc('conv-123')
              .collection('messages')
              .doc('msg-$i')
              .set(MessageModel(
                id: 'msg-$i',
                senderId: 'user-1',
                senderName: 'User',
                text: 'Message $i',
                timestamp: DateTime(2024, 1, 1, 12, i),
                type: 'text',
                status: 'sent',
                metadata: const MessageMetadataModel(
                  edited: false,
                  deleted: false,
                  priority: 'normal',
                  hasIdioms: false,
                ),
              ).toJson());
        }

        // Act - request only 2 messages
        final result = await dataSource.getMessages(
          conversationId: 'conv-123',
          limit: 2,
        );

        // Assert
        expect(result.length, 2);
      });

      // NOTE: Skipping timestamp filtering test due to fake_cloud_firestore limitation
      // fake_cloud_firestore doesn't support isLessThan with DateTime
      // This functionality is tested in integration tests with real Firebase
    });

    group('updateMessage', () {
      test('should update message document in Firestore', () async {
        // Arrange - create message first
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .set(testMessage.toJson());

        // Create updated message
        final updatedMessage = testMessage.copyWith(
          text: 'Updated text',
          status: 'edited',
        );

        // Act
        final result =
            await dataSource.updateMessage('conv-123', updatedMessage);

        // Assert
        expect(result.text, 'Updated text');
        expect(result.status, 'edited');

        // Verify in Firestore
        final doc = await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .get();

        expect(doc.data()?['text'], 'Updated text');
        expect(doc.data()?['status'], 'edited');
      });

      test('should throw RecordNotFoundException when message does not exist',
          () async {
        // Act & Assert
        expect(
          () => dataSource.updateMessage('conv-123', testMessage),
          throwsA(isA<RecordNotFoundException>()),
        );
      });
    });

    group('deleteMessage', () {
      test('should delete message document from Firestore', () async {
        // Arrange
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .set(testMessage.toJson());

        // Verify it exists
        var doc = await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .get();
        expect(doc.exists, true);

        // Act
        await dataSource.deleteMessage('conv-123', 'msg-123');

        // Assert - document should be deleted
        doc = await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .get();
        expect(doc.exists, false);
      });

      test('should not throw when deleting non-existent message', () async {
        // Act & Assert - should complete without error
        await dataSource.deleteMessage('conv-123', 'non-existent');
      });
    });

    group('watchMessages', () {
      test('should emit list of messages when they exist', () async {
        // Arrange
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .set(testMessage.toJson());

        // Act
        final stream = dataSource.watchMessages(conversationId: 'conv-123');

        // Assert
        await expectLater(
          stream.first,
          completion(predicate<List<MessageModel>>((messages) => messages.length == 1 && messages[0].id == 'msg-123')),
        );
      });

      test('should emit empty list when no messages exist', () async {
        // Act
        final stream = dataSource.watchMessages(conversationId: 'conv-123');

        // Assert
        await expectLater(
          stream.first,
          completion(predicate<List<MessageModel>>((messages) => messages.isEmpty)),
        );
      });

      test('should emit updated list when messages change', () async {
        // Arrange - start with one message
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .set(testMessage.toJson());

        // Act
        final stream = dataSource.watchMessages(conversationId: 'conv-123');

        // Listen to stream and track emissions
        final emissions = <List<MessageModel>>[];
        final subscription = stream.listen(emissions.add);

        // Wait for initial emission
        await Future.delayed(const Duration(milliseconds: 100));

        // Add another message
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-456')
            .set(testMessage2.toJson());

        // Wait for update
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(emissions.length, greaterThanOrEqualTo(2));
        expect(emissions.first.length, 1); // First emission: 1 message
        expect(emissions.last.length, 2); // Last emission: 2 messages

        await subscription.cancel();
      });

      test('should respect limit parameter', () async {
        // Arrange - create 3 messages
        for (var i = 0; i < 3; i++) {
          await fakeFirestore
              .collection('conversations')
              .doc('conv-123')
              .collection('messages')
              .doc('msg-$i')
              .set(MessageModel(
                id: 'msg-$i',
                senderId: 'user-1',
                senderName: 'User',
                text: 'Message $i',
                timestamp: DateTime(2024, 1, 1, 12, i),
                type: 'text',
                status: 'sent',
                metadata: const MessageMetadataModel(
                  edited: false,
                  deleted: false,
                  priority: 'normal',
                  hasIdioms: false,
                ),
              ).toJson());
        }

        // Act - watch with limit of 2
        final stream = dataSource.watchMessages(
          conversationId: 'conv-123',
          limit: 2,
        );

        // Assert
        await expectLater(
          stream.first,
          completion(predicate<List<MessageModel>>((messages) => messages.length == 2)),
        );
      });
    });

    group('markAsDelivered', () {
      test('should update message status to delivered', () async {
        // Arrange
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .set(testMessage.toJson());

        // Act
        await dataSource.markAsDelivered('conv-123', 'msg-123');

        // Assert
        final doc = await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .get();

        expect(doc.data()?['status'], 'delivered');
      });
    });

    group('markAsRead', () {
      test('should update message status to read', () async {
        // Arrange
        await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .set(testMessage.toJson());

        // Act
        await dataSource.markAsRead('conv-123', 'msg-123');

        // Assert
        final doc = await fakeFirestore
            .collection('conversations')
            .doc('conv-123')
            .collection('messages')
            .doc('msg-123')
            .get();

        expect(doc.data()?['status'], 'read');
      });
    });
  });
}
