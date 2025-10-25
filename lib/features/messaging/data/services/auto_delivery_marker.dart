/// Service that automatically marks incoming messages as delivered.
///
/// Watches all conversations for the current user and automatically
/// marks incoming messages as delivered when they arrive, before the
/// user opens the chat.
library;

import 'dart:async' show StreamSubscription, unawaited;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/group_conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Automatically marks incoming messages as delivered.
///
/// Monitors all active conversations (both direct and group) and marks
/// incoming (not sent by the current user) messages as delivered when
/// they first appear in the stream. This enables per-user delivery
/// tracking in the message system.
///
/// The service:
/// 1. Watches all direct conversations AND group conversations for the current user
/// 2. For each conversation, watches the message stream
/// 3. Automatically calls [markAsDelivered] for each new incoming message
/// 4. Prevents duplicate delivery marking with internal deduplication
///
/// Should be started when the app initializes and stopped when cleaning up.
class AutoDeliveryMarker {
  /// Creates a new auto delivery marker instance.
  AutoDeliveryMarker({
    required final ConversationRepository conversationRepository,
    required final GroupConversationRepository groupConversationRepository,
    required final MessageRepository messageRepository,
    required final String currentUserId,
  })  : _conversationRepository = conversationRepository,
        _groupConversationRepository = groupConversationRepository,
        _messageRepository = messageRepository,
        _currentUserId = currentUserId;

  /// Repository for accessing direct conversation data
  final ConversationRepository _conversationRepository;

  /// Repository for accessing group conversation data
  final GroupConversationRepository _groupConversationRepository;

  /// Repository for marking messages and getting message streams
  final MessageRepository _messageRepository;

  /// The ID of the current user
  final String _currentUserId;

  /// Deduplication set to prevent marking the same message twice
  final Set<String> _markedMessages = <String>{};

  /// Subscription to direct conversation changes
  StreamSubscription<dynamic>? _conversationsSub;

  /// Subscription to group conversation changes
  StreamSubscription<dynamic>? _groupConversationsSub;

  /// Subscriptions to individual conversation message streams
  final Map<String, StreamSubscription<dynamic>> _messageSubs =
      <String, StreamSubscription<dynamic>>{};

  /// Starts watching conversations and marking new messages as delivered.
  ///
  /// Begins monitoring all conversations (direct AND group) for the current
  /// user and automatically marks incoming messages as delivered.
  void start() {
    debugPrint('📨 AutoDeliveryMarker: Starting for user $_currentUserId');

    // Watch all DIRECT conversations for current user
    _conversationsSub = _conversationRepository
        .watchConversationsForUser(_currentUserId)
        .listen((final result) {
      result.fold(
        (failure) => debugPrint('❌ AutoDeliveryMarker: Failed to watch direct conversations: ${failure.message}'),
        (final conversations) {
          debugPrint('📨 AutoDeliveryMarker: Watching ${conversations.length} direct conversations');
          // For each conversation, watch its messages
          for (final conversation in conversations) {
            _watchConversationMessages(conversation.documentId);
          }
        },
      );
    });

    // Watch all GROUP conversations for current user
    _groupConversationsSub = _groupConversationRepository
        .watchGroupsForUser(_currentUserId)
        .listen((final result) {
      result.fold(
        (failure) => debugPrint('❌ AutoDeliveryMarker: Failed to watch group conversations: ${failure.message}'),
        (final groups) {
          debugPrint('📨 AutoDeliveryMarker: Watching ${groups.length} group conversations');
          // For each group, watch its messages
          for (final group in groups) {
            _watchConversationMessages(group.documentId);
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

    debugPrint('📨 AutoDeliveryMarker: Watching messages in conversation $conversationId');

    // Watch messages for this conversation
    _messageSubs[conversationId] = _messageRepository
        .watchMessages(
          conversationId: conversationId,
          currentUserId: _currentUserId,
        )
        .listen((final result) {
          result.fold(
            (failure) => debugPrint('❌ AutoDeliveryMarker: Failed to watch messages in $conversationId: ${failure.message}'),
            (final messages) {
              debugPrint('📨 AutoDeliveryMarker: Processing ${messages.length} messages in $conversationId');
              // Mark incoming messages as delivered
              for (final message in messages) {
                final isIncoming = message.senderId != _currentUserId;
                final isNotYetDelivered = !message.isDeliveredTo(_currentUserId);
                final notYetMarked = !_markedMessages.contains(message.id);

                debugPrint('📨 AutoDeliveryMarker: Message ${message.id.substring(0, 8)}: isIncoming=$isIncoming, isNotYetDelivered=$isNotYetDelivered, notYetMarked=$notYetMarked');

                if (isIncoming && isNotYetDelivered && notYetMarked) {
                  debugPrint('✅ AutoDeliveryMarker: Marking message ${message.id} as delivered to $_currentUserId');
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
    debugPrint('📨 AutoDeliveryMarker: Stopping for user $_currentUserId');
    _conversationsSub?.cancel();
    _conversationsSub = null;

    _groupConversationsSub?.cancel();
    _groupConversationsSub = null;

    for (final sub in _messageSubs.values) {
      sub.cancel();
    }
    _messageSubs.clear();
    _markedMessages.clear();
  }
}
