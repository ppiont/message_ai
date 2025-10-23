import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';

/// Data model for Message that adds serialization capabilities
///
/// This model extends the domain entity and adds fromJson/toJson methods
/// for Firebase Firestore integration.
class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.text,
    required super.senderId,
    required super.timestamp,
    required super.type,
    required super.status,
    required super.metadata, super.detectedLanguage,
    super.translations,
    super.replyTo,
    super.embedding,
    super.aiAnalysis,
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
    );

  /// Creates a MessageModel from JSON (Firestore document)
  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      senderId: json['senderId'] as String,
      timestamp: _parseDateTime(json['timestamp']),
      type: json['type'] as String,
      status: json['status'] as String,
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
    );

  /// Helper method to parse DateTime from either Timestamp or String
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      throw ArgumentError('Invalid datetime value: $value');
    }
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
    };

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
    );
}

/// Data model for MessageMetadata with serialization
class MessageMetadataModel extends MessageMetadata {
  const MessageMetadataModel({
    required super.edited,
    required super.deleted,
    required super.priority,
    required super.hasIdioms,
  });

  /// Creates a MessageMetadataModel from a domain MessageMetadata entity
  factory MessageMetadataModel.fromEntity(MessageMetadata metadata) => MessageMetadataModel(
      edited: metadata.edited,
      deleted: metadata.deleted,
      priority: metadata.priority,
      hasIdioms: metadata.hasIdioms,
    );

  /// Creates a MessageMetadataModel from JSON
  factory MessageMetadataModel.fromJson(Map<String, dynamic> json) => MessageMetadataModel(
      edited: json['edited'] as bool,
      deleted: json['deleted'] as bool,
      priority: json['priority'] as String,
      hasIdioms: json['hasIdioms'] as bool,
    );

  /// Converts this model to JSON
  Map<String, dynamic> toJson() => {
      'edited': edited,
      'deleted': deleted,
      'priority': priority,
      'hasIdioms': hasIdioms,
    };

  /// Converts this model to a domain entity
  MessageMetadata toEntity() => MessageMetadata(
      edited: edited,
      deleted: deleted,
      priority: priority,
      hasIdioms: hasIdioms,
    );
}

/// Data model for MessageAIAnalysis with serialization
class MessageAIAnalysisModel extends MessageAIAnalysis {
  const MessageAIAnalysisModel({
    required super.priority,
    required super.actionItems,
    required super.sentiment,
  });

  /// Creates a MessageAIAnalysisModel from a domain MessageAIAnalysis entity
  factory MessageAIAnalysisModel.fromEntity(MessageAIAnalysis analysis) => MessageAIAnalysisModel(
      priority: analysis.priority,
      actionItems: analysis.actionItems,
      sentiment: analysis.sentiment,
    );

  /// Creates a MessageAIAnalysisModel from JSON
  factory MessageAIAnalysisModel.fromJson(Map<String, dynamic> json) => MessageAIAnalysisModel(
      priority: json['priority'] as String,
      actionItems: List<String>.from(json['actionItems'] as List),
      sentiment: json['sentiment'] as String,
    );

  /// Converts this model to JSON
  Map<String, dynamic> toJson() => {
      'priority': priority,
      'actionItems': actionItems,
      'sentiment': sentiment,
    };

  /// Converts this model to a domain entity
  MessageAIAnalysis toEntity() => MessageAIAnalysis(
      priority: priority,
      actionItems: actionItems,
      sentiment: sentiment,
    );
}
