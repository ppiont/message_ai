/// Translation providers
library;

import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:message_ai/features/translation/data/services/auto_translation_service.dart';
import 'package:message_ai/features/translation/data/services/translation_service.dart';
import 'package:message_ai/features/translation/domain/usecases/translate_message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:message_ai/features/translation/presentation/controllers/translation_controller.dart';

part 'translation_providers.g.dart';

/// Provider for TranslationService
@riverpod
TranslationService translationService(Ref ref) => TranslationService();

/// Provider for TranslateMessage use case
@riverpod
TranslateMessage translateMessage(Ref ref) =>
    TranslateMessage(ref.watch(translationServiceProvider));

/// Provider for AutoTranslationService
///
/// This service automatically translates incoming messages based on user preferences.
/// Properly disposes of the service and cancels all subscriptions when no longer needed.
/// The service instance is auto-disposed when not actively watched, preventing memory leaks.
@riverpod
AutoTranslationService autoTranslationService(Ref ref) {
  final service = AutoTranslationService(
    translationService: ref.watch(translationServiceProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
  );

  // Ensure service is properly disposed and subscriptions are canceled
  ref.onDispose(service.dispose);

  return service;
}
