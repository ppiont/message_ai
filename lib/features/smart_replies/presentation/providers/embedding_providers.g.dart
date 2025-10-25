// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'embedding_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for EmbeddingService (data layer).
///
/// This service handles communication with the Cloud Function to generate embeddings.

@ProviderFor(embeddingService)
const embeddingServiceProvider = EmbeddingServiceProvider._();

/// Provider for EmbeddingService (data layer).
///
/// This service handles communication with the Cloud Function to generate embeddings.

final class EmbeddingServiceProvider
    extends
        $FunctionalProvider<
          EmbeddingService,
          EmbeddingService,
          EmbeddingService
        >
    with $Provider<EmbeddingService> {
  /// Provider for EmbeddingService (data layer).
  ///
  /// This service handles communication with the Cloud Function to generate embeddings.
  const EmbeddingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'embeddingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$embeddingServiceHash();

  @$internal
  @override
  $ProviderElement<EmbeddingService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EmbeddingService create(Ref ref) {
    return embeddingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmbeddingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmbeddingService>(value),
    );
  }
}

String _$embeddingServiceHash() => r'd1598b969134896201bc4f92a2ec46fec0c8235f';

/// Provider for EmbeddingGenerator (domain layer).
///
/// This service orchestrates embedding generation for messages, handling both
/// real-time generation for new messages and background processing for historical messages.

@ProviderFor(embeddingGenerator)
const embeddingGeneratorProvider = EmbeddingGeneratorProvider._();

/// Provider for EmbeddingGenerator (domain layer).
///
/// This service orchestrates embedding generation for messages, handling both
/// real-time generation for new messages and background processing for historical messages.

final class EmbeddingGeneratorProvider
    extends
        $FunctionalProvider<
          EmbeddingGenerator,
          EmbeddingGenerator,
          EmbeddingGenerator
        >
    with $Provider<EmbeddingGenerator> {
  /// Provider for EmbeddingGenerator (domain layer).
  ///
  /// This service orchestrates embedding generation for messages, handling both
  /// real-time generation for new messages and background processing for historical messages.
  const EmbeddingGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'embeddingGeneratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$embeddingGeneratorHash();

  @$internal
  @override
  $ProviderElement<EmbeddingGenerator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EmbeddingGenerator create(Ref ref) {
    return embeddingGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmbeddingGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmbeddingGenerator>(value),
    );
  }
}

String _$embeddingGeneratorHash() =>
    r'ec30b6b2dddbe7f3a4fe700854ac33800d35945a';

/// Provider for SemanticSearchService (domain layer).
///
/// This service performs semantic search using cosine similarity on message embeddings
/// to find the most relevant context for RAG-based smart replies.

@ProviderFor(semanticSearchService)
const semanticSearchServiceProvider = SemanticSearchServiceProvider._();

/// Provider for SemanticSearchService (domain layer).
///
/// This service performs semantic search using cosine similarity on message embeddings
/// to find the most relevant context for RAG-based smart replies.

final class SemanticSearchServiceProvider
    extends
        $FunctionalProvider<
          SemanticSearchService,
          SemanticSearchService,
          SemanticSearchService
        >
    with $Provider<SemanticSearchService> {
  /// Provider for SemanticSearchService (domain layer).
  ///
  /// This service performs semantic search using cosine similarity on message embeddings
  /// to find the most relevant context for RAG-based smart replies.
  const SemanticSearchServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'semanticSearchServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$semanticSearchServiceHash();

  @$internal
  @override
  $ProviderElement<SemanticSearchService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SemanticSearchService create(Ref ref) {
    return semanticSearchService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SemanticSearchService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SemanticSearchService>(value),
    );
  }
}

String _$semanticSearchServiceHash() =>
    r'dc41839ebe940d63be728088f60805906a34dc81';

/// FutureProvider for searching relevant context messages.
///
/// Performs semantic search to find the most relevant messages in a conversation
/// for providing context to smart reply generation.
///
/// Parameters:
/// - conversationId: The conversation to search within
/// - message: The incoming message to find context for
/// - limit: Maximum number of results (default: 10)
///
/// Returns: List of most relevant messages, sorted by relevance

@ProviderFor(searchRelevantContext)
const searchRelevantContextProvider = SearchRelevantContextFamily._();

/// FutureProvider for searching relevant context messages.
///
/// Performs semantic search to find the most relevant messages in a conversation
/// for providing context to smart reply generation.
///
/// Parameters:
/// - conversationId: The conversation to search within
/// - message: The incoming message to find context for
/// - limit: Maximum number of results (default: 10)
///
/// Returns: List of most relevant messages, sorted by relevance

final class SearchRelevantContextProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Message>>,
          List<Message>,
          FutureOr<List<Message>>
        >
    with $FutureModifier<List<Message>>, $FutureProvider<List<Message>> {
  /// FutureProvider for searching relevant context messages.
  ///
  /// Performs semantic search to find the most relevant messages in a conversation
  /// for providing context to smart reply generation.
  ///
  /// Parameters:
  /// - conversationId: The conversation to search within
  /// - message: The incoming message to find context for
  /// - limit: Maximum number of results (default: 10)
  ///
  /// Returns: List of most relevant messages, sorted by relevance
  const SearchRelevantContextProvider._({
    required SearchRelevantContextFamily super.from,
    required (String, Message, {int limit}) super.argument,
  }) : super(
         retry: null,
         name: r'searchRelevantContextProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchRelevantContextHash();

  @override
  String toString() {
    return r'searchRelevantContextProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Message>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Message>> create(Ref ref) {
    final argument = this.argument as (String, Message, {int limit});
    return searchRelevantContext(
      ref,
      argument.$1,
      argument.$2,
      limit: argument.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchRelevantContextProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchRelevantContextHash() =>
    r'4d1aa5810ae7a4418202d9bdab5555be221679e3';

/// FutureProvider for searching relevant context messages.
///
/// Performs semantic search to find the most relevant messages in a conversation
/// for providing context to smart reply generation.
///
/// Parameters:
/// - conversationId: The conversation to search within
/// - message: The incoming message to find context for
/// - limit: Maximum number of results (default: 10)
///
/// Returns: List of most relevant messages, sorted by relevance

final class SearchRelevantContextFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Message>>,
          (String, Message, {int limit})
        > {
  const SearchRelevantContextFamily._()
    : super(
        retry: null,
        name: r'searchRelevantContextProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// FutureProvider for searching relevant context messages.
  ///
  /// Performs semantic search to find the most relevant messages in a conversation
  /// for providing context to smart reply generation.
  ///
  /// Parameters:
  /// - conversationId: The conversation to search within
  /// - message: The incoming message to find context for
  /// - limit: Maximum number of results (default: 10)
  ///
  /// Returns: List of most relevant messages, sorted by relevance

  SearchRelevantContextProvider call(
    String conversationId,
    Message message, {
    int limit = 10,
  }) => SearchRelevantContextProvider._(
    argument: (conversationId, message, limit: limit),
    from: this,
  );

  @override
  String toString() => r'searchRelevantContextProvider';
}
