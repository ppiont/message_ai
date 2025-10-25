import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:message_ai/core/providers/database_provider.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/presentation/providers/user_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_lookup_provider.g.dart';

/// Cached user lookup result with expiration
class CachedUser {
  const CachedUser(this.user, this.fetchedAt);

  final User user;
  final DateTime fetchedAt;

  /// Cache entries expire after 5 minutes
  static const cacheDuration = Duration(minutes: 5);

  bool get isExpired => DateTime.now().difference(fetchedAt) > cacheDuration;
}

/// In-memory cache for user lookups to avoid repeated Firestore queries
///
/// This provider implements the proper pattern for chat apps:
/// - Messages store only senderId (not senderName)
/// - UI looks up display names on-demand
/// - Results are cached in memory with real-time updates
/// - Single source of truth (users collection)
///
/// Benefits:
/// - Name changes appear instantly everywhere via Firestore listeners
/// - Zero writes to messages when name changes
/// - Scalable (no need to update millions of message documents)
@riverpod
class UserLookupCache extends _$UserLookupCache {
  /// Map of userId -> StreamSubscription for active Firestore listeners
  final Map<String, StreamSubscription<dynamic>> _listeners = {};

  @override
  Map<String, CachedUser> build() {
    // Clean up listeners when provider is disposed
    ref.onDispose(() {
      for (final subscription in _listeners.values) {
        subscription.cancel();
      }
      _listeners.clear();
    });
    return {};
  }

  /// Get user by ID with caching
  ///
  /// Returns null if user not found or lookup fails
  /// Caches results for 5 minutes to minimize Drift/Firestore reads
  /// Automatically starts a Firestore listener for real-time updates
  ///
  /// Lookup strategy (offline-first):
  /// 1. Check memory cache (instant, 5 min TTL)
  /// 2. Check Drift local database (fast, offline)
  /// 3. Fall back to Firestore + cache to Drift (slow, online)
  /// 4. Start Firestore listener for real-time updates
  Future<User?> getUser(String userId) async {
    // Start watching this user for real-time updates (idempotent)
    _startWatchingUser(userId);

    // 1. Check memory cache first
    final cached = state[userId];
    if (cached != null && !cached.isExpired) {
      return cached.user;
    }

    // 2. Try Drift local database (offline-first)
    // No ref.mounted checks here - Drift is fast and synchronous enough
    try {
      final db = ref.read(databaseProvider);
      final localUser = await db.userDao.getUserByUid(userId);

      if (localUser != null) {
        // Convert UserEntity to User domain entity
        final user = User(
          uid: localUser.uid,
          email: localUser.email,
          phoneNumber: localUser.phoneNumber,
          displayName: localUser.name,
          photoURL: localUser.imageUrl,
          preferredLanguage: localUser.preferredLanguage,
          createdAt: localUser.createdAt,
          lastSeen: localUser.lastSeen,
          isOnline: localUser.isOnline,
          fcmTokens: const [], // FCM tokens not stored in local DB
        );

        // Update memory cache (safe to skip if disposed)
        if (ref.mounted) {
          state = {...state, userId: CachedUser(user, DateTime.now())};
        }
        debugPrint('✅ UserLookup: Found in Drift: ${user.displayName}');
        return user;
      }
    } catch (e) {
      debugPrint('⚠️ UserLookup: Drift lookup failed for $userId: $e');
      // Continue to Firestore fallback
    }

    // 3. Fall back to Firestore and cache to Drift
    try {
      if (!ref.mounted) {
        return null; // Check before Firestore fetch
      }
      final userCacheService = ref.read(userCacheServiceProvider);
      final userRepository = ref.read(userRepositoryProvider);
      final result = await userRepository.getUserById(userId);

      return result.fold(
        (failure) {
          // Failed to fetch - keep old cache if available
          debugPrint(
            '❌ UserLookup: Firestore fetch failed for $userId: ${failure.message}',
          );
          return cached?.user;
        },
        (user) async {
          if (!ref.mounted) {
            return null; // Check after Firestore fetch
          }

          // Cache to Drift for future offline access
          await userCacheService.syncUserToDrift(user);

          if (!ref.mounted) {
            return null; // Check after Drift write
          }

          // Update memory cache
          state = {...state, userId: CachedUser(user, DateTime.now())};
          debugPrint(
            '✅ UserLookup: Fetched from Firestore & cached: ${user.displayName}',
          );
          return user;
        },
      );
    } catch (e) {
      // On error, return cached value if available
      debugPrint('💥 UserLookup: Exception fetching user $userId: $e');
      return cached?.user;
    }
  }

  /// Get display name by user ID with caching
  ///
  /// Returns 'Unknown' if user not found
  /// This is the most common use case for message display
  Future<String> getDisplayName(String userId) async {
    final user = await getUser(userId);
    return user?.displayName ?? 'Unknown';
  }

  /// Start watching a user for real-time updates
  ///
  /// Sets up a Firestore listener that automatically updates the cache
  /// when the user's profile changes (e.g., display name update)
  void _startWatchingUser(String userId) {
    // Don't create duplicate listeners
    if (_listeners.containsKey(userId)) {
      return;
    }

    debugPrint('👁️ Starting Firestore listener for user: $userId');

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final userCacheService = ref.read(userCacheServiceProvider);

      // Create a stream from the repository's watch method
      // ignore: cancel_subscriptions - Subscription is properly cancelled in ref.onDispose() (line 44-49)
      final subscription = userRepository
          .watchUser(userId)
          .listen(
            (result) async {
              if (!ref.mounted) {
                return;
              }

              // Handle Either<Failure, User> result
              await result.fold(
                (failure) async {
                  debugPrint(
                    '❌ User watch failure for $userId: ${failure.message}',
                  );
                },
                (user) async {
                  debugPrint(
                    '🔄 User updated via listener: ${user.displayName} ($userId)',
                  );

                  // Update memory cache
                  state = {...state, userId: CachedUser(user, DateTime.now())};

                  // Update Drift for offline access
                  await userCacheService.syncUserToDrift(user);

                  debugPrint(
                    '✅ Cache & Drift updated for: ${user.displayName}',
                  );
                },
              );
            },
            onError: (Object error) {
              debugPrint('❌ Firestore listener error for $userId: $error');
            },
          );

      _listeners[userId] = subscription;
    } catch (e) {
      debugPrint('❌ Failed to start listener for $userId: $e');
    }
  }

  /// Invalidate cache for a specific user
  ///
  /// Call this when you know a user's data has changed
  void invalidate(String userId) {
    state = Map<String, CachedUser>.from(state)..remove(userId);
  }

  /// Clear entire cache
  void clearAll() {
    state = {};
    // Cancel all listeners
    for (final subscription in _listeners.values) {
      subscription.cancel();
    }
    _listeners.clear();
  }
}

/// Provider for looking up a single user by ID
///
/// This is a convenience provider that other widgets can watch
/// for reactive updates when user data changes
@riverpod
Future<User?> userById(Ref ref, String userId) async {
  final cache = ref.read(userLookupCacheProvider.notifier);
  return cache.getUser(userId);
}

/// Provider for getting a user's display name by ID
///
/// Returns 'Unknown' if user not found
/// Most commonly used in message UI components
@riverpod
Future<String> userDisplayName(Ref ref, String userId) async {
  final cache = ref.read(userLookupCacheProvider.notifier);
  return cache.getDisplayName(userId);
}
