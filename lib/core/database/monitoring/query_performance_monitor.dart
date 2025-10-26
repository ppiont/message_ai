/// Query performance monitoring with EXPLAIN QUERY PLAN analysis
library;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

/// Performance monitoring for database queries using SQLite's EXPLAIN QUERY PLAN.
///
/// **Features:**
/// - Debug-mode only (zero overhead in release builds)
/// - EXPLAIN QUERY PLAN analysis for index usage verification
/// - Execution time tracking with threshold alerts
/// - Detailed logging of query plans and performance metrics
/// - Automatic detection of missing indexes (table scans)
///
/// **Usage:**
/// ```dart
/// final monitor = QueryPerformanceMonitor(database);
/// final results = await monitor.monitorQuery(
///   'getMessagesForConversation',
///   () => (select(messages)..where(...)).get(),
///   explainSql: 'SELECT * FROM messages WHERE conversation_id = ?',
/// );
/// ```
///
/// **Performance Impact:**
/// - Debug mode: Adds ~5-10ms overhead per query for EXPLAIN analysis
/// - Release mode: Zero overhead (all monitoring code is compile-time eliminated)
class QueryPerformanceMonitor {
  QueryPerformanceMonitor(this._database);

  final DatabaseConnectionUser _database;

  /// Performance threshold in milliseconds for slow query alerts.
  static const int slowQueryThresholdMs = 100;

  /// Monitor a query's performance and log results (debug mode only).
  ///
  /// In release mode, this directly executes the query with zero overhead.
  /// In debug mode, performs EXPLAIN QUERY PLAN analysis and timing.
  ///
  /// Parameters:
  /// - [queryName]: Human-readable name for the query (e.g., 'getMessagesForConversation')
  /// - [queryFn]: Function that executes the actual query
  /// - [explainSql]: SQL query string for EXPLAIN QUERY PLAN analysis
  /// - [params]: Optional parameters for the query (for logging context)
  Future<T> monitorQuery<T>({
    required String queryName,
    required Future<T> Function() queryFn,
    String? explainSql,
    Map<String, dynamic>? params,
  }) async {
    // In release mode, execute query directly with zero overhead
    if (kReleaseMode) {
      return queryFn();
    }

    // Debug mode: Perform performance analysis
    final stopwatch = Stopwatch()..start();

    // Execute EXPLAIN QUERY PLAN if SQL provided
    if (explainSql != null) {
      await _explainQuery(queryName, explainSql, params);
    }

    // Execute the actual query
    final result = await queryFn();

    stopwatch.stop();
    final durationMs = stopwatch.elapsedMilliseconds;

    // Log query performance
    _logQueryPerformance(queryName, durationMs, params);

    // Alert if query exceeds threshold
    if (durationMs > slowQueryThresholdMs) {
      _alertSlowQuery(queryName, durationMs, params);
    }

    return result;
  }

  /// Execute EXPLAIN QUERY PLAN and log the results.
  Future<void> _explainQuery(
    String queryName,
    String sql,
    Map<String, dynamic>? params,
  ) async {
    try {
      final explainSql = 'EXPLAIN QUERY PLAN $sql';
      final results = await _database.customSelect(explainSql).get();

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📊 QUERY PLAN: $queryName');
      if (params != null && params.isNotEmpty) {
        debugPrint('   Parameters: $params');
      }
      debugPrint('   SQL: $sql');
      debugPrint('');

      // Parse and display query plan
      for (final row in results) {
        final detail = row.data['detail'] as String?;
        if (detail != null) {
          // Check for table scans (missing indexes)
          if (detail.contains('SCAN TABLE')) {
            debugPrint('   ⚠️  TABLE SCAN DETECTED: $detail');
          } else if (detail.contains('SEARCH TABLE') &&
              detail.contains('USING INDEX')) {
            final indexMatch = RegExp(r'USING INDEX (\w+)').firstMatch(detail);
            final indexName = indexMatch?.group(1) ?? 'unknown';
            debugPrint('   ✅ INDEX USED: $indexName');
            debugPrint('      $detail');
          } else {
            debugPrint('   $detail');
          }
        }
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      debugPrint('⚠️  Failed to explain query $queryName: $e');
    }
  }

  /// Log query execution performance.
  void _logQueryPerformance(
    String queryName,
    int durationMs,
    Map<String, dynamic>? params,
  ) {
    final emoji = durationMs < 50
        ? '⚡'
        : durationMs < slowQueryThresholdMs
            ? '✓'
            : '🐌';
    debugPrint(
      '$emoji Query: $queryName | ${durationMs}ms${params != null ? ' | $params' : ''}',
    );
  }

  /// Alert when a query exceeds the performance threshold.
  void _alertSlowQuery(
    String queryName,
    int durationMs,
    Map<String, dynamic>? params,
  ) {
    debugPrint('');
    debugPrint('🚨 SLOW QUERY ALERT 🚨');
    debugPrint('   Query: $queryName');
    debugPrint('   Duration: ${durationMs}ms (threshold: ${slowQueryThresholdMs}ms)');
    if (params != null && params.isNotEmpty) {
      debugPrint('   Parameters: $params');
    }
    debugPrint('   Recommendation: Check EXPLAIN QUERY PLAN for missing indexes');
    debugPrint('');
  }

  /// Monitor a stream query (logs only initial setup time).
  ///
  /// Stream queries are reactive and continuously emit updates, so we only
  /// monitor the initial setup cost, not the ongoing emissions.
  Stream<T> monitorStream<T>({
    required String queryName,
    required Stream<T> Function() streamFn,
    String? explainSql,
    Map<String, dynamic>? params,
  }) {
    // In release mode, return stream directly with zero overhead
    if (kReleaseMode) {
      return streamFn();
    }

    // Debug mode: Log stream setup
    debugPrint('📡 Stream Query: $queryName${params != null ? ' | $params' : ''}');

    // Execute EXPLAIN QUERY PLAN if SQL provided
    if (explainSql != null) {
      _explainQuery(queryName, explainSql, params).ignore();
    }

    return streamFn();
  }
}

/// Extension on DatabaseConnectionUser to add performance monitoring.
extension QueryPerformanceMonitorExtension on DatabaseConnectionUser {
  /// Create a QueryPerformanceMonitor for this database.
  QueryPerformanceMonitor get performanceMonitor =>
      QueryPerformanceMonitor(this);
}
