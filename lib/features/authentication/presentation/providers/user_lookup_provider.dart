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

  bool get isExpired =>
      DateTime.now().difference(fetchedAt) > cacheDuration;
}

/// In-memory cache for user lookups to avoid repeated Firestore queries
///
/// This provider implements the proper pattern for chat apps:
/// - Messages store only senderId (not senderName)
/// - UI looks up display names on-demand
/// - Results are cached in memory with TTL
/// - Single source of truth (users collection)
///
/// Benefits:
/// - Name changes appear instantly everywhere
/// - Zero writes to messages when name changes
/// - Scalable (no need to update millions of message documents)
@riverpod
class UserLookupCache extends _$UserLookupCache {
  @override
  Map<String, CachedUser> build() => {};

  /// Get user by ID with caching
  ///
  /// Returns null if user not found or lookup fails
  /// Caches results for 5 minutes to minimize Drift/Firestore reads
  ///
  /// Lookup strategy (offline-first):
  /// 1. Check memory cache (instant, 5 min TTL)
  /// 2. Check Drift local database (fast, offline)
  /// 3. Fall back to Firestore + cache to Drift (slow, online)
  Future<User?> getUser(String userId) async {
    // 1. Check memory cache first
    final cached = state[userId];
    if (cached != null && !cached.isExpired) {
      return cached.user;
    }

    // 2. Try Drift local database (offline-first)
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
          fcmTokens: [], // FCM tokens not stored in local DB
        );

        // Update memory cache
        state = {
          ...state,
          userId: CachedUser(user, DateTime.now()),
        };
        print('✅ UserLookup: Found in Drift: ${user.displayName}');
        return user;
      }
    } catch (e) {
      print('⚠️ UserLookup: Drift lookup failed for $userId: $e');
      // Continue to Firestore fallback
    }

    // 3. Fall back to Firestore and cache to Drift
    try {
      final userCacheService = ref.read(userCacheServiceProvider);
      final userRepository = ref.read(userRepositoryProvider);
      final result = await userRepository.getUserById(userId);

      return result.fold(
        (failure) {
          // Failed to fetch - keep old cache if available
          print('❌ UserLookup: Firestore fetch failed for $userId: ${failure.message}');
          return cached?.user;
        },
        (user) async {
          // Cache to Drift for future offline access
          await userCacheService.syncUserToDrift(user);

          // Update memory cache
          state = {
            ...state,
            userId: CachedUser(user, DateTime.now()),
          };
          print('✅ UserLookup: Fetched from Firestore & cached: ${user.displayName}');
          return user;
        },
      );
    } catch (e) {
      // On error, return cached value if available
      print('💥 UserLookup: Exception fetching user $userId: $e');
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

  /// Invalidate cache for a specific user
  ///
  /// Call this when you know a user's data has changed
  void invalidate(String userId) {
    final newState = Map<String, CachedUser>.from(state);
    newState.remove(userId);
    state = newState;
  }

  /// Clear entire cache
  void clearAll() {
    state = {};
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
