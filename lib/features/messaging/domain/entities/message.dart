import 'package:equatable/equatable.dart';
import 'package:message_ai/features/messaging/domain/entities/message_context_details.dart';

/// Domain entity representing a message in a conversation
///
/// This entity follows the clean architecture pattern and represents
/// the core business logic for messages. It is independent of any
/// data source or framework implementation.
///
/// Features:
/// - Per-user read receipts via [readBy] and [deliveredTo] maps
/// - Backward compatibility with deprecated global [status] field
/// - Helper methods for querying read receipt status
class Message extends Equatable {
  /// Creates a new message entity
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
    // Per-user read receipt fields
    this.deliveredTo,
    this.readBy,
    // Deprecated: Keep for backward compatibility with old messages
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

  /// Map of userId -> timestamp when message was delivered to that user.
  ///
  /// Null or empty for messages sent before this feature was implemented.
  /// For sender's own messages, this tracks delivery to OTHER participants.
  /// Sender always considers themselves as having the message delivered.
  final Map<String, DateTime>? deliveredTo;

  /// Map of userId -> timestamp when message was read by that user.
  ///
  /// Null or empty for messages sent before this feature was implemented.
  /// For sender's own messages, this tracks reads by OTHER participants.
  /// Sender always considers themselves as having read their own message.
  final Map<String, DateTime>? readBy;

  // ========== Read Receipt Helper Methods ==========

  /// Checks if message has been delivered to a specific user.
  ///
  /// Returns `true` if the [userId] is the sender or has an entry in [deliveredTo].
  /// The sender always has the message delivered to themselves.
  bool isDeliveredTo(final String userId) =>
      userId == senderId || (deliveredTo?.containsKey(userId) ?? false);

  /// Checks if message has been read by a specific user.
  ///
  /// Returns `true` if the [userId] is the sender or has an entry in [readBy].
  /// The sender always considers themselves as having read their own message.
  bool isReadBy(final String userId) =>
      userId == senderId || (readBy?.containsKey(userId) ?? false);

  /// Gets the delivery status for a specific user (for UI display).
  ///
  /// Returns one of: 'sent', 'delivered', 'read'
  /// Uses per-user tracking when available, falls back to global status for
  /// backward compatibility with old messages.
  String getStatusForUser(final String userId) {
    if (isReadBy(userId)) {
      return 'read';
    }
    if (isDeliveredTo(userId)) {
      return 'delivered';
    }
    return 'sent';
  }

  /// Gets aggregate delivery status for sender's messages in group chats.
  ///
  /// Determines the most important status across all participants:
  /// - If ALL other participants have read: returns 'read'
  /// - If ALL other participants have delivered (but not all read): returns 'delivered'
  /// - Otherwise: returns 'sent'
  ///
  /// Falls back to deprecated global [status] field for backward compatibility
  /// with messages created before per-user tracking was implemented.
  String getAggregateStatus(final List<String> allParticipantIds) {
    // Filter out sender from participants
    final otherParticipants =
        allParticipantIds.where((final id) => id != senderId).toList();

    if (otherParticipants.isEmpty) {
      return 'sent';
    }

    // Backward compatibility: old messages without per-user tracking
    if (readBy == null && deliveredTo == null) {
      return status;
    }

    // Check if ALL other participants have read
    final allRead = otherParticipants
        .every((final userId) => readBy?.containsKey(userId) ?? false);
    if (allRead) {
      return 'read';
    }

    // Check if ALL other participants have at least delivered
    final allDelivered = otherParticipants.every(
      (final userId) =>
          (readBy?.containsKey(userId) ?? false) ||
          (deliveredTo?.containsKey(userId) ?? false),
    );
    if (allDelivered) {
      return 'delivered';
    }

    return 'sent';
  }

  /// Gets the count of users who have read this message.
  ///
  /// Only counts participants other than the sender.
  /// Returns 0 if no per-user read receipt data is available.
  int getReadCount(final List<String> allParticipantIds) {
    final otherParticipants =
        allParticipantIds.where((final id) => id != senderId).toList();
    if (readBy == null) {
      return 0;
    }
    return otherParticipants
        .where((final userId) => readBy!.containsKey(userId))
        .length;
  }

  /// Gets list of users who have read this message.
  ///
  /// Returns empty list if no per-user read receipt data is available.
  List<String> getReadByUserIds() => readBy?.keys.toList() ?? const <String>[];

  /// Gets list of users who received the message but haven't read it.
  ///
  /// Returns empty list if no per-user read receipt data is available.
  List<String> getDeliveredButNotReadUserIds() {
    final delivered = deliveredTo?.keys.toSet() ?? const <String>{};
    final read = readBy?.keys.toSet() ?? const <String>{};
    return delivered.difference(read).toList();
  }

  /// Creates a copy of this message with the given fields replaced.
  ///
  /// Fields not provided will retain their current values.
  Message copyWith({
    final String? id,
    final String? text,
    final String? senderId,
    final DateTime? timestamp,
    final String? type,
    final String? status,
    final String? detectedLanguage,
    final Map<String, String>? translations,
    final String? replyTo,
    final MessageMetadata? metadata,
    final List<double>? embedding,
    final MessageAIAnalysis? aiAnalysis,
    final String? culturalHint,
    final MessageContextDetails? contextDetails,
    final Map<String, DateTime>? deliveredTo,
    final Map<String, DateTime>? readBy,
  }) =>
      Message(
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
  List<Object?> get props => <Object?>[
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

/// Metadata for a message.
///
/// Contains auxiliary information about message state and content.
class MessageMetadata extends Equatable {
  /// Creates a new message metadata instance.
  const MessageMetadata({
    required this.edited,
    required this.deleted,
    required this.priority,
    required this.hasIdioms,
  });

  /// Creates a default metadata instance with standard values.
  factory MessageMetadata.defaultMetadata() => const MessageMetadata(
        edited: false,
        deleted: false,
        priority: 'medium',
        hasIdioms: false,
      );

  /// Whether the message has been edited after creation
  final bool edited;

  /// Whether the message has been deleted (soft delete)
  final bool deleted;

  /// Priority level: 'low', 'medium', 'high', or 'urgent'
  final String priority;

  /// Whether the message contains idioms or slang
  final bool hasIdioms;

  /// Creates a copy of this metadata with the given fields replaced.
  MessageMetadata copyWith({
    final bool? edited,
    final bool? deleted,
    final String? priority,
    final bool? hasIdioms,
  }) =>
      MessageMetadata(
        edited: edited ?? this.edited,
        deleted: deleted ?? this.deleted,
        priority: priority ?? this.priority,
        hasIdioms: hasIdioms ?? this.hasIdioms,
      );

  @override
  List<Object?> get props => <Object?>[edited, deleted, priority, hasIdioms];
}

/// AI-generated analysis results for a message.
///
/// Contains extracted insights from NLP processing.
class MessageAIAnalysis extends Equatable {
  /// Creates a new AI analysis instance.
  const MessageAIAnalysis({
    required this.priority,
    required this.actionItems,
    required this.sentiment,
  });

  /// Priority level determined by AI: 'low', 'medium', 'high', or 'urgent'
  final String priority;

  /// List of action items extracted from the message content
  final List<String> actionItems;

  /// Sentiment analysis result: 'positive', 'neutral', or 'negative'
  final String sentiment;

  /// Creates a copy of this analysis with the given fields replaced.
  MessageAIAnalysis copyWith({
    final String? priority,
    final List<String>? actionItems,
    final String? sentiment,
  }) =>
      MessageAIAnalysis(
        priority: priority ?? this.priority,
        actionItems: actionItems ?? this.actionItems,
        sentiment: sentiment ?? this.sentiment,
      );

  @override
  List<Object?> get props => <Object?>[priority, actionItems, sentiment];
}
