/// Conversation list page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/authentication/presentation/pages/settings_page.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/messaging/presentation/pages/chat_page.dart';
import 'package:message_ai/features/messaging/presentation/pages/create_group_page.dart';
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
              if (value == 'settings') {
                _navigateToSettings();
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
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
          _showNewConversationMenu(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showNewConversationMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('New Chat'),
              subtitle: const Text('Start a 1-on-1 conversation'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const UserSelectionPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('New Group'),
              subtitle: const Text('Create a group conversation'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const CreateGroupPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList(String userId) {
    // Use optimized sorted conversation list with binary search insertion
    // This provider maintains sorted state and uses O(log n) insertion
    // instead of O(n log n) full re-sort on every update
    final conversations = ref.watch(sortedConversationListProvider(userId));

    if (conversations.isEmpty) {
      // Check if we're loading initial data
      final streamState = ref.watch(allConversationsStreamProvider(userId));
      return streamState.when(
        data: (_) => _buildEmptyState(),
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
                    ref.invalidate(sortedConversationListProvider(userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Use sorted conversation list (no need for .when since it's not async)
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

    // Extract all unique user IDs from all visible conversations for batch presence lookup
    // This replaces N individual presence subscriptions with 1 batch subscription
    final allUserIds = filteredConversations
        .expand(
          (conv) => (conv['participants'] as List<Map<String, dynamic>>)
              .map((p) => p['uid'] as String),
        )
        .toSet()
        .toList();

    // Watch batch presence (single subscription for all users)
    final presenceMapAsync = ref.watch(batchUserPresenceProvider(allUserIds));

    // Handle loading/error states for batch presence
    return presenceMapAsync.when(
          data: (presenceMap) => RefreshIndicator(
            onRefresh: () async {
              // Invalidate the stream to trigger a refresh
              ref.invalidate(allConversationsStreamProvider(userId));
              // Wait a bit for the refresh
              await Future<void>.delayed(const Duration(milliseconds: 500));
            },
            child: _buildConversationListView(
              userId,
              filteredConversations,
              presenceMap,
            ),
          ),
        // Presence loading state: show list without presence indicators
        loading: () => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allConversationsStreamProvider(userId));
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
          child: _buildConversationListView(
            userId,
            filteredConversations,
            const {}, // Empty map during loading
          ),
        ),
        // Presence error state: show list without presence indicators
        error: (_, _) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allConversationsStreamProvider(userId));
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
          child: _buildConversationListView(
            userId,
            filteredConversations,
            const {}, // Empty map on error
          ),
        ),
      );
  }

  /// Build a conversation list view with ListView.custom for optimal performance.
  ///
  /// Uses SliverChildBuilderDelegate with findChildIndexCallback to enable
  /// Flutter to efficiently map between widget positions and data indices.
  /// This improves scrolling performance, especially for large lists.
  Widget _buildConversationListView(
    String userId,
    List<Map<String, dynamic>> filteredConversations,
    Map<String, Map<String, dynamic>> presenceMap,
  ) {
    // Create a map for O(1) index lookup by conversation ID
    final conversationIdToIndex = <String, int>{};
    for (var i = 0; i < filteredConversations.length; i++) {
      final id = filteredConversations[i]['id'] as String;
      conversationIdToIndex[id] = i;
    }

    return ListView.custom(
      // Fixed height for conversation items (68px content + 8px padding top/bottom + 1px divider)
      // Using itemExtentBuilder for more accurate per-item height
      cacheExtent: 400, // Cache ~5 items above/below viewport for smooth scrolling
      childrenDelegate: SliverChildBuilderDelegate(
        (context, index) {
          // Every other index is a divider
          if (index.isOdd) {
            return const Divider(height: 1);
          }

          final itemIndex = index ~/ 2;
          if (itemIndex >= filteredConversations.length) {
            return null;
          }

          final conversation = filteredConversations[itemIndex];
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
              key: ValueKey(conversationId),
              conversationId: conversationId,
              participants: participants,
              lastMessage: conversation['lastMessage'] as String?,
              lastUpdatedAt: conversation['lastUpdatedAt'] as DateTime,
              unreadCount: conversation['unreadCount'] as int,
              currentUserId: userId,
              isGroup: true,
              groupName: groupName,
              participantCount: participantCount,
              presenceMap: presenceMap,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ChatPage(
                      conversationId: conversationId,
                      otherParticipantName: groupName,
                      otherParticipantId: '',
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
              otherParticipant = participants.isNotEmpty
                  ? participants.first
                  : {'name': 'Unknown', 'uid': ''};
            }
            final otherParticipantName =
                otherParticipant['name'] as String? ?? 'Unknown';
            final otherParticipantId =
                otherParticipant['uid'] as String? ?? '';

            return ConversationListItem(
              key: ValueKey(conversationId),
              conversationId: conversationId,
              participants: participants,
              lastMessage: conversation['lastMessage'] as String?,
              lastUpdatedAt: conversation['lastUpdatedAt'] as DateTime,
              unreadCount: conversation['unreadCount'] as int,
              currentUserId: userId,
              presenceMap: presenceMap,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ChatPage(
                      conversationId: conversationId,
                      otherParticipantName: otherParticipantName,
                      otherParticipantId: otherParticipantId,
                    ),
                  ),
                );
              },
            );
          }
        },
        childCount: filteredConversations.length * 2 - 1, // Items + dividers
        // findChildIndexCallback enables Flutter to efficiently find widgets
        // by their key, improving performance when list order changes
        findChildIndexCallback: (Key key) {
          if (key is ValueKey<String>) {
            final conversationId = key.value;
            final index = conversationIdToIndex[conversationId];
            if (index != null) {
              // Return the actual index in the list (accounting for dividers)
              return index * 2;
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEmptyState() => Center(
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

  void _showSearchDialog() {
    showDialog<void>(
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

  void _navigateToSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => const SettingsPage()));
  }

  Future<void> _handleLogout() async {
    final signOutUseCase = ref.read(signOutUseCaseProvider);
    final result = await signOutUseCase();

    result.fold(
      (failure) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        // Navigation handled by auth state listener in app.dart
        if (!mounted) {
          return;
        }
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
