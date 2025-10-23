/// Background service for syncing user profiles from Firestore to Drift
///
/// Ensures user data stays fresh and up-to-date offline.
/// Implements WhatsApp-style user profile syncing.
library;

import 'dart:async';

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

    print('✅ UserSync: Background sync started');
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
    print('🛑 UserSync: Background sync stopped');
  }

  /// Sync users when conversations load
  ///
  /// Call this when conversation list is displayed
  Future<void> syncConversationUsers(List<String> participantIds) async {
    print('🔄 UserSync: Syncing ${participantIds.length} conversation users');
    await _userCacheService.cacheUsers(participantIds);

    // Start watching these users for real-time updates
    for (final userId in participantIds) {
      _watchUser(userId);
    }
  }

  /// Sync user when message arrives
  ///
  /// Call this when a new message is received
  Future<void> syncMessageSender(String senderId) async {
    // Check if already cached
    final cached = await _database.userDao.getUserByUid(senderId);
    if (cached == null) {
      print('🔄 UserSync: Syncing new message sender: $senderId');
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
          print('⚠️ UserSync: Watch failed for $userId: ${failure.message}');
        },
        (user) async {
          // User profile updated → sync to Drift
          await _userCacheService.syncUserToDrift(user);
          print('🔄 UserSync: Real-time update for ${user.displayName}');
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

      print('🔄 UserSync: Refreshing ${userIds.length} cached users');

      // Re-cache all users (fetches fresh from Firestore)
      for (final userId in userIds) {
        await _userCacheService.cacheUser(userId);
      }

      print('✅ UserSync: Refresh complete');
    } catch (e) {
      print('❌ UserSync: Refresh failed: $e');
    }
  }

  /// Force refresh a specific user
  ///
  /// Useful when you know a user's profile has changed
  Future<void> refreshUser(String userId) async {
    print('🔄 UserSync: Force refreshing user: $userId');
    await _userCacheService.cacheUser(userId);
  }
}
