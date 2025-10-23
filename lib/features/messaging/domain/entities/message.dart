import 'package:equatable/equatable.dart';

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
    required this.status,
    required this.metadata, this.detectedLanguage,
    this.translations,
    this.replyTo,
    this.embedding,
    this.aiAnalysis,
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

  /// Delivery status (sent, delivered, read, failed)
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
