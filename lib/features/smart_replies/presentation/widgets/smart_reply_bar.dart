/// Smart reply bar widget
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/smart_replies/domain/entities/smart_reply.dart';
import 'package:message_ai/features/smart_replies/presentation/providers/smart_reply_providers.dart';

/// Widget displaying smart reply suggestions for incoming messages.
///
/// Shows horizontally scrollable action chips with AI-generated reply suggestions.
/// Features:
/// - Automatic generation when new message arrives
/// - Intent-based icons (positive, neutral, question)
/// - Shimmer loading state
/// - Auto-hide after 30 seconds
/// - Smooth slide-in/slide-out animations
/// - Tap to pre-fill message input
class SmartReplyBar extends ConsumerStatefulWidget {
  const SmartReplyBar({
    required this.conversationId,
    required this.currentUserId,
    required this.onReplySelected,
    required this.incomingMessage,
    super.key,
  });

  /// The conversation ID for context
  final String conversationId;

  /// The current user's ID (who will be replying)
  final String currentUserId;

  /// Callback when a reply is selected
  final void Function(String) onReplySelected;

  /// The incoming message that triggered reply generation
  /// When this changes (new message), smart replies are regenerated
  final Message? incomingMessage;

  @override
  ConsumerState<SmartReplyBar> createState() => _SmartReplyBarState();
}

class _SmartReplyBarState extends ConsumerState<SmartReplyBar>
    with SingleTickerProviderStateMixin {
  /// Timer for auto-hide after 30 seconds
  Timer? _autoHideTimer;

  /// Whether the bar is currently visible
  bool _isVisible = false;

  /// Animation controller for slide-in/slide-out
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  /// Track last message ID to avoid duplicate generation
  String? _lastMessageId;

  /// Cache of generated suggestions per message ID
  /// Maps message IDs to lists of generated smart reply suggestions
  final Map<String, List<SmartReply>> _suggestionCache =
      <String, List<SmartReply>>{};


  @override
  void initState() {
    super.initState();

    // Initialize slide animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 1), // Start below screen
          end: Offset.zero, // End at normal position
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
  }

  @override
  void didUpdateWidget(SmartReplyBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if we have a new incoming message that should trigger smart replies
    final newMessage = widget.incomingMessage;
    if (newMessage != null &&
        newMessage.id != _lastMessageId &&
        newMessage.senderId != widget.currentUserId) {
      debugPrint(
        '🤖 SmartReplyBar: New incoming message detected, generating smart replies...',
      );
      _lastMessageId = newMessage.id;
      _generateSmartReplies(newMessage);
    }
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// Generate smart replies for the incoming message
  Future<void> _generateSmartReplies(Message message) async {
    // Cancel any existing timer
    _autoHideTimer?.cancel();

    // Show the bar with loading state
    setState(() {
      _isVisible = true;
    });
    await _animationController.forward();

    // Start auto-hide timer (30 seconds)
    _autoHideTimer = Timer(const Duration(seconds: 30), _hideBar);
  }

  /// Hide the bar with animation
  Future<void> _hideBar() async {
    if (!mounted) {
      return;
    }

    await _animationController.reverse();
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
    }
    _autoHideTimer?.cancel();
  }

  /// Handle reply selection
  void _handleReplyTap(String replyText) {
    debugPrint('🤖 SmartReplyBar: Reply selected: $replyText');
    widget.onReplySelected(replyText);
    _hideBar();
  }

  /// Get icon for intent
  IconData _getIconForIntent(String intent) {
    switch (intent.toLowerCase()) {
      case 'positive':
        return Icons.thumb_up;
      case 'neutral':
        return Icons.chat_bubble_outline;
      case 'question':
        return Icons.help_outline;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  /// Build shimmer loading effect
  Widget _buildShimmerChip() => Container(
    height: 36,
    width: 100,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Center(
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Don't render anything if not visible
    if (!_isVisible || widget.incomingMessage == null) {
      return const SizedBox.shrink();
    }

    // Watch the smart reply provider for the current message
    final smartRepliesAsync = ref.watch(
      generateSmartRepliesProvider(
        conversationId: widget.conversationId,
        incomingMessage: widget.incomingMessage!,
        currentUserId: widget.currentUserId,
      ),
    );

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with dismiss button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick replies',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _hideBar,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Smart reply chips
            SizedBox(
              height: 40,
              child: smartRepliesAsync.when(
                data: (List<SmartReply> replies) {
                  // Cache successful results
                  if (widget.incomingMessage != null) {
                    _suggestionCache[widget.incomingMessage!.id] = replies;
                  }

                  if (replies.isEmpty) {
                    // Silently hide if no suggestions
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _hideBar();
                    });
                    return const SizedBox.shrink();
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: replies.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final reply = replies[index];
                      return ActionChip(
                        avatar: Icon(
                          _getIconForIntent(reply.intent),
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(
                          reply.text,
                          style: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () => _handleReplyTap(reply.text),
                        backgroundColor: Colors.grey[100],
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    },
                  );
                },
                loading: () => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) =>
                      _buildShimmerChip(),
                ),
                error: (Object error, StackTrace stack) {
                  debugPrint(
                    '❌ SmartReplyBar: Error generating replies: $error',
                  );
                  // Silently hide on error
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _hideBar();
                  });
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
