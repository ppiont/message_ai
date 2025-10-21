import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/authentication/data/models/user_model.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';

void main() {
  group('UserModel', () {
    final testDate = DateTime(2024, 10, 21, 12, 0, 0);
    final testTimestamp = Timestamp.fromDate(testDate);

    final testJson = {
      'uid': 'test-uid-123',
      'email': 'test@example.com',
      'phoneNumber': '+1234567890',
      'displayName': 'Test User',
      'photoURL': 'https://example.com/photo.jpg',
      'preferredLanguage': 'en',
      'createdAt': testTimestamp,
      'lastSeen': testTimestamp,
      'isOnline': true,
      'fcmTokens': ['token1', 'token2'],
    };

    final testModel = UserModel(
      uid: 'test-uid-123',
      email: 'test@example.com',
      phoneNumber: '+1234567890',
      displayName: 'Test User',
      photoURL: 'https://example.com/photo.jpg',
      preferredLanguage: 'en',
      createdAt: testDate,
      lastSeen: testDate,
      isOnline: true,
      fcmTokens: ['token1', 'token2'],
    );

    final testEntity = User(
      uid: 'test-uid-123',
      email: 'test@example.com',
      phoneNumber: '+1234567890',
      displayName: 'Test User',
      photoURL: 'https://example.com/photo.jpg',
      preferredLanguage: 'en',
      createdAt: testDate,
      lastSeen: testDate,
      isOnline: true,
      fcmTokens: ['token1', 'token2'],
    );

    group('fromJson', () {
      test('should create UserModel from complete JSON', () {
        final model = UserModel.fromJson(testJson);

        expect(model.uid, 'test-uid-123');
        expect(model.email, 'test@example.com');
        expect(model.phoneNumber, '+1234567890');
        expect(model.displayName, 'Test User');
        expect(model.photoURL, 'https://example.com/photo.jpg');
        expect(model.preferredLanguage, 'en');
        expect(model.createdAt, testDate);
        expect(model.lastSeen, testDate);
        expect(model.isOnline, true);
        expect(model.fcmTokens, ['token1', 'token2']);
      });

      test('should handle missing nullable fields', () {
        final minimalJson = {
          'uid': 'uid',
          'displayName': 'Name',
          'createdAt': testTimestamp,
          'lastSeen': testTimestamp,
        };

        final model = UserModel.fromJson(minimalJson);

        expect(model.email, isNull);
        expect(model.phoneNumber, isNull);
        expect(model.photoURL, isNull);
        expect(model.preferredLanguage, 'en'); // default
        expect(model.isOnline, false); // default
        expect(model.fcmTokens, isEmpty); // default
      });

      test('should handle empty fcmTokens array', () {
        final json = {...testJson, 'fcmTokens': []};
        final model = UserModel.fromJson(json);

        expect(model.fcmTokens, isEmpty);
      });

      test('should handle null fcmTokens', () {
        final json = {...testJson};
        json.remove('fcmTokens');
        final model = UserModel.fromJson(json);

        expect(model.fcmTokens, isEmpty);
      });
    });

    group('toJson', () {
      test('should convert UserModel to JSON', () {
        final json = testModel.toJson();

        expect(json['uid'], 'test-uid-123');
        expect(json['email'], 'test@example.com');
        expect(json['phoneNumber'], '+1234567890');
        expect(json['displayName'], 'Test User');
        expect(json['photoURL'], 'https://example.com/photo.jpg');
        expect(json['preferredLanguage'], 'en');
        expect((json['createdAt'] as Timestamp).toDate(), testDate);
        expect((json['lastSeen'] as Timestamp).toDate(), testDate);
        expect(json['isOnline'], true);
        expect(json['fcmTokens'], ['token1', 'token2']);
      });

      test('should handle null values in JSON', () {
        final model = UserModel(
          uid: 'uid',
          displayName: 'Name',
          preferredLanguage: 'en',
          createdAt: testDate,
          lastSeen: testDate,
          isOnline: false,
          fcmTokens: [],
        );

        final json = model.toJson();

        expect(json['email'], isNull);
        expect(json['phoneNumber'], isNull);
        expect(json['photoURL'], isNull);
        expect(json['fcmTokens'], isEmpty);
      });
    });

    group('JSON Round Trip', () {
      test('should maintain data integrity through fromJson and toJson', () {
        final json1 = testModel.toJson();
        final model = UserModel.fromJson(json1);
        final json2 = model.toJson();

        expect(json2['uid'], json1['uid']);
        expect(json2['email'], json1['email']);
        expect(json2['displayName'], json1['displayName']);
        expect(json2['isOnline'], json1['isOnline']);
      });
    });

    group('fromEntity', () {
      test('should create UserModel from User entity', () {
        final model = UserModel.fromEntity(testEntity);

        expect(model.uid, testEntity.uid);
        expect(model.email, testEntity.email);
        expect(model.phoneNumber, testEntity.phoneNumber);
        expect(model.displayName, testEntity.displayName);
        expect(model.photoURL, testEntity.photoURL);
        expect(model.preferredLanguage, testEntity.preferredLanguage);
        expect(model.createdAt, testEntity.createdAt);
        expect(model.lastSeen, testEntity.lastSeen);
        expect(model.isOnline, testEntity.isOnline);
        expect(model.fcmTokens, testEntity.fcmTokens);
      });
    });

    group('toEntity', () {
      test('should convert UserModel to User entity', () {
        final entity = testModel.toEntity();

        expect(entity.uid, testModel.uid);
        expect(entity.email, testModel.email);
        expect(entity.phoneNumber, testModel.phoneNumber);
        expect(entity.displayName, testModel.displayName);
        expect(entity.photoURL, testModel.photoURL);
        expect(entity.preferredLanguage, testModel.preferredLanguage);
        expect(entity.createdAt, testModel.createdAt);
        expect(entity.lastSeen, testModel.lastSeen);
        expect(entity.isOnline, testModel.isOnline);
        expect(entity.fcmTokens, testModel.fcmTokens);
      });
    });

    group('Entity Conversion Round Trip', () {
      test('should maintain data integrity through entity conversions', () {
        final model1 = UserModel.fromEntity(testEntity);
        final entity = model1.toEntity();
        final model2 = UserModel.fromEntity(entity);

        expect(model2.uid, model1.uid);
        expect(model2.email, model1.email);
        expect(model2.displayName, model1.displayName);
        expect(model2.isOnline, model1.isOnline);
      });
    });

    group('copyWith', () {
      test('should return copy with updated displayName', () {
        final updated = testModel.copyWith(displayName: 'New Name');

        expect(updated.displayName, 'New Name');
        expect(updated.uid, testModel.uid);
        expect(updated.email, testModel.email);
      });

      test('should return copy with updated isOnline', () {
        final updated = testModel.copyWith(isOnline: false);

        expect(updated.isOnline, false);
        expect(updated.uid, testModel.uid);
      });

      test(
        'should return copy with no changes when no parameters provided',
        () {
          final updated = testModel.copyWith();

          expect(updated.uid, testModel.uid);
          expect(updated.displayName, testModel.displayName);
          expect(updated.isOnline, testModel.isOnline);
        },
      );
    });

    group('Edge Cases', () {
      test('should handle very long displayName', () {
        final longName = 'A' * 500;
        final model = testModel.copyWith(displayName: longName);

        expect(model.displayName.length, 500);
      });

      test('should handle special characters', () {
        final model = testModel.copyWith(
          displayName: '名前 🎉 Test',
          email: 'test+special@example.com',
        );

        expect(model.displayName, '名前 🎉 Test');
        expect(model.email, 'test+special@example.com');
      });

      test('should handle multiple FCM tokens', () {
        final tokens = List.generate(10, (i) => 'token-$i');
        final model = testModel.copyWith(fcmTokens: tokens);

        expect(model.fcmTokens.length, 10);
        expect(model.fcmTokens.first, 'token-0');
        expect(model.fcmTokens.last, 'token-9');
      });
    });
  });
}
