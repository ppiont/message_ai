import 'package:equatable/equatable.dart';

/// Domain entity representing a conversation (1-to-1 or group chat)
///
/// This entity follows the clean architecture pattern and represents
/// the core business logic for conversations.
class Conversation extends Equatable {

  const Conversation({
    required this.documentId,
    required this.type,
    required this.participantIds,
    required this.participants,
    required this.lastUpdatedAt, required this.initiatedAt, required this.unreadCount, required this.translationEnabled, required this.autoDetectLanguage, this.lastMessage,
    this.groupName,
    this.groupImage,
    this.adminIds,
  });
  /// Unique identifier for the conversation
  final String documentId;

  /// Type of conversation ('direct' for 1-to-1, 'group' for group chats)
  final String type;

  /// List of participant user IDs
  final List<String> participantIds;

  /// List of participant details
  final List<Participant> participants;

  /// Details of the last message sent in this conversation
  final LastMessage? lastMessage;

  /// Timestamp of the last update to this conversation
  final DateTime lastUpdatedAt;

  /// Timestamp when the conversation was initiated
  final DateTime initiatedAt;

  /// Map of user IDs to their unread message counts
  final Map<String, int> unreadCount;

  /// Whether translation is enabled for this conversation
  final bool translationEnabled;

  /// Whether to automatically detect and translate languages
  final bool autoDetectLanguage;

  /// Group name (only for group conversations)
  final String? groupName;

  /// Group image URL (only for group conversations)
  final String? groupImage;

  /// List of admin user IDs (only for group conversations)
  final List<String>? adminIds;

  /// Creates a copy of this conversation with the given fields replaced
  Conversation copyWith({
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
  }) => Conversation(
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

  /// Returns true if this is a direct (1-to-1) conversation
  bool get isDirect => type == 'direct';

  /// Returns true if this is a group conversation
  bool get isGroup => type == 'group';

  /// Returns the unread count for a specific user
  int getUnreadCountForUser(String userId) => unreadCount[userId] ?? 0;

  @override
  List<Object?> get props => [
        documentId,
        type,
        participantIds,
        participants,
        lastMessage,
        lastUpdatedAt,
        initiatedAt,
        unreadCount,
        translationEnabled,
        autoDetectLanguage,
        groupName,
        groupImage,
        adminIds,
      ];
}

/// Participant details in a conversation
class Participant extends Equatable {

  const Participant({
    required this.uid,
    required this.name,
    required this.preferredLanguage, this.imageUrl,
  });
  /// User ID
  final String uid;

  /// Display name
  final String name;

  /// Profile image URL
  final String? imageUrl;

  /// Preferred language code
  final String preferredLanguage;

  /// Creates a copy of this participant with the given fields replaced
  Participant copyWith({
    String? uid,
    String? name,
    String? imageUrl,
    String? preferredLanguage,
  }) => Participant(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );

  @override
  List<Object?> get props => [uid, name, imageUrl, preferredLanguage];
}

/// Details of the last message in a conversation
class LastMessage extends Equatable {

  const LastMessage({
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.type,
    this.translations,
  });
  /// Message text content
  final String text;

  /// Sender's user ID
  final String senderId;

  /// Sender's display name
  final String senderName;

  /// Message timestamp
  final DateTime timestamp;

  /// Message type (text, image, audio, etc.)
  final String type;

  /// Map of language codes to translated text
  final Map<String, String>? translations;

  /// Creates a copy of this last message with the given fields replaced
  LastMessage copyWith({
    String? text,
    String? senderId,
    String? senderName,
    DateTime? timestamp,
    String? type,
    Map<String, String>? translations,
  }) => LastMessage(
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      translations: translations ?? this.translations,
    );

  @override
  List<Object?> get props => [
        text,
        senderId,
        senderName,
        timestamp,
        type,
        translations,
      ];
}
