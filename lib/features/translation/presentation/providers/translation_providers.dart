/// Translation providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/translation/data/services/translation_service.dart';
import 'package:message_ai/features/translation/domain/usecases/translate_message.dart';

export 'package:message_ai/features/translation/presentation/controllers/translation_controller.dart';

/// Provider for TranslationService
final translationServiceProvider = Provider<TranslationService>((ref) => TranslationService());

/// Provider for TranslateMessage use case
final translateMessageProvider = Provider<TranslateMessage>((ref) => TranslateMessage(ref.watch(translationServiceProvider)));

