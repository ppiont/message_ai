/// Translation providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:message_ai/features/translation/data/services/auto_translation_service.dart';
import 'package:message_ai/features/translation/data/services/translation_service.dart';
import 'package:message_ai/features/translation/domain/usecases/translate_message.dart';

export 'package:message_ai/features/translation/presentation/controllers/translation_controller.dart';

/// Provider for TranslationService
final translationServiceProvider = Provider<TranslationService>(
  (ref) => TranslationService(),
);

/// Provider for TranslateMessage use case
final translateMessageProvider = Provider<TranslateMessage>(
  (ref) => TranslateMessage(ref.watch(translationServiceProvider)),
);

/// Provider for AutoTranslationService
///
/// This service automatically translates incoming messages based on user preferences.
/// Start it when entering a conversation, stop it when leaving.
final autoTranslationServiceProvider = Provider<AutoTranslationService>(
  (ref) => AutoTranslationService(
    translationService: ref.watch(translationServiceProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
  ),
);
