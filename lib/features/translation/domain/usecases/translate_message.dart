/// Translate message use case
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/translation/data/services/translation_service.dart';

/// Use case for translating a message
class TranslateMessage {
  const TranslateMessage(this._translationService);

  final TranslationService _translationService;

  /// Execute the translation
  Future<Either<Failure, String>> call({
    required String messageId,
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    return _translationService.translateMessage(
      messageId: messageId,
      text: text,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }
}

