/// Repository interface for group conversation operations
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';

/// Abstract interface for managing group conversation data.
///
/// This repository handles operations related to group conversations,
/// abstracting data sources and error handling.
abstract class GroupConversationRepository {
  /// Creates a new group conversation.
  Future<Either<Failure, Conversation>> createGroup(Conversation group);

  /// Retrieves a specific group by ID.
  Future<Either<Failure, Conversation>> getGroupById(String groupId);

  /// Retrieves groups for a specific user with pagination.
  Future<Either<Failure, List<Conversation>>> getGroupsForUser(
    String userId, {
    int limit = 50,
    DateTime? before,
  });

  /// Updates an existing group.
  Future<Either<Failure, Conversation>> updateGroup(Conversation group);

  /// Deletes a group.
  Future<Either<Failure, void>> deleteGroup(String groupId);

  /// Watches groups for a user in real-time.
  Stream<Either<Failure, List<Conversation>>> watchGroupsForUser(
    String userId, {
    int limit = 50,
  });

  /// Adds a member to a group.
  Future<Either<Failure, void>> addMember(
    String groupId,
    String userId,
    String userName,
    String preferredLanguage,
  );

  /// Removes a member from a group.
  Future<Either<Failure, void>> removeMember(String groupId, String userId);

  /// Updates group information (name, image).
  Future<Either<Failure, void>> updateGroupInfo({
    required String groupId,
    String? groupName,
    String? groupImage,
  });

  /// Promotes a member to admin.
  Future<Either<Failure, void>> promoteToAdmin(String groupId, String userId);

  /// Demotes an admin to regular member.
  Future<Either<Failure, void>> demoteFromAdmin(String groupId, String userId);

  /// Updates the last message in a group.
  Future<Either<Failure, void>> updateLastMessage(
    String groupId,
    String messageText,
    String senderId,
    String senderName,
    DateTime timestamp,
  );

  /// Updates unread count for a user in a group.
  Future<Either<Failure, void>> updateUnreadCount(
    String groupId,
    String userId,
    int count,
  );
}
