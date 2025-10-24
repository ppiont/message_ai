/// Smart reply bar widget - Material Design 3 optimized
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/smart_replies/domain/entities/smart_reply.dart';
import 'package:message_ai/features/smart_replies/presentation/providers/smart_reply_providers.dart';

/// Widget displaying smart reply suggestions for incoming messages.
///
/// Features:
/// - Only appears when suggestions are fully loaded (no loading state)
/// - Simple text chips (no icons, no header, no dismiss button)
/// - Auto-hide after 30 seconds
/// - Smooth slide-in/slide-out animations
/// - Minimal, keyboard-like design
/// - Material Design 3 theming
class SmartReplyBar extends ConsumerStatefulWidget {
  const SmartReplyBar({
    required this.conversationId,
    required this.currentUserId,
    required this.onReplySelected,
    required this.incomingMessage,
    super.key,
  });

  final String conversationId;
  final String currentUserId;
  final void Function(String) onReplySelected;
  final Message? incomingMessage;

  @override
  ConsumerState<SmartReplyBar> createState() => _SmartReplyBarState();
}

class _SmartReplyBarState extends ConsumerState<SmartReplyBar>
    with SingleTickerProviderStateMixin {

  // Constants
  static const _animationDuration = Duration(milliseconds: 300);
  static const _autoHideDuration = Duration(seconds: 30);

  // State
  Timer? _autoHideTimer;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  String? _lastMessageId;
  bool _hasSuggestionsForCurrentMessage = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  @override
  void didUpdateWidget(SmartReplyBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newMessage = widget.incomingMessage;
    if (newMessage != null &&
        newMessage.id != _lastMessageId &&
        newMessage.senderId != widget.currentUserId) {
      _lastMessageId = newMessage.id;
      _hasSuggestionsForCurrentMessage = false;

      // Reset animation if showing previous suggestions
      if (_animationController.isCompleted) {
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showBarWithSuggestions() async {
    if (!mounted) {
      return;
    }

    await _animationController.forward();

    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(_autoHideDuration, _hideBar);
  }

  Future<void> _hideBar() async {
    if (!mounted) {
      return;
    }

    await _animationController.reverse();
    _autoHideTimer?.cancel();

    if (mounted) {
      setState(() {
        _hasSuggestionsForCurrentMessage = false;
      });
    }
  }

  void _handleReplyTap(String replyText) {
    // Haptic feedback on iOS
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      HapticFeedback.selectionClick();
    }

    widget.onReplySelected(replyText);
    _hideBar();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.incomingMessage == null) {
      return const SizedBox.shrink();
    }

    final smartRepliesAsync = ref.watch(
      generateSmartRepliesProvider(
        conversationId: widget.conversationId,
        incomingMessage: widget.incomingMessage!,
        currentUserId: widget.currentUserId,
      ),
    );

    return smartRepliesAsync.when(
      data: (List<SmartReply> replies) {
        if (replies.isEmpty) {
          return const SizedBox.shrink();
        }

        // Trigger animation on first load
        if (!_hasSuggestionsForCurrentMessage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _hasSuggestionsForCurrentMessage = true;
              });
              _showBarWithSuggestions();
            }
          });
        }

        if (!_hasSuggestionsForCurrentMessage) {
          return const SizedBox.shrink();
        }

        return _buildSmartReplyBar(context, replies);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildSmartReplyBar(BuildContext context, List<SmartReply> replies) {
    final colorScheme = Theme.of(context).colorScheme;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: _buildChipList(context, replies),
      ),
    );
  }

  Widget _buildChipList(BuildContext context, List<SmartReply> replies) =>
      SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: replies.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) => _buildReplyChip(context, replies[index]),
        ),
      );

  Widget _buildReplyChip(BuildContext context, SmartReply reply) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      label: Text(reply.text),
      onPressed: () => _handleReplyTap(reply.text),
      backgroundColor: colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        fontSize: 14,
        color: colorScheme.onSurface,
      ),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      side: BorderSide.none,
      elevation: 0,
    );
  }
}
