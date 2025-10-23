/// Riverpod providers for user profile operations
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:message_ai/core/providers/database_provider.dart';
import 'package:message_ai/features/authentication/data/datasources/user_remote_datasource.dart';
import 'package:message_ai/features/authentication/data/repositories/user_repository_impl.dart';
import 'package:message_ai/features/authentication/data/services/user_cache_service.dart';
import 'package:message_ai/features/authentication/domain/repositories/user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_providers.g.dart';

/// Provider for FirebaseFirestore instance
@riverpod
FirebaseFirestore firebaseFirestore(Ref ref) => FirebaseFirestore.instance;

/// Provider for UserRemoteDataSource
@riverpod
UserRemoteDataSource userRemoteDataSource(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return UserRemoteDataSourceImpl(firestore: firestore);
}

/// Provider for UserRepository
@riverpod
UserRepository userRepository(Ref ref) {
  final remoteDataSource = ref.watch(userRemoteDataSourceProvider);
  return UserRepositoryImpl(remoteDataSource: remoteDataSource);
}

/// Provider for UserCacheService
@riverpod
UserCacheService userCacheService(Ref ref) {
  final database = ref.watch(databaseProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return UserCacheService(
    database: database,
    userRepository: userRepository,
  );
}
