/// Implementation of GroupConversationRepository
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/error_mapper.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_local_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/group_conversation_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/models/conversation_model.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/domain/repositories/group_conversation_repository.dart';

/// Implementation of [GroupConversationRepository] that uses both local and remote data sources
/// for offline-first functionality.
///
/// Strategy:
/// - Reads: Local first (instant), sync from remote in background
/// - Writes: Local immediate, queue for remote sync
class GroupConversationRepositoryImpl implements GroupConversationRepository {
  // Reuse existing local data source

  GroupConversationRepositoryImpl({
    required GroupConversationRemoteDataSource remoteDataSource,
    required ConversationLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;
  final GroupConversationRemoteDataSource _remoteDataSource;
  final ConversationLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, Conversation>> createGroup(Conversation group) async {
    try {
      // Validate group fields
      if (group.type != 'group') {
        return const Left(
          ValidationFailure(message: 'Conversation type must be "group"'),
        );
      }

      if (group.participantIds.length < 2) {
        return const Left(
          ValidationFailure(message: 'Group must have at least 2 participants'),
        );
      }

      if (group.groupName == null || group.groupName!.isEmpty) {
        return const Left(ValidationFailure(message: 'Group name is required'));
      }

      if (group.adminIds == null || group.adminIds!.isEmpty) {
        return const Left(
          ValidationFailure(message: 'Group must have at least one admin'),
        );
      }

      // Offline-first: Save to local immediately
      final localGroup = await _localDataSource.createConversation(group);

      // Background sync to remote (don't wait for it)
      await _syncToRemote(localGroup);

      return Right(localGroup);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Background sync to remote - fire and forget
  Future<void> _syncToRemote(Conversation group) async {
    try {
      final groupModel = ConversationModel.fromEntity(group);
      await _remoteDataSource.createGroup(groupModel);
    } catch (e) {
      // Sync failed - will be retried by sync service
    }
  }

  @override
  Future<Either<Failure, Conversation>> getGroupById(String groupId) async {
    try {
      // Offline-first: Try local first
      final localGroup = await _localDataSource.getConversation(groupId);

      if (localGroup != null && localGroup.isGroup) {
        return Right(localGroup);
      }

      // Not in local, try remote
      final groupModel = await _remoteDataSource.getGroupById(groupId);
      final group = groupModel.toEntity();

      // Save to local for future offline access
      await _localDataSource.createConversation(group);

      return Right(group);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Conversation>>> getGroupsForUser(
    String userId, {
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      // Offline-first: Get from local first
      final localGroups = await _localDataSource.getConversationsByType(
        'group',
        limit: limit,
      );

      // Filter by participant
      final filteredGroups = localGroups
          .where((c) => c.participantIds.contains(userId))
          .toList();

      if (filteredGroups.isNotEmpty) {
        // Background sync from remote
        await _syncGroupsFromRemote(userId, limit, before);
        return Right(filteredGroups);
      }

      // No local data, fetch from remote
      final groupModels = await _remoteDataSource.getGroupsForUser(
        userId,
        limit: limit,
        before: before,
      );

      final groups = groupModels.map((model) => model.toEntity()).toList();

      // Save to local
      await _localDataSource.insertConversations(groups);

      return Right(groups);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Background sync from remote - fire and forget
  Future<void> _syncGroupsFromRemote(
    String userId,
    int limit,
    DateTime? before,
  ) async {
    try {
      final groupModels = await _remoteDataSource.getGroupsForUser(
        userId,
        limit: limit,
        before: before,
      );

      final groups = groupModels.map((model) => model.toEntity()).toList();
      await _localDataSource.insertConversations(groups);
    } catch (e) {
      // Sync failed - will be retried by sync service
    }
  }

  @override
  Future<Either<Failure, Conversation>> updateGroup(Conversation group) async {
    try {
      // Offline-first: Update local immediately
      final localGroup = await _localDataSource.updateConversation(group);

      // Background sync to remote
      await _updateRemote(localGroup);

      return Right(localGroup);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Background update to remote - fire and forget
  Future<void> _updateRemote(Conversation group) async {
    try {
      final groupModel = ConversationModel.fromEntity(group);
      await _remoteDataSource.updateGroup(groupModel);
    } catch (e) {
      // Update failed - will be retried by sync service
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroup(String groupId) async {
    try {
      // Offline-first: Delete from local immediately
      await _localDataSource.deleteConversation(groupId);

      // Background sync to remote
      await _deleteRemote(groupId);

      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Background delete from remote - fire and forget
  Future<void> _deleteRemote(String groupId) async {
    try {
      await _remoteDataSource.deleteGroup(groupId);
    } catch (e) {
      // Delete failed - will be retried by sync service
    }
  }

  @override
  Stream<Either<Failure, List<Conversation>>> watchGroupsForUser(
    String userId, {
    int limit = 50,
  }) {
    try {
      // Watch Firestore for incoming groups
      // When new groups arrive, save them to local DB
      _remoteDataSource.watchGroupsForUser(userId, limit: limit).listen((
        groupModels,
      ) async {
        try {
          final groups = groupModels.map((model) => model.toEntity()).toList();

          // Upsert to local database (updates existing, inserts new)
          await _localDataSource.insertConversations(groups);
        } catch (e) {
          // Silently fail - local stream will still work
        }
      });

      // Return local stream (which now gets updates from Firestore)
      final localStream = _localDataSource.watchConversationsByParticipant(
        userId,
        limit: limit,
      );

      // Filter to only groups
      return localStream.map((conversations) {
        final groups = conversations.where((c) => c.isGroup).toList();
        return Right<Failure, List<Conversation>>(groups);
      });
    } on AppException catch (e) {
      return Stream.value(Left(ErrorMapper.mapExceptionToFailure(e)));
    } catch (e) {
      return Stream.value(Left(UnknownFailure(message: e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> addMember(
    String groupId,
    String userId,
    String userName,
    String preferredLanguage,
  ) async {
    try {
      // Get current group
      final groupResult = await getGroupById(groupId);

      return groupResult.fold(Left.new, (group) async {
        // Add member to participants list
        final updatedParticipants = [
          ...group.participants,
          Participant(uid: userId, preferredLanguage: preferredLanguage),
        ];

        final updatedGroup = group.copyWith(
          participantIds: [...group.participantIds, userId],
          participants: updatedParticipants,
          lastUpdatedAt: DateTime.now(),
        );

        // Update local immediately
        await _localDataSource.updateConversation(updatedGroup);

        // Sync to remote in background
        await _remoteDataSource.addMember(
          groupId,
          userId,
          userName,
          preferredLanguage,
        );

        return const Right(null);
      });
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeMember(
    String groupId,
    String userId,
  ) async {
    try {
      // Get current group
      final groupResult = await getGroupById(groupId);

      return groupResult.fold(Left.new, (group) async {
        // Remove member from participants list
        final updatedParticipants = group.participants
            .where((p) => p.uid != userId)
            .toList();

        final updatedAdminIds = group.adminIds
            ?.where((id) => id != userId)
            .toList();

        // Remove user from unreadCount map
        final updatedUnreadCount = Map<String, int>.from(group.unreadCount)
          ..remove(userId);

        final updatedGroup = group.copyWith(
          participantIds: group.participantIds
              .where((id) => id != userId)
              .toList(),
          participants: updatedParticipants,
          adminIds: updatedAdminIds,
          unreadCount: updatedUnreadCount,
          lastUpdatedAt: DateTime.now(),
        );

        // Update local immediately
        await _localDataSource.updateConversation(updatedGroup);

        // Sync to remote in background
        await _remoteDataSource.removeMember(groupId, userId);

        return const Right(null);
      });
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateGroupInfo({
    required String groupId,
    String? groupName,
    String? groupImage,
  }) async {
    try {
      // Get current group
      final groupResult = await getGroupById(groupId);

      return groupResult.fold(Left.new, (group) async {
        // Update group info
        final updatedGroup = group.copyWith(
          groupName: groupName ?? group.groupName,
          groupImage: groupImage ?? group.groupImage,
          lastUpdatedAt: DateTime.now(),
        );

        // Update local immediately
        await _localDataSource.updateConversation(updatedGroup);

        // Sync to remote in background
        await _remoteDataSource.updateGroupInfo(
          groupId: groupId,
          groupName: groupName,
          groupImage: groupImage,
        );

        return const Right(null);
      });
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> promoteToAdmin(
    String groupId,
    String userId,
  ) async {
    try {
      // Get current group
      final groupResult = await getGroupById(groupId);

      return groupResult.fold(Left.new, (group) async {
        // Add user to admins list
        final updatedAdminIds = [
          ...?group.adminIds,
          if (!(group.adminIds?.contains(userId) ?? false)) userId,
        ];

        final updatedGroup = group.copyWith(
          adminIds: updatedAdminIds,
          lastUpdatedAt: DateTime.now(),
        );

        // Update local immediately
        await _localDataSource.updateConversation(updatedGroup);

        // Sync to remote in background
        await _remoteDataSource.promoteToAdmin(groupId, userId);

        return const Right(null);
      });
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> demoteFromAdmin(
    String groupId,
    String userId,
  ) async {
    try {
      // Get current group
      final groupResult = await getGroupById(groupId);

      return groupResult.fold(Left.new, (group) async {
        // Remove user from admins list
        final updatedAdminIds = group.adminIds
            ?.where((id) => id != userId)
            .toList();

        final updatedGroup = group.copyWith(
          adminIds: updatedAdminIds,
          lastUpdatedAt: DateTime.now(),
        );

        // Update local immediately
        await _localDataSource.updateConversation(updatedGroup);

        // Sync to remote in background
        await _remoteDataSource.demoteFromAdmin(groupId, userId);

        return const Right(null);
      });
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastMessage(
    String groupId,
    String messageText,
    String senderId,
    DateTime timestamp,
  ) async {
    try {
      // Offline-first: Update local immediately
      final lastMessage = LastMessage(
        text: messageText,
        senderId: senderId,
        timestamp: timestamp,
        type: 'text',
      );

      await _localDataSource.updateLastMessage(
        documentId: groupId,
        lastMessage: lastMessage,
      );

      // Background sync to remote
      await _remoteDataSource.updateLastMessage(
        groupId,
        messageText,
        senderId,
        timestamp,
      );

      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUnreadCount(
    String groupId,
    String userId,
    int count,
  ) async {
    try {
      // Get current group
      final groupResult = await getGroupById(groupId);

      return groupResult.fold(Left.new, (group) async {
        // Update unread count for user
        final updatedUnreadCount = {...group.unreadCount, userId: count};

        final updatedGroup = group.copyWith(unreadCount: updatedUnreadCount);

        // Update local immediately
        await _localDataSource.updateConversation(updatedGroup);

        // Sync to remote in background
        await _remoteDataSource.updateUnreadCount(groupId, userId, count);

        return const Right(null);
      });
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
