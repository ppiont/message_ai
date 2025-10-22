import 'package:equatable/equatable.dart';

/// User domain entity representing an authenticated user
///
/// This is the core domain model for users, independent of any
/// data source implementation details.
class User extends Equatable {

  const User({
    required this.uid,
    required this.displayName, required this.preferredLanguage, required this.createdAt, required this.lastSeen, required this.isOnline, required this.fcmTokens, this.email,
    this.phoneNumber,
    this.photoURL,
  });
  /// Firebase Authentication unique identifier
  final String uid;

  /// User's email address
  final String? email;

  /// User's phone number in E.164 format
  final String? phoneNumber;

  /// User's display name
  final String displayName;

  /// URL to user's profile photo
  final String? photoURL;

  /// User's preferred language code (e.g., 'en', 'es', 'fr')
  final String preferredLanguage;

  /// Timestamp when user account was created
  final DateTime createdAt;

  /// Timestamp of user's last activity
  final DateTime lastSeen;

  /// Whether user is currently online
  final bool isOnline;

  /// List of FCM tokens for push notifications across devices
  final List<String> fcmTokens;

  /// Creates a copy of this user with the given fields replaced
  User copyWith({
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
  }) => User(
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

  @override
  List<Object?> get props => [
    uid,
    email,
    phoneNumber,
    displayName,
    photoURL,
    preferredLanguage,
    createdAt,
    lastSeen,
    isOnline,
    fcmTokens,
  ];

  @override
  String toString() => 'User(uid: $uid, displayName: $displayName, email: $email, '
        'isOnline: $isOnline, preferredLanguage: $preferredLanguage)';
}
