import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/messaging/data/services/typing_indicator_service.dart';

void main() {
  late TypingIndicatorService service;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = TypingIndicatorService(firestore: fakeFirestore);
  });

  tearDown(() {
    service.dispose();
  });

  group('TypingIndicatorService', () {
    group('setTyping', () {
      test('should create typing status document when isTyping is true',
          () async {
        // Arrange
        const conversationId = 'conv-1';
        const userId = 'user-1';
        const userName = 'User One';

        // Act
        await service.setTyping(
          conversationId: conversationId,
          userId: userId,
          userName: userName,
          isTyping: true,
        );

        // Wait for debounce
        await Future.delayed(
          TypingIndicatorService.debounceDuration + const Duration(milliseconds: 100),
        );

        // Assert
        final doc = await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc(userId)
            .get();

        expect(doc.exists, true);
        expect(doc.data()?['userId'], userId);
        expect(doc.data()?['userName'], userName);
        expect(doc.data()?['isTyping'], true);
      });

      test('should delete typing status document when isTyping is false',
          () async {
        // Arrange
        const conversationId = 'conv-1';
        const userId = 'user-1';
        const userName = 'User One';

        // First set typing to true
        await service.setTyping(
          conversationId: conversationId,
          userId: userId,
          userName: userName,
          isTyping: true,
        );

        await Future.delayed(
          TypingIndicatorService.debounceDuration + const Duration(milliseconds: 100),
        );

        // Act - Set to false
        await service.setTyping(
          conversationId: conversationId,
          userId: userId,
          userName: userName,
          isTyping: false,
        );

        // Assert
        final doc = await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc(userId)
            .get();

        expect(doc.exists, false);
      });

      test('should debounce rapid typing updates', () async {
        // Arrange
        const conversationId = 'conv-1';
        const userId = 'user-1';
        const userName = 'User One';

        // Act - Rapid typing updates
        for (int i = 0; i < 5; i++) {
          await service.setTyping(
            conversationId: conversationId,
            userId: userId,
            userName: userName,
            isTyping: true,
          );
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Assert - Should not create document yet (still debouncing)
        var doc = await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc(userId)
            .get();

        expect(doc.exists, false);

        // Wait for debounce to complete
        await Future.delayed(
          TypingIndicatorService.debounceDuration + const Duration(milliseconds: 100),
        );

        // Now document should exist
        doc = await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc(userId)
            .get();

        expect(doc.exists, true);
      });

      test('should auto-clear typing status after timeout', () async {
        // Arrange
        const conversationId = 'conv-1';
        const userId = 'user-1';
        const userName = 'User One';

        // Act
        await service.setTyping(
          conversationId: conversationId,
          userId: userId,
          userName: userName,
          isTyping: true,
        );

        // Wait for debounce
        await Future.delayed(
          TypingIndicatorService.debounceDuration + const Duration(milliseconds: 100),
        );

        // Verify document exists
        var doc = await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc(userId)
            .get();

        expect(doc.exists, true);

        // Wait for timeout
        await Future.delayed(
          TypingIndicatorService.typingTimeout + const Duration(seconds: 1),
        );

        // Assert - Document should be deleted
        doc = await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc(userId)
            .get();

        expect(doc.exists, false);
      });
    });

    group('watchTypingUsers', () {
      test('should emit list of typing users', () async {
        // Arrange
        const conversationId = 'conv-1';
        const currentUserId = 'user-1';

        // Add typing status for other users
        await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc('user-2')
            .set({
          'userId': 'user-2',
          'userName': 'User Two',
          'isTyping': true,
          'lastUpdated': DateTime.now(),
        });

        await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc('user-3')
            .set({
          'userId': 'user-3',
          'userName': 'User Three',
          'isTyping': true,
          'lastUpdated': DateTime.now(),
        });

        // Act
        final stream = service.watchTypingUsers(
          conversationId: conversationId,
          currentUserId: currentUserId,
        );

        // Assert
        await expectLater(
          stream,
          emits(predicate<List<TypingUser>>((users) {
            return users.length == 2 &&
                users.any((u) => u.userId == 'user-2') &&
                users.any((u) => u.userId == 'user-3');
          })),
        );
      });

      test('should exclude current user from typing users', () async {
        // Arrange
        const conversationId = 'conv-1';
        const currentUserId = 'user-1';

        // Add typing status for current user and other user
        await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc('user-1')
            .set({
          'userId': 'user-1',
          'userName': 'User One',
          'isTyping': true,
          'lastUpdated': DateTime.now(),
        });

        await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc('user-2')
            .set({
          'userId': 'user-2',
          'userName': 'User Two',
          'isTyping': true,
          'lastUpdated': DateTime.now(),
        });

        // Act
        final stream = service.watchTypingUsers(
          conversationId: conversationId,
          currentUserId: currentUserId,
        );

        // Assert - Should only include user-2
        await expectLater(
          stream,
          emits(predicate<List<TypingUser>>((users) {
            return users.length == 1 && users.first.userId == 'user-2';
          })),
        );
      });

      test('should filter out stale typing status', () async {
        // Arrange
        const conversationId = 'conv-1';
        const currentUserId = 'user-1';

        // Add fresh typing status
        await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc('user-2')
            .set({
          'userId': 'user-2',
          'userName': 'User Two',
          'isTyping': true,
          'lastUpdated': DateTime.now(),
        });

        // Add stale typing status (5 minutes ago)
        await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc('user-3')
            .set({
          'userId': 'user-3',
          'userName': 'User Three',
          'isTyping': true,
          'lastUpdated': DateTime.now().subtract(const Duration(minutes: 5)),
        });

        // Act
        final stream = service.watchTypingUsers(
          conversationId: conversationId,
          currentUserId: currentUserId,
        );

        // Assert - Should only include user-2 (fresh)
        await expectLater(
          stream,
          emits(predicate<List<TypingUser>>((users) {
            return users.length == 1 && users.first.userId == 'user-2';
          })),
        );
      });

      test('should emit empty list when no one is typing', () async {
        // Arrange
        const conversationId = 'conv-1';
        const currentUserId = 'user-1';

        // Act
        final stream = service.watchTypingUsers(
          conversationId: conversationId,
          currentUserId: currentUserId,
        );

        // Assert
        await expectLater(
          stream,
          emits(predicate<List<TypingUser>>((users) => users.isEmpty)),
        );
      });
    });

    group('clearTyping', () {
      test('should clear typing status and cancel timers', () async {
        // Arrange
        const conversationId = 'conv-1';
        const userId = 'user-1';
        const userName = 'User One';

        // First set typing
        await service.setTyping(
          conversationId: conversationId,
          userId: userId,
          userName: userName,
          isTyping: true,
        );

        await Future.delayed(
          TypingIndicatorService.debounceDuration + const Duration(milliseconds: 100),
        );

        // Verify document exists
        var doc = await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc(userId)
            .get();

        expect(doc.exists, true);

        // Act
        await service.clearTyping(
          conversationId: conversationId,
          userId: userId,
          userName: userName,
        );

        // Assert
        doc = await fakeFirestore
            .collection('conversations')
            .doc(conversationId)
            .collection('typingStatus')
            .doc(userId)
            .get();

        expect(doc.exists, false);
      });
    });

    group('dispose', () {
      test('should cancel all timers', () async {
        // Arrange
        await service.setTyping(
          conversationId: 'conv-1',
          userId: 'user-1',
          userName: 'User One',
          isTyping: true,
        );

        await service.setTyping(
          conversationId: 'conv-2',
          userId: 'user-2',
          userName: 'User Two',
          isTyping: true,
        );

        // Act
        service.dispose();

        // Wait for what would be debounce time
        await Future.delayed(
          TypingIndicatorService.debounceDuration + const Duration(milliseconds: 100),
        );

        // Assert - Documents should NOT exist (timers were cancelled)
        final doc1 = await fakeFirestore
            .collection('conversations')
            .doc('conv-1')
            .collection('typingStatus')
            .doc('user-1')
            .get();

        final doc2 = await fakeFirestore
            .collection('conversations')
            .doc('conv-2')
            .collection('typingStatus')
            .doc('user-2')
            .get();

        expect(doc1.exists, false);
        expect(doc2.exists, false);
      });
    });

    group('TypingUser', () {
      test('should create from Firestore document', () async {
        // Arrange
        final now = DateTime.now();
        await fakeFirestore
            .collection('conversations')
            .doc('conv-1')
            .collection('typingStatus')
            .doc('user-1')
            .set({
          'userId': 'user-1',
          'userName': 'User One',
          'isTyping': true,
          'lastUpdated': now,
        });

        final doc = await fakeFirestore
            .collection('conversations')
            .doc('conv-1')
            .collection('typingStatus')
            .doc('user-1')
            .get();

        // Act
        final typingUser = TypingUser.fromFirestore(doc);

        // Assert
        expect(typingUser.userId, 'user-1');
        expect(typingUser.userName, 'User One');
        expect(typingUser.lastUpdated.year, now.year);
        expect(typingUser.lastUpdated.month, now.month);
        expect(typingUser.lastUpdated.day, now.day);
      });

      test('should implement equality', () {
        // Arrange
        final user1 = TypingUser(
          userId: 'user-1',
          userName: 'User One',
          lastUpdated: DateTime(2024, 1, 1),
        );
        final user2 = TypingUser(
          userId: 'user-1',
          userName: 'User One',
          lastUpdated: DateTime(2024, 1, 2),
        );

        // Assert
        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('should implement toString', () {
        // Arrange
        final user = TypingUser(
          userId: 'user-1',
          userName: 'User One',
          lastUpdated: DateTime(2024, 1, 1),
        );

        // Act
        final string = user.toString();

        // Assert
        expect(string, contains('user-1'));
        expect(string, contains('User One'));
      });
    });
  });
}
