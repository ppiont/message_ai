/// Use case for analyzing cultural context of a message
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/cultural_context/data/services/cultural_context_service.dart';

/// Use case for analyzing cultural context of a message
///
/// This use case:
/// 1. Calls the cultural context service to analyze a message
/// 2. Returns the cultural hint if found, or null if message is straightforward
/// 3. Designed for fire-and-forget background analysis
class AnalyzeMessageCulturalContext {
  AnalyzeMessageCulturalContext({
    required CulturalContextService culturalContextService,
  }) : _culturalContextService = culturalContextService;

  final CulturalContextService _culturalContextService;

  /// Execute the use case
  ///
  /// Parameters:
  /// - [text]: The message text to analyze
  /// - [language]: The language code of the message
  ///
  /// Returns:
  /// - Right(String?): Cultural hint if found, null if not needed
  /// - Left(Failure): Error if analysis fails
  Future<Either<Failure, String?>> call({
    required String text,
    required String language,
  }) async => _culturalContextService.analyzeCulturalContext(
      text: text,
      language: language,
    );
}
