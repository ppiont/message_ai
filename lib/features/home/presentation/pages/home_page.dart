import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';

/// Home page displayed after successful authentication
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth state to get the current user
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MessageAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              final signOutUseCase = ref.read(signOutUseCaseProvider);
              await signOutUseCase();
            },
          ),
        ],
      ),
      body: Center(
        child: authState.when(
          data: (user) {
            if (user == null) {
              return const CircularProgressIndicator();
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 80, color: Colors.green),
                const SizedBox(height: 24),
                Text(
                  'Welcome!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  user.email ?? 'No email',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  user.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                const Text(
                  '🚧 Messaging features coming soon! 🚧',
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) =>
              Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
