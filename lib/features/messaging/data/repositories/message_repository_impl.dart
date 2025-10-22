/// Implementation of MessageRepository
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/error_mapper.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/data/datasources/message_local_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/models/message_model.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Implementation of [MessageRepository] that uses both local and remote data sources
/// for offline-first functionality.
///
/// Strategy:
/// - Reads: Local first (instant), sync from remote in background
/// - Writes: Local immediate, queue for remote sync
class MessageRepositoryImpl implements MessageRepository {

  MessageRepositoryImpl({
    required MessageRemoteDataSource remoteDataSource,
    required MessageLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;
  final MessageRemoteDataSource _remoteDataSource;
  final MessageLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, Message>> createMessage(
    String conversationId,
    Message message,
  ) async {
    try {
      // Offline-first: Save to local immediately
      final localMessage = await _localDataSource.createMessage(
        conversationId,
        message,
      );

      // Background sync to remote (don't wait for it)
      _syncToRemote(conversationId, localMessage);

      return Right(localMessage);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  /// Background sync to remote - fire and forget
  Future<void> _syncToRemote(String conversationId, Message message) async {
    try {
      final messageModel = MessageModel.fromEntity(message);
      await _remoteDataSource.createMessage(conversationId, messageModel);

      // Mark as synced in local
      await _localDataSource.updateSyncStatus(
        messageId: message.id,
        syncStatus: 'synced',
        lastSyncAttempt: DateTime.now(),
        retryCount: 0,
      );
    } catch (e) {
      // Sync failed - will be retried by sync service
      await _localDataSource.updateSyncStatus(
        messageId: message.id,
        syncStatus: 'failed',
        lastSyncAttempt: DateTime.now(),
        retryCount: 1,
      );
    }
  }

  @override
  Future<Either<Failure, Message>> getMessageById(
    String conversationId,
    String messageId,
  ) async {
    try {
      // Offline-first: Try local first
      final localMessage = await _localDataSource.getMessage(messageId);

      if (localMessage != null) {
        return Right(localMessage);
      }

      // Not in local, try remote
      final messageModel = await _remoteDataSource.getMessageById(
        conversationId,
        messageId,
      );
      final message = messageModel.toEntity();

      // Save to local for future offline access
      await _localDataSource.createMessage(conversationId, message);

      return Right(message);
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
      // Offline-first: Get from local database
      final localMessages = await _localDataSource.getMessages(
        conversationId: conversationId,
        limit: limit,
      );

      return Right(localMessages);
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
      // Offline-first: Update local immediately
      final updatedMessage = await _localDataSource.updateMessage(
        conversationId,
        message,
      );

      // Background sync to remote
      _syncUpdateToRemote(conversationId, updatedMessage);

      return Right(updatedMessage);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<void> _syncUpdateToRemote(
    String conversationId,
    Message message,
  ) async {
    try {
      final messageModel = MessageModel.fromEntity(message);
      await _remoteDataSource.updateMessage(conversationId, messageModel);
    } catch (e) {
      // Silently fail - will be retried by sync service
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(
    String conversationId,
    String messageId,
  ) async {
    try {
      // Offline-first: Delete from local immediately
      await _localDataSource.deleteMessage(messageId);

      // Background delete from remote
      _syncDeleteToRemote(conversationId, messageId);

      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Future<void> _syncDeleteToRemote(
    String conversationId,
    String messageId,
  ) async {
    try {
      await _remoteDataSource.deleteMessage(conversationId, messageId);
    } catch (e) {
      // Silently fail - message is already deleted locally
    }
  }

  @override
  Stream<Either<Failure, List<Message>>> watchMessages({
    required String conversationId,
    required String currentUserId,
    int limit = 50,
  }) {
    try {
      // Watch Firestore for incoming messages
      // When new messages arrive, save them to local DB
      // Note: Delivery marking is handled by AutoDeliveryMarker service
      _remoteDataSource
          .watchMessages(conversationId: conversationId, limit: limit)
          .listen((messageModels) async {
            try {
              final messages = messageModels
                  .map((model) => model.toEntity())
                  .toList();

              // Upsert to local database (updates existing, inserts new)
              await _localDataSource.insertMessages(conversationId, messages);
            } catch (e) {
              // Silently fail - local stream will still work
            }
          });

      // Return local stream (which now gets updates from Firestore)
      final localStream = _localDataSource.watchMessages(
        conversationId: conversationId,
        limit: limit,
      );

      return localStream.map(
        Right<Failure, List<Message>>.new,
      );
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
      // Get message from local
      final message = await _localDataSource.getMessage(messageId);
      if (message == null) {
        return const Left(RecordNotFoundFailure(recordType: 'Message'));
      }

      // Offline-first: Update local immediately
      final updatedMessage = message.copyWith(status: 'delivered');

      await _localDataSource.updateMessage(conversationId, updatedMessage);

      // Background sync to remote
      _remoteDataSource.markAsDelivered(conversationId, messageId);

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
      // Get message from local
      final message = await _localDataSource.getMessage(messageId);
      if (message == null) {
        return const Left(RecordNotFoundFailure(recordType: 'Message'));
      }

      // Offline-first: Update local immediately
      final updatedMessage = message.copyWith(status: 'read');

      await _localDataSource.updateMessage(conversationId, updatedMessage);

      // Background sync to remote
      _remoteDataSource.markAsRead(conversationId, messageId);

      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
