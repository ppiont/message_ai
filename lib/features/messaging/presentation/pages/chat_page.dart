/// Chat page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:message_ai/features/messaging/presentation/widgets/message_bubble.dart';
import 'package:message_ai/features/messaging/presentation/widgets/message_input.dart';
import 'package:message_ai/features/messaging/presentation/widgets/typing_indicator.dart';

/// Main chat screen for displaying and sending messages.
///
/// Shows messages in real-time, allows sending new messages,
/// and handles loading/empty states.
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({
    required this.conversationId,
    required this.otherParticipantName,
    super.key,
  });

  final String conversationId;
  final String otherParticipantName;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final Set<String> _markedAsRead = {}; // Track which messages we've marked

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Marks a message as read
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
            Text(widget.otherParticipantName),
            // TODO: Add online status / typing indicator
          ],
        ),
        actions: [
          // TODO: Add menu for conversation settings
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation settings coming soon!'),
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
      conversationMessagesStreamProvider(widget.conversationId),
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

            // Mark incoming messages as read (only once)
            if (!isMe &&
                status != 'read' &&
                !_markedAsRead.contains(messageId)) {
              _markMessageAsRead(messageId);
            }

            // Check if we should show timestamp
            final showTimestamp = _shouldShowTimestamp(messages, index);

            return MessageBubble(
              message: message['text'] as String,
              isMe: isMe,
              senderName: message['senderName'] as String? ?? 'Unknown',
              timestamp: message['timestamp'] as DateTime,
              showTimestamp: showTimestamp,
              status: status,
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
                conversationMessagesStreamProvider(widget.conversationId),
              ),
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
  }

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
