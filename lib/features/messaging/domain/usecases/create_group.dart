/// Use case for creating a new group conversation
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:uuid/uuid.dart';

/// Use case for creating a new group conversation.
///
/// This validates group requirements and creates a new group
/// with the specified participants and admin(s).
class CreateGroup {
  CreateGroup(this._conversationRepository) : _uuid = const Uuid();
  final ConversationRepository _conversationRepository;
  final Uuid _uuid;

  /// Creates a new group conversation.
  ///
  /// [groupName] - Name of the group (required)
  /// [participantIds] - List of participant user IDs (minimum 2)
  /// [participants] - List of participant details
  /// [adminIds] - List of admin user IDs (minimum 1)
  /// [creatorId] - ID of the user creating the group
  /// [groupImage] - Optional group image URL
  ///
  /// Returns the newly created group conversation.
  Future<Either<Failure, Conversation>> call({
    required String groupName,
    required List<String> participantIds,
    required List<Participant> participants,
    required List<String> adminIds,
    required String creatorId,
    String? groupImage,
  }) async {
    // Validate input
    if (groupName.trim().isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Group name cannot be empty',
          fieldErrors: {'groupName': 'Group name is required'},
        ),
      );
    }

    if (participantIds.length < 2) {
      return const Left(
        ValidationFailure(
          message: 'Group must have at least 2 participants',
          fieldErrors: {'participants': 'Minimum 2 participants required'},
        ),
      );
    }

    if (adminIds.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Group must have at least one admin',
          fieldErrors: {'adminIds': 'At least one admin is required'},
        ),
      );
    }

    if (!participantIds.contains(creatorId)) {
      return const Left(
        ValidationFailure(
          message: 'Creator must be a participant',
          fieldErrors: {'creatorId': 'Creator must be in participant list'},
        ),
      );
    }

    if (!adminIds.contains(creatorId)) {
      return const Left(
        ValidationFailure(
          message: 'Creator must be an admin',
          fieldErrors: {'creatorId': 'Creator must be in admin list'},
        ),
      );
    }

    // Validate all admins are participants
    for (final adminId in adminIds) {
      if (!participantIds.contains(adminId)) {
        return Left(
          ValidationFailure(
            message: 'All admins must be participants',
            fieldErrors: {'adminIds': 'Admin $adminId is not a participant'},
          ),
        );
      }
    }

    // Create new group
    final now = DateTime.now();
    final unreadCount = {
      for (final participantId in participantIds) participantId: 0,
    };

    final newGroup = Conversation(
      documentId: _uuid.v4(),
      type: 'group',
      participantIds: participantIds,
      participants: participants,
      lastUpdatedAt: now,
      initiatedAt: now,
      unreadCount: unreadCount,
      translationEnabled: false,
      autoDetectLanguage: false,
      groupName: groupName,
      groupImage: groupImage,
      adminIds: adminIds,
    );

    return _conversationRepository.createConversation(newGroup);
  }
}
