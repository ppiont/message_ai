/// Riverpod providers for cultural context feature
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:message_ai/features/cultural_context/data/services/cultural_context_service.dart';
import 'package:message_ai/features/cultural_context/domain/usecases/analyze_message_cultural_context.dart';
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

/// Provider for cultural context analyzer (background service)
///
/// Note: This is imported and used in messaging_providers.dart
/// We keep it here to avoid circular dependencies
