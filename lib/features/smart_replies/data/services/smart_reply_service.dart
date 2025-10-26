import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/smart_replies/domain/entities/smart_reply.dart';

/// Service for generating smart reply suggestions using Cloud Functions.
///
/// This service calls the unified Firebase Cloud Function that handles
/// the complete RAG pipeline server-side:
/// 1. Generates embedding with Vertex AI
/// 2. Performs vector search using Firestore find_nearest()
/// 3. Fetches user communication style
/// 4. Generates AI-powered reply suggestions with GPT-4o-mini
///
/// Architecture:
/// - Data layer service (handles Cloud Function communication)
/// - Returns `Either<Failure, List<SmartReply>>` for error handling
/// - All RAG orchestration happens server-side
/// - Caching and rate limiting handled by Cloud Function
///
/// Performance: Target <2 seconds response time
class SmartReplyService {
  SmartReplyService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  /// Generates smart reply suggestions for an incoming message.
  ///
  /// This simplified method only requires the incoming message text and
  /// conversation context. All other operations (embedding generation,
  /// vector search, style analysis) happen server-side.
  ///
  /// Parameters:
  /// - [conversationId]: The conversation context
  /// - [incomingMessageText]: The message text to generate replies for
  /// - [userId]: The current user's ID for fetching their communication style
  ///
  /// Returns:
  /// - `Right(List<SmartReply>)`: Generated suggestions on success
  /// - `Left(Failure)`: Error details on failure
  Future<Either<Failure, List<SmartReply>>> generateSmartReplies({
    required String conversationId,
    required String incomingMessageText,
    required String userId,
  }) async {
    try {
      // Validate input
      if (incomingMessageText.trim().isEmpty) {
        return const Left(
          ValidationFailure(message: 'Incoming message text cannot be empty'),
        );
      }

      debugPrint(
        'SmartReplyService: Generating smart replies for message "${incomingMessageText.substring(0, incomingMessageText.length > 50 ? 50 : incomingMessageText.length)}..."',
      );

      // DEBUG: Check auth state
      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint('SmartReplyService: Current user: ${currentUser?.uid}');
      debugPrint('SmartReplyService: Current user email: ${currentUser?.email}');
      debugPrint('SmartReplyService: Is anonymous: ${currentUser?.isAnonymous}');

      if (currentUser == null) {
        debugPrint('SmartReplyService: ERROR - User is not signed in!');
        return const Left(
          ServerFailure(message: 'User must be signed in to generate smart replies'),
        );
      }

      // Call unified Cloud Function (handles entire RAG pipeline server-side)
      final result = await _functions
          .httpsCallable('generate_smart_replies_complete')
          .call<Map<String, dynamic>>({
            'conversationId': conversationId,
            'incomingMessageText': incomingMessageText,
            'userId': userId,
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
