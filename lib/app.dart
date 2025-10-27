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
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app.g.dart';

// Global navigation key for handling notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Initializes app services asynchronously without blocking the UI
///
/// This provider ensures services are initialized AFTER the widget tree is built,
/// preventing main thread blocking during app startup.
@Riverpod(keepAlive: true)
void servicesInitializer(Ref ref) {
  // Watch auth state and initialize services when user signs in
  ref.listen(authStateProvider, (previous, next) {
    next.whenData((user) {
      if (user != null) {
        // Initialize services asynchronously (fire-and-forget)
        // This runs in a microtask to avoid blocking the current frame
        Future.microtask(() async {
          try {
            // Initialize user sync service
            ref.read(userSyncServiceProvider).startBackgroundSync();

            // REMOVED: AutoDeliveryMarker (was creating N+1 Firestore listeners)
            // Messages are marked as delivered when conversation is opened instead

            // Initialize FCM for push notifications
            await ref.read(fcmServiceProvider).initialize(
              userId: user.uid,
              onNotificationTap: ({
                required String conversationId,
                required String senderId,
              }) {
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
            debugPrint('⚠️ Service initialization error: $e');
          }
        });
      }
    });
  });
}

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
///
/// **Presence management:**
/// - Handled automatically by presenceController + RTDB onDisconnect()
/// - No manual lifecycle tracking needed (causes duplicate writes)
/// - RTDB handles connection loss, app kill, and network drops automatically
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch authentication state FIRST
    final authState = ref.watch(authStateProvider);

    // Initialize presence controller BEFORE checking user state
    // This ensures it can handle both sign-in AND sign-out events
    ref.watch(presenceControllerProvider);

    // Initialize services asynchronously (non-blocking)
    // This provider watches auth state and starts services in a microtask
    // No blocking operations during build - keeps UI responsive!
    ref.watch(servicesInitializerProvider);

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
