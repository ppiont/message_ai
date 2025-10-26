/// Message bubble widget
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:message_ai/features/authentication/presentation/providers/user_lookup_provider.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:message_ai/features/messaging/presentation/widgets/message_context_dialog.dart';
import 'package:message_ai/features/translation/presentation/providers/language_detection_provider.dart';
import 'package:message_ai/features/translation/presentation/providers/translation_providers.dart';

/// Widget displaying a single message bubble in the chat.
///
/// Shows different styling for sent vs received messages,
/// includes sender name (looked up dynamically), timestamp, delivery status, and translation functionality.
class MessageBubble extends ConsumerStatefulWidget {
  const MessageBubble({
    required this.conversationId,
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
    this.culturalHint,
    this.readCount,
    this.deliveredCount,
    this.totalRecipients,
    super.key,
  });

  final String conversationId;
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
  final String? culturalHint;
  final int? readCount;
  final int? deliveredCount;
  final int? totalRecipients;

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  String? _fallbackDetectedLanguage;
  bool _isDetectingLanguage = false;

  @override
  void initState() {
    super.initState();
    // If message doesn't have detectedLanguage, try to detect it on-the-fly
    if (widget.detectedLanguage == null && !widget.isMe) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _detectLanguageFallback();
        }
      });
    }
  }

  /// Fallback language detection for messages without detectedLanguage
  ///
  /// Uses debounced batch detection coordinator to avoid redundant ML Kit
  /// calls during rapid scrolling. Instead of individual detection, registers
  /// with coordinator and checks cache after batch detection completes.
  Future<void> _detectLanguageFallback() async {
    if (_isDetectingLanguage) {
      return;
    }

    // Check cache first before requesting detection
    final cache = ref.read(languageDetectionCacheProvider.notifier);
    final cachedLanguage = cache.getCached(widget.messageId);

    if (cachedLanguage != null) {
      // Cache hit! Use cached result without detection
      if (mounted) {
        setState(() {
          _fallbackDetectedLanguage = cachedLanguage;
        });
        debugPrint(
          '✅ Using cached language detection: ${widget.message.substring(0, widget.message.length.clamp(0, 30))}... -> $cachedLanguage',
        );
      }
      return;
    }

    // Cache miss - register with debounced coordinator for batch detection
    setState(() {
      _isDetectingLanguage = true;
    });

    try {
      // Register detection request with coordinator (non-blocking)
      ref.read(
        debouncedBatchDetectionCoordinatorProvider.notifier,
      ).requestDetection(widget.messageId, widget.message);

      debugPrint(
        '📝 Registered detection request: ${widget.message.substring(0, widget.message.length.clamp(0, 30))}...',
      );

      // Wait for batch detection to complete (300ms debounce + detection time)
      // Check cache after reasonable delay to pick up batch result
      await Future<void>.delayed(const Duration(milliseconds: 600));

      // Check cache again for batch detection result
      if (!mounted) {
        return;
      }

      final batchDetected = cache.getCached(widget.messageId);
      if (batchDetected != null) {
        setState(() {
          _fallbackDetectedLanguage = batchDetected;
        });

        debugPrint(
          '✅ Batch language detection: ${widget.message.substring(0, widget.message.length.clamp(0, 30))}... -> $batchDetected',
        );

        // Update the message in Firestore with detected language for future
        final messageRepository = ref.read(messageRepositoryProvider);
        final messageResult = await messageRepository.getMessageById(
          widget.conversationId,
          widget.messageId,
        );

        await messageResult.fold(
          (failure) async {
            debugPrint(
              'Failed to get message for language update: ${failure.message}',
            );
          },
          (messageEntity) async {
            final updatedMessage = messageEntity.copyWith(
              detectedLanguage: batchDetected,
            );
            await messageRepository.updateMessage(
              widget.conversationId,
              updatedMessage,
            );
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Fallback language detection failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLanguage = false;
        });
      }
    }
  }

  /// Get effective detected language (use fallback if original is null)
  String? get effectiveDetectedLanguage =>
      widget.detectedLanguage ?? _fallbackDetectedLanguage;

  @override
  Widget build(BuildContext context) {
    final translationState =
        ref.watch<Map<String, MessageTranslationState>>(
          translationControllerProvider,
        )[widget.messageId] ??
        const MessageTranslationState();
    final translationController = ref.read(
      translationControllerProvider.notifier,
    );

    // Look up sender name dynamically (cached for performance)
    final senderNameAsync = ref.watch(userDisplayNameProvider(widget.senderId));

    // Determine what text to show
    final displayText = _getDisplayText(translationState);
    final canTranslate = _canTranslate();

    return Column(
      crossAxisAlignment: widget.isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (widget.showTimestamp) _buildTimestampDivider(context),
        Padding(
          padding: EdgeInsets.only(
            left: widget.isMe ? 64 : 8,
            right: widget.isMe ? 8 : 64,
            top: 4,
            bottom: 4,
          ),
          child: Column(
            crossAxisAlignment: widget.isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!widget.isMe)
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
                    error: (error, stackTrace) => Text(
                      'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                onLongPressStart: (details) =>
                    _showContextMenu(context, details, ref),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isMe
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                      bottomRight: Radius.circular(widget.isMe ? 4 : 16),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message text with animation using AnimatedOpacity + Stack
                      // This avoids expensive saveLayer operations from AnimatedSwitcher
                      // Both texts are in the tree for smooth fade animation between them
                      Stack(
                        children: [
                          // Translated text (bottom layer when visible)
                          AnimatedOpacity(
                            opacity: translationState.isTranslated ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              displayText,
                              style: TextStyle(
                                fontSize: 15,
                                color: widget.isMe ? Colors.white : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                          // Original text (top layer when visible)
                          AnimatedOpacity(
                            opacity: translationState.isTranslated ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              widget.message,
                              style: TextStyle(
                                fontSize: 15,
                                color: widget.isMe ? Colors.white : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat.jm().format(widget.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.isMe
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                          // Cultural context badge (only for received messages with hints)
                          if (!widget.isMe && widget.culturalHint != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _showCulturalContextDialog(context),
                              child: Icon(
                                Icons.public,
                                size: 14,
                                color: widget.isMe
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                          if (widget.isMe) ...[
                            const SizedBox(width: 4),
                            _buildStatusIcon(context),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Translation button (only for received messages with translation available)
              if (canTranslate)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: _buildTranslationButton(
                    context,
                    ref,
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
      return widget.message;
    }

    // Get translated text from translations map
    final targetLanguage = widget.userPreferredLanguage ?? 'en';
    return widget.translations?[targetLanguage] ?? widget.message;
  }

  /// Check if translation should be offered for this message
  bool _canTranslate() {
    // Use effective detected language (includes fallback)
    final detectedLang = effectiveDetectedLanguage;

    // Only show translate button for received messages
    if (widget.isMe) {
      return false;
    }

    // Need user preferred language and detected language
    if (widget.userPreferredLanguage == null || detectedLang == null) {
      return false;
    }

    // Don't show translate button if message is already in user's language
    final isAlreadyInUserLanguage =
        detectedLang == widget.userPreferredLanguage;

    // Show translate button if languages differ
    return !isAlreadyInUserLanguage;
  }

  /// Build the translation button widget
  Widget _buildTranslationButton(
    BuildContext context,
    WidgetRef ref,
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
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            style: TextStyle(fontSize: 12, color: Colors.red[400]),
          ),
        ],
      );
    }

    return TextButton(
      onPressed: () => _handleTranslationTap(ref, translationController),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
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
            _formatTimestampDivider(widget.timestamp),
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
    // For group messages, show detailed counts
    final isGroupMessage = (widget.totalRecipients ?? 0) > 1;

    Widget statusIcon;
    switch (widget.status) {
      case 'sent':
        statusIcon = const Icon(Icons.check, size: 16, color: Colors.white);
      case 'delivered':
        statusIcon = const Icon(Icons.done_all, size: 16, color: Colors.white);
      case 'read':
        statusIcon = const Icon(
          Icons.done_all,
          size: 16,
          color: Colors.lightBlueAccent,
        );
      default:
        return const SizedBox.shrink();
    }

    // For group messages, add count text
    if (isGroupMessage && widget.status != 'sent') {
      final count = widget.status == 'read'
          ? widget.readCount ?? 0
          : widget.deliveredCount ?? 0;
      final total = widget.totalRecipients ?? 0;

      return GestureDetector(
        onTap: () => _showReadReceiptDetails(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            statusIcon,
            const SizedBox(width: 2),
            Text(
              '$count/$total',
              style: TextStyle(
                fontSize: 11,
                color: widget.status == 'read'
                    ? Colors.lightBlueAccent
                    : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return statusIcon;
  }

  /// Show detailed read receipt dialog
  void _showReadReceiptDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.readCount != null && widget.readCount! > 0)
              _buildStatusRow(
                icon: Icons.done_all,
                color: Colors.blue,
                label: 'Read by',
                count: widget.readCount!,
              ),
            if (widget.deliveredCount != null && widget.deliveredCount! > 0)
              _buildStatusRow(
                icon: Icons.done_all,
                color: Colors.grey,
                label: 'Delivered to',
                count: widget.deliveredCount!,
              ),
            const SizedBox(height: 8),
            Text(
              'Total recipients: ${widget.totalRecipients ?? 0}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text('$label $count', style: const TextStyle(fontSize: 14)),
      ],
    ),
  );

  String _formatTimestampDivider(DateTime ts) {
    final now = DateTime.now();
    final difference = now.difference(ts);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.EEEE().format(ts); // e.g., "Monday"
    } else {
      return DateFormat.yMMMd().format(ts); // e.g., "Jan 15, 2024"
    }
  }

  /// Show context menu on long press
  Future<void> _showContextMenu(
    BuildContext context,
    LongPressStartDetails details,
    WidgetRef ref,
  ) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (overlay == null) {
      return;
    }

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'show_context',
          child: Row(
            children: [
              Icon(Icons.translate, size: 20, color: Colors.blue),
              SizedBox(width: 12),
              Text('Show Context'),
            ],
          ),
        ),
      ],
    );

    if (result == 'show_context' && context.mounted) {
      await _handleShowContext(context, ref);
    }
  }

  /// Handle show context action (unified cultural context + idioms)
  Future<void> _handleShowContext(BuildContext context, WidgetRef ref) async {
    // Show loading indicator
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final messageContextService = ref.read(messageContextServiceProvider);

      // Get detected language
      final language = effectiveDetectedLanguage ?? 'en';

      final result = await messageContextService.analyzeMessageContext(
        text: widget.message,
        language: language,
      );

      if (!context.mounted) {
        return;
      }

      // Close loading dialog
      Navigator.of(context).pop();

      result.fold(
        (failure) {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to analyze context: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (contextDetails) {
          if (contextDetails == null || !contextDetails.hasContent) {
            // Show "no context" message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No cultural context needed for this message'),
              ),
            );
          } else {
            // Show dialog with context details
            MessageContextDialog.show(context, contextDetails);
          }
        },
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      // Close loading dialog if still open
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Show cultural context dialog
  void _showCulturalContextDialog(BuildContext context) {
    if (widget.culturalHint == null) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.public, color: Colors.blue),
            SizedBox(width: 8),
            Text('Cultural Context'),
          ],
        ),
        content: Text(
          widget.culturalHint!,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Handle translation button tap
  Future<void> _handleTranslationTap(
    WidgetRef ref,
    TranslationController translationController,
  ) async {
    final translationState =
        ref.read<Map<String, MessageTranslationState>>(
          translationControllerProvider,
        )[widget.messageId] ??
        const MessageTranslationState();

    // If already translated, just toggle back to original
    if (translationState.isTranslated) {
      translationController.toggleTranslation(widget.messageId);
      return;
    }

    // Check if translation already exists
    final targetLanguage = widget.userPreferredLanguage!;
    if (widget.translations != null &&
        widget.translations!.containsKey(targetLanguage)) {
      // Translation exists, just toggle display
      translationController.toggleTranslation(widget.messageId);
      return;
    }

    // Need to fetch translation - use effective detected language
    final sourceLang = effectiveDetectedLanguage;
    if (sourceLang == null) {
      translationController.setError(
        widget.messageId,
        'Cannot detect message language',
      );
      return;
    }

    translationController.setLoading(widget.messageId, isLoading: true);

    final translateUseCase = ref.read(translateMessageProvider);
    final messageRepository = ref.read(messageRepositoryProvider);

    final result = await translateUseCase(
      messageId: widget.messageId,
      text: widget.message,
      sourceLanguage: sourceLang,
      targetLanguage: targetLanguage,
    );

    unawaited(
      result.fold(
        (failure) async {
          translationController.setError(widget.messageId, failure.message);
        },
        (translatedText) async {
          // Update message with new translation
          final updatedTranslations = {
            ...?widget.translations,
            targetLanguage: translatedText,
          };

          // Get the full message entity to update it
          final messageResult = await messageRepository.getMessageById(
            widget.conversationId,
            widget.messageId,
          );

          await messageResult.fold(
            (failure) async {
              translationController.setError(
                widget.messageId,
                'Failed to save translation',
              );
            },
            (messageEntity) async {
              // Update the message with new translation
              final updatedMessage = messageEntity.copyWith(
                translations: Map<String, String>.from(updatedTranslations),
              );

              final updateResult = await messageRepository.updateMessage(
                widget.conversationId,
                updatedMessage,
              );

              updateResult.fold(
                (failure) {
                  translationController.setError(
                    widget.messageId,
                    'Failed to save translation',
                  );
                },
                (_) {
                  // Success! Toggle to show translation
                  translationController
                    ..setLoading(widget.messageId, isLoading: false)
                    ..toggleTranslation(widget.messageId);
                },
              );
            },
          );
        },
      ),
    );
  }
}
