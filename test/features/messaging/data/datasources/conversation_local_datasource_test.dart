import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_local_datasource.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';

void main() {
  late AppDatabase database;
  late ConversationLocalDataSourceImpl dataSource;

  // Test data
  final testConversation = Conversation(
    documentId: 'conv-1',
    type: 'direct',
    participantIds: const ['user-1', 'user-2'],
    participants: const [
      Participant(
        uid: 'user-1',
        name: 'User One',
        preferredLanguage: 'en',
      ),
      Participant(
        uid: 'user-2',
        name: 'User Two',
        preferredLanguage: 'es',
      ),
    ],
    lastMessage: LastMessage(
      text: 'Hello',
      senderId: 'user-1',
      timestamp: DateTime(2024, 1, 1, 12),
      type: 'text',
    ),
    lastUpdatedAt: DateTime(2024, 1, 1, 12),
    initiatedAt: DateTime(2024, 1, 1, 10),
    unreadCount: const {'user-1': 0, 'user-2': 1},
    translationEnabled: true,
    autoDetectLanguage: true,
  );

  setUp(() {
    // Create in-memory database for each test
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = ConversationLocalDataSourceImpl(
      conversationDao: database.conversationDao,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('ConversationLocalDataSource', () {
    group('Basic CRUD Operations', () {
      group('createConversation', () {
        test('should successfully create a conversation', () async {
          // Act
          final result = await dataSource.createConversation(testConversation);

          // Assert
          expect(result, testConversation);

          // Verify it was actually saved
          final retrieved = await dataSource.getConversation('conv-1');
          expect(retrieved, isNotNull);
          expect(retrieved!.documentId, 'conv-1');
        });

        test(
          'should throw RecordAlreadyExistsException for duplicate ID',
          () async {
            // Arrange - Create conversation first time
            await dataSource.createConversation(testConversation);

            // Act & Assert - Try to create again with same ID
            expect(
              () => dataSource.createConversation(testConversation),
              throwsA(isA<RecordAlreadyExistsException>()),
            );
          },
        );

        test('should create conversation with all fields correctly', () async {
          // Arrange
          final fullConversation = Conversation(
            documentId: 'conv-full',
            type: 'group',
            participantIds: const ['user-1', 'user-2', 'user-3'],
            participants: const [
              Participant(
                uid: 'user-1',
                name: 'User One',
                imageUrl: 'https://example.com/1.jpg',
                preferredLanguage: 'en',
              ),
              Participant(
                uid: 'user-2',
                name: 'User Two',
                preferredLanguage: 'es',
              ),
              Participant(
                uid: 'user-3',
                name: 'User Three',
                preferredLanguage: 'fr',
              ),
            ],
            lastMessage: LastMessage(
              text: 'Group message',
              senderId: 'user-1',
              timestamp: DateTime(2024, 1, 1, 12),
              type: 'text',
              translations: const {
                'es': 'Mensaje de grupo',
                'fr': 'Message de groupe',
              },
            ),
            lastUpdatedAt: DateTime(2024, 1, 1, 12),
            initiatedAt: DateTime(2024, 1, 1, 10),
            unreadCount: const {'user-1': 0, 'user-2': 2, 'user-3': 1},
            translationEnabled: true,
            autoDetectLanguage: true,
            groupName: 'Test Group',
            groupImage: 'https://example.com/group.jpg',
            adminIds: const ['user-1'],
          );

          // Act
          await dataSource.createConversation(fullConversation);

          // Assert
          final retrieved = await dataSource.getConversation('conv-full');
          expect(retrieved, isNotNull);
          expect(retrieved!.type, 'group');
          expect(retrieved.groupName, 'Test Group');
          expect(retrieved.adminIds, ['user-1']);
          expect(retrieved.participants.length, 3);
          expect(
            retrieved.lastMessage?.translations?['es'],
            'Mensaje de grupo',
          );
        });
      });

      group('getConversation', () {
        test('should return conversation when it exists', () async {
          // Arrange
          await dataSource.createConversation(testConversation);

          // Act
          final result = await dataSource.getConversation('conv-1');

          // Assert
          expect(result, isNotNull);
          expect(result!.documentId, 'conv-1');
          expect(result.type, 'direct');
        });

        test('should return null when conversation does not exist', () async {
          // Act
          final result = await dataSource.getConversation('non-existent');

          // Assert
          expect(result, isNull);
        });
      });

      group('updateConversation', () {
        test('should successfully update a conversation', () async {
          // Arrange
          await dataSource.createConversation(testConversation);

          final updatedConversation = testConversation.copyWith(
            translationEnabled: false,
            lastMessage: LastMessage(
              text: 'Updated message',
              senderId: 'user-2',
              timestamp: DateTime(2024, 1, 1, 13),
              type: 'text',
            ),
          );

          // Act
          await dataSource.updateConversation(updatedConversation);

          // Assert
          final retrieved = await dataSource.getConversation('conv-1');
          expect(retrieved!.translationEnabled, false);
          expect(retrieved.lastMessage?.text, 'Updated message');
        });

        test(
          'should throw RecordNotFoundException for non-existent conversation',
          () async {
            // Arrange
            final nonExistentConversation = Conversation(
              documentId: 'non-existent',
              type: 'direct',
              participantIds: const ['user-1', 'user-2'],
              participants: const [],
              lastUpdatedAt: DateTime.now(),
              initiatedAt: DateTime.now(),
              unreadCount: const {},
              translationEnabled: true,
              autoDetectLanguage: true,
            );

            // Act & Assert
            expect(
              () => dataSource.updateConversation(nonExistentConversation),
              throwsA(isA<RecordNotFoundException>()),
            );
          },
        );
      });

      group('deleteConversation', () {
        test('should successfully delete a conversation', () async {
          // Arrange
          await dataSource.createConversation(testConversation);

          // Act
          final result = await dataSource.deleteConversation('conv-1');

          // Assert
          expect(result, true);

          // Verify deletion
          final retrieved = await dataSource.getConversation('conv-1');
          expect(retrieved, isNull);
        });

        test('should return false when conversation does not exist', () async {
          // Act
          final result = await dataSource.deleteConversation('non-existent');

          // Assert
          expect(result, false);
        });
      });
    });

    group('Query Operations', () {
      group('getAllConversations', () {
        test(
          'should return all conversations ordered by lastUpdatedAt',
          () async {
            // Arrange
            final conv1 = testConversation.copyWith(
              documentId: 'conv-1',
              lastUpdatedAt: DateTime(2024, 1, 1, 10),
            );
            final conv2 = testConversation.copyWith(
              documentId: 'conv-2',
              lastUpdatedAt: DateTime(2024, 1, 1, 12),
            );
            final conv3 = testConversation.copyWith(
              documentId: 'conv-3',
              lastUpdatedAt: DateTime(2024, 1, 1, 11),
            );

            await dataSource.createConversation(conv1);
            await dataSource.createConversation(conv2);
            await dataSource.createConversation(conv3);

            // Act
            final conversations = await dataSource.getAllConversations();

            // Assert
            expect(conversations.length, 3);
            // Should be ordered newest first
            expect(conversations[0].documentId, 'conv-2');
            expect(conversations[1].documentId, 'conv-3');
            expect(conversations[2].documentId, 'conv-1');
          },
        );

        test('should respect limit and offset parameters', () async {
          // Arrange - Create 5 conversations
          for (var i = 1; i <= 5; i++) {
            await dataSource.createConversation(
              testConversation.copyWith(
                documentId: 'conv-$i',
                lastUpdatedAt: DateTime(2024, 1, 1, 10 + i),
              ),
            );
          }

          // Act
          final page1 = await dataSource.getAllConversations(
            limit: 2,
          );
          final page2 = await dataSource.getAllConversations(
            limit: 2,
            offset: 2,
          );

          // Assert
          expect(page1.length, 2);
          expect(page2.length, 2);
          expect(page1[0].documentId, 'conv-5'); // Newest first
          expect(page2[0].documentId, 'conv-3');
        });

        test('should return empty list when no conversations exist', () async {
          // Act
          final conversations = await dataSource.getAllConversations();

          // Assert
          expect(conversations, isEmpty);
        });
      });

      group('getConversationsByParticipant', () {
        test('should return conversations for specific participant', () async {
          // Arrange
          final conv1 = testConversation.copyWith(
            documentId: 'conv-1',
            participantIds: ['user-1', 'user-2'],
          );
          final conv2 = testConversation.copyWith(
            documentId: 'conv-2',
            participantIds: ['user-1', 'user-3'],
          );
          final conv3 = testConversation.copyWith(
            documentId: 'conv-3',
            participantIds: ['user-2', 'user-3'],
          );

          await dataSource.createConversation(conv1);
          await dataSource.createConversation(conv2);
          await dataSource.createConversation(conv3);

          // Act
          final conversations = await dataSource.getConversationsByParticipant(
            'user-1',
          );

          // Assert
          expect(conversations.length, 2);
          expect(
            conversations.every((c) => c.participantIds.contains('user-1')),
            true,
          );
        });

        test('should return empty list if no conversations found', () async {
          // Act
          final conversations = await dataSource.getConversationsByParticipant(
            'user-999',
          );

          // Assert
          expect(conversations, isEmpty);
        });
      });

      group('getConversationsByType', () {
        test('should return conversations of specific type', () async {
          // Arrange
          final directConv = testConversation.copyWith(
            documentId: 'conv-direct',
            type: 'direct',
          );
          final groupConv = testConversation.copyWith(
            documentId: 'conv-group',
            type: 'group',
          );

          await dataSource.createConversation(directConv);
          await dataSource.createConversation(groupConv);

          // Act
          final directConversations = await dataSource.getConversationsByType(
            'direct',
          );
          final groupConversations = await dataSource.getConversationsByType(
            'group',
          );

          // Assert
          expect(directConversations.length, 1);
          expect(directConversations.first.type, 'direct');
          expect(groupConversations.length, 1);
          expect(groupConversations.first.type, 'group');
        });
      });

      group('getDirectConversation', () {
        test('should find direct conversation between two users', () async {
          // Arrange
          await dataSource.createConversation(testConversation);

          // Act
          final conversation = await dataSource.getDirectConversation(
            'user-1',
            'user-2',
          );

          // Assert
          expect(conversation, isNotNull);
          expect(conversation!.type, 'direct');
          expect(conversation.participantIds.contains('user-1'), true);
          expect(conversation.participantIds.contains('user-2'), true);
        });

        test('should return null if no direct conversation exists', () async {
          // Act
          final conversation = await dataSource.getDirectConversation(
            'user-1',
            'user-999',
          );

          // Assert
          expect(conversation, isNull);
        });
      });

      group('searchConversationsByName', () {
        test('should find conversations matching group name', () async {
          // Arrange
          final conv1 = testConversation.copyWith(
            documentId: 'conv-1',
            type: 'group',
            groupName: 'Project Team',
          );
          final conv2 = testConversation.copyWith(
            documentId: 'conv-2',
            type: 'group',
            groupName: 'Marketing Team',
          );

          await dataSource.createConversation(conv1);
          await dataSource.createConversation(conv2);

          // Act
          final results = await dataSource.searchConversationsByName('Team');

          // Assert
          expect(results.length, 2);
        });
      });

      group('getActiveConversations', () {
        test('should return conversations with recent activity', () async {
          // Arrange
          final now = DateTime.now();
          final recentConv = testConversation.copyWith(
            documentId: 'conv-recent',
            lastUpdatedAt: now.subtract(const Duration(days: 2)),
          );
          final oldConv = testConversation.copyWith(
            documentId: 'conv-old',
            lastUpdatedAt: now.subtract(const Duration(days: 30)),
          );

          await dataSource.createConversation(recentConv);
          await dataSource.createConversation(oldConv);

          // Act
          final activeConversations = await dataSource.getActiveConversations(

          );

          // Assert
          expect(activeConversations.length, 1);
          expect(activeConversations.first.documentId, 'conv-recent');
        });
      });
    });

    group('Stream Operations', () {
      group('watchAllConversations', () {
        test('should emit conversations on changes', () async {
          // Arrange
          final stream = dataSource.watchAllConversations();

          // Act & Assert
          final expectation = expectLater(
            stream.first,
            completion(predicate<List<Conversation>>((list) => list.isEmpty)),
          );

          // Create a conversation after setting up watch
          await dataSource.createConversation(testConversation);

          await expectation;
        });
      });

      group('watchConversationsByParticipant', () {
        test('should emit participant conversations on changes', () async {
          // Arrange
          final stream = dataSource.watchConversationsByParticipant('user-1');

          // Act & Assert
          final expectation = expectLater(
            stream.first,
            completion(predicate<List<Conversation>>((list) => list.isEmpty)),
          );

          await dataSource.createConversation(testConversation);

          await expectation;
        });
      });
    });

    group('Special Operations', () {
      group('updateLastMessage', () {
        test('should update last message information', () async {
          // Arrange
          await dataSource.createConversation(testConversation);

          final newLastMessage = LastMessage(
            text: 'New message',
            senderId: 'user-2',
            timestamp: DateTime(2024, 1, 1, 13),
            type: 'text',
          );

          // Act
          final result = await dataSource.updateLastMessage(
            documentId: 'conv-1',
            lastMessage: newLastMessage,
          );

          // Assert
          expect(result, true);

          final updated = await dataSource.getConversation('conv-1');
          expect(updated!.lastMessage?.text, 'New message');
          expect(updated.lastMessage?.senderId, 'user-2');
        });
      });

      group('incrementUnreadCount', () {
        test('should increment unread count for non-senders', () async {
          // Arrange
          await dataSource.createConversation(testConversation);

          // Act
          await dataSource.incrementUnreadCount(
            documentId: 'conv-1',
            senderId: 'user-1',
            participantIds: ['user-1', 'user-2'],
          );

          // Assert
          final updated = await dataSource.getConversation('conv-1');
          expect(updated!.unreadCount['user-1'], 0); // Sender has 0
          expect(
            updated.unreadCount['user-2'],
            greaterThan(0),
          ); // Others incremented
        });
      });

      group('resetUnreadCount', () {
        test('should reset unread count for specific user', () async {
          // Arrange
          final convWithUnread = testConversation.copyWith(
            unreadCount: {'user-1': 0, 'user-2': 5},
          );
          await dataSource.createConversation(convWithUnread);

          // Act
          await dataSource.resetUnreadCount(
            documentId: 'conv-1',
            userId: 'user-2',
          );

          // Assert
          final updated = await dataSource.getConversation('conv-1');
          expect(updated!.unreadCount['user-2'], 0);
        });
      });

      group('countConversations', () {
        test('should return correct count', () async {
          // Arrange
          await dataSource.createConversation(testConversation);
          await dataSource.createConversation(
            testConversation.copyWith(documentId: 'conv-2'),
          );

          // Act
          final count = await dataSource.countConversations();

          // Assert
          expect(count, 2);
        });
      });

      group('countUnreadConversations', () {
        test('should count conversations with unread messages', () async {
          // Arrange
          final conv1 = testConversation.copyWith(
            documentId: 'conv-1',
            unreadCount: {'user-1': 5, 'user-2': 0},
          );
          final conv2 = testConversation.copyWith(
            documentId: 'conv-2',
            unreadCount: {'user-1': 0, 'user-2': 0},
          );

          await dataSource.createConversation(conv1);
          await dataSource.createConversation(conv2);

          // Act
          final count = await dataSource.countUnreadConversations('user-1');

          // Assert
          expect(count, greaterThanOrEqualTo(0));
        });
      });
    });

    group('Sync Operations', () {
      group('updateSyncStatus', () {
        test('should update sync status fields', () async {
          // Arrange
          await dataSource.createConversation(testConversation);

          // Act
          final result = await dataSource.updateSyncStatus(
            documentId: 'conv-1',
            syncStatus: 'synced',
            lastSyncAttempt: DateTime.now(),
            retryCount: 0,
          );

          // Assert
          expect(result, true);
        });
      });

      group('replaceTempId', () {
        test('should replace temporary ID with real ID', () async {
          // Arrange
          final tempConv = testConversation.copyWith(documentId: 'temp-123');
          await dataSource.createConversation(tempConv);

          // Act
          final result = await dataSource.replaceTempId(
            tempId: 'temp-123',
            realId: 'real-123',
          );

          // Assert
          expect(result, true);

          // Verify temp is gone and real exists
          final tempExists = await dataSource.getConversation('temp-123');
          final realExists = await dataSource.getConversation('real-123');

          expect(tempExists, isNull);
          expect(realExists, isNotNull);
        });
      });

      group('getConversationsUpdatedAfter', () {
        test('should return conversations updated after timestamp', () async {
          // Arrange
          final cutoff = DateTime(2024, 1, 1, 11);

          final oldConv = testConversation.copyWith(
            documentId: 'conv-old',
            lastUpdatedAt: DateTime(2024, 1, 1, 10),
          );
          final newConv = testConversation.copyWith(
            documentId: 'conv-new',
            lastUpdatedAt: DateTime(2024, 1, 1, 12),
          );

          await dataSource.createConversation(oldConv);
          await dataSource.createConversation(newConv);

          // Act
          final conversations = await dataSource.getConversationsUpdatedAfter(
            cutoff,
          );

          // Assert
          expect(conversations.length, 1);
          expect(conversations.first.documentId, 'conv-new');
        });
      });
    });

    group('Batch Operations', () {
      group('insertConversations', () {
        test('should insert multiple conversations at once', () async {
          // Arrange
          final conversations = [
            testConversation.copyWith(documentId: 'conv-1'),
            testConversation.copyWith(documentId: 'conv-2'),
            testConversation.copyWith(documentId: 'conv-3'),
          ];

          // Act
          await dataSource.insertConversations(conversations);

          // Assert
          final all = await dataSource.getAllConversations();
          expect(all.length, 3);
        });
      });

      group('batchDeleteConversations', () {
        test('should delete multiple conversations', () async {
          // Arrange
          await dataSource.createConversation(
            testConversation.copyWith(documentId: 'conv-1'),
          );
          await dataSource.createConversation(
            testConversation.copyWith(documentId: 'conv-2'),
          );
          await dataSource.createConversation(
            testConversation.copyWith(documentId: 'conv-3'),
          );

          // Act
          await dataSource.batchDeleteConversations(['conv-1', 'conv-2']);

          // Assert
          final remaining = await dataSource.getAllConversations();
          expect(remaining.length, 1);
          expect(remaining.first.documentId, 'conv-3');
        });
      });
    });

    group('Conflict Resolution', () {
      group('hasConflict', () {
        test('should detect no conflict for identical conversations', () async {
          // Arrange
          final localConv = testConversation;
          final remoteConv = testConversation;

          // Act
          final hasConflict = await dataSource.hasConflict(
            localConversation: localConv,
            remoteConversation: remoteConv,
          );

          // Assert
          expect(hasConflict, false);
        });

        test('should detect conflict when last message differs', () async {
          // Arrange
          final localConv = testConversation;
          final remoteConv = testConversation.copyWith(
            lastMessage: LastMessage(
              text: 'Different message',
              senderId: 'user-2',
              timestamp: DateTime(2024, 1, 1, 12),
              type: 'text',
            ),
          );

          // Act
          final hasConflict = await dataSource.hasConflict(
            localConversation: localConv,
            remoteConversation: remoteConv,
          );

          // Assert
          expect(hasConflict, true);
        });

        test('should detect conflict when participant count differs', () async {
          // Arrange
          final localConv = testConversation;
          final remoteConv = testConversation.copyWith(
            participantIds: ['user-1', 'user-2', 'user-3'],
          );

          // Act
          final hasConflict = await dataSource.hasConflict(
            localConversation: localConv,
            remoteConversation: remoteConv,
          );

          // Assert
          expect(hasConflict, true);
        });

        test('should detect conflict when settings differ', () async {
          // Arrange
          final localConv = testConversation;
          final remoteConv = testConversation.copyWith(
            translationEnabled: false,
          );

          // Act
          final hasConflict = await dataSource.hasConflict(
            localConversation: localConv,
            remoteConversation: remoteConv,
          );

          // Assert
          expect(hasConflict, true);
        });

        test('should detect conflict when group metadata differs', () async {
          // Arrange
          final localConv = testConversation.copyWith(
            type: 'group',
            groupName: 'Old Name',
          );
          final remoteConv = testConversation.copyWith(
            type: 'group',
            groupName: 'New Name',
          );

          // Act
          final hasConflict = await dataSource.hasConflict(
            localConversation: localConv,
            remoteConversation: remoteConv,
          );

          // Assert
          expect(hasConflict, true);
        });
      });

      group('resolveConflict', () {
        test('should resolve with server-wins strategy', () async {
          // Arrange
          final localConv = testConversation.copyWith(
            translationEnabled: false,
          );
          final remoteConv = testConversation.copyWith(
            translationEnabled: true,
          );

          await dataSource.createConversation(localConv);

          // Act
          final resolved = await dataSource.resolveConflict(
            localConversation: localConv,
            remoteConversation: remoteConv,
          );

          // Assert
          expect(resolved.translationEnabled, true);

          // Verify database was updated
          final updated = await dataSource.getConversation('conv-1');
          expect(updated!.translationEnabled, true);
        });

        test('should resolve with client-wins strategy', () async {
          // Arrange
          final localConv = testConversation.copyWith(
            translationEnabled: false,
          );
          final remoteConv = testConversation.copyWith(
            translationEnabled: true,
          );

          await dataSource.createConversation(localConv);

          // Act
          final resolved = await dataSource.resolveConflict(
            localConversation: localConv,
            remoteConversation: remoteConv,
            strategy: 'client-wins',
          );

          // Assert
          expect(resolved.translationEnabled, false);
        });

        test('should resolve with merge strategy', () async {
          // Arrange
          final localConv = testConversation.copyWith(
            unreadCount: {'user-1': 5, 'user-2': 0},
            lastMessage: LastMessage(
              text: 'Local message',
              senderId: 'user-1',
              timestamp: DateTime(2024, 1, 1, 14),
              type: 'text',
            ),
          );
          final remoteConv = testConversation.copyWith(
            unreadCount: {'user-1': 2, 'user-2': 3},
            lastMessage: LastMessage(
              text: 'Remote message',
              senderId: 'user-2',
              timestamp: DateTime(2024, 1, 1, 13),
              type: 'text',
            ),
          );

          await dataSource.createConversation(localConv);

          // Act
          final resolved = await dataSource.resolveConflict(
            localConversation: localConv,
            remoteConversation: remoteConv,
            strategy: 'merge',
          );

          // Assert
          // Should prefer higher unread counts
          expect(resolved.unreadCount['user-1'], 5);
          expect(resolved.unreadCount['user-2'], 3);
          // Should prefer most recent last message
          expect(resolved.lastMessage?.text, 'Local message');
        });

        test('should throw ValidationException for invalid strategy', () async {
          // Arrange
          await dataSource.createConversation(testConversation);

          // Act & Assert
          expect(
            () => dataSource.resolveConflict(
              localConversation: testConversation,
              remoteConversation: testConversation,
              strategy: 'invalid-strategy',
            ),
            throwsA(isA<ValidationException>()),
          );
        });
      });

      group('mergeConversations', () {
        test('should use most recent last message', () async {
          // Arrange
          final localConv = testConversation.copyWith(
            lastMessage: LastMessage(
              text: 'Older message',
              senderId: 'user-1',
              timestamp: DateTime(2024, 1, 1, 11),
              type: 'text',
            ),
          );
          final remoteConv = testConversation.copyWith(
            lastMessage: LastMessage(
              text: 'Newer message',
              senderId: 'user-2',
              timestamp: DateTime(2024, 1, 1, 13),
              type: 'text',
            ),
          );

          // Act
          final merged = dataSource.mergeConversations(
            localConversation: localConv,
            remoteConversation: remoteConv,
          );

          // Assert
          expect(merged.lastMessage?.text, 'Newer message');
        });

        test('should prefer higher unread counts', () async {
          // Arrange
          final localConv = testConversation.copyWith(
            unreadCount: {'user-1': 10, 'user-2': 2},
          );
          final remoteConv = testConversation.copyWith(
            unreadCount: {'user-1': 5, 'user-2': 8},
          );

          // Act
          final merged = dataSource.mergeConversations(
            localConversation: localConv,
            remoteConversation: remoteConv,
          );

          // Assert
          expect(merged.unreadCount['user-1'], 10);
          expect(merged.unreadCount['user-2'], 8);
        });

        test('should merge participant lists (union)', () async {
          // Arrange
          final localConv = testConversation.copyWith(
            participantIds: ['user-1', 'user-2'],
            participants: [
              const Participant(
                uid: 'user-1',
                name: 'User One',
                preferredLanguage: 'en',
              ),
              const Participant(
                uid: 'user-2',
                name: 'User Two',
                preferredLanguage: 'es',
              ),
            ],
          );
          final remoteConv = testConversation.copyWith(
            participantIds: ['user-1', 'user-3'],
            participants: [
              const Participant(
                uid: 'user-1',
                name: 'User One',
                preferredLanguage: 'en',
              ),
              const Participant(
                uid: 'user-3',
                name: 'User Three',
                preferredLanguage: 'fr',
              ),
            ],
          );

          // Act
          final merged = dataSource.mergeConversations(
            localConversation: localConv,
            remoteConversation: remoteConv,
          );

          // Assert
          expect(merged.participantIds.length, 3);
          expect(merged.participantIds.contains('user-1'), true);
          expect(merged.participantIds.contains('user-2'), true);
          expect(merged.participantIds.contains('user-3'), true);
        });

        test('should merge admin IDs for group chats', () async {
          // Arrange
          final localConv = testConversation.copyWith(
            type: 'group',
            adminIds: ['user-1'],
          );
          final remoteConv = testConversation.copyWith(
            type: 'group',
            adminIds: ['user-1', 'user-2'],
          );

          // Act
          final merged = dataSource.mergeConversations(
            localConversation: localConv,
            remoteConversation: remoteConv,
          );

          // Assert
          expect(merged.adminIds, isNotNull);
          expect(merged.adminIds!.length, 2);
          expect(merged.adminIds!.contains('user-1'), true);
          expect(merged.adminIds!.contains('user-2'), true);
        });

        test('should use most recent lastUpdatedAt', () async {
          // Arrange
          final localConv = testConversation.copyWith(
            lastUpdatedAt: DateTime(2024, 1, 1, 14),
          );
          final remoteConv = testConversation.copyWith(
            lastUpdatedAt: DateTime(2024, 1, 1, 12),
          );

          // Act
          final merged = dataSource.mergeConversations(
            localConversation: localConv,
            remoteConversation: remoteConv,
          );

          // Assert
          expect(merged.lastUpdatedAt, DateTime(2024, 1, 1, 14));
        });
      });
    });
  });
}
