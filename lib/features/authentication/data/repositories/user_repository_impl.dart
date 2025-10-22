/// Implementation of UserRepository using Firestore
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/error_mapper.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/data/datasources/user_remote_datasource.dart';
import 'package:message_ai/features/authentication/data/models/user_model.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/user_repository.dart';

/// Implementation of UserRepository
class UserRepositoryImpl implements UserRepository {

  UserRepositoryImpl({required UserRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;
  final UserRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, User>> createUser(User user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      final result = await _remoteDataSource.createUser(userModel);
      return Right(result.toEntity());
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, User>> getUserById(String userId) async {
    try {
      final result = await _remoteDataSource.getUserById(userId);
      return Right(result.toEntity());
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, User?>> getUserByEmail(String email) async {
    try {
      final result = await _remoteDataSource.getUserByEmail(email);
      return Right(result?.toEntity());
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, User?>> getUserByPhoneNumber(
    String phoneNumber,
  ) async {
    try {
      final result = await _remoteDataSource.getUserByPhoneNumber(phoneNumber);
      return Right(result?.toEntity());
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, User>> updateUser(User user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      final result = await _remoteDataSource.updateUser(userModel);
      return Right(result.toEntity());
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserOnlineStatus(
    String userId,
    bool isOnline,
  ) async {
    try {
      await _remoteDataSource.updateUserOnlineStatus(userId, isOnline);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserLastSeen(
    String userId,
    DateTime lastSeen,
  ) async {
    try {
      await _remoteDataSource.updateUserLastSeen(userId, lastSeen);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserFcmToken(
    String userId,
    String fcmToken,
  ) async {
    try {
      await _remoteDataSource.updateUserFcmToken(userId, fcmToken);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await _remoteDataSource.deleteUser(userId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    }
  }

  @override
  Stream<Either<Failure, User>> watchUser(String userId) {
    try {
      return _remoteDataSource
          .watchUser(userId)
          .map((userModel) => Right<Failure, User>(userModel.toEntity()));
    } on AppException catch (e) {
      return Stream.value(Left(ErrorMapper.mapExceptionToFailure(e)));
    }
  }

  @override
  Future<Either<Failure, bool>> userExists(String userId) async {
    try {
      final result = await _remoteDataSource.userExists(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    }
  }
}
