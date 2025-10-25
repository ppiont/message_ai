import 'package:equatable/equatable.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';

/// Presentation layer wrapper that combines a Message with computed status information.
///
/// This class is used in the UI layer to display messages with their delivery/read status
/// without polluting the domain Message entity with presentation logic.
///
/// Status is computed from MessageStatusEntity records stored in the database.
class MessageWithStatus extends Equatable {
  const MessageWithStatus({
    required this.message,
    required this.status,
    required this.readCount,
    required this.deliveredCount,
  });

  /// Factory constructor to build MessageWithStatus from a Message and its status records.
  ///
  /// [message] - The domain message entity
  /// [statusRecords] - List of MessageStatusEntity records for this message from the database
  /// [currentUserId] - The current user's ID (to determine perspective)
  /// [allParticipantIds] - All participant IDs in the conversation (for group chats)
  ///
  /// Computes:
  /// - Individual status for direct chats (sent/delivered/read)
  /// - Aggregate status for group chats (based on all participants)
  /// - Read count (how many users have read the message)
  factory MessageWithStatus.fromStatusRecords({
    required Message message,
    required List<MessageStatusEntity> statusRecords,
    required String currentUserId,
    required List<String> allParticipantIds,
  }) {
    // For messages sent by current user, compute aggregate status
    if (message.senderId == currentUserId) {
      return _computeStatusForSender(
        message: message,
        statusRecords: statusRecords,
        allParticipantIds: allParticipantIds,
      );
    } else {
      // For received messages, just show the current user's status
      return _computeStatusForReceiver(
        message: message,
        statusRecords: statusRecords,
        currentUserId: currentUserId,
      );
    }
  }

  /// Computes status for messages sent by the current user (aggregate across all recipients).
  static MessageWithStatus _computeStatusForSender({
    required Message message,
    required List<MessageStatusEntity> statusRecords,
    required List<String> allParticipantIds,
  }) {
    // Filter out sender from participants
    final otherParticipants = allParticipantIds
        .where((id) => id != message.senderId)
        .toList();

    if (otherParticipants.isEmpty) {
      return MessageWithStatus(
        message: message,
        status: 'sent',
        readCount: 0,
        deliveredCount: 0,
      );
    }

    // Count reads and deliveries
    var readCount = 0;
    var deliveredCount = 0;

    for (final participantId in otherParticipants) {
      final statusRecord = statusRecords.firstWhere(
        (record) => record.userId == participantId,
        orElse: () => MessageStatusEntity(
          messageId: message.id,
          userId: participantId,
          status: 'sent',
        ),
      );

      if (statusRecord.status == 'read') {
        readCount++;
        deliveredCount++; // Read implies delivered
      } else if (statusRecord.status == 'delivered') {
        deliveredCount++;
      }
    }

    // Determine aggregate status
    String aggregateStatus;
    if (readCount == otherParticipants.length) {
      // All participants have read
      aggregateStatus = 'read';
    } else if (deliveredCount == otherParticipants.length) {
      // All participants have at least delivered (some may have read)
      aggregateStatus = 'delivered';
    } else {
      // Not all participants have received
      aggregateStatus = 'sent';
    }

    return MessageWithStatus(
      message: message,
      status: aggregateStatus,
      readCount: readCount,
      deliveredCount: deliveredCount,
    );
  }

  /// Computes status for messages received by the current user (simple lookup).
  static MessageWithStatus _computeStatusForReceiver({
    required Message message,
    required List<MessageStatusEntity> statusRecords,
    required String currentUserId,
  }) {
    // Find the status record for current user
    final userStatus = statusRecords.firstWhere(
      (record) => record.userId == currentUserId,
      orElse: () => MessageStatusEntity(
        messageId: message.id,
        userId: currentUserId,
        status: 'sent',
      ),
    );

    return MessageWithStatus(
      message: message,
      status: userStatus.status,
      readCount: 0, // Not relevant for received messages
      deliveredCount: 0, // Not relevant for received messages
    );
  }

  /// The underlying message entity
  final Message message;

  /// Computed delivery/read status for this message
  ///
  /// For sent messages (current user is sender):
  /// - 'sent': Not all recipients have received
  /// - 'delivered': All recipients have received, but not all have read
  /// - 'read': All recipients have read
  ///
  /// For received messages (current user is recipient):
  /// - 'sent': Not yet delivered to current user
  /// - 'delivered': Delivered to current user but not read
  /// - 'read': Read by current user
  final String status;

  /// Number of users who have read this message (only relevant for sent messages)
  final int readCount;

  /// Number of users who have received this message (only relevant for sent messages)
  final int deliveredCount;

  @override
  List<Object?> get props => [message, status, readCount, deliveredCount];
}
