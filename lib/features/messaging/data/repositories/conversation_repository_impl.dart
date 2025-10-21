/// Implementation of ConversationRepository
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/error_mapper.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/models/conversation_model.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';

/// Implementation of [ConversationRepository] that uses [ConversationRemoteDataSource]
/// to interact with Firestore.
class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationRemoteDataSource _remoteDataSource;

  ConversationRepositoryImpl({
    required ConversationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, Conversation>> createConversation(
    Conversation conversation,
  ) async {
    try {
      final conversationModel = ConversationModel.fromEntity(conversation);
      final createdConversationModel =
          await _remoteDataSource.createConversation(conversationModel);
      return Right(createdConversationModel.toEntity());
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Conversation>> getConversationById(
    String conversationId,
  ) async {
    try {
      final conversationModel =
          await _remoteDataSource.getConversationById(conversationId);
      return Right(conversationModel.toEntity());
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
      return _remoteDataSource
          .watchConversationsForUser(userId, limit: limit)
          .map((conversationModels) => Right<Failure, List<Conversation>>(
                conversationModels.map((model) => model.toEntity()).toList(),
              ));
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
      final conversationModel =
          await _remoteDataSource.findDirectConversation(userId1, userId2);
      return Right(conversationModel?.toEntity());
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
      await _remoteDataSource.updateLastMessage(
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
