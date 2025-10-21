import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('UserDao - Basic CRUD', () {
    test('insertUser inserts a user successfully', () async {
      final now = DateTime.now();
      final user = UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        createdAt: now,
        lastSeen: now,
      );

      await database.userDao.insertUser(user);

      final retrieved = await database.userDao.getUserByUid('user-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Alice'));
    });

    test('upsertUser updates existing user', () async {
      final now = DateTime.now();
      final user = UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        createdAt: now,
        lastSeen: now,
      );

      await database.userDao.insertUser(user);

      // Upsert with same UID
      await database.userDao.upsertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice Updated',
        createdAt: now,
        lastSeen: now,
      ));

      final retrieved = await database.userDao.getUserByUid('user-1');
      expect(retrieved!.name, equals('Alice Updated'));
    });

    test('updateUser updates specific user', () async {
      final now = DateTime.now();
      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        createdAt: now,
        lastSeen: now,
      ));

      final updated = await database.userDao.updateUser(
        'user-1',
        const UsersCompanion(email: Value('alice@example.com')),
      );

      expect(updated, isTrue);
      final retrieved = await database.userDao.getUserByUid('user-1');
      expect(retrieved!.email, equals('alice@example.com'));
    });

    test('deleteUser removes user', () async {
      final now = DateTime.now();
      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        createdAt: now,
        lastSeen: now,
      ));

      final deleted = await database.userDao.deleteUser('user-1');
      expect(deleted, equals(1));

      final retrieved = await database.userDao.getUserByUid('user-1');
      expect(retrieved, isNull);
    });
  });

  group('UserDao - Query Operations', () {
    test('getAllUsers returns users ordered by name', () async {
      final now = DateTime.now();

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-2',
        name: 'Bob',
        createdAt: now,
        lastSeen: now,
      ));

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        createdAt: now,
        lastSeen: now,
      ));

      final users = await database.userDao.getAllUsers();

      expect(users.length, equals(2));
      expect(users[0].name, equals('Alice')); // Alphabetically first
      expect(users[1].name, equals('Bob'));
    });

    test('getUsersByUids returns multiple users', () async {
      final now = DateTime.now();

      for (int i = 0; i < 3; i++) {
        await database.userDao.insertUser(UsersCompanion.insert(
          uid: 'user-$i',
          name: 'User $i',
          createdAt: now,
          lastSeen: now,
        ));
      }

      final users = await database.userDao.getUsersByUids(
        ['user-0', 'user-2'],
      );

      expect(users.length, equals(2));
      expect(users.any((u) => u.uid == 'user-0'), isTrue);
      expect(users.any((u) => u.uid == 'user-2'), isTrue);
    });

    test('watchUser emits updates', () async {
      final now = DateTime.now();

      // Insert user first
      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        createdAt: now,
        lastSeen: now,
      ));

      // Start watching
      final stream = database.userDao.watchUser('user-1');

      // Should emit the existing user
      await expectLater(
        stream,
        emits(predicate<UserEntity?>(
          (user) => user != null && user.name == 'Alice',
        )),
      );
    });

    test('countUsers returns correct count', () async {
      final now = DateTime.now();

      for (int i = 0; i < 5; i++) {
        await database.userDao.insertUser(UsersCompanion.insert(
          uid: 'user-$i',
          name: 'User $i',
          createdAt: now,
          lastSeen: now,
        ));
      }

      final count = await database.userDao.countUsers();
      expect(count, equals(5));
    });
  });

  group('UserDao - Search Operations', () {
    test('searchUsersByName finds users', () async {
      final now = DateTime.now();

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice Smith',
        createdAt: now,
        lastSeen: now,
      ));

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-2',
        name: 'Bob Johnson',
        createdAt: now,
        lastSeen: now,
      ));

      final results = await database.userDao.searchUsersByName('Alice');

      expect(results.length, equals(1));
      expect(results.first.name, equals('Alice Smith'));
    });

    test('searchUsersByEmail finds users', () async {
      final now = DateTime.now();

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        email: const Value('alice@example.com'),
        createdAt: now,
        lastSeen: now,
      ));

      final results = await database.userDao.searchUsersByEmail('alice@');

      expect(results.length, equals(1));
      expect(results.first.email, equals('alice@example.com'));
    });

    test('searchUsersByPhone finds users', () async {
      final now = DateTime.now();

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        phoneNumber: const Value('+1234567890'),
        createdAt: now,
        lastSeen: now,
      ));

      final results = await database.userDao.searchUsersByPhone('123456');

      expect(results.length, equals(1));
      expect(results.first.phoneNumber, equals('+1234567890'));
    });

    test('searchUsers searches across all fields', () async {
      final now = DateTime.now();

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        email: const Value('alice@test.com'),
        phoneNumber: const Value('+1234567890'),
        createdAt: now,
        lastSeen: now,
      ));

      // Search by name
      var results = await database.userDao.searchUsers('Alice');
      expect(results.length, equals(1));

      // Search by email
      results = await database.userDao.searchUsers('test.com');
      expect(results.length, equals(1));

      // Search by phone
      results = await database.userDao.searchUsers('123456');
      expect(results.length, equals(1));
    });

    test('getUserByEmail returns exact match', () async {
      final now = DateTime.now();

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        email: const Value('alice@example.com'),
        createdAt: now,
        lastSeen: now,
      ));

      final user = await database.userDao.getUserByEmail('alice@example.com');
      expect(user, isNotNull);
      expect(user!.uid, equals('user-1'));
    });

    test('getUserByPhone returns exact match', () async {
      final now = DateTime.now();

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        phoneNumber: const Value('+1234567890'),
        createdAt: now,
        lastSeen: now,
      ));

      final user = await database.userDao.getUserByPhone('+1234567890');
      expect(user, isNotNull);
      expect(user!.uid, equals('user-1'));
    });
  });

  group('UserDao - Status Operations', () {
    test('updateUserOnlineStatus updates status', () async {
      final now = DateTime.now();
      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        createdAt: now,
        lastSeen: now,
      ));

      final updated = await database.userDao.updateUserOnlineStatus(
        uid: 'user-1',
        isOnline: true,
      );

      expect(updated, isTrue);

      final user = await database.userDao.getUserByUid('user-1');
      expect(user!.isOnline, isTrue);
    });

    test('getOnlineUsers filters by status', () async {
      final now = DateTime.now();

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        isOnline: const Value(true),
        createdAt: now,
        lastSeen: now,
      ));

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-2',
        name: 'Bob',
        isOnline: const Value(false),
        createdAt: now,
        lastSeen: now,
      ));

      final onlineUsers = await database.userDao.getOnlineUsers();

      expect(onlineUsers.length, equals(1));
      expect(onlineUsers.first.name, equals('Alice'));
    });

    test('countOnlineUsers returns correct count', () async {
      final now = DateTime.now();

      for (int i = 0; i < 3; i++) {
        await database.userDao.insertUser(UsersCompanion.insert(
          uid: 'user-$i',
          name: 'User $i',
          isOnline: Value(i % 2 == 0), // 0 and 2 are online
          createdAt: now,
          lastSeen: now,
        ));
      }

      final count = await database.userDao.countOnlineUsers();
      expect(count, equals(2));
    });

    test('setAllUsersOffline sets all online users to offline', () async {
      final now = DateTime.now();

      for (int i = 0; i < 3; i++) {
        await database.userDao.insertUser(UsersCompanion.insert(
          uid: 'user-$i',
          name: 'User $i',
          isOnline: const Value(true),
          createdAt: now,
          lastSeen: now,
        ));
      }

      await database.userDao.setAllUsersOffline();

      final onlineCount = await database.userDao.countOnlineUsers();
      expect(onlineCount, equals(0));
    });
  });

  group('UserDao - Update Operations', () {
    test('updateFcmToken updates token', () async {
      final now = DateTime.now();
      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        createdAt: now,
        lastSeen: now,
      ));

      final updated = await database.userDao.updateFcmToken(
        uid: 'user-1',
        token: 'fcm-token-123',
      );

      expect(updated, isTrue);

      final user = await database.userDao.getUserByUid('user-1');
      expect(user!.fcmToken, equals('fcm-token-123'));
    });

    test('updatePreferredLanguage updates language', () async {
      final now = DateTime.now();
      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        createdAt: now,
        lastSeen: now,
      ));

      final updated = await database.userDao.updatePreferredLanguage(
        uid: 'user-1',
        languageCode: 'es',
      );

      expect(updated, isTrue);

      final user = await database.userDao.getUserByUid('user-1');
      expect(user!.preferredLanguage, equals('es'));
    });

    test('updateProfileImage updates image URL', () async {
      final now = DateTime.now();
      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        createdAt: now,
        lastSeen: now,
      ));

      final updated = await database.userDao.updateProfileImage(
        uid: 'user-1',
        imageUrl: 'https://example.com/avatar.jpg',
      );

      expect(updated, isTrue);

      final user = await database.userDao.getUserByUid('user-1');
      expect(user!.imageUrl, equals('https://example.com/avatar.jpg'));
    });

    test('updateLastSeen updates timestamp', () async {
      final now = DateTime.now();
      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        createdAt: now,
        lastSeen: now,
      ));

      // Wait a bit to ensure timestamp difference
      await Future.delayed(const Duration(seconds: 1));

      final updated = await database.userDao.updateLastSeen('user-1');
      expect(updated, isTrue);

      final user = await database.userDao.getUserByUid('user-1');
      // Compare seconds since epoch to avoid microsecond precision issues
      expect(
        user!.lastSeen.millisecondsSinceEpoch ~/ 1000,
        greaterThan(now.millisecondsSinceEpoch ~/ 1000),
      );
    });
  });

  group('UserDao - Batch Operations', () {
    test('insertUsers inserts multiple users', () async {
      final now = DateTime.now();
      final users = List.generate(
        5,
        (i) => UsersCompanion.insert(
          uid: 'user-$i',
          name: 'User $i',
          createdAt: now,
          lastSeen: now,
        ),
      );

      await database.userDao.insertUsers(users);

      final count = await database.userDao.countUsers();
      expect(count, equals(5));
    });

    test('batchUpdateOnlineStatus updates multiple users', () async {
      final now = DateTime.now();

      for (int i = 0; i < 3; i++) {
        await database.userDao.insertUser(UsersCompanion.insert(
          uid: 'user-$i',
          name: 'User $i',
          createdAt: now,
          lastSeen: now,
        ));
      }

      await database.userDao.batchUpdateOnlineStatus({
        'user-0': true,
        'user-1': false,
        'user-2': true,
      });

      final onlineCount = await database.userDao.countOnlineUsers();
      expect(onlineCount, equals(2));
    });

    test('batchDeleteUsers removes multiple users', () async {
      final now = DateTime.now();

      for (int i = 0; i < 5; i++) {
        await database.userDao.insertUser(UsersCompanion.insert(
          uid: 'user-$i',
          name: 'User $i',
          createdAt: now,
          lastSeen: now,
        ));
      }

      await database.userDao.batchDeleteUsers(['user-0', 'user-2', 'user-4']);

      final remaining = await database.userDao.getAllUsers();
      expect(remaining.length, equals(2));
    });
  });

  group('UserDao - Special Queries', () {
    test('getUsersByLanguage filters by language', () async {
      final now = DateTime.now();

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        preferredLanguage: const Value('es'),
        createdAt: now,
        lastSeen: now,
      ));

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-2',
        name: 'Bob',
        preferredLanguage: const Value('fr'),
        createdAt: now,
        lastSeen: now,
      ));

      final spanishUsers = await database.userDao.getUsersByLanguage('es');

      expect(spanishUsers.length, equals(1));
      expect(spanishUsers.first.name, equals('Alice'));
    });

    test('getRecentlyActiveUsers returns recent users', () async {
      final now = DateTime.now();
      final old = now.subtract(const Duration(days: 30));

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-recent',
        name: 'Recent User',
        createdAt: now,
        lastSeen: now,
      ));

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-old',
        name: 'Old User',
        createdAt: old,
        lastSeen: old,
      ));

      final recentUsers = await database.userDao.getRecentlyActiveUsers();

      expect(recentUsers.length, equals(1));
      expect(recentUsers.first.uid, equals('user-recent'));
    });

    test('userExists returns true for existing user', () async {
      final now = DateTime.now();
      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-1',
        name: 'Alice',
        createdAt: now,
        lastSeen: now,
      ));

      final exists = await database.userDao.userExists('user-1');
      expect(exists, isTrue);

      final notExists = await database.userDao.userExists('user-999');
      expect(notExists, isFalse);
    });

    test('getUsersCreatedAfter returns users after timestamp', () async {
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 1));

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-old',
        name: 'Old User',
        createdAt: cutoff.subtract(const Duration(minutes: 10)),
        lastSeen: now,
      ));

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-new',
        name: 'New User',
        createdAt: now,
        lastSeen: now,
      ));

      final newUsers = await database.userDao.getUsersCreatedAfter(cutoff);

      expect(newUsers.length, equals(1));
      expect(newUsers.first.uid, equals('user-new'));
    });

    test('getInactiveUsers returns users not seen recently', () async {
      final now = DateTime.now();
      final veryOld = now.subtract(const Duration(days: 60));

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-active',
        name: 'Active User',
        createdAt: now,
        lastSeen: now,
      ));

      await database.userDao.insertUser(UsersCompanion.insert(
        uid: 'user-inactive',
        name: 'Inactive User',
        createdAt: veryOld,
        lastSeen: veryOld,
      ));

      final inactiveUsers = await database.userDao.getInactiveUsers();

      expect(inactiveUsers.length, equals(1));
      expect(inactiveUsers.first.uid, equals('user-inactive'));
    });
  });
}
