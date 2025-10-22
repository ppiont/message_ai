/// Conversation list page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/messaging/presentation/pages/chat_page.dart';
import 'package:message_ai/features/messaging/presentation/pages/user_selection_page.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:message_ai/features/messaging/presentation/widgets/conversation_list_item.dart';

/// Main page displaying the list of user's conversations.
///
/// Shows conversations sorted by last updated time, with real-time updates.
/// Includes pull-to-refresh, search, and handles empty/loading/error states.
class ConversationListPage extends ConsumerStatefulWidget {
  const ConversationListPage({super.key});

  @override
  ConsumerState<ConversationListPage> createState() =>
      _ConversationListPageState();
}

class _ConversationListPageState extends ConsumerState<ConversationListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          // Search icon
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              _showSearchDialog();
            },
          ),
          // Menu (for future: settings, logout, etc.)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
            ],
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text('Please sign in to view conversations'))
          : _buildConversationList(currentUser.uid),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UserSelectionPage()),
          );
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildConversationList(String userId) {
    // Use unified stream that includes both direct conversations and groups
    final conversationsStream = ref.watch(
      allConversationsStreamProvider(userId),
    );

    return conversationsStream.when(
      data: (conversations) {
        // Filter conversations based on search query
        final filteredConversations = _searchQuery.isEmpty
            ? conversations
            : conversations.where((conv) {
                final type = conv['type'] as String?;

                // For groups, search by group name
                if (type == 'group') {
                  final groupName = conv['groupName'] as String? ?? '';
                  return groupName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
                }

                // For direct conversations, search by participant name
                final participants =
                    conv['participants'] as List<Map<String, dynamic>>;
                return participants.any((p) {
                  final name = p['name'] as String? ?? '';
                  return name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
                });
              }).toList();

        if (filteredConversations.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Invalidate the stream to trigger a refresh
            ref.invalidate(allConversationsStreamProvider(userId));
            // Wait a bit for the refresh
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.separated(
            itemCount: filteredConversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = filteredConversations[index];
              final conversationId = conversation['id'] as String;
              final type = conversation['type'] as String?;
              final participants =
                  conversation['participants'] as List<Map<String, dynamic>>;

              // Handle groups vs direct conversations
              if (type == 'group') {
                // Group conversation
                final groupName =
                    conversation['groupName'] as String? ?? 'Unknown Group';
                final participantCount =
                    conversation['participantCount'] as int? ?? 0;

                return ConversationListItem(
                  conversationId: conversationId,
                  participants: participants,
                  lastMessage: conversation['lastMessage'] as String?,
                  lastUpdatedAt: conversation['lastUpdatedAt'] as DateTime,
                  unreadCount: conversation['unreadCount'] as int,
                  currentUserId: userId,
                  isGroup: true,
                  groupName: groupName,
                  participantCount: participantCount,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          conversationId: conversationId,
                          otherParticipantName: groupName,
                          otherParticipantId: '', // Not used for groups
                          isGroup: true,
                        ),
                      ),
                    );
                  },
                );
              } else {
                // Direct conversation
                Map<String, dynamic> otherParticipant;
                try {
                  otherParticipant = participants.firstWhere(
                    (p) => p['uid'] != userId,
                  );
                } catch (e) {
                  // Fallback to first participant if not found
                  otherParticipant = participants.isNotEmpty
                      ? participants.first
                      : {'name': 'Unknown', 'uid': ''};
                }
                final otherParticipantName =
                    otherParticipant['name'] as String? ?? 'Unknown';
                final otherParticipantId =
                    otherParticipant['uid'] as String? ?? '';

                return ConversationListItem(
                  conversationId: conversationId,
                  participants: participants,
                  lastMessage: conversation['lastMessage'] as String?,
                  lastUpdatedAt: conversation['lastUpdatedAt'] as DateTime,
                  unreadCount: conversation['unreadCount'] as int,
                  currentUserId: userId,
                  isGroup: false,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          conversationId: conversationId,
                          otherParticipantName: otherParticipantName,
                          otherParticipantId: otherParticipantId,
                          isGroup: false,
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load conversations: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(allConversationsStreamProvider(userId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty
                ? 'No conversations yet'
                : 'No conversations found',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Start a new conversation to get started'
                : 'Try a different search term',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Conversations'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter name...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final signOutUseCase = ref.read(signOutUseCaseProvider);
    final result = await signOutUseCase();

    result.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        // Navigation handled by auth state listener in app.dart
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }
}
