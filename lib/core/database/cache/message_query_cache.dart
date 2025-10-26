/// LRU cache for message query results with TTL support
library;

import 'dart:collection';

import 'package:message_ai/core/database/app_database.dart';

/// Cache entry with TTL (Time To Live) tracking.
///
/// Stores cached query results along with expiration timestamp.
class _CacheEntry<T> {
  _CacheEntry({
    required this.value,
    required this.expiresAt,
  });

  final T value;
  final DateTime expiresAt;

  /// Check if this cache entry has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// LRU (Least Recently Used) cache for message query results.
///
/// **Features:**
/// - Maximum 50 cached queries (configurable)
/// - 5-minute TTL per cache entry (configurable)
/// - Automatic eviction of least recently used entries when cache is full
/// - Automatic expiration of stale entries
/// - Cache invalidation on data mutations
///
/// **Performance:**
/// - O(1) cache lookup via HashMap
/// - O(1) LRU eviction via LinkedHashMap
/// - Target: <10ms for cache hits vs 50ms for database queries
///
/// **Memory:**
/// - Estimated 200KB per cached query (50 messages × 4KB average)
/// - Max memory usage: ~10MB (50 queries × 200KB)
///
/// **Architecture:**
/// This cache sits between the DAO and data source layers, caching only
/// Future-based queries (not reactive streams). Drift streams already have
/// built-in change detection and don't need external caching.
class MessageQueryCache {
  MessageQueryCache({
    int maxEntries = 50,
    Duration ttl = const Duration(minutes: 5),
  })  : _maxEntries = maxEntries,
        _ttl = ttl;

  final int _maxEntries;
  final Duration _ttl;

  /// LRU cache storage using LinkedHashMap for insertion order tracking.
  ///
  /// LinkedHashMap maintains insertion order, allowing us to identify
  /// the least recently used entry (first entry) for eviction.
  final LinkedHashMap<String, _CacheEntry<List<MessageEntity>>> _cache =
      LinkedHashMap();

  /// Cache statistics for monitoring and debugging.
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  int _expirations = 0;

  /// Get cached query result if available and not expired.
  ///
  /// Returns null if cache miss or entry expired.
  /// Updates LRU order by moving accessed entry to end.
  List<MessageEntity>? get(String key) {
    final entry = _cache.remove(key); // Remove to re-insert at end (LRU update)

    if (entry == null) {
      _misses++;
      return null;
    }

    // Check if expired
    if (entry.isExpired) {
      _expirations++;
      _misses++;
      return null;
    }

    // Re-insert at end (most recently used)
    _cache[key] = entry;
    _hits++;

    return entry.value;
  }

  /// Cache a query result with TTL.
  ///
  /// If cache is full, evicts the least recently used entry (first entry).
  void put(String key, List<MessageEntity> value) {
    // Remove existing entry if present (to update LRU order)
    _cache.remove(key);

    // Evict LRU entry if cache is full
    if (_cache.length >= _maxEntries) {
      _cache.remove(_cache.keys.first); // Remove least recently used (first)
      _evictions++;
    }

    // Add new entry at end (most recently used)
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(_ttl),
    );
  }

  /// Invalidate (remove) a specific cache entry.
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// Invalidate all cache entries for a specific conversation.
  ///
  /// Called when messages are inserted/updated/deleted in a conversation.
  void invalidateConversation(String conversationId) {
    // Remove all entries with keys starting with conversationId
    _cache.removeWhere((key, _) => key.startsWith('$conversationId:'));
  }

  /// Invalidate all cache entries.
  ///
  /// Called on bulk operations or when cache becomes unreliable.
  void invalidateAll() {
    _cache.clear();
  }

  /// Remove expired entries from cache (garbage collection).
  ///
  /// Should be called periodically to reclaim memory.
  /// Returns number of expired entries removed.
  int removeExpired() {
    final before = _cache.length;
    _cache.removeWhere((_, entry) => entry.isExpired);
    final removed = before - _cache.length;
    _expirations += removed;
    return removed;
  }

  /// Generate cache key for conversation messages query.
  ///
  /// Format: "conversationId:limit:offset"
  static String keyForConversationMessages({
    required String conversationId,
    required int limit,
    required int offset,
  }) =>
      '$conversationId:$limit:$offset';

  /// Generate cache key for search query.
  ///
  /// Format: "search:query"
  static String keyForSearch(String query) => 'search:$query';

  /// Generate cache key for sender messages query.
  ///
  /// Format: "sender:conversationId:senderId:limit"
  static String keyForSenderMessages({
    required String conversationId,
    required String senderId,
    required int limit,
  }) =>
      'sender:$conversationId:$senderId:$limit';

  // ============================================================================
  // Cache Statistics & Monitoring
  // ============================================================================

  /// Get cache hit rate (0.0 to 1.0).
  double get hitRate {
    final total = _hits + _misses;
    return total > 0 ? _hits / total : 0.0;
  }

  /// Get cache statistics for debugging.
  Map<String, dynamic> getStats() => {
        'size': _cache.length,
        'maxEntries': _maxEntries,
        'hits': _hits,
        'misses': _misses,
        'hitRate': hitRate,
        'evictions': _evictions,
        'expirations': _expirations,
      };

  /// Reset cache statistics.
  void resetStats() {
    _hits = 0;
    _misses = 0;
    _evictions = 0;
    _expirations = 0;
  }

  /// Get current cache size.
  int get size => _cache.length;

  /// Check if cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Check if cache is full.
  bool get isFull => _cache.length >= _maxEntries;
}
