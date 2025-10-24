import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/entities/message_context_details.dart';

/// Data model for Message that adds serialization capabilities.
///
/// This model extends the domain [Message] entity and adds fromJson/toJson methods
/// for Firebase Firestore integration. It handles JSON serialization of per-user
/// read receipt maps and timestamp conversions.
class MessageModel extends Message {
  /// Creates a new message model instance.
  const MessageModel({
    required super.id,
    required super.text,
    required super.senderId,
    required super.timestamp,
    required super.type,
    required super.metadata,
    super.detectedLanguage,
    super.translations,
    super.replyTo,
    super.embedding,
    super.aiAnalysis,
    super.culturalHint,
    super.contextDetails,
    super.deliveredTo,
    super.readBy,
    super.status = 'sent',
  });

  /// Creates a MessageModel from a domain Message entity
  factory MessageModel.fromEntity(Message message) => MessageModel(
      id: message.id,
      text: message.text,
      senderId: message.senderId,
      timestamp: message.timestamp,
      type: message.type,
      status: message.status,
      detectedLanguage: message.detectedLanguage,
      translations: message.translations,
      replyTo: message.replyTo,
      metadata: message.metadata,
      embedding: message.embedding,
      aiAnalysis: message.aiAnalysis,
      culturalHint: message.culturalHint,
      contextDetails: message.contextDetails,
      deliveredTo: message.deliveredTo,
      readBy: message.readBy,
    );

  /// Creates a MessageModel from JSON (Firestore document)
  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      senderId: json['senderId'] as String,
      timestamp: _parseDateTime(json['timestamp']),
      type: json['type'] as String,
      status: json['status'] as String? ?? 'sent',
      detectedLanguage: json['detectedLanguage'] as String?,
      translations: json['translations'] != null
          ? Map<String, String>.from(json['translations'] as Map)
          : null,
      replyTo: json['replyTo'] as String?,
      metadata: MessageMetadataModel.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
      embedding: json['embedding'] != null
          ? List<double>.from(
              (json['embedding'] as List).map((e) => (e as num).toDouble()),
            )
          : null,
      aiAnalysis: json['aiAnalysis'] != null
          ? MessageAIAnalysisModel.fromJson(
              json['aiAnalysis'] as Map<String, dynamic>,
            )
          : null,
      culturalHint: json['culturalHint'] as String?,
      contextDetails: json['contextDetails'] != null
          ? MessageContextDetails.fromJson(
              json['contextDetails'] as Map<String, dynamic>,
            )
          : null,
      // NEW: Parse per-user read receipts
      deliveredTo: _parseTimestampMap(json['deliveredTo']),
      readBy: _parseTimestampMap(json['readBy']),
    );

  /// Parses timestamp map from Firestore JSON.
  ///
  /// Converts Firestore Timestamp objects to Dart DateTime instances.
  /// Returns null if the input is null or if the resulting map is empty.
  static Map<String, DateTime>? _parseTimestampMap(final dynamic value) {
    if (value == null) {
      return null;
    }

    final map = value as Map<String, dynamic>;
    final result = <String, DateTime>{};

    map.forEach((final userId, final timestamp) {
      result[userId] = _parseDateTime(timestamp);
    });

    return result.isEmpty ? null : result;
  }

  /// Parses a DateTime from Firestore Timestamp or ISO 8601 string.
  ///
  /// Handles both Firestore Timestamp objects and ISO 8601 string formats
  /// for backward compatibility with different data sources.
  /// Throws [ArgumentError] if the value is in an unsupported format.
  static DateTime _parseDateTime(final dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    throw ArgumentError('Invalid datetime value: $value');
  }

  /// Converts this MessageModel to JSON for Firestore
  Map<String, dynamic> toJson() => {
      'id': id,
      'text': text,
      'senderId': senderId,
      'timestamp': Timestamp.fromDate(timestamp), // Use Firestore Timestamp
      'type': type,
      'status': status,
      if (detectedLanguage != null) 'detectedLanguage': detectedLanguage,
      if (translations != null) 'translations': translations,
      if (replyTo != null) 'replyTo': replyTo,
      'metadata': MessageMetadataModel.fromEntity(metadata).toJson(),
      if (embedding != null) 'embedding': embedding,
      if (aiAnalysis != null)
        'aiAnalysis': MessageAIAnalysisModel.fromEntity(aiAnalysis!).toJson(),
      if (culturalHint != null) 'culturalHint': culturalHint,
      if (contextDetails != null) 'contextDetails': contextDetails!.toJson(),
      // NEW: Serialize per-user read receipts
      if (deliveredTo != null) 'deliveredTo': _serializeTimestampMap(deliveredTo!),
      if (readBy != null) 'readBy': _serializeTimestampMap(readBy!),
    };

  /// Serializes a timestamp map to Firestore format.
  ///
  /// Converts Dart DateTime instances to Firestore Timestamp objects
  /// for proper JSON serialization.
  static Map<String, dynamic> _serializeTimestampMap(
    final Map<String, DateTime> map,
  ) {
    final result = <String, dynamic>{};
    map.forEach((final userId, final timestamp) {
      result[userId] = Timestamp.fromDate(timestamp);
    });
    return result;
  }

  /// Converts this model to a domain entity
  Message toEntity() => Message(
      id: id,
      text: text,
      senderId: senderId,
      timestamp: timestamp,
      type: type,
      status: status,
      detectedLanguage: detectedLanguage,
      translations: translations,
      replyTo: replyTo,
      metadata: metadata,
      embedding: embedding,
      aiAnalysis: aiAnalysis,
      culturalHint: culturalHint,
      contextDetails: contextDetails,
      deliveredTo: deliveredTo,
      readBy: readBy,
    );

  /// Creates a copy of this model with the given fields replaced
  @override
  MessageModel copyWith({
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
  }) => MessageModel(
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
}

/// Data model for [MessageMetadata] with Firestore serialization.
class MessageMetadataModel extends MessageMetadata {
  /// Creates a new message metadata model instance.
  const MessageMetadataModel({
    required super.edited,
    required super.deleted,
    required super.priority,
    required super.hasIdioms,
  });

  /// Creates a [MessageMetadataModel] from a domain entity.
  factory MessageMetadataModel.fromEntity(final MessageMetadata metadata) =>
      MessageMetadataModel(
        edited: metadata.edited,
        deleted: metadata.deleted,
        priority: metadata.priority,
        hasIdioms: metadata.hasIdioms,
      );

  /// Creates a [MessageMetadataModel] from JSON (Firestore document).
  factory MessageMetadataModel.fromJson(final Map<String, dynamic> json) =>
      MessageMetadataModel(
        edited: json['edited'] as bool,
        deleted: json['deleted'] as bool,
        priority: json['priority'] as String,
        hasIdioms: json['hasIdioms'] as bool,
      );

  /// Converts this model to JSON for Firestore.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'edited': edited,
        'deleted': deleted,
        'priority': priority,
        'hasIdioms': hasIdioms,
      };

  /// Converts this model to a domain entity.
  MessageMetadata toEntity() => MessageMetadata(
        edited: edited,
        deleted: deleted,
        priority: priority,
        hasIdioms: hasIdioms,
      );
}

/// Data model for [MessageAIAnalysis] with Firestore serialization.
class MessageAIAnalysisModel extends MessageAIAnalysis {
  /// Creates a new AI analysis model instance.
  const MessageAIAnalysisModel({
    required super.priority,
    required super.actionItems,
    required super.sentiment,
  });

  /// Creates a [MessageAIAnalysisModel] from a domain entity.
  factory MessageAIAnalysisModel.fromEntity(final MessageAIAnalysis analysis) =>
      MessageAIAnalysisModel(
        priority: analysis.priority,
        actionItems: analysis.actionItems,
        sentiment: analysis.sentiment,
      );

  /// Creates a [MessageAIAnalysisModel] from JSON (Firestore document).
  factory MessageAIAnalysisModel.fromJson(final Map<String, dynamic> json) =>
      MessageAIAnalysisModel(
        priority: json['priority'] as String,
        actionItems: List<String>.from(json['actionItems'] as List<dynamic>),
        sentiment: json['sentiment'] as String,
      );

  /// Converts this model to JSON for Firestore.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'priority': priority,
        'actionItems': actionItems,
        'sentiment': sentiment,
      };

  /// Converts this model to a domain entity.
  MessageAIAnalysis toEntity() => MessageAIAnalysis(
        priority: priority,
        actionItems: actionItems,
        sentiment: sentiment,
      );
}
