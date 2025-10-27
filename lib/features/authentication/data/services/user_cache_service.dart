import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/database/services/drift_write_queue.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/user_repository.dart';

/// Caches user profiles in Drift for offline access
///
/// This service bridges the gap between Firestore (source of truth)
/// and Drift (offline cache) for user profiles.
///
/// Usage:
/// - Call `cacheUser()` when encountering a new user ID
/// - Call `cacheUsers()` when loading conversations/groups
/// - Cache is updated automatically from Firestore
class UserCacheService {
  UserCacheService({
    required AppDatabase database,
    required UserRepository userRepository,
    required DriftWriteQueue writeQueue,
  }) : _database = database,
       _userRepository = userRepository,
       _writeQueue = writeQueue;

  final AppDatabase _database;
  final UserRepository _userRepository;
  final DriftWriteQueue _writeQueue;

  /// Cache a single user by ID
  ///
  /// Fetches from Firestore and saves to Drift
  /// Silently fails if user doesn't exist or network is unavailable
  Future<void> cacheUser(String userId) async {
    try {
      // Check if already cached recently (avoid redundant fetches)
      final cached = await _database.userDao.getUserByUid(userId);
      if (cached != null) {
        // Already cached, no need to fetch again
        return;
      }

      // Fetch from Firestore
      final result = await _userRepository.getUserById(userId);

      await result.fold(
        (failure) async {
          // User not found or network error - silently fail
          debugPrint(
            '⚠️ UserCache: Failed to cache user $userId: ${failure.message}',
          );
        },
        (user) async {
          // Save to Drift
          await _saveUserToDrift(user);
          debugPrint('✅ UserCache: Cached user $userId: ${user.displayName}');
        },
      );
    } catch (e) {
      // Silently fail - offline mode or other error
      debugPrint('💥 UserCache: Exception caching user $userId: $e');
    }
  }

  /// Cache multiple users by IDs
  ///
  /// Useful for caching all conversation participants at once
  ///
  /// PERFORMANCE: Fetches users in parallel from Firestore,
  /// then writes to Drift sequentially to avoid database locks
  Future<void> cacheUsers(List<String> userIds) async {
    if (userIds.isEmpty) return;

    try {
      // Filter out already-cached users
      final uncachedUserIds = <String>[];
      for (final userId in userIds) {
        final cached = await _database.userDao.getUserByUid(userId);
        if (cached == null) {
          uncachedUserIds.add(userId);
        }
      }

      if (uncachedUserIds.isEmpty) {
        debugPrint('✅ UserCache: All ${userIds.length} users already cached');
        return;
      }

      debugPrint(
        '🔄 UserCache: Fetching ${uncachedUserIds.length} users in parallel',
      );

      // Fetch all users in parallel from Firestore (FAST!)
      final fetchFutures = uncachedUserIds
          .map(_userRepository.getUserById)
          .toList();

      final results = await Future.wait(fetchFutures);

      // Save to Drift sequentially (SQLite constraint)
      for (var i = 0; i < results.length; i++) {
        final result = results[i];
        final userId = uncachedUserIds[i];

        await result.fold(
          (failure) async {
            debugPrint(
              '⚠️ UserCache: Failed to fetch $userId: ${failure.message}',
            );
          },
          (user) async {
            await _saveUserToDrift(user);
            debugPrint('✅ UserCache: Cached ${user.displayName}');
          },
        );
      }
    } catch (e) {
      debugPrint('💥 UserCache: Exception in cacheUsers: $e');
    }
  }

  /// Save a user entity to Drift via write queue
  Future<void> _saveUserToDrift(User user) async {
    final companion = UsersCompanion.insert(
      uid: user.uid,
      email: Value(user.email),
      phoneNumber: Value(user.phoneNumber),
      name: user.displayName,
      imageUrl: Value(user.photoURL),
      preferredLanguage: Value(user.preferredLanguage),
      createdAt: user.createdAt,
      lastSeen: user.lastSeen,
      isOnline: Value(user.isOnline),
    );

    // Use write queue to prevent database locks
    await _writeQueue.enqueue(
      () => _database.userDao.upsertUser(companion),
      debugLabel: 'Cache user: ${user.displayName} (${user.uid})',
    );
  }

  /// Sync a user from Firestore to Drift
  ///
  /// Use this when you already have a User entity from Firestore
  /// and just need to save it to Drift
  Future<void> syncUserToDrift(User user) async {
    try {
      await _saveUserToDrift(user);
      debugPrint('✅ UserCache: Synced user ${user.uid}: ${user.displayName}');
    } catch (e) {
      debugPrint('💥 UserCache: Failed to sync user ${user.uid}: $e');
    }
  }
}
