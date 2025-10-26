import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/app.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/error/error_logger.dart';
import 'package:message_ai/core/network/network_info.dart';
import 'package:message_ai/core/presentation/pages/splash_page.dart';
import 'package:message_ai/features/messaging/data/services/fcm_service.dart';
import 'package:message_ai/workers/delivery_tracking_worker.dart';
import 'package:message_ai/workers/message_sync_worker.dart';
import 'package:message_ai/workers/read_receipt_worker.dart';
import 'package:workmanager/workmanager.dart';

/// Unified WorkManager callback dispatcher for all background tasks.
///
/// MUST be a top-level function (cannot be in a class or async).
/// This is called by the Android/iOS system when a background task runs.
///
/// Handles:
/// - message-sync: Sync pending messages to Firestore
/// - delivery-tracking: Sync delivery confirmations to Firestore
/// - read-receipt-sync: Sync read receipts to Firestore
@pragma('vm:entry-point')
void workManagerCallbackDispatcher() {
  Workmanager().executeTask((
    String task,
    Map<String, dynamic>? inputData,
  ) async {
    debugPrint('[WorkManager] Executing task: $task');

    AppDatabase? database;

    try {
      // Initialize Firebase (required for Firestore access in background isolate)
      await Firebase.initializeApp();

      // Initialize Drift database
      database = AppDatabase();

      // Route to appropriate worker based on task name
      switch (task) {
        case 'message-sync':
          final networkInfo = NetworkInfoImpl(Connectivity());
          final worker = MessageSyncWorker(
            database: database,
            networkInfo: networkInfo,
          );
          final result = await worker.syncAll();
          debugPrint(
            '[WorkManager] message-sync complete: ${result.synced} synced, ${result.failed} failed',
          );
          return true;

        case 'delivery-tracking':
          final worker = DeliveryTrackingWorker(database: database);
          final result = await worker.processDeliveries();
          debugPrint(
            '[WorkManager] delivery-tracking complete: ${result.synced} synced, ${result.failed} failed',
          );
          return true;

        case 'read-receipt-sync':
          final worker = ReadReceiptWorker(database: database);
          final result = await worker.syncReadReceipts();
          debugPrint(
            '[WorkManager] read-receipt-sync complete: ${result.synced} synced, ${result.failed} failed',
          );
          return true;

        default:
          debugPrint('[WorkManager] Unknown task: $task');
          return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[WorkManager] Task failed: $e');
      debugPrint('[WorkManager] Stack trace: $stackTrace');
      return false;
    } finally {
      // Clean up database connection
      await database?.close();
    }
  });
}

/// Application entry point
///
/// **Optimized Startup Pattern (Task 10.1):**
/// 1. Show splash screen immediately (<100ms)
/// 2. Initialize services asynchronously in background
/// 3. Transition to main app when initialization complete
/// 4. Handle initialization errors gracefully
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Show splash screen immediately (no blocking operations)
  // This provides instant visual feedback to the user
  runApp(const SplashPage());

  try {
    // Initialize services asynchronously
    await _initializeApp();

    // Initialization successful - run the main app
    runApp(const ProviderScope(child: App()));
  } catch (error, stackTrace) {
    // Initialization failed - show error screen
    debugPrint('[Initialization] Failed: $error');
    debugPrint('[Initialization] Stack trace: $stackTrace');

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // User can restart the app manually
                    // In a real app, you might want to implement retry logic
                  },
                  child: const Text('Report Issue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Initialize all app services.
///
/// **Parallel Initialization (Task 10.2):**
/// Independent services run in parallel using Future.wait for optimal performance.
/// Target: 40-60% reduction in total initialization time.
Future<void> _initializeApp() async {
  final startTime = DateTime.now();
  debugPrint('[Initialization] Starting...');

  // Phase 1: Parallelize truly independent services
  // Firebase and ErrorLogger have no dependencies on each other
  await Future.wait([
    _initializeFirebase(),
    _initializeErrorLogger(),
  ]);

  // Phase 2: Parallelize services that depend on Firebase but not each other
  // FCM handler and WorkManager both need Firebase but are independent
  await Future.wait([
    _initializeFCMHandler(),
    _initializeWorkManager(),
  ]);

  // Phase 3: Register background tasks (depends on WorkManager)
  await _registerPeriodicTasks();

  final duration = DateTime.now().difference(startTime);
  debugPrint('[Initialization] Complete in ${duration.inMilliseconds}ms!');
}

/// Initialize Firebase.
///
/// **Timing:** ~200-500ms (depends on network)
Future<void> _initializeFirebase() async {
  final startTime = DateTime.now();
  debugPrint('[Initialization] Firebase starting...');

  await Firebase.initializeApp();

  final duration = DateTime.now().difference(startTime);
  debugPrint('[Initialization] Firebase complete (${duration.inMilliseconds}ms)');
}

/// Register Firebase Cloud Messaging background handler.
///
/// **Timing:** <10ms (synchronous operation)
/// **Dependency:** Requires Firebase.initializeApp()
Future<void> _initializeFCMHandler() async {
  final startTime = DateTime.now();
  debugPrint('[Initialization] FCM background handler starting...');

  // MUST be called AFTER Firebase.initializeApp()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final duration = DateTime.now().difference(startTime);
  debugPrint(
    '[Initialization] FCM background handler complete (${duration.inMilliseconds}ms)',
  );
}

/// Initialize WorkManager for background tasks.
///
/// **Timing:** ~100-300ms (depends on platform)
/// **Dependency:** Requires Firebase.initializeApp() (for background isolate)
Future<void> _initializeWorkManager() async {
  final startTime = DateTime.now();
  debugPrint('[Initialization] WorkManager starting...');

  await Workmanager().initialize(workManagerCallbackDispatcher);

  final duration = DateTime.now().difference(startTime);
  debugPrint('[Initialization] WorkManager complete (${duration.inMilliseconds}ms)');
}

/// Initialize error logging.
///
/// **Timing:** ~50-150ms
/// **Dependency:** None (independent service)
Future<void> _initializeErrorLogger() async {
  final startTime = DateTime.now();
  debugPrint('[Initialization] Error logging starting...');

  await ErrorLogger.initialize();

  final duration = DateTime.now().difference(startTime);
  debugPrint('[Initialization] Error logging complete (${duration.inMilliseconds}ms)');
}

/// Register periodic WorkManager tasks
///
/// These tasks run in the background even when the app is closed.
/// WorkManager handles scheduling, retries, and battery optimization.
Future<void> _registerPeriodicTasks() async {
  // Message sync: Every 15 minutes
  // Syncs pending messages from Drift to Firestore
  await Workmanager().registerPeriodicTask(
    'message-sync',
    'message-sync',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
  );

  // Delivery tracking: Every 15 minutes (minimum periodic interval)
  // Syncs message delivery status to Firestore
  await Workmanager().registerPeriodicTask(
    'delivery-tracking',
    'delivery-tracking',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  debugPrint('[WorkManager] Periodic tasks registered');
}
