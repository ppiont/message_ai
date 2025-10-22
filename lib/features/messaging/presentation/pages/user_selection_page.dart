/// User selection page for starting new conversations
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/presentation/pages/chat_page.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:message_ai/features/messaging/presentation/widgets/user_list_item.dart';

/// Page for selecting a user to start a new conversation.
///
/// Shows a searchable list of all users (excluding current user).
/// Tapping a user creates or finds an existing conversation and opens the chat.
class UserSelectionPage extends ConsumerStatefulWidget {
  const UserSelectionPage({super.key});

  @override
  ConsumerState<UserSelectionPage> createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends ConsumerState<UserSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCreatingConversation = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select User')),
        body: const Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Conversation')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // User list
          Expanded(child: _buildUserList(currentUser)),
          // Loading overlay
          if (_isCreatingConversation)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserList(User currentUser) => StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Trigger rebuild to retry
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter users
        final users = snapshot.data!.docs
            .map((doc) {
              final data = doc.data()! as Map<String, dynamic>;
              // Extract fields with proper null handling
              final uid = data['uid'] as String?;
              final displayName = data['displayName'] as String? ?? '';
              final email = data['email'] as String? ?? '';
              final photoURL = data['photoURL'] as String?;
              final preferredLanguage =
                  data['preferredLanguage'] as String? ?? 'en';

              // Skip users with missing required fields
              if (uid == null || uid.isEmpty) {
                return null;
              }

              return {
                'uid': uid,
                'displayName': displayName,
                'email': email,
                'photoURL': photoURL,
                'preferredLanguage': preferredLanguage,
              };
            })
            .where((user) => user != null)
            .cast<Map<String, dynamic>>()
            .where((user) => user['uid'] != currentUser.uid)
            .where((user) {
              if (_searchQuery.isEmpty) return true;
              final name = (user['displayName'] as String).toLowerCase();
              final email = (user['email'] as String).toLowerCase();
              return name.contains(_searchQuery) ||
                  email.contains(_searchQuery);
            })
            .toList();

        if (users.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index];
            return UserListItem(
              uid: user['uid'] as String,
              displayName: user['displayName'] as String,
              email: user['email'] as String,
              imageUrl: user['photoURL'] as String?,
              onTap: () => _handleUserSelected(
                currentUser,
                user['uid'] as String,
                user['displayName'] as String,
                user['email'] as String,
                user['photoURL'] as String?,
                user['preferredLanguage'] as String,
              ),
            );
          },
        );
      },
    );

  Widget _buildEmptyState() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty ? 'No users found' : 'No matching users',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Users will appear here once they sign up'
                : 'Try a different search term',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );

  Future<void> _handleUserSelected(
    User currentUser,
    String otherUserId,
    String otherUserName,
    String otherUserEmail,
    String? otherUserPhotoURL,
    String otherUserPreferredLanguage,
  ) async {
    setState(() {
      _isCreatingConversation = true;
    });

    try {
      // Create Participant objects for use case
      final currentUserParticipant = Participant(
        uid: currentUser.uid,
        name: currentUser.displayName,
        imageUrl: currentUser.photoURL,
        preferredLanguage: currentUser.preferredLanguage,
      );

      final otherUserParticipant = Participant(
        uid: otherUserId,
        name: otherUserName.isNotEmpty
            ? otherUserName
            : (otherUserEmail.isNotEmpty ? otherUserEmail : 'Unknown User'),
        imageUrl: otherUserPhotoURL,
        preferredLanguage: otherUserPreferredLanguage,
      );

      // Find or create conversation
      final findOrCreateUseCase = ref.read(
        findOrCreateDirectConversationUseCaseProvider,
      );
      final result = await findOrCreateUseCase(
        userId1: currentUser.uid,
        userId2: otherUserId,
        user1Participant: currentUserParticipant,
        user2Participant: otherUserParticipant,
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to create conversation: ${failure.message}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        },
        (conversation) {
          // Navigate to chat page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ChatPage(
                conversationId: conversation.documentId,
                otherParticipantName: otherUserName.isEmpty
                    ? otherUserEmail
                    : otherUserName,
                otherParticipantId: otherUserId,
              ),
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingConversation = false;
        });
      }
    }
  }
}
