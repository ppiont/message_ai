/// Riverpod providers for cultural context feature
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:message_ai/core/database/daos/cultural_context_queue_dao.dart';
import 'package:message_ai/core/providers/database_provider.dart';
import 'package:message_ai/features/cultural_context/data/services/cultural_context_analyzer.dart';
import 'package:message_ai/features/cultural_context/data/services/cultural_context_service.dart';
import 'package:message_ai/features/cultural_context/domain/entities/cultural_context_state.dart';
import 'package:message_ai/features/cultural_context/domain/services/cultural_context_queue.dart';
import 'package:message_ai/features/cultural_context/domain/usecases/analyze_message_cultural_context.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cultural_context_providers.g.dart';

/// Provider for Firebase Functions instance
@riverpod
FirebaseFunctions firebaseFunctions(Ref ref) =>
    FirebaseFunctions.instance;

/// Provider for cultural context service
@riverpod
CulturalContextService culturalContextService(Ref ref) {
  final functions = ref.watch(firebaseFunctionsProvider);
  return CulturalContextService(functions: functions);
}

/// Provider for analyze message cultural context use case
@riverpod
AnalyzeMessageCulturalContext analyzeMessageCulturalContext(Ref ref) {
  final service = ref.watch(culturalContextServiceProvider);
  return AnalyzeMessageCulturalContext(culturalContextService: service);
}

/// Provider for cultural context queue DAO
@riverpod
CulturalContextQueueDao culturalContextQueueDao(Ref ref) {
  final db = ref.watch(databaseProvider);
  return CulturalContextQueueDao(db);
}

/// Provider for cultural context queue (background processing)
@Riverpod(keepAlive: true)
CulturalContextQueue culturalContextQueue(Ref ref) {
  final queueDao = ref.watch(culturalContextQueueDaoProvider);
  final service = ref.watch(culturalContextServiceProvider);
  final messageRepository = ref.watch(messageRepositoryProvider);

  final queue = CulturalContextQueue(
    queueDao: queueDao,
    culturalContextService: service,
    messageRepository: messageRepository,
  )..startProcessing(); // Start processing queue in background

  // Clean up when provider is disposed
  ref.onDispose(queue.dispose);

  return queue;
}

/// Provider for cultural context analyzer (background service)
@riverpod
CulturalContextAnalyzer culturalContextAnalyzer(Ref ref) {
  final queue = ref.watch(culturalContextQueueProvider);
  return CulturalContextAnalyzer(queue: queue);
}

/// Provider for cultural context state per message
///
/// This provider tracks the analysis state for a specific message.
/// Returns CulturalContextState (Loading, Success, or Error)
@riverpod
CulturalContextState culturalContextState(
  Ref ref,
  String messageId,
) =>
    // For now, this is a placeholder that always returns success
    // In a full implementation, this would track the queue status
    // and update based on queue processing events
    //
    // Future enhancement: Subscribe to queue updates and return
    // appropriate state based on queue entry status
    const CulturalContextStateSuccess(culturalHint: null);

/// Provider for queue statistics (for debugging)
@riverpod
Future<Map<String, int>> culturalContextQueueStats(Ref ref) async {
  final queue = ref.watch(culturalContextQueueProvider);
  return queue.getStats();
}
