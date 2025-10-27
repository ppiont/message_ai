import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/database/app_database.dart';

/// Worker to sync read receipts to Firestore
///
/// Syncs read status records to Firestore subcollections.
/// Runs in background via WorkManager periodic tasks.
///
/// Architecture:
/// - Queries read status records from MessageStatusDao
/// - Batch syncs to Firestore subcollections
/// - Updates Firestore with read timestamps
/// - WorkManager handles scheduling and retries
///
/// Note: This is similar to DeliveryTrackingWorker but focused on 'read' status.
/// They could be merged, but keeping separate for clarity and independent scheduling.
class ReadReceiptWorker {
  ReadReceiptWorker({
    required AppDatabase database,
    FirebaseFirestore? firestore,
  }) : _database = database,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final AppDatabase _database;
  final FirebaseFirestore _firestore;

  /// Sync all read receipts to Firestore
  ///
  /// This is the main entry point called by WorkManager.
  /// Finds all status records with status = 'read' and syncs them.
  Future<ReadReceiptResult> syncReadReceipts() async {
    debugPrint('[ReadReceiptWorker] Starting read receipt sync...');

    try {
      // Get all status records (filtering for 'read' status)
      final statusRecords = await _database.messageStatusDao
          .getPendingStatusSync();

      // Filter for read status
      final readRecords = statusRecords
          .where((record) => record.status == 'read')
          .toList();

      if (readRecords.isEmpty) {
        debugPrint('[ReadReceiptWorker] No read receipts to sync');
        return const ReadReceiptResult(synced: 0, failed: 0);
      }

      debugPrint(
        '[ReadReceiptWorker] Found ${readRecords.length} read receipts to sync',
      );

      var synced = 0;
      var failed = 0;

      // Batch write to Firestore
      final batch = _firestore.batch();
      var batchSize = 0;
      const maxBatchSize = 500; // Firestore limit

      for (final statusRecord in readRecords) {
        try {
          // Get conversationId for this message
          final message = await _database.messageDao.getMessageById(
            statusRecord.messageId,
          );

          if (message == null) {
            debugPrint(
              '[ReadReceiptWorker] Message ${statusRecord.messageId} not found, skipping',
            );
            failed++;
            continue;
          }

          // Reference to Firestore subcollection
          // conversations/{conversationId}/messages/{messageId}/status/{userId}
          final statusDocRef = _firestore
              .collection('conversations')
              .doc(message.conversationId)
              .collection('messages')
              .doc(statusRecord.messageId)
              .collection('status')
              .doc(statusRecord.userId);

          // Prepare data
          final data = {
            'status': 'read',
            'timestamp': statusRecord.timestamp != null
                ? Timestamp.fromDate(statusRecord.timestamp!)
                : null,
            'userId': statusRecord.userId,
          };

          // Add to batch
          batch.set(statusDocRef, data, SetOptions(merge: true));
          batchSize++;

          // Commit batch if at limit
          if (batchSize >= maxBatchSize) {
            await batch.commit();
            synced += batchSize;
            batchSize = 0;
            debugPrint(
              '[ReadReceiptWorker] Committed batch: $synced synced so far',
            );
          }
        } catch (e) {
          failed++;
          debugPrint('[ReadReceiptWorker] Error processing read receipt: $e');
        }
      }

      // Commit remaining batch
      if (batchSize > 0) {
        await batch.commit();
        synced += batchSize;
      }

      debugPrint(
        '[ReadReceiptWorker] Complete: $synced synced, $failed failed',
      );

      return ReadReceiptResult(synced: synced, failed: failed);
    } catch (e) {
      debugPrint('[ReadReceiptWorker] Failed: $e');
      rethrow;
    }
  }
}

/// Result of read receipt sync operation
class ReadReceiptResult {
  const ReadReceiptResult({required this.synced, required this.failed});

  final int synced;
  final int failed;
}
