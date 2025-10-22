/// Global message delivery tracker
///
/// Watches ALL conversations and automatically marks incoming messages
/// as delivered when they arrive, regardless of which screen is open.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:message_ai/features/messaging/data/models/message_model.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Tracks and marks incoming messages as delivered globally
class MessageDeliveryTracker {
  final MessageRepository _messageRepository;
  final FirebaseFirestore _firestore;
  final String _currentUserId;

  MessageDeliveryTracker({
    required MessageRepository messageRepository,
    required FirebaseFirestore firestore,
    required String currentUserId,
  })  : _messageRepository = messageRepository,
        _firestore = firestore,
        _currentUserId = currentUserId;

  /// Start watching for incoming messages globally
  void start() {
    // Use collection group query to watch ALL messages across ALL conversations
    _firestore
        .collectionGroup('messages')
        .where('senderId', isNotEqualTo: _currentUserId)
        .where('status', isEqualTo: 'sent')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final messageData = change.doc.data();
          if (messageData != null) {
            try {
              final message = MessageModel.fromJson(messageData);

              // Extract conversation ID from document path
              // Path format: conversations/{convId}/messages/{msgId}
              final pathSegments = change.doc.reference.path.split('/');
              if (pathSegments.length >= 2) {
                final conversationId = pathSegments[pathSegments.length - 3];

                // Mark as delivered (fire and forget)
                _messageRepository.markAsDelivered(
                  conversationId,
                  message.id,
                );
              }
            } catch (e) {
              // Silently fail - not critical
            }
          }
        }
      }
    });
  }
}
