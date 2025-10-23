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
}

