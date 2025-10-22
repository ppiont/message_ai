import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Create an in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Users Table Schema', () {
    test('table is created with correct name', () {
      expect(database.users.actualTableName, equals('users'));
    });

    test('table has correct primary key', () {
      final primaryKey = database.users.$primaryKey;
      expect(primaryKey.length, equals(1));
      expect(primaryKey.first.$name, equals('uid'));
    });

    test('table has all required columns', () {
      final columns = database.users.$columns;
      final columnNames = columns.map((c) => c.$name).toList();

      expect(
        columnNames,
        containsAll([
          'uid',
          'email',
          'phone_number',
          'name',
          'image_url',
          'fcm_token',
          'preferred_language',
          'created_at',
          'last_seen',
          'is_online',
        ]),
      );
    });

    test('uid column is non-nullable text', () {
      final uidColumn =
          database.users.$columns.firstWhere((c) => c.$name == 'uid')
              as GeneratedColumn<String>;
      expect(uidColumn.$nullable, isFalse);
      expect(uidColumn.type, equals(DriftSqlType.string));
    });

    test('email column is nullable text', () {
      final emailColumn =
          database.users.$columns.firstWhere((c) => c.$name == 'email')
              as GeneratedColumn<String>;
      expect(emailColumn.$nullable, isTrue);
      expect(emailColumn.type, equals(DriftSqlType.string));
    });

    test('preferred_language has default value', () {
      final langColumn =
          database.users.$columns.firstWhere(
                (c) => c.$name == 'preferred_language',
              )
              as GeneratedColumn<String>;
      expect(langColumn.defaultValue, isNotNull);
    });

    test('is_online has default value of false', () {
      final onlineColumn =
          database.users.$columns.firstWhere((c) => c.$name == 'is_online')
              as GeneratedColumn<bool>;
      expect(onlineColumn.defaultValue, isNotNull);
    });
  });

  group('Users Table CRUD Operations', () {
    test('can insert a user', () async {
      final now = DateTime.now();
      final user = UsersCompanion.insert(
        uid: 'test-uid-123',
        name: 'Test User',
        createdAt: now,
        lastSeen: now,
      );

      await database.into(database.users).insert(user);

      final allUsers = await database.select(database.users).get();
      expect(allUsers.length, equals(1));
      expect(allUsers.first.uid, equals('test-uid-123'));
      expect(allUsers.first.name, equals('Test User'));
    });

    test('can insert user with optional fields', () async {
      final now = DateTime.now();
      final user = UsersCompanion.insert(
        uid: 'test-uid-456',
        name: 'John Doe',
        email: const Value('john@example.com'),
        phoneNumber: const Value('+1234567890'),
        imageUrl: const Value('https://example.com/avatar.jpg'),
        fcmToken: const Value('fcm-token-xyz'),
        preferredLanguage: const Value('es'),
        createdAt: now,
        lastSeen: now,
        isOnline: const Value(true),
      );

      await database.into(database.users).insert(user);

      final result = await (database.select(
        database.users,
      )..where((tbl) => tbl.uid.equals('test-uid-456'))).getSingle();

      expect(result.email, equals('john@example.com'));
      expect(result.phoneNumber, equals('+1234567890'));
      expect(result.imageUrl, equals('https://example.com/avatar.jpg'));
      expect(result.fcmToken, equals('fcm-token-xyz'));
      expect(result.preferredLanguage, equals('es'));
      expect(result.isOnline, isTrue);
    });

    test('can read a specific user by uid', () async {
      final now = DateTime.now();
      final user1 = UsersCompanion.insert(
        uid: 'user-1',
        name: 'User One',
        createdAt: now,
        lastSeen: now,
      );
      final user2 = UsersCompanion.insert(
        uid: 'user-2',
        name: 'User Two',
        createdAt: now,
        lastSeen: now,
      );

      await database.into(database.users).insert(user1);
      await database.into(database.users).insert(user2);

      final result = await (database.select(
        database.users,
      )..where((tbl) => tbl.uid.equals('user-2'))).getSingle();

      expect(result.uid, equals('user-2'));
      expect(result.name, equals('User Two'));
    });

    test('can update a user', () async {
      final now = DateTime.now();
      final user = UsersCompanion.insert(
        uid: 'user-update',
        name: 'Original Name',
        createdAt: now,
        lastSeen: now,
      );

      await database.into(database.users).insert(user);

      // Update the user
      await (database.update(
        database.users,
      )..where((tbl) => tbl.uid.equals('user-update'))).write(
        const UsersCompanion(
          name: Value('Updated Name'),
          isOnline: Value(true),
        ),
      );

      final updated = await (database.select(
        database.users,
      )..where((tbl) => tbl.uid.equals('user-update'))).getSingle();

      expect(updated.name, equals('Updated Name'));
      expect(updated.isOnline, isTrue);
    });

    test('can delete a user', () async {
      final now = DateTime.now();
      final user = UsersCompanion.insert(
        uid: 'user-delete',
        name: 'To Delete',
        createdAt: now,
        lastSeen: now,
      );

      await database.into(database.users).insert(user);

      // Verify user exists
      var allUsers = await database.select(database.users).get();
      expect(allUsers.length, equals(1));

      // Delete the user
      await (database.delete(
        database.users,
      )..where((tbl) => tbl.uid.equals('user-delete'))).go();

      // Verify user is deleted
      allUsers = await database.select(database.users).get();
      expect(allUsers.length, equals(0));
    });

    test('primary key constraint prevents duplicate uids', () async {
      final now = DateTime.now();
      final user1 = UsersCompanion.insert(
        uid: 'duplicate-uid',
        name: 'User One',
        createdAt: now,
        lastSeen: now,
      );
      final user2 = UsersCompanion.insert(
        uid: 'duplicate-uid',
        name: 'User Two',
        createdAt: now,
        lastSeen: now,
      );

      await database.into(database.users).insert(user1);

      // Attempting to insert duplicate uid should fail
      expect(
        () => database.into(database.users).insert(user2),
        throwsA(isA<SqliteException>()),
      );
    });

    test('can query users with isOnline filter', () async {
      final now = DateTime.now();

      // Insert online users
      await database
          .into(database.users)
          .insert(
            UsersCompanion.insert(
              uid: 'online-1',
              name: 'Online User 1',
              createdAt: now,
              lastSeen: now,
              isOnline: const Value(true),
            ),
          );

      await database
          .into(database.users)
          .insert(
            UsersCompanion.insert(
              uid: 'online-2',
              name: 'Online User 2',
              createdAt: now,
              lastSeen: now,
              isOnline: const Value(true),
            ),
          );

      // Insert offline user
      await database
          .into(database.users)
          .insert(
            UsersCompanion.insert(
              uid: 'offline-1',
              name: 'Offline User',
              createdAt: now,
              lastSeen: now,
              isOnline: const Value(false),
            ),
          );

      // Query online users
      final onlineUsers = await (database.select(
        database.users,
      )..where((tbl) => tbl.isOnline.equals(true))).get();

      expect(onlineUsers.length, equals(2));
      expect(onlineUsers.every((u) => u.isOnline), isTrue);
    });

    test('can query users by preferred language', () async {
      final now = DateTime.now();

      await database
          .into(database.users)
          .insert(
            UsersCompanion.insert(
              uid: 'spanish-user',
              name: 'Spanish User',
              preferredLanguage: const Value('es'),
              createdAt: now,
              lastSeen: now,
            ),
          );

      await database
          .into(database.users)
          .insert(
            UsersCompanion.insert(
              uid: 'french-user',
              name: 'French User',
              preferredLanguage: const Value('fr'),
              createdAt: now,
              lastSeen: now,
            ),
          );

      final spanishUsers = await (database.select(
        database.users,
      )..where((tbl) => tbl.preferredLanguage.equals('es'))).get();

      expect(spanishUsers.length, equals(1));
      expect(spanishUsers.first.preferredLanguage, equals('es'));
    });
  });

  group('Users Table Data Integrity', () {
    test('null values are properly handled', () async {
      final now = DateTime.now();
      final user = UsersCompanion.insert(
        uid: 'minimal-user',
        name: 'Minimal User',
        createdAt: now,
        lastSeen: now,
        // All optional fields left as null
      );

      await database.into(database.users).insert(user);

      final result = await (database.select(
        database.users,
      )..where((tbl) => tbl.uid.equals('minimal-user'))).getSingle();

      expect(result.email, isNull);
      expect(result.phoneNumber, isNull);
      expect(result.imageUrl, isNull);
      expect(result.fcmToken, isNull);
    });

    test('default values are applied correctly', () async {
      final now = DateTime.now();
      final user = UsersCompanion.insert(
        uid: 'default-values',
        name: 'Default User',
        createdAt: now,
        lastSeen: now,
        // preferredLanguage and isOnline should use defaults
      );

      await database.into(database.users).insert(user);

      final result = await (database.select(
        database.users,
      )..where((tbl) => tbl.uid.equals('default-values'))).getSingle();

      expect(result.preferredLanguage, equals('en')); // Default value
      expect(result.isOnline, isFalse); // Default value
    });
  });
}
