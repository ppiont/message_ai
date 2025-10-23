import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:message_ai/features/smart_replies/domain/entities/user_communication_style.dart';
import 'package:message_ai/features/smart_replies/domain/services/user_style_analyzer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'style_analyzer_providers.g.dart';

/// Cache key for user style analysis.
class _StyleCacheKey {
  const _StyleCacheKey({required this.userId, required this.conversationId});

  final String userId;
  final String conversationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _StyleCacheKey &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          conversationId == other.conversationId;

  @override
  int get hashCode => userId.hashCode ^ conversationId.hashCode;
}

/// Provider for UserStyleAnalyzer service (domain layer).
///
/// This service analyzes user communication patterns to enable
/// AI features like smart replies to match the user's writing style.
@riverpod
UserStyleAnalyzer userStyleAnalyzer(Ref ref) =>
    UserStyleAnalyzer(messageRepository: ref.watch(messageRepositoryProvider));

/// State provider for cached user communication styles.
///
/// Caching strategy:
/// - Cache key: userId-conversationId
/// - TTL: Invalidate after ~20 new messages (managed by consumer)
/// - Storage: In-memory map for fast access
///
/// This avoids re-analyzing the same user's style repeatedly
/// within a short time frame, improving performance.
@riverpod
class UserStyleCache extends _$UserStyleCache {
  @override
  // ignore: library_private_types_in_public_api
  Map<_StyleCacheKey, UserCommunicationStyle> build() => {};

  /// Gets a cached style for a user in a conversation.
  UserCommunicationStyle? get(String userId, String conversationId) {
    final key = _StyleCacheKey(userId: userId, conversationId: conversationId);
    return state[key];
  }

  /// Stores a style in the cache.
  void put(String userId, String conversationId, UserCommunicationStyle style) {
    final key = _StyleCacheKey(userId: userId, conversationId: conversationId);
    state = {...state, key: style};
  }

  /// Removes a cached style (useful for forcing re-analysis).
  void invalidate(String userId, String conversationId) {
    final key = _StyleCacheKey(userId: userId, conversationId: conversationId);
    final newState = Map<_StyleCacheKey, UserCommunicationStyle>.from(state)
      ..remove(key);
    state = newState;
  }

  /// Clears all cached styles.
  void clear() {
    state = {};
  }
}

/// FutureProvider for analyzing a user's communication style.
///
/// This provider:
/// 1. Checks the cache first for recent analysis
/// 2. If not cached or stale, performs fresh analysis
/// 3. Caches the result for future access
///
/// Usage:
/// ```dart
/// final styleAsync = ref.watch(
///   analyzeUserStyleProvider(userId: 'user123', conversationId: 'conv456'),
/// );
/// styleAsync.when(
///   data: (style) => Text('Style: ${style.styleDescription}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error analyzing style'),
/// );
/// ```
@riverpod
Future<UserCommunicationStyle> analyzeUserStyle(
  Ref ref, {
  required String userId,
  required String conversationId,
}) async {
  final analyzer = ref.watch(userStyleAnalyzerProvider);
  final cache = ref.watch(userStyleCacheProvider.notifier);

  // Check cache first
  final cachedStyle = cache.get(userId, conversationId);
  if (cachedStyle != null) {
    // Check if cache is still fresh (less than 1 hour old)
    final cacheAge = DateTime.now().difference(cachedStyle.lastAnalyzedAt);
    if (cacheAge.inHours < 1) {
      return cachedStyle;
    }
  }

  // Perform fresh analysis
  final style = await analyzer.analyzeUserStyle(userId, conversationId);

  // Cache the result
  cache.put(userId, conversationId, style);

  return style;
}
