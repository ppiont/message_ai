/// Background service for analyzing cultural context of messages
library;

import 'dart:async';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/cultural_context/domain/usecases/analyze_message_cultural_context.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Service that analyzes cultural context of received messages in the background
///
/// This service:
/// 1. Only analyzes received messages (not sent messages)
/// 2. Only analyzes messages in foreign languages (detectedLanguage != userPreferredLanguage)
/// 3. Runs async without blocking message display
/// 4. Fails silently if analysis fails
/// 5. Updates message with cultural hint if found
class CulturalContextAnalyzer {
  CulturalContextAnalyzer({
    required AnalyzeMessageCulturalContext analyzeCulturalContext,
    required MessageRepository messageRepository,
  })  : _analyzeCulturalContext = analyzeCulturalContext,
        _messageRepository = messageRepository;

  final AnalyzeMessageCulturalContext _analyzeCulturalContext;
  final MessageRepository _messageRepository;
  final Set<String> _analyzed = {}; // Track analyzed messages to avoid duplicates

  /// Analyze a message for cultural context in the background
  ///
  /// This is fire-and-forget - it runs async and doesn't block
  Future<void> analyzeMessageInBackground({
    required String conversationId,
    required Message message,
    required User currentUser,
  }) async {
    // Skip if already analyzed
    if (_analyzed.contains(message.id)) {
      return;
    }

    // Skip if already has cultural hint
    if (message.culturalHint != null) {
      _analyzed.add(message.id);
      return;
    }

    // Skip if message was sent by current user
    if (message.senderId == currentUser.uid) {
      return;
    }

    // Skip if no detected language
    if (message.detectedLanguage == null) {
      return;
    }

    // Skip if message is already in user's preferred language
    if (message.detectedLanguage == currentUser.preferredLanguage) {
      return;
    }

    // Mark as being analyzed
    _analyzed.add(message.id);

    // Run analysis in background (fire-and-forget)
    unawaited(_performAnalysis(conversationId, message));
  }

  /// Perform the actual cultural context analysis
  Future<void> _performAnalysis(String conversationId, Message message) async {
    try {
      final result = await _analyzeCulturalContext(
        text: message.text,
        language: message.detectedLanguage!,
      );

      await result.fold(
        (failure) async {
          // Analysis failed - fail silently
          // Remove from analyzed set so it can be retried later
          _analyzed.remove(message.id);
        },
        (culturalHint) async {
          // Only update if we got a cultural hint
          if (culturalHint != null) {
            final updatedMessage = message.copyWith(culturalHint: culturalHint);

            await _messageRepository.updateMessage(
              conversationId,
              updatedMessage,
            );
          }
        },
      );
    } catch (e) {
      // Fail silently - remove from analyzed set for retry
      _analyzed.remove(message.id);
    }
  }

  /// Clear the analyzed messages cache
  void clearCache() {
    _analyzed.clear();
  }
}
