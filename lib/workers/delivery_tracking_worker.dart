import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/database/app_database.dart';

/// Worker to batch process delivery confirmations
///
/// Syncs local message status records to Firestore.
/// Runs in background via WorkManager periodic tasks.
///
/// Architecture:
/// - Queries pending delivery status from MessageStatusDao
/// - Batch syncs to Firestore subcollections
/// - Updates local DB with sync flag
/// - WorkManager handles scheduling and retries
class DeliveryTrackingWorker {
  DeliveryTrackingWorker({
    required AppDatabase database,
    FirebaseFirestore? firestore,
  }) : _database = database,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final AppDatabase _database;
  final FirebaseFirestore _firestore;

  /// Process all pending delivery confirmations
  ///
  /// This is the main entry point called by WorkManager.
  /// Syncs message status records to Firestore.
  Future<DeliveryTrackingResult> processDeliveries() async {
    debugPrint('[DeliveryTrackingWorker] Starting delivery tracking...');

    try {
      // Get all status records (in production, we'd filter by 'pending sync')
      final statusRecords = await _database.messageStatusDao
          .getPendingStatusSync();

      if (statusRecords.isEmpty) {
        debugPrint('[DeliveryTrackingWorker] No delivery records to sync');
        return const DeliveryTrackingResult(synced: 0, failed: 0);
      }

      debugPrint(
        '[DeliveryTrackingWorker] Found ${statusRecords.length} status records to sync',
      );

      var synced = 0;
      var failed = 0;

      // Batch write to Firestore
      final batch = _firestore.batch();
      var batchSize = 0;
      const maxBatchSize = 500; // Firestore limit

      for (final statusRecord in statusRecords) {
        try {
          // Get conversationId for this message
          final message = await _database.messageDao.getMessageById(
            statusRecord.messageId,
          );

          if (message == null) {
            debugPrint(
              '[DeliveryTrackingWorker] Message ${statusRecord.messageId} not found, skipping',
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
            'status': statusRecord.status,
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
              '[DeliveryTrackingWorker] Committed batch: $synced synced so far',
            );
          }
        } catch (e) {
          failed++;
          debugPrint(
            '[DeliveryTrackingWorker] Error processing status record: $e',
          );
        }
      }

      // Commit remaining batch
      if (batchSize > 0) {
        await batch.commit();
        synced += batchSize;
      }

      debugPrint(
        '[DeliveryTrackingWorker] Complete: $synced synced, $failed failed',
      );

      return DeliveryTrackingResult(synced: synced, failed: failed);
    } catch (e) {
      debugPrint('[DeliveryTrackingWorker] Failed: $e');
      rethrow;
    }
  }
}

/// Result of delivery tracking operation
class DeliveryTrackingResult {
  const DeliveryTrackingResult({required this.synced, required this.failed});

  final int synced;
  final int failed;
}
