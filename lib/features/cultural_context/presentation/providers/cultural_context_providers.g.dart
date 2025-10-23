// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cultural_context_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for Firebase Functions instance

@ProviderFor(firebaseFunctions)
const firebaseFunctionsProvider = FirebaseFunctionsProvider._();

/// Provider for Firebase Functions instance

final class FirebaseFunctionsProvider
    extends
        $FunctionalProvider<
          FirebaseFunctions,
          FirebaseFunctions,
          FirebaseFunctions
        >
    with $Provider<FirebaseFunctions> {
  /// Provider for Firebase Functions instance
  const FirebaseFunctionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseFunctionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseFunctionsHash();

  @$internal
  @override
  $ProviderElement<FirebaseFunctions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFunctions create(Ref ref) {
    return firebaseFunctions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFunctions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFunctions>(value),
    );
  }
}

String _$firebaseFunctionsHash() => r'666a7e2cbe9f95968c7e945fc2b6b378b40c140d';

/// Provider for cultural context service

@ProviderFor(culturalContextService)
const culturalContextServiceProvider = CulturalContextServiceProvider._();

/// Provider for cultural context service

final class CulturalContextServiceProvider
    extends
        $FunctionalProvider<
          CulturalContextService,
          CulturalContextService,
          CulturalContextService
        >
    with $Provider<CulturalContextService> {
  /// Provider for cultural context service
  const CulturalContextServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'culturalContextServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$culturalContextServiceHash();

  @$internal
  @override
  $ProviderElement<CulturalContextService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CulturalContextService create(Ref ref) {
    return culturalContextService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CulturalContextService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CulturalContextService>(value),
    );
  }
}

String _$culturalContextServiceHash() =>
    r'3070cf68fe06a58f375f9c3f61acd1f82abce0fb';

/// Provider for analyze message cultural context use case

@ProviderFor(analyzeMessageCulturalContext)
const analyzeMessageCulturalContextProvider =
    AnalyzeMessageCulturalContextProvider._();

/// Provider for analyze message cultural context use case

final class AnalyzeMessageCulturalContextProvider
    extends
        $FunctionalProvider<
          AnalyzeMessageCulturalContext,
          AnalyzeMessageCulturalContext,
          AnalyzeMessageCulturalContext
        >
    with $Provider<AnalyzeMessageCulturalContext> {
  /// Provider for analyze message cultural context use case
  const AnalyzeMessageCulturalContextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyzeMessageCulturalContextProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyzeMessageCulturalContextHash();

  @$internal
  @override
  $ProviderElement<AnalyzeMessageCulturalContext> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnalyzeMessageCulturalContext create(Ref ref) {
    return analyzeMessageCulturalContext(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyzeMessageCulturalContext value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyzeMessageCulturalContext>(
        value,
      ),
    );
  }
}

String _$analyzeMessageCulturalContextHash() =>
    r'728278c067d9ac4b8b8c951511892664aa973c79';
