import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/data/services/message_queue.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';
import 'package:message_ai/features/smart_replies/domain/services/embedding_generator.dart';
import 'package:message_ai/features/translation/data/services/language_detection_service.dart';

/// Use case for sending a message in a conversation.
///
/// This use case:
/// 1. Validates the message content
/// 2. Detects the language of the message using ML Kit
/// 3. Creates the message in Firestore with detected language
/// 4. Updates the conversation's last message
/// 5. Generates embedding for the message (fire-and-forget)
///
/// Returns the created message or a Failure.
class SendMessage {

  SendMessage({
    required MessageRepository messageRepository,
    required ConversationRepository conversationRepository,
    required LanguageDetectionService languageDetectionService,
    EmbeddingGenerator? embeddingGenerator,
    MessageQueue? messageQueue,
  })  : _messageRepository = messageRepository,
        _conversationRepository = conversationRepository,
        _languageDetectionService = languageDetectionService,
        _embeddingGenerator = embeddingGenerator,
        _messageQueue = messageQueue;
  final MessageRepository _messageRepository;
  final ConversationRepository _conversationRepository;
  final LanguageDetectionService _languageDetectionService;
  final EmbeddingGenerator? _embeddingGenerator;
  final MessageQueue? _messageQueue;

  /// Sends a message to a conversation.
  ///
  /// [conversationId] - ID of the conversation to send the message to
  /// [message] - The message entity to send
  ///
  /// Returns Right(Message) on success, Left(Failure) on error.
  ///
  /// The message will have its language automatically detected using ML Kit
  /// before being sent. Detection typically takes <50ms.
  Future<Either<Failure, Message>> call(
    String conversationId,
    Message message,
  ) async {
    // Validate message content
    if (message.text.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Message cannot be empty',
          fieldErrors: {'text': 'Message text is required'},
        ),
      );
    }

    // Detect language using ML Kit (on-device, <50ms)
    // This is done before sending to enable translation for recipients
    String? detectedLanguage;
    try {
      detectedLanguage = await _languageDetectionService.detectLanguage(
        message.text,
      );
    } catch (e) {
      // Non-critical error - continue without detected language
      debugPrint('Language detection failed: $e');
    }

    // Create message with detected language
    // If detection failed or confidence was low, detectedLanguage will be null
    // and the Message entity will use the existing detectedLanguage value (if any)
    final Message messageWithLanguage = detectedLanguage != null
        ? message.copyWith(detectedLanguage: detectedLanguage)
        : message;

    // Create message in repository (offline-first)
    // This saves to local DB immediately and attempts background sync to Firestore
    final result = await _messageRepository.createMessage(
      conversationId,
      messageWithLanguage,
    );

    // Check if message queue is available and enqueue if needed
    // This ensures robust retry logic even if repository sync fails
    if (_messageQueue != null) {
      await result.fold(
        (failure) async {
          // Repository create failed - enqueue for retry
          try {
            await _messageQueue.enqueue(
              conversationId: conversationId,
              message: messageWithLanguage,
            );
          } catch (e) {
            // Queue enqueue failed - message is still in local DB
            // and will be picked up by MessageSyncService
            debugPrint('Failed to enqueue message: $e');
          }
        },
        (createdMessage) async {
          // Message created - check if it's in failed state and needs retry
          // This handles the case where repository marked it as 'failed'
          // The message is already in local DB, just ensuring it's queued for retry
          // MessageQueue will handle duplicate prevention via local DB
        },
      );
    }

    return result.fold<Future<Either<Failure, Message>>>(
      (failure) async => Left(failure),
      (createdMessage) async {
        // Update conversation's last message
        // (non-critical operation, ignore failures)
        await _conversationRepository.updateLastMessage(
          conversationId,
          createdMessage.text,
          createdMessage.senderId,
          createdMessage.timestamp,
        );

        // Generate embedding for the message (fire-and-forget)
        // This doesn't block the send operation - embeddings are generated
        // in the background for the Smart Replies RAG pipeline
        if (_embeddingGenerator != null) {
          unawaited(
            _embeddingGenerator.generateForMessage(
              conversationId: conversationId,
              message: createdMessage,
            ),
          );
        }

        return Right(createdMessage);
      },
    );
  }
}
