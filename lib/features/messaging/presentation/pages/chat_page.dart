/// Chat page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/authentication/presentation/providers/user_lookup_provider.dart';
import 'package:message_ai/features/messaging/presentation/pages/group_management_page.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:message_ai/features/messaging/presentation/widgets/message_bubble.dart';
import 'package:message_ai/features/messaging/presentation/widgets/message_input.dart';
import 'package:message_ai/features/messaging/presentation/widgets/typing_indicator.dart';

/// Main chat screen for displaying and sending messages.
///
/// Shows messages in real-time, allows sending new messages,
/// and handles loading/empty states.
/// Supports both direct conversations and group chats.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({
    required this.conversationId,
    required this.otherParticipantName,
    required this.otherParticipantId,
    this.isGroup = false,
    super.key,
  });

  final String conversationId;
  final String otherParticipantName;
  final String otherParticipantId;
  final bool isGroup;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _markedAsRead =
      {}; // Track which messages we've marked as read

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Marks a message as read (when user actually sees it)
  /// Note: Messages are automatically marked as delivered in the repository
  void _markMessageAsRead(String messageId) {
    // Add to set immediately to prevent duplicate calls
    _markedAsRead.add(messageId);

    // Call use case asynchronously
    final markAsReadUseCase = ref.read(markMessageAsReadUseCaseProvider);
    markAsReadUseCase(widget.conversationId, messageId).then((result) {
      result.fold(
        (failure) {
          // Silently fail - read receipts are not critical
          // Remove from set so we can retry later
          _markedAsRead.remove(messageId);
        },
        (_) {
          // Success - keep in set
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.otherParticipantName)),
        body: const Center(child: Text('Please sign in to view messages')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // For direct conversations, dynamically look up the name
            // For groups, use the static group name
            if (widget.isGroup)
              Text(widget.otherParticipantName)
            else
              Consumer(
                builder: (context, ref, _) {
                  final displayNameAsync = ref.watch(
                    userDisplayNameProvider(widget.otherParticipantId),
                  );
                  return displayNameAsync.when(
                    data: (name) => Text(name),
                    loading: () => Text(widget.otherParticipantName), // Fallback
                    error: (_, __) => Text(widget.otherParticipantName), // Fallback
                  );
                },
              ),
            _buildPresenceStatus(),
          ],
        ),
        actions: [
          if (widget.isGroup)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GroupManagementPage(
                      conversationId: widget.conversationId,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(currentUser.uid)),
          _buildTypingIndicator(currentUser.uid),
          MessageInput(
            conversationId: widget.conversationId,
            currentUserId: currentUser.uid,
            currentUserName: currentUser.displayName,
            onMessageSent: _scrollToBottom,
          ),
        ],
      ),
    );
  }

  Widget _buildPresenceStatus() {
    if (widget.isGroup) {
      // Get conversation to extract participant IDs
      final conversationAsync = ref.watch(
        getConversationByIdProvider(widget.conversationId),
      );

      return conversationAsync.when(
        data: (conversation) {
          final participantIds = conversation.participants.map((p) => p.uid).toList();
          final groupPresenceAsync = ref.watch(
            groupPresenceStatusProvider(participantIds),
          );

          return groupPresenceAsync.when(
            data: (presence) {
              final displayText = presence['displayText'] as String? ?? '';
              final onlineCount = presence['onlineCount'] as int? ?? 0;

              if (displayText.isEmpty) return const SizedBox.shrink();

              return Text(
                displayText,
                style: TextStyle(
                  fontSize: 12,
                  color: onlineCount > 0 ? Colors.green : Colors.grey,
                  fontWeight: onlineCount > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      );
    } else {
      // Show individual user presence status
      final presenceAsync = ref.watch(
        userPresenceProvider(widget.otherParticipantId),
      );

      return presenceAsync.when(
        data: (presence) {
          if (presence == null) {
            return const SizedBox.shrink();
          }

          final isOnline = presence['isOnline'] as bool? ?? false;
          final lastSeen = presence['lastSeen'] as DateTime?;

          if (isOnline) {
            return const Text(
              'Online',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            );
          } else if (lastSeen != null) {
            return Text(
              'Last seen ${_formatLastSeen(lastSeen)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            );
          }

          return const SizedBox.shrink();
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      );
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'a while ago';
    }
  }

  Widget _buildTypingIndicator(String currentUserId) {
    final typingUsersAsync = ref.watch(
      conversationTypingUsersProvider(widget.conversationId, currentUserId),
    );

    return typingUsersAsync.when(
      data: (typingUsers) {
        final typingNames = typingUsers.map((u) => u.userName).toList();
        return TypingIndicator(typingUserNames: typingNames);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildMessageList(String currentUserId) {
    final messagesStream = ref.watch(
      conversationMessagesStreamProvider(widget.conversationId, currentUserId),
    );

    return messagesStream.when(
      data: (messages) {
        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        // Scroll to bottom when messages first load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollToBottom();
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message['senderId'] == currentUserId;
            final messageId = message['id'] as String;
            final status = message['status'] as String? ?? 'sent';

            // Mark incoming messages as read when user sees them (only once)
            // Only mark as read if already delivered (not sent)
            // Note: Messages are automatically marked as delivered in the repository
            if (!isMe &&
                status == 'delivered' &&
                !_markedAsRead.contains(messageId)) {
              _markMessageAsRead(messageId);
            }

            // Check if we should show timestamp
            final showTimestamp = _shouldShowTimestamp(messages, index);

            // Get current user for translation preferences
            final currentUser = ref.read(currentUserProvider);

            return MessageBubble(
              conversationId: widget.conversationId,
              messageId: messageId,
              message: message['text'] as String,
              senderId: message['senderId'] as String,
              isMe: isMe,
              timestamp: message['timestamp'] as DateTime,
              showTimestamp: showTimestamp,
              status: status,
              detectedLanguage: message['detectedLanguage'] as String?,
              translations: message['translations'] != null
                  ? Map<String, String>.from(message['translations'] as Map)
                  : null,
              userPreferredLanguage: currentUser?.preferredLanguage,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load messages: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(
                conversationMessagesStreamProvider(
                  widget.conversationId,
                  currentUserId,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
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
          'No messages yet',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          'Send a message to start the conversation',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
        ),
      ],
    ),
  );

  bool _shouldShowTimestamp(List<Map<String, dynamic>> messages, int index) {
    if (index == 0) return true; // Always show for first message

    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    final currentTime = currentMessage['timestamp'] as DateTime;
    final previousTime = previousMessage['timestamp'] as DateTime;

    // Show timestamp if messages are more than 5 minutes apart
    return currentTime.difference(previousTime).inMinutes > 5;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
