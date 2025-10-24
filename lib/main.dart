import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/app.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/error/error_logger.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_local_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/message_local_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/repositories/conversation_repository_impl.dart';
import 'package:message_ai/features/messaging/data/repositories/message_repository_impl.dart';
import 'package:message_ai/features/messaging/data/services/fcm_service.dart';
import 'package:message_ai/features/messaging/data/services/message_sync_service.dart';
import 'package:workmanager/workmanager.dart';

/// Top-level callback dispatcher for WorkManager background tasks.
///
/// MUST be a top-level function (cannot be in a class or async).
/// This is called by the Android/iOS system when a background task runs.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask(
    (String task, Map<String, dynamic>? inputData) async {
      try {
        debugPrint('[WorkManager] Executing task: $task');

        switch (task) {
          case 'syncPendingMessages':
            await _syncPendingMessagesTask();
            return true;
          default:
            debugPrint('[WorkManager] Unknown task: $task');
            return false;
        }
      } catch (e) {
        debugPrint('[WorkManager] Task failed: $e');
        return false;
      }
    },
  );
}

/// Background task to sync pending messages.
///
/// This runs even when the app is closed, triggered by WorkManager.
Future<void> _syncPendingMessagesTask() async {
  debugPrint('[WorkManager] Starting pending messages sync...');

  try {
    // Initialize Firebase (required for Firestore access)
    await Firebase.initializeApp();

    // Initialize Drift database
    final database = AppDatabase();

    // Initialize data sources
    final messageLocalDataSource = MessageLocalDataSourceImpl(
      messageDao: database.messageDao,
    );
    final messageRemoteDataSource = MessageRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    );
    final conversationLocalDataSource = ConversationLocalDataSourceImpl(
      conversationDao: database.conversationDao,
    );
    final conversationRemoteDataSource = ConversationRemoteDataSourceImpl(
      firestore: FirebaseFirestore.instance,
    );

    // Initialize repositories
    final messageRepository = MessageRepositoryImpl(
      remoteDataSource: messageRemoteDataSource,
      localDataSource: messageLocalDataSource,
    );
    final conversationRepository = ConversationRepositoryImpl(
      remoteDataSource: conversationRemoteDataSource,
      localDataSource: conversationLocalDataSource,
    );

    // Initialize sync service
    final syncService = MessageSyncService(
      messageLocalDataSource: messageLocalDataSource,
      messageRepository: messageRepository,
      conversationLocalDataSource: conversationLocalDataSource,
      conversationRepository: conversationRepository,
      messageDao: database.messageDao,
    );

    // Perform sync
    final result = await syncService.syncAll();

    debugPrint(
      '[WorkManager] Sync complete: ${result.messagesSynced} messages, ${result.conversationsSynced} conversations',
    );

    // Clean up
    await database.close();
  } catch (e) {
    debugPrint('[WorkManager] Sync failed: $e');
    rethrow;
  }
}

/// Application entry point
///
/// Initializes Firebase and the Flutter application.
/// Sets up error handling and runs the root App widget.
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Register background message handler
  // MUST be called AFTER Firebase.initializeApp() and BEFORE runApp()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize WorkManager for background tasks
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kDebugMode,
  );

  // Initialize error logging
  await ErrorLogger.initialize();

  // Run the app with Riverpod
  runApp(const ProviderScope(child: App()));
}
