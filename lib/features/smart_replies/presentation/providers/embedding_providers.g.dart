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
