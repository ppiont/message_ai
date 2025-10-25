/// Auto-translation service for incoming messages
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';
import 'package:message_ai/features/translation/data/services/translation_service.dart';

/// Service that automatically translates incoming messages based on user's preferred language
///
/// This service:
/// - Listens to incoming messages
/// - Identifies messages that need translation (detectedLanguage != userPreferredLanguage)
/// - Auto-fetches translations in the background
/// - Updates messages with translations for instant display when user toggles
///
/// Benefits:
/// - Translations are pre-fetched before user clicks translate button (instant UX)
/// - Reduces perceived latency
/// - User still has control (manual toggle to view)
/// - Respects rate limits
class AutoTranslationService {
  AutoTranslationService({
    required TranslationService translationService,
    required MessageRepository messageRepository,
  }) : _translationService = translationService,
       _messageRepository = messageRepository;

  final TranslationService _translationService;
  final MessageRepository _messageRepository;

  // Track active subscription to prevent multiple listeners
  StreamSubscription<dynamic>? _messageSubscription;

  // Track messages being translated to prevent duplicate requests
  final Set<String> _translatingMessages = <String>{};

  /// Start auto-translating messages for a conversation
  ///
  /// Listens to incoming messages and automatically translates them
  /// if they're in a different language than the user's preference.
  ///
  /// Call this when entering a conversation.
  /// Call [stop] when leaving the conversation to clean up.
  void start({
    required String conversationId,
    required String currentUserId,
    required String userPreferredLanguage,
  }) {
    // Stop any existing subscription
    stop();

    // Watch messages in the conversation
    _messageSubscription = _messageRepository
        .watchMessages(
          conversationId: conversationId,
          currentUserId: currentUserId,
        )
        .listen((result) {
          result.fold(
            (failure) {
              // Log error but don't crash
              debugPrint(
                '[AutoTranslationService] Error watching messages: ${failure.message}',
              );
            },
            (messages) {
              // Process messages for auto-translation
              _processMessages(
                messages: messages,
                conversationId: conversationId,
                currentUserId: currentUserId,
                userPreferredLanguage: userPreferredLanguage,
              );
            },
          );
        });
  }

  /// Stop auto-translation and clean up
  ///
  /// Call this when leaving a conversation or disposing the service.
  void stop() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _translatingMessages.clear();
  }

  /// Process messages to determine which need translation
  Future<void> _processMessages({
    required List<Message> messages,
    required String conversationId,
    required String currentUserId,
    required String userPreferredLanguage,
  }) async {
    // Filter messages that need translation:
    // 1. Not sent by current user (received messages only)
    // 2. Have a detected language
    // 3. Detected language differs from user preference
    // 4. Don't already have translation for user's language
    // 5. Not currently being translated
    final messagesToTranslate = messages.where((message) {
      // Skip messages sent by current user
      if (message.senderId == currentUserId) {
        return false;
      }

      // Skip if no detected language
      if (message.detectedLanguage == null ||
          message.detectedLanguage!.isEmpty) {
        return false;
      }

      // Skip if already in user's preferred language
      if (message.detectedLanguage == userPreferredLanguage) {
        return false;
      }

      // Skip if translation already exists
      if (message.translations?[userPreferredLanguage] != null) {
        return false;
      }

      // Skip if currently being translated
      if (_translatingMessages.contains(message.id)) {
        return false;
      }

      return true;
    }).toList();

    // If no messages need translation, return early
    if (messagesToTranslate.isEmpty) {
      return;
    }

    debugPrint(
      '[AutoTranslationService] Auto-translating ${messagesToTranslate.length} messages',
    );

    // Use batch translation for efficiency
    await _batchTranslateMessages(
      messages: messagesToTranslate,
      conversationId: conversationId,
      targetLanguage: userPreferredLanguage,
    );
  }

  /// Batch translate multiple messages for efficiency
  Future<void> _batchTranslateMessages({
    required List<Message> messages,
    required String conversationId,
    required String targetLanguage,
  }) async {
    // Mark messages as being translated
    for (final message in messages) {
      _translatingMessages.add(message.id);
    }

    try {
      // Prepare batch translation request
      final messageIds = messages.map((m) => m.id).toList();
      final texts = messages.map((m) => m.text).toList();
      final sourceLanguage = messages.first.detectedLanguage!;

      // Call batch translate service
      final results = await _translationService.batchTranslateMessages(
        messageIds: messageIds,
        texts: texts,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );

      // Process results and update messages
      for (final message in messages) {
        final result = results[message.id];
        if (result == null) {
          continue;
        }

        await result.fold(
          (failure) async {
            // Translation failed - log and skip
            debugPrint(
              '[AutoTranslationService] Failed to translate message ${message.id}: ${failure.message}',
            );
          },
          (translatedText) async {
            // Translation succeeded - update message
            final updatedTranslations = <String, String>{
              ...?message.translations,
              targetLanguage: translatedText,
            };

            final updatedMessage = message.copyWith(
              translations: updatedTranslations,
            );

            // Update in repository (will sync to Firestore)
            await _messageRepository.updateMessage(
              conversationId,
              updatedMessage,
            );

            debugPrint(
              '[AutoTranslationService] Successfully translated message ${message.id}',
            );
          },
        );
      }
    } catch (e) {
      debugPrint('[AutoTranslationService] Batch translation error: $e');
    } finally {
      // Remove from translating set
      for (final message in messages) {
        _translatingMessages.remove(message.id);
      }
    }
  }

  /// Dispose the service and clean up resources
  void dispose() {
    stop();
  }
}
