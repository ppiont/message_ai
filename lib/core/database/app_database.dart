import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/database/daos/conversation_dao.dart';
import 'package:message_ai/core/database/daos/message_dao.dart';
import 'package:message_ai/core/database/daos/user_dao.dart';
import 'package:message_ai/core/database/tables/conversations_table.dart';
import 'package:message_ai/core/database/tables/messages_table.dart';
import 'package:message_ai/core/database/tables/users_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
@DriftDatabase(
  tables: [Users, Conversations, Messages],
  daos: [MessageDao, ConversationDao, UserDao],
)
class AppDatabase extends _$AppDatabase {
  /// Create database instance
  AppDatabase() : super(_openConnection());

  /// Create database instance for testing with custom executor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Migration from v1 to v2: Remove senderName column from messages
      if (from == 1 && to == 2) {
        // SQLite doesn't support DROP COLUMN directly, so we need to:
        // 1. Create new table without senderName
        // 2. Copy data from old table
        // 3. Drop old table
        // 4. Rename new table

        await customStatement('''
            CREATE TABLE messages_new (
              id TEXT NOT NULL PRIMARY KEY,
              conversation_id TEXT NOT NULL,
              message_text TEXT NOT NULL,
              sender_id TEXT NOT NULL,
              timestamp INTEGER NOT NULL,
              message_type TEXT NOT NULL DEFAULT 'text',
              status TEXT NOT NULL DEFAULT 'sending',
              detected_language TEXT,
              translations TEXT,
              reply_to TEXT,
              metadata TEXT,
              ai_analysis TEXT,
              embedding TEXT,
              sync_status TEXT NOT NULL DEFAULT 'pending',
              retry_count INTEGER NOT NULL DEFAULT 0,
              temp_id TEXT,
              last_sync_attempt INTEGER
            );
          ''');

        await customStatement('''
            INSERT INTO messages_new
            SELECT
              id,
              conversation_id,
              message_text,
              sender_id,
              timestamp,
              message_type,
              status,
              detected_language,
              translations,
              reply_to,
              metadata,
              ai_analysis,
              embedding,
              sync_status,
              retry_count,
              temp_id,
              last_sync_attempt
            FROM messages;
          ''');

        await customStatement('DROP TABLE messages;');
        await customStatement('ALTER TABLE messages_new RENAME TO messages;');

        debugPrint('✅ Migration v1→v2: Removed senderName column from messages');
      }

      // Migration from v2 to v3: Add cultural_hint column to messages
      if (from <= 2 && to >= 3) {
        // Add cultural_hint column to messages table
        await m.addColumn(messages, messages.culturalHint);
        debugPrint('✅ Migration v2→v3: Added culturalHint column to messages');
      }
    },
    beforeOpen: (details) async {
      // Enable foreign keys
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// Opens a connection to the database
LazyDatabase _openConnection() => LazyDatabase(() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final file = File(p.join(dbFolder.path, 'messageai.db'));

  // Use single-isolate database to avoid lock contention
  // Background isolate creates separate connection → database locks
  // Write queue ensures sequential writes within single isolate
  return NativeDatabase(
    file,
    logStatements: true, // Enable logging in debug mode
    setup: (db) {
      // Enable WAL mode for better concurrency
      // WAL allows multiple readers + one writer simultaneously
      db.execute('PRAGMA journal_mode = WAL');
    },
  );
});
