import 'package:drift/drift.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/database/tables/cultural_context_queue_table.dart';

part 'cultural_context_queue_dao.g.dart';

/// DAO for cultural context analysis queue operations
///
/// Provides database operations for managing the cultural context analysis queue:
/// - Adding new analysis requests
/// - Fetching pending requests
/// - Updating request status and retry counts
/// - Cleaning up completed/failed requests
@DriftAccessor(tables: [CulturalContextQueue])
class CulturalContextQueueDao extends DatabaseAccessor<AppDatabase>
    with _$CulturalContextQueueDaoMixin {
  CulturalContextQueueDao(super.db);

  /// Add a new analysis request to the queue
  Future<void> addToQueue(CulturalContextQueueCompanion entry) =>
      into(culturalContextQueue).insert(entry);

  /// Get all pending requests (ready to process)
  ///
  /// Returns requests that are:
  /// - Status is 'pending' OR 'failed' with retries remaining
  /// - nextRetryAt is null OR in the past
  /// Ordered by priority (highest first), then createdAt (oldest first)
  Stream<List<CulturalContextQueueEntity>> watchPendingRequests() {
    final now = DateTime.now();
    return (select(culturalContextQueue)
          ..where((tbl) =>
              (tbl.status.equals('pending') |
                  (tbl.status.equals('failed') &
                      tbl.retryCount.isSmallerThan(tbl.maxRetries))) &
              (tbl.nextRetryAt.isNull() | tbl.nextRetryAt.isSmallerThanValue(now)))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.priority, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.createdAt),
          ]))
        .watch();
  }

  /// Get pending requests as a one-time query (not streaming)
  Future<List<CulturalContextQueueEntity>> getPendingRequests() {
    final now = DateTime.now();
    return (select(culturalContextQueue)
          ..where((tbl) =>
              (tbl.status.equals('pending') |
                  (tbl.status.equals('failed') &
                      tbl.retryCount.isSmallerThan(tbl.maxRetries))) &
              (tbl.nextRetryAt.isNull() | tbl.nextRetryAt.isSmallerThanValue(now)))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.priority, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(expression: tbl.createdAt),
          ])
          ..limit(10)) // Batch size for rate limiting
        .get();
  }

  /// Mark request as processing
  Future<void> markAsProcessing(String id) =>
      (update(culturalContextQueue)..where((tbl) => tbl.id.equals(id))).write(
        CulturalContextQueueCompanion(
          status: const Value('processing'),
          lastAttemptAt: Value(DateTime.now()),
        ),
      );

  /// Mark request as completed
  Future<void> markAsCompleted(String id) =>
      (update(culturalContextQueue)..where((tbl) => tbl.id.equals(id))).write(
        const CulturalContextQueueCompanion(
          status: Value('completed'),
        ),
      );

  /// Mark request as failed with retry scheduling
  ///
  /// Implements exponential backoff:
  /// - First retry: 30 seconds
  /// - Second retry: 2 minutes
  /// - Third retry: 5 minutes
  Future<void> markAsFailed(String id, String errorMessage) async {
    final entry = await (select(culturalContextQueue)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    final newRetryCount = entry.retryCount + 1;
    final hasRetriesRemaining = newRetryCount < entry.maxRetries;

    // Calculate exponential backoff
    Duration backoff;
    if (newRetryCount == 1) {
      backoff = const Duration(seconds: 30);
    } else if (newRetryCount == 2) {
      backoff = const Duration(minutes: 2);
    } else {
      backoff = const Duration(minutes: 5);
    }

    final nextRetryAt = hasRetriesRemaining
        ? DateTime.now().add(backoff)
        : null;

    await (update(culturalContextQueue)..where((tbl) => tbl.id.equals(id))).write(
      CulturalContextQueueCompanion(
        status: const Value('failed'),
        retryCount: Value(newRetryCount),
        lastAttemptAt: Value(DateTime.now()),
        nextRetryAt: Value(nextRetryAt),
        errorMessage: Value(errorMessage),
      ),
    );
  }

  /// Check if a message is already in the queue
  Future<bool> isMessageQueued(String messageId) async {
    final count = await (selectOnly(culturalContextQueue)
          ..addColumns([culturalContextQueue.id.count()])
          ..where(
            culturalContextQueue.messageId.equals(messageId) &
                (culturalContextQueue.status.equals('pending') |
                    culturalContextQueue.status.equals('processing')),
          ))
        .getSingle();
    return (count.read(culturalContextQueue.id.count()) ?? 0) > 0;
  }

  /// Delete completed entries older than specified duration
  Future<void> deleteOldCompleted(Duration age) {
    final cutoffTime = DateTime.now().subtract(age);
    return (delete(culturalContextQueue)
          ..where((tbl) =>
              tbl.status.equals('completed') &
              tbl.createdAt.isSmallerThanValue(cutoffTime)))
        .go();
  }

  /// Delete all failed entries (for cleanup)
  Future<void> deleteAllFailed() =>
      (delete(culturalContextQueue)..where((tbl) => tbl.status.equals('failed')))
          .go();

  /// Get queue statistics
  Future<Map<String, int>> getQueueStats() async {
    final allEntries = await select(culturalContextQueue).get();

    final stats = <String, int>{
      'total': allEntries.length,
      'pending': allEntries.where((e) => e.status == 'pending').length,
      'processing': allEntries.where((e) => e.status == 'processing').length,
      'completed': allEntries.where((e) => e.status == 'completed').length,
      'failed': allEntries.where((e) => e.status == 'failed').length,
    };

    return stats;
  }

  /// Delete a specific queue entry
  Future<void> deleteEntry(String id) =>
      (delete(culturalContextQueue)..where((tbl) => tbl.id.equals(id))).go();

  /// Clear all queue entries (for testing/debugging)
  Future<void> clearQueue() => delete(culturalContextQueue).go();
}
