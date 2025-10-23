/// Explain message idioms use case
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/idiom_explanation/data/services/idiom_explanation_service.dart';
import 'package:message_ai/features/idiom_explanation/domain/entities/idiom_explanation.dart';

/// Use case for explaining idioms, slang, and colloquialisms in a message
class ExplainMessageIdioms {
  const ExplainMessageIdioms(this._idiomExplanationService);

  final IdiomExplanationService _idiomExplanationService;

  /// Execute the idiom explanation
  Future<Either<Failure, IdiomExplanationResult>> call({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async =>
      _idiomExplanationService.explainIdioms(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
}
