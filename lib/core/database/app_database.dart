import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/users_table.dart';
import 'tables/conversations_table.dart';
import 'tables/messages_table.dart';

part 'app_database.g.dart';

/// Main application database
///
/// This database handles all local data persistence for offline-first architecture.
/// Uses drift for type-safe SQL queries and reactive streams.
///
/// Features:
/// - Offline-first message storage
/// - Conversation metadata
/// - User profiles cache
/// - Message queue for syncing
@DriftDatabase(tables: [Users, Conversations, Messages], daos: [])
class AppDatabase extends _$AppDatabase {
  /// Create database instance
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations will be handled here
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

/// Opens a connection to the database
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'messageai.db'));

    return NativeDatabase.createInBackground(
      file,
      logStatements: true, // Enable logging in debug mode
    );
  });
}
