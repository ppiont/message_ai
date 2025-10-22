/// Use case for sending a message
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';
import 'package:message_ai/features/translation/data/services/language_detection_service.dart';

/// Use case for sending a message in a conversation.
///
/// This use case:
/// 1. Validates the message content
/// 2. Detects the language of the message using ML Kit
/// 3. Creates the message in Firestore with detected language
/// 4. Updates the conversation's last message
///
/// Returns the created message or a Failure.
class SendMessage {
  final MessageRepository _messageRepository;
  final ConversationRepository _conversationRepository;
  final LanguageDetectionService _languageDetectionService;

  SendMessage({
    required MessageRepository messageRepository,
    required ConversationRepository conversationRepository,
    required LanguageDetectionService languageDetectionService,
  })  : _messageRepository = messageRepository,
        _conversationRepository = conversationRepository,
        _languageDetectionService = languageDetectionService;

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
      print('Language detection failed: $e');
    }

    // Create message with detected language
    // If detection failed or confidence was low, detectedLanguage will be null
    // and the Message entity will use the existing detectedLanguage value (if any)
    final messageWithLanguage = detectedLanguage != null
        ? message.copyWith(detectedLanguage: detectedLanguage)
        : message;

    // Create message in Firestore
    final result = await _messageRepository.createMessage(
      conversationId,
      messageWithLanguage,
    );

    return result.fold(
      (failure) => Left(failure),
      (createdMessage) async {
        // Update conversation's last message
        // (non-critical operation, ignore failures)
        await _conversationRepository.updateLastMessage(
          conversationId,
          createdMessage.text,
          createdMessage.senderId,
          createdMessage.senderName,
          createdMessage.timestamp,
        );

        return Right(createdMessage);
      },
    );
  }
}
