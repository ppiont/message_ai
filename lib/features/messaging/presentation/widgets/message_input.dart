/// Message input widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:uuid/uuid.dart';

/// Widget for composing and sending messages.
///
/// Includes text input, send button, and handles message sending logic.
class MessageInput extends ConsumerStatefulWidget {
  const MessageInput({
    required this.conversationId,
    required this.currentUserId,
    required this.currentUserName,
    this.onMessageSent,
    super.key,
  });

  final String conversationId;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback? onMessageSent;

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final Uuid _uuid = const Uuid();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Listen to text changes for typing indicator
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    // Note: Don't use ref in dispose - typing will auto-clear after timeout
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final typingService = ref.read(typingIndicatorServiceProvider);

    typingService.setTyping(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      userName: widget.currentUserName,
      isTyping: text.isNotEmpty,
    );
  }

  void _clearTypingStatus() {
    final typingService = ref.read(typingIndicatorServiceProvider);
    typingService.clearTyping(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      userName: widget.currentUserName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // TODO: Add attachment button
          // IconButton(
          //   icon: const Icon(Icons.attach_file),
          //   onPressed: () {},
          // ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isSending,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              color: Colors.white,
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Create message entity
      final message = Message(
        id: _uuid.v4(),
        senderId: widget.currentUserId,
        senderName: widget.currentUserName,
        text: text,
        timestamp: DateTime.now(),
        status: 'sent',
        type: 'text',
        metadata: MessageMetadata.defaultMetadata(),
      );

      // Send message via use case
      final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);
      final result = await sendMessageUseCase(
        widget.conversationId,
        message,
      );

      result.fold(
        (failure) {
          // Show error
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (sentMessage) {
          // Clear input and typing status
          _controller.clear();
          _clearTypingStatus();
          widget.onMessageSent?.call();
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}
