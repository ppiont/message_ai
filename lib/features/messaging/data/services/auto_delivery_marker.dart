/// Service that automatically marks incoming messages as delivered.
///
/// Watches all conversations for the current user and automatically
/// marks incoming messages as delivered when they arrive, before the
/// user opens the chat.
library;

import 'dart:async' show StreamSubscription, unawaited;

import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Automatically marks incoming messages as delivered.
///
/// Monitors all active conversations and marks incoming (not sent by the
/// current user) messages as delivered when they first appear in the stream.
/// This enables per-user delivery tracking in the message system.
///
/// The service:
/// 1. Watches all conversations for the current user
/// 2. For each conversation, watches the message stream
/// 3. Automatically calls [markAsDelivered] for each new incoming message
/// 4. Prevents duplicate delivery marking with internal deduplication
///
/// Should be started when the app initializes and stopped when cleaning up.
class AutoDeliveryMarker {
  /// Creates a new auto delivery marker instance.
  AutoDeliveryMarker({
    required final ConversationRepository conversationRepository,
    required final MessageRepository messageRepository,
    required final String currentUserId,
  })  : _conversationRepository = conversationRepository,
        _messageRepository = messageRepository,
        _currentUserId = currentUserId;

  /// Repository for accessing conversation data
  final ConversationRepository _conversationRepository;

  /// Repository for marking messages and getting message streams
  final MessageRepository _messageRepository;

  /// The ID of the current user
  final String _currentUserId;

  /// Deduplication set to prevent marking the same message twice
  final Set<String> _markedMessages = <String>{};

  /// Subscription to conversation changes
  StreamSubscription<dynamic>? _conversationsSub;

  /// Subscriptions to individual conversation message streams
  final Map<String, StreamSubscription<dynamic>> _messageSubs =
      <String, StreamSubscription<dynamic>>{};

  /// Starts watching conversations and marking new messages as delivered.
  ///
  /// Begins monitoring all conversations for the current user and
  /// automatically marks incoming messages as delivered.
  void start() {
    // Watch all conversations for current user
    _conversationRepository
        .watchConversationsForUser(_currentUserId)
        .listen((final result) {
      result.fold(
        (_) {}, // Silently ignore errors
        (final conversations) {
          // For each conversation, watch its messages
          for (final conversation in conversations) {
            _watchConversationMessages(conversation.documentId);
          }
        },
      );
    });
  }

  /// Watches messages in a specific conversation and marks them as delivered.
  ///
  /// Cancels any existing subscription before creating a new one,
  /// and listens for message updates.
  void _watchConversationMessages(final String conversationId) {
    // Cancel existing subscription if any
    _messageSubs[conversationId]?.cancel();

    // Watch messages for this conversation
    _messageSubs[conversationId] = _messageRepository
        .watchMessages(
          conversationId: conversationId,
          currentUserId: _currentUserId,
        )
        .listen((final result) {
          result.fold(
            (_) {}, // Silently ignore errors
            (final messages) {
              // Mark incoming messages as delivered
              for (final message in messages) {
                final isIncoming = message.senderId != _currentUserId;
                final isSent = message.status == 'sent';
                final notYetMarked = !_markedMessages.contains(message.id);

                if (isIncoming && isSent && notYetMarked) {
                  _markedMessages.add(message.id);
                  unawaited(
                    _messageRepository.markAsDelivered(
                      conversationId,
                      message.id,
                      _currentUserId,
                    ),
                  );
                }
              }
            },
          );
        });
  }

  /// Stops watching conversations and cleans up resources.
  ///
  /// Cancels all active subscriptions and clears internal state.
  /// Should be called when the app shuts down or the user logs out.
  void stop() {
    _conversationsSub?.cancel();
    _conversationsSub = null;

    for (final sub in _messageSubs.values) {
      sub.cancel();
    }
    _messageSubs.clear();
    _markedMessages.clear();
  }
}
