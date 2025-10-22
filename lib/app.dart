import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/config/env_config.dart';
import 'package:message_ai/features/authentication/presentation/pages/auth_page.dart';
import 'package:message_ai/features/authentication/presentation/pages/profile_setup_page.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/messaging/presentation/pages/conversation_list_page.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';

/// Root application widget
///
/// This widget serves as the entry point for the MaterialApp configuration.
/// It will be configured with:
/// - Theme configuration
/// - Routing setup
/// - State management (Riverpod)
/// - Authentication state handling
/// - Offline-first sync services
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch authentication state FIRST
    final authState = ref.watch(authStateProvider);

    // Only initialize services if user is authenticated
    // This prevents errors during logout when widget tree is unstable
    final user = authState.value;
    if (user != null) {
      // Initialize offline-first services
      // These are keepAlive providers, so watching them ensures they start
      ref.watch(messageSyncServiceProvider);
      ref.watch(messageQueueProvider);

      // Initialize presence controller
      // Automatically manages online/offline status based on auth
      ref.watch(presenceControllerProvider);

      // Initialize auto delivery marker
      // Automatically marks incoming messages as delivered across all conversations
      try {
        ref.watch(autoDeliveryMarkerProvider);
      } catch (e) {
        // Silently fail if marker can't be initialized
      }

      // Initialize FCM for push notifications
      // This is done here (not in sign-in/sign-up pages) to avoid unmounted widget issues
      try {
        final fcmService = ref.read(fcmServiceProvider);
        fcmService.initialize(userId: user.uid);
      } catch (e) {
        // Silently fail if FCM can't be initialized
        print('FCM initialization failed: $e');
      }
    }

    return MaterialApp(
      title: envConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 48,
                ),
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
