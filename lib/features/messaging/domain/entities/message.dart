import 'package:equatable/equatable.dart';
import 'package:message_ai/features/messaging/domain/entities/message_context_details.dart';

/// Domain entity representing a message in a conversation
///
/// This entity follows the clean architecture pattern and represents
/// the core business logic for messages. It is independent of any
/// data source or framework implementation.
///
/// Status tracking (delivered/read) is now handled separately via
/// MessageStatus table and MessageStatusDao. See MessageWithStatus
/// for presentation layer wrapper that includes status information.
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

  /// Creates a copy of this message with the given fields replaced.
  ///
  /// Fields not provided will retain their current values.
  Message copyWith({
    final String? id,
    final String? text,
    final String? senderId,
    final DateTime? timestamp,
    final String? type,
    final String? detectedLanguage,
    final Map<String, String>? translations,
    final String? replyTo,
    final MessageMetadata? metadata,
    final List<double>? embedding,
    final MessageAIAnalysis? aiAnalysis,
    final String? culturalHint,
    final MessageContextDetails? contextDetails,
  }) => Message(
    id: id ?? this.id,
    text: text ?? this.text,
    senderId: senderId ?? this.senderId,
    timestamp: timestamp ?? this.timestamp,
    type: type ?? this.type,
    detectedLanguage: detectedLanguage ?? this.detectedLanguage,
    translations: translations ?? this.translations,
    replyTo: replyTo ?? this.replyTo,
    metadata: metadata ?? this.metadata,
    embedding: embedding ?? this.embedding,
    aiAnalysis: aiAnalysis ?? this.aiAnalysis,
    culturalHint: culturalHint ?? this.culturalHint,
    contextDetails: contextDetails ?? this.contextDetails,
  );

  @override
  List<Object?> get props => <Object?>[
    id,
    text,
    senderId,
    timestamp,
    type,
    detectedLanguage,
    translations,
    replyTo,
    metadata,
    embedding,
    aiAnalysis,
    culturalHint,
    contextDetails,
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
  }) => MessageMetadata(
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
  }) => MessageAIAnalysis(
    priority: priority ?? this.priority,
    actionItems: actionItems ?? this.actionItems,
    sentiment: sentiment ?? this.sentiment,
  );

  @override
  List<Object?> get props => <Object?>[priority, actionItems, sentiment];
}
