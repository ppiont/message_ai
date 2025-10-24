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
/// - Intent-based icons (positive, neutral, question)
/// - Auto-hide after 30 seconds
/// - Smooth slide-in/slide-out animations
/// - Full accessibility support
/// - Platform-adaptive behavior (iOS swipe-to-dismiss, Android back button)
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
  static const Map<String, IconData> _intentIcons = {
    'positive': Icons.thumb_up_outlined,
    'neutral': Icons.chat_bubble_outline,
    'question': Icons.help_outline,
  };

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

  IconData _getIconForIntent(String intent) =>
      _intentIcons[intent.toLowerCase()] ?? Icons.chat_bubble_outline;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isIOS = theme.platform == TargetPlatform.iOS;

    Widget barContent = Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
        boxShadow: isIOS ? null : [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          _buildChipList(context, replies),
        ],
      ),
    );

    // iOS: Add swipe-down to dismiss
    if (isIOS) {
      barContent = Dismissible(
        key: const Key('smart_reply_bar_dismissible'),
        direction: DismissDirection.down,
        onDismissed: (_) => _hideBar(),
        child: barContent,
      );
    }

    return SlideTransition(
      position: _slideAnimation,
      child: barContent,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Semantics(
          label: 'Quick reply suggestions',
          hint: 'Swipe right to browse suggested responses',
          child: Text(
            'Quick replies',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Semantics(
          label: 'Dismiss quick replies',
          button: true,
          child: IconButton(
            icon: Icon(
              Icons.close,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            onPressed: _hideBar,
            tooltip: 'Dismiss',
          ),
        ),
      ],
    );
  }

  Widget _buildChipList(BuildContext context, List<SmartReply> replies) =>
      Semantics(
        label: 'Smart reply suggestions',
        hint: '${replies.length} suggestions available',
        child: RepaintBoundary(
          child: SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: replies.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final reply = replies[index];
                return Semantics(
                  label: 'Reply with: ${reply.text}',
                  hint: 'Intent: ${reply.intent}',
                  button: true,
                  child: _buildReplyChip(context, reply),
                );
              },
            ),
          ),
        ),
      );

  Widget _buildReplyChip(BuildContext context, SmartReply reply) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      avatar: Icon(
        _getIconForIntent(reply.intent),
        size: 18,
      ),
      label: Text(reply.text),
      onPressed: () => _handleReplyTap(reply.text),
      backgroundColor: colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        fontSize: 14,
        color: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
      ),
      visualDensity: VisualDensity.standard,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      pressElevation: 1,
    );
  }
}
