/// Implementation of ConversationRepository
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/error_mapper.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_local_datasource.dart';
import 'package:message_ai/features/messaging/data/models/conversation_model.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';

/// Implementation of [ConversationRepository] that uses both local and remote data sources
/// for offline-first functionality.
///
/// Strategy:
/// - Reads: Local first (instant), sync from remote in background
/// - Writes: Local immediate, queue for remote sync
class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationRemoteDataSource _remoteDataSource;
  final ConversationLocalDataSource _localDataSource;

  ConversationRepositoryImpl({
    required ConversationRemoteDataSource remoteDataSource,
    required ConversationLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, Conversation>> createConversation(
    Conversation conversation,
  ) async {
    try {
      // Offline-first: Save to local immediately
      final localConversation =
          await _localDataSource.createConversation(conversation);

      // Background sync to remote (don't wait for it)
      _syncToRemote(localConversation);

      return Right(localConversation);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Background sync to remote - fire and forget
  Future<void> _syncToRemote(Conversation conversation) async {
    try {
      final conversationModel = ConversationModel.fromEntity(conversation);
      await _remoteDataSource.createConversation(conversationModel);
    } catch (e) {
      // Sync failed - will be retried by sync service
    }
  }

  @override
  Future<Either<Failure, Conversation>> getConversationById(
    String conversationId,
  ) async {
    try {
      // Offline-first: Try local first
      final localConversation =
          await _localDataSource.getConversation(conversationId);

      if (localConversation != null) {
        return Right(localConversation);
      }

      // Not in local, try remote
      final conversationModel =
          await _remoteDataSource.getConversationById(conversationId);
      final conversation = conversationModel.toEntity();

      // Save to local for future offline access
      await _localDataSource.createConversation(conversation);

      return Right(conversation);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Conversation>>> getConversationsForUser(
    String userId, {
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      final conversationModels =
          await _remoteDataSource.getConversationsForUser(
        userId,
        limit: limit,
        before: before,
      );
      return Right(
        conversationModels.map((model) => model.toEntity()).toList(),
      );
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Conversation>> updateConversation(
    Conversation conversation,
  ) async {
    try {
      final conversationModel = ConversationModel.fromEntity(conversation);
      final updatedConversationModel =
          await _remoteDataSource.updateConversation(conversationModel);
      return Right(updatedConversationModel.toEntity());
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteConversation(
    String conversationId,
  ) async {
    try {
      await _remoteDataSource.deleteConversation(conversationId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Conversation>>> watchConversationsForUser(
    String userId, {
    int limit = 50,
  }) {
    try {
      // Watch Firestore for conversation updates
      // When conversations change, save them to local DB
      _remoteDataSource
          .watchConversationsForUser(userId, limit: limit)
          .listen((conversationModels) async {
        try {
          final conversations =
              conversationModels.map((model) => model.toEntity()).toList();
          // Upsert to local database (updates existing, inserts new)
          await _localDataSource.insertConversations(conversations);
        } catch (e) {
          // Silently fail - local stream will still work
        }
      });

      // Return local stream (which now gets updates from Firestore)
      final localStream = _localDataSource.watchConversationsByParticipant(
        userId,
        limit: limit,
      );

      return localStream.map(
        (conversations) => Right<Failure, List<Conversation>>(conversations),
      );
    } on AppException catch (e) {
      return Stream.value(Left(ErrorMapper.mapExceptionToFailure(e)));
    } catch (e) {
      return Stream.value(Left(UnknownFailure(message: e.toString())));
    }
  }


  @override
  Future<Either<Failure, Conversation?>> findDirectConversation(
    String userId1,
    String userId2,
  ) async {
    try {
      // Offline-first: Try local first
      final localConversation =
          await _localDataSource.getDirectConversation(userId1, userId2);

      if (localConversation != null) {
        return Right(localConversation);
      }

      // Not in local, try remote
      final conversationModel =
          await _remoteDataSource.findDirectConversation(userId1, userId2);

      if (conversationModel != null) {
        final conversation = conversationModel.toEntity();
        // Save to local for future offline access
        await _localDataSource.createConversation(conversation);
        return Right(conversation);
      }

      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastMessage(
    String conversationId,
    String messageText,
    String senderId,
    String senderName,
    DateTime timestamp,
  ) async {
    try {
      // Offline-first: Update local immediately
      final lastMessage = LastMessage(
        text: messageText,
        senderId: senderId,
        senderName: senderName,
        timestamp: timestamp,
        type: 'text',
      );

      await _localDataSource.updateLastMessage(
        documentId: conversationId,
        lastMessage: lastMessage,
      );

      // Background sync to remote
      _remoteDataSource.updateLastMessage(
        conversationId,
        messageText,
        senderId,
        senderName,
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
    String conversationId,
    String userId,
    int count,
  ) async {
    try {
      await _remoteDataSource.updateUnreadCount(conversationId, userId, count);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
