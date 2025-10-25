import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/smart_replies/domain/entities/smart_reply.dart';
import 'package:message_ai/features/smart_replies/domain/entities/user_communication_style.dart';

/// Service for generating smart reply suggestions using Cloud Functions.
///
/// This service calls the Firebase Cloud Function to generate AI-powered
/// reply suggestions that match the user's communication style and are
/// contextually relevant to the incoming message.
///
/// Architecture:
/// - Data layer service (handles Cloud Function communication)
/// - Returns `Either<Failure, List<SmartReply>>` for error handling
/// - Caching and rate limiting handled by Cloud Function
///
/// Performance: Target <2 seconds response time
class SmartReplyService {
  SmartReplyService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Generates smart reply suggestions for an incoming message.
  ///
  /// Parameters:
  /// - [conversationId]: The conversation context
  /// - [incomingMessage]: The message to generate replies for
  /// - [userStyle]: The user's learned communication style
  /// - [relevantContext]: Semantically relevant messages from history
  ///
  /// Returns:
  /// - `Right(List<SmartReply>)`: Generated suggestions on success
  /// - `Left(Failure)`: Error details on failure
  Future<Either<Failure, List<SmartReply>>> generateSmartReplies({
    required String conversationId,
    required Message incomingMessage,
    required UserCommunicationStyle userStyle,
    required List<Message> relevantContext,
  }) async {
    try {
      // Validate input
      if (incomingMessage.text.trim().isEmpty) {
        return const Left(
          ValidationFailure(message: 'Incoming message text cannot be empty'),
        );
      }

      if (incomingMessage.embedding == null ||
          incomingMessage.embedding!.isEmpty) {
        return const Left(
          ValidationFailure(message: 'Incoming message must have an embedding'),
        );
      }

      debugPrint(
        'SmartReplyService: Generating smart replies for message "${incomingMessage.text.substring(0, incomingMessage.text.length > 50 ? 50 : incomingMessage.text.length)}..."',
      );

      // Convert context messages to JSON format
      final contextJson = relevantContext
          .map(
            (msg) => <String, dynamic>{
              'text': msg.text,
              'senderId': msg.senderId,
              'timestamp': msg.timestamp.toIso8601String(),
            },
          )
          .toList();

      // Call Cloud Function
      final result = await _functions
          .httpsCallable('generate_smart_replies')
          .call<Map<String, dynamic>>({
            'conversationId': conversationId,
            'incomingMessageText': incomingMessage.text,
            'incomingMessageEmbedding': incomingMessage.embedding,
            'userStyle': userStyle.toJson(),
            'relevantContext': contextJson,
          });

      final data = result.data;

      // Extract suggestions
      final suggestionsJson = data['suggestions'] as List<dynamic>?;
      if (suggestionsJson == null || suggestionsJson.isEmpty) {
        return const Left(
          AIServiceFailure(
            message: 'Smart reply generation failed: empty response',
          ),
        );
      }

      // Parse suggestions
      final suggestions = suggestionsJson
          .map(
            (json) => SmartReply.fromJson(
              Map<String, dynamic>.from(json as Map<Object?, Object?>),
            ),
          )
          .toList();

      final cached = data['cached'] as bool? ?? false;

      debugPrint(
        'SmartReplyService: Generated ${suggestions.length} smart replies '
        '(${cached ? "cached" : "new"})',
      );

      return Right(suggestions);
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'SmartReplyService: Cloud Function error: ${e.code} - ${e.message}',
      );

      // Map Firebase Functions errors to appropriate Failures
      switch (e.code) {
        case 'invalid-argument':
          return Left(
            ValidationFailure(message: e.message ?? 'Invalid argument'),
          );
        case 'unauthenticated':
          return Left(
            ServerFailure(message: 'User not authenticated: ${e.message}'),
          );
        case 'resource-exhausted':
          return Left(
            RateLimitExceededFailure(
              retryAfter: DateTime.now().add(const Duration(hours: 1)),
            ),
          );
        default:
          return Left(
            AIServiceFailure(
              message:
                  e.message ?? 'Failed to generate smart replies: ${e.code}',
            ),
          );
      }
    } catch (e) {
      debugPrint('SmartReplyService: Unexpected error: $e');
      return Left(
        AIServiceFailure(message: 'Failed to generate smart replies: $e'),
      );
    }
  }
}
