// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messagingFirestoreHash() =>
    r'075f59e78a7b16cab126cf43dfd452c86998e781';

/// Provides the FirebaseFirestore instance for messaging operations.
///
/// Copied from [messagingFirestore].
@ProviderFor(messagingFirestore)
final messagingFirestoreProvider =
    AutoDisposeProvider<FirebaseFirestore>.internal(
      messagingFirestore,
      name: r'messagingFirestoreProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$messagingFirestoreHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MessagingFirestoreRef = AutoDisposeProviderRef<FirebaseFirestore>;
String _$messageRemoteDataSourceHash() =>
    r'3bf4eecac4b81321a843d236e9c2fa7abc9e0655';

/// Provides the [MessageRemoteDataSource] implementation.
///
/// Copied from [messageRemoteDataSource].
@ProviderFor(messageRemoteDataSource)
final messageRemoteDataSourceProvider =
    AutoDisposeProvider<MessageRemoteDataSource>.internal(
      messageRemoteDataSource,
      name: r'messageRemoteDataSourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$messageRemoteDataSourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MessageRemoteDataSourceRef =
    AutoDisposeProviderRef<MessageRemoteDataSource>;
String _$conversationRemoteDataSourceHash() =>
    r'56b43642c6ec61a3d0fc58f25afa73afe00fb395';

/// Provides the [ConversationRemoteDataSource] implementation.
///
/// Copied from [conversationRemoteDataSource].
@ProviderFor(conversationRemoteDataSource)
final conversationRemoteDataSourceProvider =
    AutoDisposeProvider<ConversationRemoteDataSource>.internal(
      conversationRemoteDataSource,
      name: r'conversationRemoteDataSourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$conversationRemoteDataSourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConversationRemoteDataSourceRef =
    AutoDisposeProviderRef<ConversationRemoteDataSource>;
String _$messageRepositoryHash() => r'64198466d7b1525d08d4fe8cf0fdbcb8bcf71efb';

/// Provides the [MessageRepository] implementation.
///
/// Copied from [messageRepository].
@ProviderFor(messageRepository)
final messageRepositoryProvider =
    AutoDisposeProvider<MessageRepository>.internal(
      messageRepository,
      name: r'messageRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$messageRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MessageRepositoryRef = AutoDisposeProviderRef<MessageRepository>;
String _$conversationRepositoryHash() =>
    r'e4c92eac36c3008160bbbca958e50f5fb245a371';

/// Provides the [ConversationRepository] implementation.
///
/// Copied from [conversationRepository].
@ProviderFor(conversationRepository)
final conversationRepositoryProvider =
    AutoDisposeProvider<ConversationRepository>.internal(
      conversationRepository,
      name: r'conversationRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$conversationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConversationRepositoryRef =
    AutoDisposeProviderRef<ConversationRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
