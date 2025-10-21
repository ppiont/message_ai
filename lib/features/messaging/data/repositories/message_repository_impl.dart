/// Implementation of MessageRepository
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/error_mapper.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/models/message_model.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Implementation of [MessageRepository] that uses [MessageRemoteDataSource]
/// to interact with Firestore.
class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource _remoteDataSource;

  MessageRepositoryImpl({required MessageRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, Message>> createMessage(
    String conversationId,
    Message message,
  ) async {
    try {
      final messageModel = MessageModel.fromEntity(message);
      final createdMessageModel =
          await _remoteDataSource.createMessage(conversationId, messageModel);
      return Right(createdMessageModel.toEntity());
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> getMessageById(
    String conversationId,
    String messageId,
  ) async {
    try {
      final messageModel =
          await _remoteDataSource.getMessageById(conversationId, messageId);
      return Right(messageModel.toEntity());
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages({
    required String conversationId,
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      final messageModels = await _remoteDataSource.getMessages(
        conversationId: conversationId,
        limit: limit,
        before: before,
      );
      return Right(messageModels.map((model) => model.toEntity()).toList());
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> updateMessage(
    String conversationId,
    Message message,
  ) async {
    try {
      final messageModel = MessageModel.fromEntity(message);
      final updatedMessageModel =
          await _remoteDataSource.updateMessage(conversationId, messageModel);
      return Right(updatedMessageModel.toEntity());
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(
    String conversationId,
    String messageId,
  ) async {
    try {
      await _remoteDataSource.deleteMessage(conversationId, messageId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Message>>> watchMessages({
    required String conversationId,
    int limit = 50,
  }) {
    try {
      return _remoteDataSource
          .watchMessages(conversationId: conversationId, limit: limit)
          .map((messageModels) =>
              Right<Failure, List<Message>>(
                messageModels.map((model) => model.toEntity()).toList(),
              ));
    } on AppException catch (e) {
      return Stream.value(Left(ErrorMapper.mapExceptionToFailure(e)));
    } catch (e) {
      return Stream.value(Left(UnknownFailure(message: e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> markAsDelivered(
    String conversationId,
    String messageId,
  ) async {
    try {
      await _remoteDataSource.markAsDelivered(conversationId, messageId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(
    String conversationId,
    String messageId,
  ) async {
    try {
      await _remoteDataSource.markAsRead(conversationId, messageId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
