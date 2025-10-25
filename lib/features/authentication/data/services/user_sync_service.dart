import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/features/authentication/data/services/user_cache_service.dart';
import 'package:message_ai/features/authentication/domain/repositories/user_repository.dart';

/// Automatically syncs user profiles in the background
///
/// **How it works:**
/// 1. When conversations load → sync all participants
/// 2. When messages arrive → sync sender if not cached
/// 3. Periodic refresh → update stale user data
/// 4. Real-time watch → listen for profile changes in Firestore
///
/// **WhatsApp-style behavior:**
/// - Alice changes her name in Firestore
/// - Bob's app watches for changes → auto-syncs to his Drift cache
/// - Bob sees Alice's new name immediately (no message updates!)
class UserSyncService {
  UserSyncService({
    required AppDatabase database,
    required UserRepository userRepository,
    required UserCacheService userCacheService,
  }) : _database = database,
       _userRepository = userRepository,
       _userCacheService = userCacheService;

  final AppDatabase _database;
  final UserRepository _userRepository;
  final UserCacheService _userCacheService;

  final Map<String, StreamSubscription<dynamic>> _userWatchers = {};
  Timer? _refreshTimer;

  // Debouncing for syncConversationUsers to prevent duplicate syncs
  DateTime? _lastSyncTime;
  Set<String>? _lastSyncedUserIds;
  static const _syncDebounceThreshold = Duration(milliseconds: 500);

  /// Start background syncing
  ///
  /// Call this when the app starts and user is authenticated
  void startBackgroundSync() {
    // Refresh all cached users every hour
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _refreshAllCachedUsers(),
    );

    debugPrint('✅ UserSync: Background sync started');
  }

  /// Stop background syncing
  ///
  /// Call this when user signs out
  void stopBackgroundSync() {
    _refreshTimer?.cancel();
    for (final watcher in _userWatchers.values) {
      watcher.cancel();
    }
    _userWatchers.clear();
    debugPrint('🛑 UserSync: Background sync stopped');
  }

  /// Sync users when conversations load
  ///
  /// Call this when conversation list is displayed
  ///
  /// PERFORMANCE: Includes debouncing to prevent redundant syncs when called
  /// multiple times in quick succession with the same user set (e.g., during
  /// stream initialization when Firestore listeners trigger multiple emissions)
  Future<void> syncConversationUsers(List<String> participantIds) async {
    final now = DateTime.now();
    final userIdSet = participantIds.toSet();

    // DEBOUNCING: Skip if we synced these exact same users within the threshold
    if (_lastSyncTime != null &&
        _lastSyncedUserIds != null &&
        now.difference(_lastSyncTime!) < _syncDebounceThreshold &&
        userIdSet.difference(_lastSyncedUserIds!).isEmpty &&
        _lastSyncedUserIds!.difference(userIdSet).isEmpty) {
      debugPrint(
        '⏭️ UserSync: Skipping duplicate sync (${participantIds.length} users, ${now.difference(_lastSyncTime!).inMilliseconds}ms since last sync)',
      );
      return;
    }

    debugPrint(
      '🔄 UserSync: Syncing ${participantIds.length} conversation users',
    );

    // Update debounce tracking
    _lastSyncTime = now;
    _lastSyncedUserIds = userIdSet;

    await _userCacheService.cacheUsers(participantIds);

    // Start watching these users for real-time updates
    participantIds.forEach(_watchUser);
  }

  /// Sync user when message arrives
  ///
  /// Call this when a new message is received
  Future<void> syncMessageSender(String senderId) async {
    // Check if already cached
    final cached = await _database.userDao.getUserByUid(senderId);
    if (cached == null) {
      debugPrint('🔄 UserSync: Syncing new message sender: $senderId');
      await _userCacheService.cacheUser(senderId);
      _watchUser(senderId);
    }
  }

  /// Watch a user for real-time updates from Firestore
  ///
  /// When the user changes their profile, auto-sync to Drift
  void _watchUser(String userId) {
    // Don't create duplicate watchers
    if (_userWatchers.containsKey(userId)) {
      return;
    }

    // ignore: cancel_subscriptions - Cancelled in stopBackgroundSync()
    final watcher = _userRepository.watchUser(userId).listen((result) {
      result.fold(
        (failure) {
          // User deleted or network error
          debugPrint(
            '⚠️ UserSync: Watch failed for $userId: ${failure.message}',
          );
        },
        (user) async {
          // User profile updated → sync to Drift
          await _userCacheService.syncUserToDrift(user);
          debugPrint('🔄 UserSync: Real-time update for ${user.displayName}');
        },
      );
    });

    _userWatchers[userId] = watcher;
  }

  /// Refresh all cached users from Firestore
  ///
  /// Called periodically to keep user data fresh
  Future<void> _refreshAllCachedUsers() async {
    try {
      // Get all cached user IDs from Drift
      final cachedUsers = await _database.userDao.getAllUsers();
      final userIds = cachedUsers.map((u) => u.uid).toList();

      debugPrint('🔄 UserSync: Refreshing ${userIds.length} cached users');

      // Re-cache all users (fetches fresh from Firestore)
      for (final userId in userIds) {
        await _userCacheService.cacheUser(userId);
      }

      debugPrint('✅ UserSync: Refresh complete');
    } catch (e) {
      debugPrint('❌ UserSync: Refresh failed: $e');
    }
  }

  /// Force refresh a specific user
  ///
  /// Useful when you know a user's profile has changed
  Future<void> refreshUser(String userId) async {
    debugPrint('🔄 UserSync: Force refreshing user: $userId');
    await _userCacheService.cacheUser(userId);
  }
}
