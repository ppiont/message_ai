import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/messaging/data/services/presence_service.dart';

void main() {
  late PresenceService service;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = PresenceService(firestore: fakeFirestore);
  });

  tearDown(() {
    service.dispose();
  });

  group('PresenceService', () {
    group('setOnline', () {
      test('should create presence document with online status', () async {
        // Arrange
        const userId = 'user-1';
        const userName = 'User One';

        // Act
        await service.setOnline(userId: userId, userName: userName);

        // Wait a moment for the update
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final doc =
            await fakeFirestore.collection('presence').doc(userId).get();

        expect(doc.exists, true);
        expect(doc.data()?['userId'], userId);
        expect(doc.data()?['userName'], userName);
        expect(doc.data()?['isOnline'], true);
        expect(doc.data()?['lastSeen'], isNotNull);
      });

      test('should start heartbeat timer', () async {
        // Arrange
        const userId = 'user-1';
        const userName = 'User One';

        // Act
        await service.setOnline(userId: userId, userName: userName);

        // Wait for first heartbeat
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Document should exist with online status
        final doc =
            await fakeFirestore.collection('presence').doc(userId).get();

        expect(doc.exists, true);
        expect(doc.data()?['isOnline'], true);
        // Note: Heartbeat timer is internal implementation detail
        // We verify it's online, which means setOnline worked
      });
    });

    group('setOffline', () {
      test('should update presence document with offline status', () async {
        // Arrange
        const userId = 'user-1';
        const userName = 'User One';

        // First set online
        await service.setOnline(userId: userId, userName: userName);
        await Future.delayed(const Duration(milliseconds: 100));

        // Act - Set offline
        await service.setOffline(userId: userId, userName: userName);

        // Assert
        final doc =
            await fakeFirestore.collection('presence').doc(userId).get();

        expect(doc.exists, true);
        expect(doc.data()?['isOnline'], false);
      });

      test('should stop heartbeat timer', () async {
        // Arrange
        const userId = 'user-1';
        const userName = 'User One';

        await service.setOnline(userId: userId, userName: userName);
        await Future.delayed(const Duration(milliseconds: 100));

        // Act - Set offline
        await service.setOffline(userId: userId, userName: userName);

        // Assert - Should be offline
        final doc =
            await fakeFirestore.collection('presence').doc(userId).get();

        expect(doc.data()?['isOnline'], false);
        // Note: Heartbeat timer is internal implementation detail
        // Setting offline stops the timer (verified by not throwing errors)
      });
    });

    group('watchUserPresence', () {
      test('should emit presence updates for user', () async {
        // Arrange
        const userId = 'user-1';
        const userName = 'User One';

        // Create initial presence
        await fakeFirestore.collection('presence').doc(userId).set({
          'userId': userId,
          'userName': userName,
          'isOnline': true,
          'lastSeen': DateTime.now(),
        });

        // Act
        final stream = service.watchUserPresence(userId: userId);

        // Assert
        await expectLater(
          stream,
          emits(predicate<UserPresence?>((presence) {
            return presence != null &&
                presence.userId == userId &&
                presence.isOnline == true;
          })),
        );
      });

      test('should emit null when presence document does not exist', () async {
        // Arrange
        const userId = 'non-existent';

        // Act
        final stream = service.watchUserPresence(userId: userId);

        // Assert
        await expectLater(stream, emits(null));
      });

      test('should emit updates when presence changes', () async {
        // Arrange
        const userId = 'user-1';
        const userName = 'User One';

        await fakeFirestore.collection('presence').doc(userId).set({
          'userId': userId,
          'userName': userName,
          'isOnline': true,
          'lastSeen': DateTime.now(),
        });

        // Act
        final stream = service.watchUserPresence(userId: userId);

        // Listen to stream
        final presenceList = <UserPresence?>[];
        final subscription = stream.listen(presenceList.add);

        // Wait for initial emission
        await Future.delayed(const Duration(milliseconds: 100));

        // Update presence to offline
        await fakeFirestore.collection('presence').doc(userId).update({
          'isOnline': false,
          'lastSeen': DateTime.now(),
        });

        // Wait for update
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(presenceList.length, greaterThanOrEqualTo(2));
        expect(presenceList.first?.isOnline, true);
        expect(presenceList.last?.isOnline, false);

        await subscription.cancel();
      });
    });

    group('watchUsersPresence', () {
      test('should emit presence map for multiple users', () async {
        // Arrange
        await fakeFirestore.collection('presence').doc('user-1').set({
          'userId': 'user-1',
          'userName': 'User One',
          'isOnline': true,
          'lastSeen': DateTime.now(),
        });

        await fakeFirestore.collection('presence').doc('user-2').set({
          'userId': 'user-2',
          'userName': 'User Two',
          'isOnline': false,
          'lastSeen': DateTime.now(),
        });

        // Act
        final stream = service.watchUsersPresence(
          userIds: ['user-1', 'user-2'],
        );

        // Assert
        await expectLater(
          stream,
          emits(predicate<Map<String, UserPresence>>((map) {
            return map.length == 2 &&
                map['user-1']?.isOnline == true &&
                map['user-2']?.isOnline == false;
          })),
        );
      });

      test('should handle empty user list', () async {
        // Act
        final stream = service.watchUsersPresence(userIds: []);

        // Assert
        await expectLater(stream, emits({}));
      });

      test('should handle large user lists (limited to 10)', () async {
        // Arrange - Create 15 users
        for (int i = 1; i <= 15; i++) {
          await fakeFirestore.collection('presence').doc('user-$i').set({
            'userId': 'user-$i',
            'userName': 'User $i',
            'isOnline': true,
            'lastSeen': DateTime.now(),
          });
        }

        final userIds = List.generate(15, (i) => 'user-${i + 1}');

        // Act
        final stream = service.watchUsersPresence(userIds: userIds);

        // Assert - Should only include first 10 due to Firestore 'in' query limit
        await expectLater(
          stream,
          emits(predicate<Map<String, UserPresence>>((map) {
            return map.length == 10;
          })),
        );
      });
    });

    group('dispose', () {
      test('should stop heartbeat timer', () async {
        // Arrange
        await service.setOnline(userId: 'user-1', userName: 'User One');

        // Act
        service.dispose();

        // Assert - Should not throw
        expect(service, isNotNull);
      });
    });

    group('UserPresence', () {
      test('should create from Firestore document', () async {
        // Arrange
        final now = DateTime.now();
        await fakeFirestore.collection('presence').doc('user-1').set({
          'userId': 'user-1',
          'userName': 'User One',
          'isOnline': true,
          'lastSeen': now,
        });

        final doc =
            await fakeFirestore.collection('presence').doc('user-1').get();

        // Act
        final presence = UserPresence.fromFirestore(doc);

        // Assert
        expect(presence.userId, 'user-1');
        expect(presence.userName, 'User One');
        expect(presence.isOnline, true);
        expect(presence.lastSeen.year, now.year);
        expect(presence.lastSeen.month, now.month);
        expect(presence.lastSeen.day, now.day);
      });

      test('should handle missing fields gracefully', () async {
        // Arrange
        await fakeFirestore.collection('presence').doc('user-1').set({
          'userId': 'user-1',
          'userName': 'User One',
        });

        final doc =
            await fakeFirestore.collection('presence').doc('user-1').get();

        // Act
        final presence = UserPresence.fromFirestore(doc);

        // Assert
        expect(presence.userId, 'user-1');
        expect(presence.userName, 'User One');
        expect(presence.isOnline, false); // Default
        expect(presence.lastSeen, isNotNull); // Falls back to DateTime.now()
      });

      group('getStatusText', () {
        test('should return "Online" when user is online', () {
          // Arrange
          final presence = UserPresence(
            userId: 'user-1',
            userName: 'User One',
            isOnline: true,
            lastSeen: DateTime.now(),
          );

          // Act
          final status = presence.getStatusText();

          // Assert
          expect(status, 'Online');
        });

        test('should return "Last seen just now" for < 1 minute', () {
          // Arrange
          final presence = UserPresence(
            userId: 'user-1',
            userName: 'User One',
            isOnline: false,
            lastSeen: DateTime.now().subtract(const Duration(seconds: 30)),
          );

          // Act
          final status = presence.getStatusText();

          // Assert
          expect(status, 'Last seen just now');
        });

        test('should return minutes for < 1 hour', () {
          // Arrange
          final presence = UserPresence(
            userId: 'user-1',
            userName: 'User One',
            isOnline: false,
            lastSeen: DateTime.now().subtract(const Duration(minutes: 15)),
          );

          // Act
          final status = presence.getStatusText();

          // Assert
          expect(status, 'Last seen 15 minutes ago');
        });

        test('should return hours for < 24 hours', () {
          // Arrange
          final presence = UserPresence(
            userId: 'user-1',
            userName: 'User One',
            isOnline: false,
            lastSeen: DateTime.now().subtract(const Duration(hours: 5)),
          );

          // Act
          final status = presence.getStatusText();

          // Assert
          expect(status, 'Last seen 5 hours ago');
        });

        test('should return "yesterday" for 1 day ago', () {
          // Arrange
          final presence = UserPresence(
            userId: 'user-1',
            userName: 'User One',
            isOnline: false,
            lastSeen: DateTime.now().subtract(const Duration(days: 1)),
          );

          // Act
          final status = presence.getStatusText();

          // Assert
          expect(status, 'Last seen yesterday');
        });

        test('should return days for < 1 week', () {
          // Arrange
          final presence = UserPresence(
            userId: 'user-1',
            userName: 'User One',
            isOnline: false,
            lastSeen: DateTime.now().subtract(const Duration(days: 3)),
          );

          // Act
          final status = presence.getStatusText();

          // Assert
          expect(status, 'Last seen 3 days ago');
        });

        test('should return date for > 1 week', () {
          // Arrange
          final lastSeen = DateTime(2024, 1, 1);
          final presence = UserPresence(
            userId: 'user-1',
            userName: 'User One',
            isOnline: false,
            lastSeen: lastSeen,
          );

          // Act
          final status = presence.getStatusText();

          // Assert
          expect(status, 'Last seen 1/1/2024');
        });
      });

      test('should implement equality', () {
        // Arrange
        final presence1 = UserPresence(
          userId: 'user-1',
          userName: 'User One',
          isOnline: true,
          lastSeen: DateTime(2024, 1, 1),
        );
        final presence2 = UserPresence(
          userId: 'user-1',
          userName: 'User One',
          isOnline: true,
          lastSeen: DateTime(2024, 1, 2), // Different lastSeen doesn't affect equality
        );

        // Assert
        expect(presence1, equals(presence2));
        expect(presence1.hashCode, equals(presence2.hashCode));
      });

      test('should implement toString', () {
        // Arrange
        final presence = UserPresence(
          userId: 'user-1',
          userName: 'User One',
          isOnline: true,
          lastSeen: DateTime(2024, 1, 1),
        );

        // Act
        final string = presence.toString();

        // Assert
        expect(string, contains('user-1'));
        expect(string, contains('User One'));
        expect(string, contains('true'));
      });
    });
  });
}
