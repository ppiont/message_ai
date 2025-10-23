/// Translation providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/translation/data/services/translation_service.dart';
import 'package:message_ai/features/translation/domain/usecases/translate_message.dart';

/// Provider for TranslationService
final translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});

/// Provider for TranslateMessage use case
final translateMessageProvider = Provider<TranslateMessage>((ref) {
  return TranslateMessage(ref.watch(translationServiceProvider));
});

