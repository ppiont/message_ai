/// Auto Delivery Marker Service
///
/// Watches all conversations for the current user and automatically
/// marks incoming messages as delivered.
library;

import 'dart:async';

import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Automatically marks incoming messages as delivered
class AutoDeliveryMarker {
  AutoDeliveryMarker({
    required ConversationRepository conversationRepository,
    required MessageRepository messageRepository,
    required String currentUserId,
  })  : _conversationRepository = conversationRepository,
        _messageRepository = messageRepository,
        _currentUserId = currentUserId;

  final ConversationRepository _conversationRepository;
  final MessageRepository _messageRepository;
  final String _currentUserId;

  final Set<String> _markedMessages = <String>{};
  StreamSubscription<dynamic>? _conversationsSub;
  final Map<String, StreamSubscription<dynamic>> _messageSubs =
      <String, StreamSubscription<dynamic>>{};

  /// Start watching conversations and marking messages
  void start() {
    // Watch all conversations for current user
    _conversationRepository
        .watchConversationsForUser(_currentUserId)
        .listen((result) {
      result.fold(
        (_) {}, // Ignore errors
        (conversations) {
          // For each conversation, watch its messages
          for (final conversation in conversations) {
            _watchConversationMessages(conversation.documentId);
          }
        },
      );
    });
  }

  void _watchConversationMessages(String conversationId) {
    // Cancel existing subscription if any
    _messageSubs[conversationId]?.cancel();

    // Watch messages for this conversation
    _messageSubs[conversationId] = _messageRepository
        .watchMessages(
          conversationId: conversationId,
          currentUserId: _currentUserId,
        )
        .listen((result) {
      result.fold(
        (_) {}, // Ignore errors
        (messages) {
          // Mark incoming messages as delivered
          for (final message in messages) {
            // Only mark if:
            // 1. Not sent by me
            // 2. Not already marked by us (deduplication)
            if (message.senderId != _currentUserId &&
                !_markedMessages.contains(message.id)) {
              _markedMessages.add(message.id);
              _messageRepository.markAsDelivered(
                conversationId,
                message.id,
                _currentUserId,
              );
            }
          }
        },
      );
    });
  }

  /// Stop watching and clean up
  void stop() {
    _conversationsSub?.cancel();
    for (final sub in _messageSubs.values) {
      sub.cancel();
    }
    _messageSubs.clear();
    _markedMessages.clear();
  }
}
