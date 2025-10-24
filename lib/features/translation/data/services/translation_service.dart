/// Translation service
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';

/// Service for translating messages using Cloud Functions
class TranslationService {
  TranslationService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Translate a message to the target language
  ///
  /// Returns the translated text or a Failure
  Future<Either<Failure, String>> translateMessage({
    required String messageId,
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('translate_message')
          .call<Map<String, dynamic>>({
            'messageId': messageId,
            'text': text,
            'sourceLanguage': sourceLanguage,
            'targetLanguage': targetLanguage,
          });

      final data = result.data;

      // Check for rate limit
      if (data['rateLimitExceeded'] == true) {
        return Left(
          ServerFailure(
            message:
                'Translation rate limit exceeded. Try again in ${data['retryAfter']} seconds.',
          ),
        );
      }

      // Check for cached translation
      final translatedText = data['translatedText'] as String?;
      if (translatedText == null || translatedText.isEmpty) {
        return const Left(
          ServerFailure(message: 'Translation failed: empty response'),
        );
      }

      return Right(translatedText);
    } on FirebaseFunctionsException catch (e) {
      return Left(ServerFailure(message: 'Translation failed: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: 'Translation failed: $e'));
    }
  }

  /// Batch translate multiple messages to improve efficiency
  ///
  /// Translates all messages in parallel and returns a map of messageId to either
  /// the translated text or a failure.
  ///
  /// This is more efficient than translating messages one-by-one as it:
  /// - Reduces total latency (parallel execution)
  /// - Better utilizes network connections
  /// - Provides faster user experience when loading conversations
  ///
  /// Returns a `Map&lt;String, Either&lt;Failure, String&gt;&gt;` where:
  /// - Key: messageId
  /// - Value: Either a Failure or the translated text
  Future<Map<String, Either<Failure, String>>> batchTranslateMessages({
    required List<String> messageIds,
    required List<String> texts,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    // Validate input lengths match
    if (messageIds.length != texts.length) {
      throw ArgumentError(
        'messageIds and texts lists must have the same length',
      );
    }

    // Create parallel translation requests
    final futures = <Future<MapEntry<String, Either<Failure, String>>>>[];

    for (var i = 0; i < messageIds.length; i++) {
      final messageId = messageIds[i];
      final text = texts[i];

      futures.add(
        translateMessage(
          messageId: messageId,
          text: text,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        ).then((result) => MapEntry(messageId, result)),
      );
    }

    // Wait for all translations to complete
    final results = await Future.wait(futures);

    // Convert list of entries to map
    return Map<String, Either<Failure, String>>.fromEntries(results);
  }
}
