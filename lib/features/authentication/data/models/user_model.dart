import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';

/// Data model for User with JSON serialization support
///
/// Handles conversion between Firestore documents, JSON, and the domain entity.
class UserModel {

  const UserModel({
    required this.uid,
    required this.displayName, required this.preferredLanguage, required this.createdAt, required this.lastSeen, required this.isOnline, required this.fcmTokens, this.email,
    this.phoneNumber,
    this.photoURL,
  });

  /// Creates a UserModel from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      displayName: json['displayName'] as String,
      photoURL: json['photoURL'] as String?,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastSeen: (json['lastSeen'] as Timestamp).toDate(),
      isOnline: json['isOnline'] as bool? ?? false,
      fcmTokens:
          (json['fcmTokens'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

  /// Creates a UserModel from a User entity
  factory UserModel.fromEntity(User user) => UserModel(
      uid: user.uid,
      email: user.email,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
      photoURL: user.photoURL,
      preferredLanguage: user.preferredLanguage,
      createdAt: user.createdAt,
      lastSeen: user.lastSeen,
      isOnline: user.isOnline,
      fcmTokens: user.fcmTokens,
    );
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String displayName;
  final String? photoURL;
  final String preferredLanguage;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnline;
  final List<String> fcmTokens;

  /// Converts this UserModel to JSON map for Firestore
  Map<String, dynamic> toJson() => {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoURL': photoURL,
      'preferredLanguage': preferredLanguage,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isOnline': isOnline,
      'fcmTokens': fcmTokens,
    };

  /// Converts this UserModel to a User entity
  User toEntity() => User(
      uid: uid,
      email: email,
      phoneNumber: phoneNumber,
      displayName: displayName,
      photoURL: photoURL,
      preferredLanguage: preferredLanguage,
      createdAt: createdAt,
      lastSeen: lastSeen,
      isOnline: isOnline,
      fcmTokens: fcmTokens,
    );

  /// Creates a copy of this model with the given fields replaced
  UserModel copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoURL,
    String? preferredLanguage,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    List<String>? fcmTokens,
  }) => UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
}
