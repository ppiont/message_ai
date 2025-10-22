import 'package:drift/drift.dart';

/// Users table for caching user profile data
///
/// Stores user information for offline access and quick lookup.
/// Syncs with Firebase Auth and Firestore users collection.
@DataClassName('UserEntity')
class Users extends Table {
  /// Unique user ID (matches Firebase Auth UID)
  TextColumn get uid => text()();

  /// User's email address
  TextColumn get email => text().nullable()();

  /// User's phone number
  TextColumn get phoneNumber => text().nullable()();

  /// Display name
  TextColumn get name => text()();

  /// Profile image URL
  TextColumn get imageUrl => text().nullable()();

  /// FCM token for push notifications
  TextColumn get fcmToken => text().nullable()();

  /// Preferred language code (e.g., 'en', 'es')
  TextColumn get preferredLanguage =>
      text().withDefault(const Constant('en'))();

  /// Account creation timestamp
  DateTimeColumn get createdAt => dateTime()();

  /// Last seen timestamp
  DateTimeColumn get lastSeen => dateTime()();

  /// Online status indicator
  BoolColumn get isOnline => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}
