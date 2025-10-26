/// Message input widget
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/formality_adjustment/presentation/controllers/formality_controller.dart';
import 'package:message_ai/features/formality_adjustment/presentation/widgets/formality_adjuster.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:message_ai/features/translation/presentation/providers/language_detection_provider.dart';
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
    this.controller,
    super.key,
  });

  final String conversationId;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback? onMessageSent;
  final TextEditingController? controller;

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  late TextEditingController _controller;
  final Uuid _uuid = const Uuid();
  bool _isSending = false;
  String _currentText = '';

  /// Timer for debouncing language detection during typing
  Timer? _detectionTimer;

  /// Detected language of the message being composed
  String? _composingLanguage;

  @override
  void initState() {
    super.initState();
    // Use provided controller or create a local one
    _controller = widget.controller ?? TextEditingController();
    // Listen to text changes for typing indicator
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _detectionTimer?.cancel();
    // Only dispose if we created it locally
    if (widget.controller == null) {
      _controller.dispose();
    }
    // Note: Don't use ref in dispose - typing will auto-clear after timeout
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    setState(() {
      _currentText = text;
    });

    // Update typing indicator
    final typingService = ref.read(typingIndicatorServiceProvider);
    // ignore: cascade_invocations
    typingService.setTyping(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      userName: widget.currentUserName,
      isTyping: text.isNotEmpty,
    );

    // Trigger debounced language detection for messages longer than 10 characters
    // This pre-detects the language so we can cache it before sending
    _detectionTimer?.cancel();

    if (text.trim().length > 10) {
      _detectionTimer = Timer(const Duration(seconds: 1), () async {
        if (!mounted) {
          return;
        }

        try {
          final languageDetectionService = ref.read(
            languageDetectionServiceProvider,
          );
          final detectedLanguage = await languageDetectionService.detectLanguage(
            text,
          );

          if (mounted && detectedLanguage != null) {
            setState(() {
              _composingLanguage = detectedLanguage;
            });
            debugPrint(
              '[MessageInput] Pre-detected language: $detectedLanguage',
            );
          }
        } catch (e) {
          debugPrint('[MessageInput] Language detection failed: $e');
        }
      });
    } else {
      // Clear language indicator for short text
      if (_composingLanguage != null) {
        setState(() {
          _composingLanguage = null;
        });
      }
    }
  }

  void _clearTypingStatus() {
    final typingService = ref.read(typingIndicatorServiceProvider);
    // ignore: cascade_invocations
    typingService.clearTyping(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      userName: widget.currentUserName,
    );
  }

  @override
  Widget build(BuildContext context) => Container(
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
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Formality adjuster (shown only when typing)
        FormalityAdjuster(
          text: _currentText,
          language: 'auto',
          onTextAdjusted: (adjustedText) {
            _controller.text = adjustedText;
            // Move cursor to end
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: adjustedText.length),
            );
            // Update current text state
            setState(() {
              _currentText = adjustedText;
            });
          },
        ),
        Row(
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
                  // Show detected language indicator
                  suffixIcon: _composingLanguage != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(
                              _composingLanguage!.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.blue[100],
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                      : null,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                enabled: !_isSending,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
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
      ],
    ),
  );

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Create message entity
      final messageId = _uuid.v4();
      final message = Message(
        id: messageId,
        senderId: widget.currentUserId,
        text: text,
        timestamp: DateTime.now(),
        type: 'text',
        metadata: MessageMetadata.defaultMetadata(),
        // Note: Status tracking done separately via MessageStatus table
      );

      // Pre-cache detected language if available
      // This allows MessageBubble to instantly show translation button
      if (_composingLanguage != null) {
        ref.read(languageDetectionCacheProvider.notifier).cache(
              messageId,
              _composingLanguage!,
            );
        debugPrint(
          '[MessageInput] Pre-cached language for message $messageId: $_composingLanguage',
        );
      }

      // Send message via use case
      final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);
      final result = await sendMessageUseCase(widget.conversationId, message);

      result.fold(
        (failure) {
          // Show error
          if (!mounted) {
            return;
          }
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

          // Clear formality cache
          ref.read(formalityControllerProvider.notifier).clear();

          // Clear composing language
          setState(() {
            _composingLanguage = null;
          });

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
