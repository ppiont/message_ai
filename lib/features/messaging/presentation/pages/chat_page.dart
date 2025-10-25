/// Chat page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/presentation/providers/auth_providers.dart';
import 'package:message_ai/features/authentication/presentation/providers/user_lookup_provider.dart';
import 'package:message_ai/features/messaging/data/services/typing_indicator_service.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/presentation/pages/group_management_page.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:message_ai/features/messaging/presentation/widgets/message_bubble.dart';
import 'package:message_ai/features/messaging/presentation/widgets/message_input.dart';
import 'package:message_ai/features/messaging/presentation/widgets/typing_indicator.dart';
import 'package:message_ai/features/smart_replies/presentation/widgets/smart_reply_bar.dart';
import 'package:message_ai/features/translation/data/services/auto_translation_service.dart';
import 'package:message_ai/features/translation/presentation/providers/translation_providers.dart';

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
  final TextEditingController _messageInputController = TextEditingController();

  /// Latest incoming message (for smart reply generation)
  Message? _latestIncomingMessage;

  /// Track previous message count to detect new messages vs updates
  int _previousMessageCount = 0;

  /// Auto-translation service instance (saved to avoid using ref in dispose)
  AutoTranslationService? _autoTranslationService;

  @override
  void initState() {
    super.initState();

    // Start auto-translation service when entering conversation
    // This will automatically translate incoming messages based on user preference
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserWithFirestoreProvider).value;
      if (currentUser != null) {
        _autoTranslationService = ref.read(autoTranslationServiceProvider);
        _autoTranslationService!.start(
          conversationId: widget.conversationId,
          currentUserId: currentUser.uid,
          userPreferredLanguage: currentUser.preferredLanguage,
        );
      }
    });
  }

  @override
  void dispose() {
    // Stop auto-translation service when leaving conversation
    // Safe: using saved instance instead of ref.read() during dispose
    _autoTranslationService?.stop();

    _scrollController.dispose();
    _messageInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use currentUserWithFirestoreProvider to get actual preferredLanguage from Firestore
    final currentUserAsync = ref.watch(currentUserWithFirestoreProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.otherParticipantName)),
            body: const Center(child: Text('Please sign in to view messages')),
          );
        }

        return _buildChatScaffold(context, currentUser);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(widget.otherParticipantName)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(widget.otherParticipantName)),
        body: Center(child: Text('Error loading user data: $error')),
      ),
    );
  }

  Widget _buildChatScaffold(BuildContext context, User currentUser) => Scaffold(
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
                  data: Text.new,
                  loading: () => Text(widget.otherParticipantName), // Fallback
                  error: (error, stackTrace) =>
                      Text(widget.otherParticipantName), // Fallback
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
                MaterialPageRoute<void>(
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
        Expanded(child: _buildMessageList(currentUser)),
        _buildTypingIndicator(currentUser.uid),
        SmartReplyBar(
          conversationId: widget.conversationId,
          currentUserId: currentUser.uid,
          onReplySelected: (replyText) {
            _messageInputController.text = replyText;
            // Move cursor to end
            _messageInputController.selection = TextSelection.fromPosition(
              TextPosition(offset: replyText.length),
            );
          },
          incomingMessage: _latestIncomingMessage,
        ),
        MessageInput(
          conversationId: widget.conversationId,
          currentUserId: currentUser.uid,
          currentUserName: currentUser.displayName,
          onMessageSent: _scrollToBottom,
          controller: _messageInputController,
        ),
      ],
    ),
  );

  Widget _buildPresenceStatus() {
    if (widget.isGroup) {
      // Get conversation to extract participant IDs
      final conversationAsync = ref.watch(
        getConversationByIdProvider(widget.conversationId),
      );

      return conversationAsync.when(
        data: (conversation) {
          final participantIds = conversation.participants
              .map((p) => p.uid)
              .toList();
          final groupPresenceAsync = ref.watch(
            groupPresenceStatusProvider(participantIds),
          );

          return groupPresenceAsync.when(
            data: (Map<String, dynamic> presence) {
              final displayText = presence['displayText'] as String? ?? '';
              final onlineCount = presence['onlineCount'] as int? ?? 0;

              if (displayText.isEmpty) {
                return const SizedBox.shrink();
              }

              return Text(
                displayText,
                style: TextStyle(
                  fontSize: 12,
                  color: onlineCount > 0 ? Colors.green : Colors.grey,
                  fontWeight: onlineCount > 0
                      ? FontWeight.w500
                      : FontWeight.normal,
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
        data: (Map<String, dynamic>? presence) {
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
      data: (List<TypingUser> typingUsers) {
        final typingNames = typingUsers
            .map<String>((TypingUser u) => u.userName)
            .toList();
        return TypingIndicator(typingUserNames: typingNames);
      },
      loading: () => const SizedBox.shrink(),
      error: (Object _, StackTrace _) => const SizedBox.shrink(),
    );
  }

  Widget _buildMessageList(User currentUser) {
    final messagesStream = ref.watch(
      conversationMessagesStreamProvider(
        widget.conversationId,
        currentUser.uid,
      ),
    );

    return messagesStream.when(
      data: (messages) {
        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        // Track latest incoming message for smart replies
        // Get the most recent message that's not from current user
        for (final msg in messages.reversed) {
          final senderId = msg['senderId'] as String;
          if (senderId != currentUser.uid) {
            final messageId = msg['id'] as String;
            // Only update if it's a new message
            if (_latestIncomingMessage?.id != messageId) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _latestIncomingMessage = Message(
                      id: messageId,
                      text: msg['text'] as String,
                      senderId: senderId,
                      timestamp: msg['timestamp'] as DateTime,
                      type: msg['type'] as String? ?? 'text',
                      // Note: msg['status'] ignored - status now tracked separately
                      metadata: MessageMetadata.defaultMetadata(),
                      detectedLanguage: msg['detectedLanguage'] as String?,
                      translations: msg['translations'] != null
                          ? Map<String, String>.from(
                              msg['translations'] as Map<String, dynamic>,
                            )
                          : null,
                      embedding: msg['embedding'] != null
                          ? List<double>.from(
                              (msg['embedding'] as List<dynamic>).map(
                                (e) => (e as num).toDouble(),
                              ),
                            )
                          : null,
                    );
                  });
                }
              });
            }
            break;
          }
        }

        // Only scroll to bottom when NEW messages arrive (not on updates like translations)
        final currentMessageCount = messages.length;
        final isNewMessage = currentMessageCount > _previousMessageCount;

        if (isNewMessage) {
          _previousMessageCount = currentMessageCount;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollToBottom();
            }
          });
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          itemCount: messages.length,
          itemBuilder: (BuildContext context, int index) {
            final message = messages[index];
            final isMe = message['senderId'] == currentUser.uid;
            final messageId = message['id'] as String;
            final status = message['status'] as String? ?? 'sent';

            // Mark incoming messages as read when user sees them (only once)
            // Only mark as read if already delivered (not sent)
            // Note: Messages are automatically marked as delivered when conversation opens
            // Read receipts are handled separately by markMessageAsReadUseCase if needed

            // Check if we should show timestamp
            final showTimestamp = _shouldShowTimestamp(messages, index);

            // currentUser is now passed from _buildChatScaffold with Firestore data
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
                  ? Map<String, String>.from(
                      message['translations'] as Map<String, dynamic>,
                    )
                  : null,
              userPreferredLanguage: currentUser.preferredLanguage,
              culturalHint: message['culturalHint'] as String?,
              readCount: message['readCount'] as int?,
              deliveredCount: message['deliveredCount'] as int?,
              // For group chats, totalRecipients should exclude sender
              // For now, we'll add it to the message map in the stream provider
              totalRecipients: message['totalRecipients'] as int?,
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
                  currentUser.uid,
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
    if (index == 0) {
      return true; // Always show for first message
    }

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
