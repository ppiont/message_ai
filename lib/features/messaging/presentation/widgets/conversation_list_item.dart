/// Conversation list item widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:message_ai/features/authentication/presentation/providers/user_lookup_provider.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';

/// Widget displaying a single conversation in the conversation list.
///
/// Shows participant info, last message preview, timestamp, unread badge, and online status.
/// Supports both direct conversations and group chats.
class ConversationListItem extends ConsumerWidget {
  const ConversationListItem({
    required this.conversationId,
    required this.participants,
    required this.currentUserId,
    required this.lastUpdatedAt,
    required this.onTap,
    this.lastMessage,
    this.unreadCount = 0,
    this.isGroup = false,
    this.groupName,
    this.participantCount,
    super.key,
  });

  final String conversationId;
  final List<Map<String, dynamic>> participants;
  final String? lastMessage;
  final DateTime lastUpdatedAt;
  final int unreadCount;
  final String currentUserId;
  final VoidCallback onTap;
  final bool isGroup;
  final String? groupName;
  final int? participantCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isGroup) {
      // Group conversation
      final name = groupName ?? 'Unknown Group';
      final participantIds = participants
          .map((p) => p['uid'] as String)
          .toList();
      final groupPresenceAsync = ref.watch(
        groupPresenceStatusProvider(participantIds),
      );

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildGroupAvatarWithPresence(name, groupPresenceAsync),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTimestamp(lastUpdatedAt),
              style: TextStyle(
                fontSize: 12,
                color: unreadCount > 0
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
                fontWeight: unreadCount > 0
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lastMessage ?? 'No messages yet',
                    style: TextStyle(
                      color: lastMessage == null
                          ? Colors.grey
                          : Colors.grey[700],
                      fontWeight: unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Show member count and online status
                  groupPresenceAsync.when(
                    data: (presence) {
                      final onlineCount = presence['onlineCount'] as int? ?? 0;
                      final totalCount =
                          presence['totalCount'] as int? ??
                          participantCount ??
                          0;
                      return Text(
                        onlineCount > 0
                            ? '$onlineCount/$totalCount online'
                            : '$totalCount members',
                        style: TextStyle(
                          fontSize: 11,
                          color: onlineCount > 0
                              ? Colors.green
                              : Colors.grey[600],
                          fontWeight: onlineCount > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      );
                    },
                    loading: () => Text(
                      '${participantCount ?? 0} members',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    error: (_, _) => Text(
                      '${participantCount ?? 0} members',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              _buildUnreadBadge(context),
            ],
          ],
        ),
        onTap: onTap,
      );
    } else {
      // Direct conversation
      Map<String, dynamic> otherParticipant;
      try {
        otherParticipant = participants.firstWhere(
          (p) => p['uid'] != currentUserId,
        );
      } catch (e) {
        // Fallback to first participant if not found
        otherParticipant = participants.isNotEmpty
            ? participants.first
            : {'uid': '', 'imageUrl': null};
      }

      final imageUrl = otherParticipant['imageUrl'] as String?;
      final otherUserId = otherParticipant['uid'] as String? ?? '';

      // Watch presence for the other user
      final presenceAsync = ref.watch(userPresenceProvider(otherUserId));

      // Dynamically look up display name
      final displayNameAsync = ref.watch(userDisplayNameProvider(otherUserId));

      return displayNameAsync.when(
        data: (displayName) => ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: _buildAvatarWithPresence(
            displayName,
            imageUrl,
            presenceAsync,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: unreadCount > 0
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimestamp(lastUpdatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: unreadCount > 0
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                  fontWeight: unreadCount > 0
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  lastMessage ?? 'No messages yet',
                  style: TextStyle(
                    color: lastMessage == null ? Colors.grey : Colors.grey[700],
                    fontWeight: unreadCount > 0
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                _buildUnreadBadge(context),
              ],
            ],
          ),
          onTap: onTap,
        ),
        loading: () => ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: _buildAvatarWithPresence(
            'Loading...',
            imageUrl,
            presenceAsync,
          ),
          title: const Text('Loading...'),
          onTap: onTap,
        ),
        error: (_, _) => ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: _buildAvatarWithPresence('Unknown', imageUrl, presenceAsync),
          title: const Text('Unknown'),
          onTap: onTap,
        ),
      );
    }
  }

  Widget _buildGroupAvatarWithPresence(
    String name,
    AsyncValue<Map<String, dynamic>> groupPresenceAsync,
  ) => Stack(
    children: [
      _buildGroupAvatar(name),
      // Online indicator (bottom-right of avatar)
      groupPresenceAsync.when(
        data: (presence) {
          final onlineCount = presence['onlineCount'] as int? ?? 0;
          if (onlineCount == 0) return const SizedBox.shrink();

          return Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    ],
  );

  Widget _buildAvatarWithPresence(
    String name,
    String? imageUrl,
    AsyncValue<Map<String, dynamic>?> presenceAsync,
  ) => Stack(
    children: [
      _buildAvatar(name, imageUrl),
      // Presence indicator (bottom-right of avatar)
      presenceAsync.when(
        data: (presence) {
          if (presence == null) return const SizedBox.shrink();

          final isOnline = presence['isOnline'] as bool? ?? false;
          return Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    ],
  );

  Widget _buildGroupAvatar(String name) {
    // Generate color from name for consistent avatar colors
    final color = _generateColorFromString(name);

    return CircleAvatar(
      radius: 28,
      backgroundColor: color,
      child: const Icon(Icons.group, color: Colors.white, size: 28),
    );
  }

  Widget _buildAvatar(String name, String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(imageUrl),
        backgroundColor: Colors.grey[300],
      );
    }

    // Generate color from name for consistent avatar colors
    final color = _generateColorFromString(name);

    return CircleAvatar(
      radius: 28,
      backgroundColor: color,
      child: Text(
        _getInitials(name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUnreadBadge(BuildContext context) {
    final displayCount = unreadCount > 99 ? '99+' : '$unreadCount';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minWidth: 24),
      child: Text(
        displayCount,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat.jm().format(timestamp); // e.g., "3:45 PM"
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat.E().format(timestamp); // e.g., "Mon"
    } else if (difference.inDays < 365) {
      // This year - show month and day
      return DateFormat.MMMd().format(timestamp); // e.g., "Jan 15"
    } else {
      // Older - show full date
      return DateFormat.yMMMd().format(timestamp); // e.g., "Jan 15, 2024"
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Color _generateColorFromString(String str) {
    // Generate consistent color from string hash
    var hash = 0;
    for (var i = 0; i < str.length; i++) {
      hash = str.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Use predefined Material colors for better aesthetics
    final colors = [
      Colors.blue[700]!,
      Colors.green[700]!,
      Colors.orange[700]!,
      Colors.purple[700]!,
      Colors.red[700]!,
      Colors.teal[700]!,
      Colors.pink[700]!,
      Colors.indigo[700]!,
      Colors.cyan[700]!,
      Colors.amber[700]!,
    ];

    return colors[hash.abs() % colors.length];
  }
}
