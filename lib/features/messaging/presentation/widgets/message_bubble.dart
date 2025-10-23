/// Message bubble widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:message_ai/features/authentication/presentation/providers/user_lookup_provider.dart';
import 'package:message_ai/features/translation/presentation/controllers/translation_controller.dart';

/// Widget displaying a single message bubble in the chat.
///
/// Shows different styling for sent vs received messages,
/// includes sender name (looked up dynamically), timestamp, delivery status, and translation functionality.
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    required this.messageId,
    required this.message,
    required this.senderId,
    required this.isMe,
    required this.timestamp,
    this.showTimestamp = false,
    this.status = 'sent',
    this.detectedLanguage,
    this.translations,
    this.userPreferredLanguage,
    super.key,
  });

  final String messageId;
  final String message;
  final String senderId;
  final bool isMe;
  final DateTime timestamp;
  final bool showTimestamp;
  final String status;
  final String? detectedLanguage;
  final Map<String, String>? translations;
  final String? userPreferredLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translationState = ref.watch(translationControllerProvider)[messageId] ??
        const MessageTranslationState();
    final translationController = ref.read(translationControllerProvider.notifier);

    // Look up sender name dynamically (cached for performance)
    final senderNameAsync = ref.watch(userDisplayNameProvider(senderId));

    // Determine what text to show
    final displayText = _getDisplayText(translationState);
    final canTranslate = _canTranslate();

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (showTimestamp) _buildTimestampDivider(context),
        Padding(
          padding: EdgeInsets.only(
            left: isMe ? 64 : 8,
            right: isMe ? 8 : 64,
            top: 4,
            bottom: 4,
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: senderNameAsync.when(
                    data: (senderName) => Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    loading: () => Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    error: (_, __) => Text(
                      'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message text with animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: Text(
                        displayText,
                        key: ValueKey(translationState.isTranslated),
                        style: TextStyle(
                          fontSize: 15,
                          color: isMe ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat.jm().format(timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(context),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Translation button (only for received messages with translation available)
              if (canTranslate)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: _buildTranslationButton(
                    context,
                    translationState,
                    translationController,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get the text to display based on translation state
  String _getDisplayText(MessageTranslationState translationState) {
    if (!translationState.isTranslated) {
      return message;
    }

    // Get translated text from translations map
    final targetLanguage = userPreferredLanguage ?? 'en';
    return translations?[targetLanguage] ?? message;
  }

  /// Check if translation is available for this message
  bool _canTranslate() {
    // Only show translate button for received messages
    if (isMe) return false;

    // Need user preferred language and translations map
    if (userPreferredLanguage == null || translations == null) return false;

    // Check if translation exists for user's language
    final hasTranslation = translations!.containsKey(userPreferredLanguage);

    // Don't show translate button if message is already in user's language
    final isAlreadyInUserLanguage = detectedLanguage == userPreferredLanguage;

    return hasTranslation && !isAlreadyInUserLanguage;
  }

  /// Build the translation button widget
  Widget _buildTranslationButton(
    BuildContext context,
    MessageTranslationState translationState,
    TranslationController translationController,
  ) {
    if (translationState.isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Translating...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    }

    if (translationState.error != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 14, color: Colors.red[400]),
          const SizedBox(width: 4),
          Text(
            'Translation unavailable',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[400],
            ),
          ),
        ],
      );
    }

    return TextButton(
      onPressed: () => translationController.toggleTranslation(messageId),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            translationState.isTranslated ? Icons.language : Icons.translate,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            translationState.isTranslated ? 'Show original' : 'Translate',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampDivider(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatTimestampDivider(timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );

  Widget _buildStatusIcon(BuildContext context) {
    switch (status) {
      case 'sent':
        return const Icon(
          Icons.check,
          size: 16, // Increased from 14
          color: Colors.white, // Changed from white70 to full white
        );
      case 'delivered':
        return const Icon(
          Icons.done_all,
          size: 16, // Increased from 14
          color: Colors.white, // Changed from white70 to full white
        );
      case 'read':
        return const Icon(
          Icons.done_all,
          size: 16, // Increased from 14
          color: Colors.lightBlueAccent, // More visible color for read status
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatTimestampDivider(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.EEEE().format(timestamp); // e.g., "Monday"
    } else {
      return DateFormat.yMMMd().format(timestamp); // e.g., "Jan 15, 2024"
    }
  }
}
