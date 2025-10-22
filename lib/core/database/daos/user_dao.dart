import 'package:drift/drift.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/database/tables/users_table.dart';

part 'user_dao.g.dart';

/// Data Access Object for Users table
///
/// Handles all local database operations for users including:
/// - CRUD operations
/// - User search (by name, phone, email)
/// - Status updates (online/offline)
/// - FCM token management
/// - Reactive streams for real-time UI updates
@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  // ============================================================================
  // Query Methods
  // ============================================================================

  /// Get a single user by UID
  Future<UserEntity?> getUserByUid(String uid) => (select(users)..where((u) => u.uid.equals(uid))).getSingleOrNull();

  /// Get multiple users by UIDs
  Future<List<UserEntity>> getUsersByUids(List<String> uids) => (select(users)..where((u) => u.uid.isIn(uids))).get();

  /// Get all users
  Future<List<UserEntity>> getAllUsers({
    int limit = 100,
    int offset = 0,
  }) => (select(users)
          ..orderBy([(u) => OrderingTerm.asc(u.name)])
          ..limit(limit, offset: offset))
        .get();

  /// Watch a specific user (reactive stream)
  ///
  /// Returns a stream that emits new values whenever the user changes
  Stream<UserEntity?> watchUser(String uid) => (select(users)..where((u) => u.uid.equals(uid))).watchSingleOrNull();

  /// Watch all users (reactive stream)
  Stream<List<UserEntity>> watchAllUsers({int limit = 100}) => (select(users)
          ..orderBy([(u) => OrderingTerm.asc(u.name)])
          ..limit(limit))
        .watch();

  /// Search users by name
  ///
  /// Performs a case-insensitive LIKE search on the name field
  Future<List<UserEntity>> searchUsersByName(String query) => (select(users)
          ..where((u) => u.name.like('%$query%'))
          ..orderBy([(u) => OrderingTerm.asc(u.name)]))
        .get();

  /// Search users by email
  Future<List<UserEntity>> searchUsersByEmail(String query) => (select(users)
          ..where((u) => u.email.like('%$query%'))
          ..orderBy([(u) => OrderingTerm.asc(u.name)]))
        .get();

  /// Search users by phone number
  Future<List<UserEntity>> searchUsersByPhone(String query) => (select(users)
          ..where((u) => u.phoneNumber.like('%$query%'))
          ..orderBy([(u) => OrderingTerm.asc(u.name)]))
        .get();

  /// Get online users
  Future<List<UserEntity>> getOnlineUsers() => (select(users)
          ..where((u) => u.isOnline.equals(true))
          ..orderBy([(u) => OrderingTerm.asc(u.name)]))
        .get();

  /// Watch online users (reactive)
  Stream<List<UserEntity>> watchOnlineUsers() => (select(users)
          ..where((u) => u.isOnline.equals(true))
          ..orderBy([(u) => OrderingTerm.asc(u.name)]))
        .watch();

  /// Get users by preferred language
  Future<List<UserEntity>> getUsersByLanguage(String languageCode) => (select(users)
          ..where((u) => u.preferredLanguage.equals(languageCode))
          ..orderBy([(u) => OrderingTerm.asc(u.name)]))
        .get();

  /// Get recently active users
  ///
  /// Returns users who were last seen within the specified time period
  Future<List<UserEntity>> getRecentlyActiveUsers({
    Duration timeWindow = const Duration(days: 7),
    int limit = 50,
  }) {
    final cutoffTime = DateTime.now().subtract(timeWindow);
    return (select(users)
          ..where((u) => u.lastSeen.isBiggerThanValue(cutoffTime))
          ..orderBy([(u) => OrderingTerm.desc(u.lastSeen)])
          ..limit(limit))
        .get();
  }

  /// Count total users
  Future<int> countUsers() async {
    final count = users.uid.count();
    final query = selectOnly(users)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Count online users
  Future<int> countOnlineUsers() async {
    final count = users.uid.count();
    final query = selectOnly(users)
      ..addColumns([count])
      ..where(users.isOnline.equals(true));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============================================================================
  // Insert/Update/Delete Operations
  // ============================================================================

  /// Insert a new user
  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);

  /// Insert or update a user (upsert)
  Future<int> upsertUser(UsersCompanion user) => into(users).insertOnConflictUpdate(user);

  /// Batch insert users (efficient for initial sync)
  Future<void> insertUsers(List<UsersCompanion> userList) async {
    await batch((batch) {
      batch.insertAll(users, userList);
    });
  }

  /// Update user by UID
  Future<bool> updateUser(String uid, UsersCompanion user) => (update(users)..where((u) => u.uid.equals(uid)))
        .write(user)
        .then((count) => count > 0);

  /// Update user's online status
  Future<bool> updateUserOnlineStatus({
    required String uid,
    required bool isOnline,
  }) {
    final now = DateTime.now();
    return updateUser(
      uid,
      UsersCompanion(
        isOnline: Value(isOnline),
        lastSeen: Value(now),
      ),
    );
  }

  /// Update user's FCM token
  Future<bool> updateFcmToken({
    required String uid,
    required String token,
  }) => updateUser(
      uid,
      UsersCompanion(
        fcmToken: Value(token),
      ),
    );

  /// Update user's preferred language
  Future<bool> updatePreferredLanguage({
    required String uid,
    required String languageCode,
  }) => updateUser(
      uid,
      UsersCompanion(
        preferredLanguage: Value(languageCode),
      ),
    );

  /// Update user's profile image
  Future<bool> updateProfileImage({
    required String uid,
    required String imageUrl,
  }) => updateUser(
      uid,
      UsersCompanion(
        imageUrl: Value(imageUrl),
      ),
    );

  /// Update last seen timestamp
  Future<bool> updateLastSeen(String uid) => updateUser(
      uid,
      UsersCompanion(
        lastSeen: Value(DateTime.now()),
      ),
    );

  /// Delete a user
  Future<int> deleteUser(String uid) => (delete(users)..where((u) => u.uid.equals(uid))).go();

  /// Delete all users (use with caution!)
  Future<int> deleteAllUsers() => delete(users).go();

  // ============================================================================
  // Batch Operations
  // ============================================================================

  /// Batch update user statuses
  Future<void> batchUpdateOnlineStatus(
    Map<String, bool> userStatuses,
  ) async {
    final now = DateTime.now();
    await batch((batch) {
      for (final entry in userStatuses.entries) {
        batch.update(
          users,
          UsersCompanion(
            isOnline: Value(entry.value),
            lastSeen: Value(now),
          ),
          where: (u) => u.uid.equals(entry.key),
        );
      }
    });
  }

  /// Batch update FCM tokens
  Future<void> batchUpdateFcmTokens(Map<String, String> tokenMap) async {
    await batch((batch) {
      for (final entry in tokenMap.entries) {
        batch.update(
          users,
          UsersCompanion(
            fcmToken: Value(entry.value),
          ),
          where: (u) => u.uid.equals(entry.key),
        );
      }
    });
  }

  /// Batch delete users
  Future<void> batchDeleteUsers(List<String> uids) async {
    await batch((batch) {
      for (final uid in uids) {
        batch.deleteWhere(
          users,
          (u) => u.uid.equals(uid),
        );
      }
    });
  }

  // ============================================================================
  // Special Queries
  // ============================================================================

  /// Search users by any field (name, email, or phone)
  ///
  /// Performs a comprehensive search across multiple fields
  Future<List<UserEntity>> searchUsers(String query) async {
    final results = <UserEntity>{};

    // Search by name
    final nameResults = await searchUsersByName(query);
    results.addAll(nameResults);

    // Search by email
    final emailResults = await searchUsersByEmail(query);
    results.addAll(emailResults);

    // Search by phone
    final phoneResults = await searchUsersByPhone(query);
    results.addAll(phoneResults);

    // Convert set back to list and sort by name
    final list = results.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// Get user by email (exact match)
  Future<UserEntity?> getUserByEmail(String email) => (select(users)..where((u) => u.email.equals(email)))
        .getSingleOrNull();

  /// Get user by phone number (exact match)
  Future<UserEntity?> getUserByPhone(String phoneNumber) => (select(users)..where((u) => u.phoneNumber.equals(phoneNumber)))
        .getSingleOrNull();

  /// Check if user exists by UID
  Future<bool> userExists(String uid) async {
    final user = await getUserByUid(uid);
    return user != null;
  }

  /// Get users created after a specific date
  ///
  /// Useful for sync operations
  Future<List<UserEntity>> getUsersCreatedAfter(DateTime timestamp) => (select(users)
          ..where((u) => u.createdAt.isBiggerThanValue(timestamp))
          ..orderBy([(u) => OrderingTerm.desc(u.createdAt)]))
        .get();

  /// Get users who haven't been seen in a while (inactive users)
  Future<List<UserEntity>> getInactiveUsers({
    Duration inactivePeriod = const Duration(days: 30),
    int limit = 50,
  }) {
    final cutoffTime = DateTime.now().subtract(inactivePeriod);
    return (select(users)
          ..where((u) => u.lastSeen.isSmallerThanValue(cutoffTime))
          ..orderBy([(u) => OrderingTerm.desc(u.lastSeen)])
          ..limit(limit))
        .get();
  }

  /// Set all users offline (useful for app lifecycle events)
  Future<void> setAllUsersOffline() async {
    await (update(users)..where((u) => u.isOnline.equals(true)))
        .write(const UsersCompanion(
      isOnline: Value(false),
    ));
  }
}
