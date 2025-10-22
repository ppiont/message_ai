import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';

void main() {
  group('User Entity', () {
    final testDate = DateTime(2024, 10, 21, 12);

    final testUser = User(
      uid: 'test-uid-123',
      email: 'test@example.com',
      phoneNumber: '+1234567890',
      displayName: 'Test User',
      photoURL: 'https://example.com/photo.jpg',
      preferredLanguage: 'en',
      createdAt: testDate,
      lastSeen: testDate,
      isOnline: true,
      fcmTokens: const ['token1', 'token2'],
    );

    test('should create user with all properties', () {
      expect(testUser.uid, 'test-uid-123');
      expect(testUser.email, 'test@example.com');
      expect(testUser.phoneNumber, '+1234567890');
      expect(testUser.displayName, 'Test User');
      expect(testUser.photoURL, 'https://example.com/photo.jpg');
      expect(testUser.preferredLanguage, 'en');
      expect(testUser.createdAt, testDate);
      expect(testUser.lastSeen, testDate);
      expect(testUser.isOnline, true);
      expect(testUser.fcmTokens, ['token1', 'token2']);
    });

    test('should create user with nullable fields as null', () {
      final minimalUser = User(
        uid: 'uid',
        displayName: 'Name',
        preferredLanguage: 'en',
        createdAt: testDate,
        lastSeen: testDate,
        isOnline: false,
        fcmTokens: const [],
      );

      expect(minimalUser.email, isNull);
      expect(minimalUser.phoneNumber, isNull);
      expect(minimalUser.photoURL, isNull);
    });

    group('copyWith', () {
      test('should return copy with updated displayName', () {
        final updated = testUser.copyWith(displayName: 'New Name');

        expect(updated.displayName, 'New Name');
        expect(updated.uid, testUser.uid);
        expect(updated.email, testUser.email);
      });

      test('should return copy with updated isOnline', () {
        final updated = testUser.copyWith(isOnline: false);

        expect(updated.isOnline, false);
        expect(updated.uid, testUser.uid);
      });

      test('should return copy with updated fcmTokens', () {
        final updated = testUser.copyWith(fcmTokens: ['new-token']);

        expect(updated.fcmTokens, ['new-token']);
        expect(updated.uid, testUser.uid);
      });

      test('should return copy with multiple fields updated', () {
        final updated = testUser.copyWith(
          displayName: 'Updated Name',
          isOnline: false,
          preferredLanguage: 'es',
        );

        expect(updated.displayName, 'Updated Name');
        expect(updated.isOnline, false);
        expect(updated.preferredLanguage, 'es');
        expect(updated.uid, testUser.uid);
      });

      test(
        'should return copy with no changes when no parameters provided',
        () {
          final updated = testUser.copyWith();

          expect(updated.uid, testUser.uid);
          expect(updated.displayName, testUser.displayName);
          expect(updated.email, testUser.email);
        },
      );
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        final user1 = testUser;
        final user2 = User(
          uid: 'test-uid-123',
          email: 'test@example.com',
          phoneNumber: '+1234567890',
          displayName: 'Test User',
          photoURL: 'https://example.com/photo.jpg',
          preferredLanguage: 'en',
          createdAt: testDate,
          lastSeen: testDate,
          isOnline: true,
          fcmTokens: const ['token1', 'token2'],
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('should not be equal when uid differs', () {
        final user1 = testUser;
        final user2 = testUser.copyWith(uid: 'different-uid');

        expect(user1, isNot(equals(user2)));
      });

      test('should not be equal when displayName differs', () {
        final user1 = testUser;
        final user2 = testUser.copyWith(displayName: 'Different Name');

        expect(user1, isNot(equals(user2)));
      });

      test('should not be equal when isOnline differs', () {
        final user1 = testUser;
        final user2 = testUser.copyWith(isOnline: false);

        expect(user1, isNot(equals(user2)));
      });
    });

    group('toString', () {
      test('should return string representation with key fields', () {
        final string = testUser.toString();

        expect(string, contains('test-uid-123'));
        expect(string, contains('Test User'));
        expect(string, contains('test@example.com'));
        expect(string, contains('true'));
        expect(string, contains('en'));
      });
    });

    group('Edge Cases', () {
      test('should handle empty fcmTokens list', () {
        final user = testUser.copyWith(fcmTokens: []);

        expect(user.fcmTokens, isEmpty);
      });

      test('should handle long displayName', () {
        final longName = 'A' * 100;
        final user = testUser.copyWith(displayName: longName);

        expect(user.displayName, longName);
        expect(user.displayName.length, 100);
      });

      test('should handle special characters in displayName', () {
        final user = testUser.copyWith(displayName: '名前 テスト 🎉');

        expect(user.displayName, '名前 テスト 🎉');
      });
    });
  });
}
