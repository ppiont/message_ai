import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/database/daos/message_dao.dart';
import 'package:message_ai/core/providers/database_provider.dart';

void main() {
  group('Database Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() async {
      // Properly dispose the database before disposing container
      final db = container.read(databaseProvider);
      await db.close();
      container.dispose();
    });

    test('databaseProvider creates database instance', () {
      final database = container.read(databaseProvider);

      expect(database, isA<AppDatabase>());
      expect(database.schemaVersion, equals(1));
    });

    test('databaseProvider returns same instance on multiple reads', () {
      final database1 = container.read(databaseProvider);
      final database2 = container.read(databaseProvider);

      expect(identical(database1, database2), isTrue);
    });

    test('messageDaoProvider provides MessageDao', () {
      final messageDao = container.read(messageDaoProvider);

      expect(messageDao, isNotNull);
      // Verify it's from the same database instance
      final database = container.read(databaseProvider);
      expect(identical(messageDao, database.messageDao), isTrue);
    });

    test('conversationDaoProvider provides ConversationDao', () {
      final conversationDao = container.read(conversationDaoProvider);

      expect(conversationDao, isNotNull);
      // Verify it's from the same database instance
      final database = container.read(databaseProvider);
      expect(identical(conversationDao, database.conversationDao), isTrue);
    });

    test('userDaoProvider provides UserDao', () {
      final userDao = container.read(userDaoProvider);

      expect(userDao, isNotNull);
      // Verify it's from the same database instance
      final database = container.read(databaseProvider);
      expect(identical(userDao, database.userDao), isTrue);
    });

    test('DAOs share the same database instance', () {
      final messageDao = container.read(messageDaoProvider);
      final conversationDao = container.read(conversationDaoProvider);
      final userDao = container.read(userDaoProvider);

      // All DAOs should use the same database instance
      final database = container.read(databaseProvider);

      expect(identical(messageDao, database.messageDao), isTrue);
      expect(identical(conversationDao, database.conversationDao), isTrue);
      expect(identical(userDao, database.userDao), isTrue);
    });
  });

  group('ProviderScope Widget Integration', () {
    testWidgets('ProviderScope allows access to providers',
        (WidgetTester tester) async {
      var providerAccessed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              // Access provider in build
              final _ = ref.watch(databaseProvider);
              providerAccessed = true;
              return Container();
            },
          ),
        ),
      );

      expect(providerAccessed, isTrue);
    });

    testWidgets('Providers work correctly in widget tree',
        (WidgetTester tester) async {
      AppDatabase? capturedDatabase;
      MessageDao? capturedMessageDao;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              capturedDatabase = ref.watch(databaseProvider);
              capturedMessageDao = ref.watch(messageDaoProvider);
              return Container();
            },
          ),
        ),
      );

      expect(capturedDatabase, isNotNull);
      expect(capturedDatabase, isA<AppDatabase>());
      expect(capturedMessageDao, isNotNull);
      expect(identical(capturedMessageDao, capturedDatabase!.messageDao),
          isTrue);

      // Clean up
      await capturedDatabase!.close();
    });
  });
}
