import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';

/// Data model for Conversation that adds serialization capabilities
///
/// This model extends the domain entity and adds fromJson/toJson methods
/// for Firebase Firestore integration.
class ConversationModel extends Conversation {
  const ConversationModel({
    required super.documentId,
    required super.type,
    required super.participantIds,
    required super.participants,
    required super.lastUpdatedAt, required super.initiatedAt, required super.unreadCount, required super.translationEnabled, required super.autoDetectLanguage, super.lastMessage,
    super.groupName,
    super.groupImage,
    super.adminIds,
  });

  /// Creates a ConversationModel from a domain Conversation entity
  factory ConversationModel.fromEntity(Conversation conversation) => ConversationModel(
      documentId: conversation.documentId,
      type: conversation.type,
      participantIds: conversation.participantIds,
      participants: conversation.participants,
      lastMessage: conversation.lastMessage,
      lastUpdatedAt: conversation.lastUpdatedAt,
      initiatedAt: conversation.initiatedAt,
      unreadCount: conversation.unreadCount,
      translationEnabled: conversation.translationEnabled,
      autoDetectLanguage: conversation.autoDetectLanguage,
      groupName: conversation.groupName,
      groupImage: conversation.groupImage,
      adminIds: conversation.adminIds,
    );

  /// Creates a ConversationModel from JSON (Firestore document)
  factory ConversationModel.fromJson(Map<String, dynamic> json) => ConversationModel(
      documentId: json['documentId'] as String,
      type: json['type'] as String,
      participantIds: List<String>.from(json['participantIds'] as List),
      participants: (json['participants'] as List)
          .map((p) => ParticipantModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      lastMessage: json['lastMessage'] != null
          ? LastMessageModel.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            )
          : null,
      lastUpdatedAt: _parseDateTime(json['lastUpdatedAt']),
      initiatedAt: _parseDateTime(json['initiatedAt']),
      unreadCount: Map<String, int>.from(json['unreadCount'] as Map),
      translationEnabled: json['translationEnabled'] as bool,
      autoDetectLanguage: json['autoDetectLanguage'] as bool,
      groupName: json['groupName'] as String?,
      groupImage: json['groupImage'] as String?,
      adminIds: json['adminIds'] != null
          ? List<String>.from(json['adminIds'] as List)
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

  /// Converts this ConversationModel to JSON for Firestore
  Map<String, dynamic> toJson() => {
      'documentId': documentId,
      'type': type,
      'participantIds': participantIds,
      'participants': participants
          .map((p) => ParticipantModel.fromEntity(p).toJson())
          .toList(),
      if (lastMessage != null)
        'lastMessage': LastMessageModel.fromEntity(lastMessage!).toJson(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'initiatedAt': initiatedAt.toIso8601String(),
      'unreadCount': unreadCount,
      'translationEnabled': translationEnabled,
      'autoDetectLanguage': autoDetectLanguage,
      if (groupName != null) 'groupName': groupName,
      if (groupImage != null) 'groupImage': groupImage,
      if (adminIds != null) 'adminIds': adminIds,
    };

  /// Converts this model to a domain entity
  Conversation toEntity() => Conversation(
      documentId: documentId,
      type: type,
      participantIds: participantIds,
      participants: participants,
      lastMessage: lastMessage,
      lastUpdatedAt: lastUpdatedAt,
      initiatedAt: initiatedAt,
      unreadCount: unreadCount,
      translationEnabled: translationEnabled,
      autoDetectLanguage: autoDetectLanguage,
      groupName: groupName,
      groupImage: groupImage,
      adminIds: adminIds,
    );

  /// Creates a copy of this model with the given fields replaced
  @override
  ConversationModel copyWith({
    String? documentId,
    String? type,
    List<String>? participantIds,
    List<Participant>? participants,
    LastMessage? lastMessage,
    DateTime? lastUpdatedAt,
    DateTime? initiatedAt,
    Map<String, int>? unreadCount,
    bool? translationEnabled,
    bool? autoDetectLanguage,
    String? groupName,
    String? groupImage,
    List<String>? adminIds,
  }) => ConversationModel(
      documentId: documentId ?? this.documentId,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      initiatedAt: initiatedAt ?? this.initiatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      translationEnabled: translationEnabled ?? this.translationEnabled,
      autoDetectLanguage: autoDetectLanguage ?? this.autoDetectLanguage,
      groupName: groupName ?? this.groupName,
      groupImage: groupImage ?? this.groupImage,
      adminIds: adminIds ?? this.adminIds,
    );
}

/// Data model for Participant with serialization
class ParticipantModel extends Participant {
  const ParticipantModel({
    required super.uid,
    required super.name,
    required super.preferredLanguage, super.imageUrl,
  });

  /// Creates a ParticipantModel from a domain Participant entity
  factory ParticipantModel.fromEntity(Participant participant) => ParticipantModel(
      uid: participant.uid,
      name: participant.name,
      imageUrl: participant.imageUrl,
      preferredLanguage: participant.preferredLanguage,
    );

  /// Creates a ParticipantModel from JSON
  factory ParticipantModel.fromJson(Map<String, dynamic> json) => ParticipantModel(
      uid: json['uid'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      preferredLanguage: json['preferredLanguage'] as String,
    );

  /// Converts this model to JSON
  Map<String, dynamic> toJson() => {
      'uid': uid,
      'name': name,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'preferredLanguage': preferredLanguage,
    };

  /// Converts this model to a domain entity
  Participant toEntity() => Participant(
      uid: uid,
      name: name,
      imageUrl: imageUrl,
      preferredLanguage: preferredLanguage,
    );
}

/// Data model for LastMessage with serialization
class LastMessageModel extends LastMessage {
  const LastMessageModel({
    required super.text,
    required super.senderId,
    required super.timestamp,
    required super.type,
    super.translations,
  });

  /// Creates a LastMessageModel from a domain LastMessage entity
  factory LastMessageModel.fromEntity(LastMessage lastMessage) => LastMessageModel(
      text: lastMessage.text,
      senderId: lastMessage.senderId,
      timestamp: lastMessage.timestamp,
      type: lastMessage.type,
      translations: lastMessage.translations,
    );

  /// Creates a LastMessageModel from JSON
  factory LastMessageModel.fromJson(Map<String, dynamic> json) => LastMessageModel(
      text: json['text'] as String,
      senderId: json['senderId'] as String,
      timestamp: ConversationModel._parseDateTime(json['timestamp']),
      type: json['type'] as String,
      translations: json['translations'] != null
          ? Map<String, String>.from(json['translations'] as Map)
          : null,
    );

  /// Converts this model to JSON
  Map<String, dynamic> toJson() => {
      'text': text,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      if (translations != null) 'translations': translations,
    };

  /// Converts this model to a domain entity
  LastMessage toEntity() => LastMessage(
      text: text,
      senderId: senderId,
      timestamp: timestamp,
      type: type,
      translations: translations,
    );
}
