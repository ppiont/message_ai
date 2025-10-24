import 'package:equatable/equatable.dart';
import 'package:message_ai/features/messaging/domain/entities/message_context_details.dart';

/// Domain entity representing a message in a conversation
///
/// This entity follows the clean architecture pattern and represents
/// the core business logic for messages. It is independent of any
/// data source or framework implementation.
class Message extends Equatable {

  const Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    required this.type,
    required this.metadata,
    this.detectedLanguage,
    this.translations,
    this.replyTo,
    this.embedding,
    this.aiAnalysis,
    this.culturalHint,
    this.contextDetails,
    // NEW FIELDS for per-user read receipts
    this.deliveredTo,
    this.readBy,
    // DEPRECATED: Keep for backward compatibility with old messages
    @Deprecated('Use readBy/deliveredTo for per-user tracking')
    this.status = 'sent',
  });
  /// Unique identifier for the message
  final String id;

  /// The text content of the message
  final String text;

  /// ID of the user who sent the message
  /// Note: Display name is looked up dynamically via UserLookupProvider
  /// This ensures name changes propagate instantly without updating all messages
  final String senderId;

  /// When the message was sent
  final DateTime timestamp;

  /// Type of message (text, image, audio, video, etc.)
  final String type;

  /// DEPRECATED: Global delivery status for backward compatibility
  /// For new messages, use readBy/deliveredTo instead
  @Deprecated('Use readBy/deliveredTo for per-user tracking')
  final String status;

  /// Detected language code (e.g., 'en', 'es', 'fr')
  final String? detectedLanguage;

  /// Map of language codes to translated text
  final Map<String, String>? translations;

  /// ID of the message this is replying to (null if not a reply)
  final String? replyTo;

  /// Message metadata
  final MessageMetadata metadata;

  /// Vector embedding for semantic search (null if not yet generated)
  final List<double>? embedding;

  /// AI-generated analysis of the message
  final MessageAIAnalysis? aiAnalysis;

  /// Cultural context hint explaining nuances, idioms, or formality (brief summary)
  final String? culturalHint;

  /// Detailed context analysis including formality, cultural notes, and idioms
  ///
  /// This is fetched on-demand when user requests context analysis and cached
  /// in Firestore for eventual consistency across all users in group chats.
  final MessageContextDetails? contextDetails;

  // ========== NEW: Per-User Read Receipt Fields ==========

  /// Map of userId -> timestamp when message was delivered to that user
  /// Null or empty for messages sent before this feature was implemented
  /// For sender's own messages, this tracks delivery to OTHER participants
  final Map<String, DateTime>? deliveredTo;

  /// Map of userId -> timestamp when message was read by that user
  /// Null or empty for messages sent before this feature was implemented
  /// For sender's own messages, this tracks reads by OTHER participants
  final Map<String, DateTime>? readBy;

  // ========== Helper Methods for Read Receipt Logic ==========

  /// Check if message has been delivered to a specific user
  bool isDeliveredTo(String userId) {
    if (userId == senderId) {
      return true;
    } // Sender always has it delivered
    return deliveredTo?.containsKey(userId) ?? false;
  }

  /// Check if message has been read by a specific user
  bool isReadBy(String userId) {
    if (userId == senderId) {
      return true;
    } // Sender always has read their own message
    return readBy?.containsKey(userId) ?? false;
  }

  /// Get delivery status for a specific user (for UI display)
  /// Returns: 'sent', 'delivered', 'read'
  String getStatusForUser(String userId) {
    if (isReadBy(userId)) {
      return 'read';
    }
    if (isDeliveredTo(userId)) {
      return 'delivered';
    }
    return 'sent';
  }

  /// Get aggregate status for sender's messages in group chats
  /// Logic:
  /// - If ALL participants have read: 'read'
  /// - If ALL participants have delivered (but not all read): 'delivered'
  /// - Otherwise: 'sent'
  String getAggregateStatus(List<String> allParticipantIds) {
    // Filter out sender from participants
    final otherParticipants =
        allParticipantIds.where((id) => id != senderId).toList();

    if (otherParticipants.isEmpty) {
      return 'sent';
    } // No other participants

    // Check for backward compatibility (old messages without per-user tracking)
    if (readBy == null && deliveredTo == null) {
      return status; // Fall back to old global status
    }

    // Check if ALL other participants have read
    final allRead = otherParticipants
        .every((userId) => readBy?.containsKey(userId) ?? false);
    if (allRead && otherParticipants.isNotEmpty) {
      return 'read';
    }

    // Check if ALL other participants have at least delivered
    final allDelivered = otherParticipants.every((userId) =>
        (readBy?.containsKey(userId) ?? false) ||
        (deliveredTo?.containsKey(userId) ?? false));
    if (allDelivered) {
      return 'delivered';
    }

    return 'sent';
  }

  /// Get read count for group messages (how many users have read)
  int getReadCount(List<String> allParticipantIds) {
    final otherParticipants =
        allParticipantIds.where((id) => id != senderId).toList();
    if (readBy == null) {
      return 0;
    }
    return otherParticipants
        .where((userId) => readBy!.containsKey(userId))
        .length;
  }

  /// Get list of users who have read this message
  List<String> getReadByUserIds() {
    return readBy?.keys.toList() ?? [];
  }

  /// Get list of users who have received but not read this message
  List<String> getDeliveredButNotReadUserIds() {
    final delivered = deliveredTo?.keys.toSet() ?? {};
    final read = readBy?.keys.toSet() ?? {};
    return delivered.difference(read).toList();
  }

  /// Creates a copy of this message with the given fields replaced
  Message copyWith({
    String? id,
    String? text,
    String? senderId,
    DateTime? timestamp,
    String? type,
    String? status,
    String? detectedLanguage,
    Map<String, String>? translations,
    String? replyTo,
    MessageMetadata? metadata,
    List<double>? embedding,
    MessageAIAnalysis? aiAnalysis,
    String? culturalHint,
    MessageContextDetails? contextDetails,
    Map<String, DateTime>? deliveredTo,
    Map<String, DateTime>? readBy,
  }) => Message(
      id: id ?? this.id,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      translations: translations ?? this.translations,
      replyTo: replyTo ?? this.replyTo,
      metadata: metadata ?? this.metadata,
      embedding: embedding ?? this.embedding,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      culturalHint: culturalHint ?? this.culturalHint,
      contextDetails: contextDetails ?? this.contextDetails,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      readBy: readBy ?? this.readBy,
    );

  @override
  List<Object?> get props => [
        id,
        text,
        senderId,
        timestamp,
        type,
        status,
        detectedLanguage,
        translations,
        replyTo,
        metadata,
        embedding,
        aiAnalysis,
        culturalHint,
        contextDetails,
        deliveredTo,
        readBy,
      ];
}

/// Metadata for a message
class MessageMetadata extends Equatable {

  const MessageMetadata({
    required this.edited,
    required this.deleted,
    required this.priority,
    required this.hasIdioms,
  });

  /// Creates a default metadata instance
  factory MessageMetadata.defaultMetadata() => const MessageMetadata(
      edited: false,
      deleted: false,
      priority: 'medium',
      hasIdioms: false,
    );
  /// Whether the message has been edited
  final bool edited;

  /// Whether the message has been deleted
  final bool deleted;

  /// Priority level (low, medium, high, urgent)
  final String priority;

  /// Whether the message contains idioms or slang
  final bool hasIdioms;

  /// Creates a copy of this metadata with the given fields replaced
  MessageMetadata copyWith({
    bool? edited,
    bool? deleted,
    String? priority,
    bool? hasIdioms,
  }) => MessageMetadata(
      edited: edited ?? this.edited,
      deleted: deleted ?? this.deleted,
      priority: priority ?? this.priority,
      hasIdioms: hasIdioms ?? this.hasIdioms,
    );

  @override
  List<Object?> get props => [edited, deleted, priority, hasIdioms];
}

/// AI-generated analysis of a message
class MessageAIAnalysis extends Equatable {

  const MessageAIAnalysis({
    required this.priority,
    required this.actionItems,
    required this.sentiment,
  });
  /// Priority level determined by AI (low, medium, high, urgent)
  final String priority;

  /// List of action items extracted from the message
  final List<String> actionItems;

  /// Sentiment analysis (positive, neutral, negative)
  final String sentiment;

  /// Creates a copy of this analysis with the given fields replaced
  MessageAIAnalysis copyWith({
    String? priority,
    List<String>? actionItems,
    String? sentiment,
  }) => MessageAIAnalysis(
      priority: priority ?? this.priority,
      actionItems: actionItems ?? this.actionItems,
      sentiment: sentiment ?? this.sentiment,
    );

  @override
  List<Object?> get props => [priority, actionItems, sentiment];
}
