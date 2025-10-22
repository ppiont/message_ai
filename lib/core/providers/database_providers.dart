/// Database providers for Riverpod
library;

import 'package:message_ai/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_providers.g.dart';

/// Provides the [AppDatabase] instance.
///
/// This is a singleton provider that creates the database once
/// and keeps it alive for the lifetime of the app.
@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final database = AppDatabase();

  // Dispose when app closes
  ref.onDispose(() {
    database.close();
  });

  return database;
}
