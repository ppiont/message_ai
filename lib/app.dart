import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/config/env_config.dart';
import 'package:message_ai/features/authentication/presentation/pages/auth_page.dart';
import 'package:message_ai/features/authentication/presentation/pages/profile_setup_page.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/authentication/presentation/providers/user_providers.dart';
import 'package:message_ai/features/messaging/presentation/pages/chat_page.dart';
import 'package:message_ai/features/messaging/presentation/pages/conversation_list_page.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';

// Global navigation key for handling notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Handles notification tap by fetching conversation details and navigating.
Future<void> _handleNotificationNavigation({
  required String conversationId,
  required String senderId,
  required NavigatorState navigator,
}) async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Determine collection based on conversation ID
    final isGroup = conversationId.startsWith('group-');
    final collection = isGroup ? 'group-conversations' : 'conversations';

    // Fetch conversation to get participant details
    final conversationDoc = await firestore
        .collection(collection)
        .doc(conversationId)
        .get();

    if (!conversationDoc.exists) {
      debugPrint('Conversation $conversationId not found');
      return;
    }

    final conversationData = conversationDoc.data()!;

    if (isGroup) {
      // For groups, navigate with group name
      final groupName = conversationData['name'] as String? ?? 'Group Chat';
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (context) => ChatPage(
            conversationId: conversationId,
            otherParticipantId: conversationId,
            otherParticipantName: groupName,
            isGroup: true,
          ),
        ),
      );
    } else {
      // For direct chats, fetch sender's name
      final senderDoc = await firestore.collection('users').doc(senderId).get();

      final senderName =
          senderDoc.data()?['displayName'] as String? ??
          senderDoc.data()?['email'] as String? ??
          'Unknown User';

      await navigator.push(
        MaterialPageRoute<void>(
          builder: (context) => ChatPage(
            conversationId: conversationId,
            otherParticipantId: senderId,
            otherParticipantName: senderName,
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('Failed to navigate from notification: $e');
  }
}

/// Root application widget
///
/// This widget serves as the entry point for the MaterialApp configuration.
/// It will be configured with:
/// - Theme configuration
/// - Routing setup
/// - State management (Riverpod)
/// - Authentication state handling
/// - Offline-first sync services
/// - Push notification handling with navigation
/// - App lifecycle management for presence tracking
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Register lifecycle observer to handle app backgrounding/foregrounding
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Get current user for presence updates
    final authState = ref.read(authStateProvider);
    final user = authState.value;

    if (user == null) {
      return; // Not authenticated, skip presence updates
    }

    // Get presence service
    final presenceService = ref.read(presenceServiceProvider);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - set online and configure onDisconnect
        presenceService.setOnline(userId: user.uid, userName: user.displayName);

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App went to background - set offline as backup
        // (onDisconnect will also trigger if connection is lost)
        presenceService.setOffline(
          userId: user.uid,
          userName: user.displayName,
        );

      case AppLifecycleState.detached:
        // App is about to be killed - set offline
        presenceService.setOffline(
          userId: user.uid,
          userName: user.displayName,
        );

      case AppLifecycleState.hidden:
        // App is hidden (similar to paused)
        presenceService.setOffline(
          userId: user.uid,
          userName: user.displayName,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch authentication state FIRST
    final authState = ref.watch(authStateProvider);

    // Only initialize services if user is authenticated
    // This prevents errors during logout when widget tree is unstable
    final user = authState.value;
    if (user != null) {
      // Initialize offline-first services
      // These are keepAlive providers, so watching them ensures they start
      // Note: MessageSyncService and MessageQueue removed - now handled by WorkManager
      // Initialize presence controller
      // Automatically manages online/offline status based on auth
      ref.watch(presenceControllerProvider);

      // Initialize user sync service
      // Automatically syncs user profiles from Firestore to Drift
      ref.watch(userSyncServiceProvider).startBackgroundSync();

      // Initialize auto delivery marker
      // Automatically marks incoming messages as delivered across all conversations
      try {
        ref.watch(autoDeliveryMarkerProvider);
      } catch (e) {
        // Silently fail if marker can't be initialized
        debugPrint('Auto delivery marker initialization failed: $e');
      }

      // Initialize FCM for push notifications
      // This is done here (not in sign-in/sign-up pages) to avoid unmounted widget issues
      try {
        ref
            .read(fcmServiceProvider)
            .initialize(
              userId: user.uid,
              onNotificationTap:
                  ({required String conversationId, required String senderId}) {
                    // Navigate to chat page when notification is tapped
                    // Using global navigator key to handle navigation from any app state
                    final navigator = navigatorKey.currentState;
                    if (navigator != null) {
                      _handleNotificationNavigation(
                        conversationId: conversationId,
                        senderId: senderId,
                        navigator: navigator,
                      );
                    }
                  },
            );
      } catch (e) {
        // Silently fail if FCM can't be initialized
        debugPrint('FCM initialization failed: $e');
      }
    }

    return MaterialApp(
      navigatorKey: navigatorKey, // For notification navigation
      title: envConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: authState.when(
        data: (user) {
          if (user != null) {
            // Check if user has completed profile setup
            if (user.displayName.isEmpty) {
              return const ProfileSetupPage();
            }
            return const ConversationListPage();
          } else {
            return const AuthPage();
          }
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Refresh the auth state
                    ref.invalidate(authStateProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
