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

/// Provider for cultural context queue DAO

@ProviderFor(culturalContextQueueDao)
const culturalContextQueueDaoProvider = CulturalContextQueueDaoProvider._();

/// Provider for cultural context queue DAO

final class CulturalContextQueueDaoProvider
    extends
        $FunctionalProvider<
          CulturalContextQueueDao,
          CulturalContextQueueDao,
          CulturalContextQueueDao
        >
    with $Provider<CulturalContextQueueDao> {
  /// Provider for cultural context queue DAO
  const CulturalContextQueueDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'culturalContextQueueDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$culturalContextQueueDaoHash();

  @$internal
  @override
  $ProviderElement<CulturalContextQueueDao> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CulturalContextQueueDao create(Ref ref) {
    return culturalContextQueueDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CulturalContextQueueDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CulturalContextQueueDao>(value),
    );
  }
}

String _$culturalContextQueueDaoHash() =>
    r'b7c19af73ba6d65f486d88a9a44807eb4fc437b7';

/// Provider for cultural context queue (event-driven processing)
///
/// Processes items immediately when enqueued (no polling).
/// On startup, resumes any pending items from previous session.

@ProviderFor(culturalContextQueue)
const culturalContextQueueProvider = CulturalContextQueueProvider._();

/// Provider for cultural context queue (event-driven processing)
///
/// Processes items immediately when enqueued (no polling).
/// On startup, resumes any pending items from previous session.

final class CulturalContextQueueProvider
    extends
        $FunctionalProvider<
          CulturalContextQueue,
          CulturalContextQueue,
          CulturalContextQueue
        >
    with $Provider<CulturalContextQueue> {
  /// Provider for cultural context queue (event-driven processing)
  ///
  /// Processes items immediately when enqueued (no polling).
  /// On startup, resumes any pending items from previous session.
  const CulturalContextQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'culturalContextQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$culturalContextQueueHash();

  @$internal
  @override
  $ProviderElement<CulturalContextQueue> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CulturalContextQueue create(Ref ref) {
    return culturalContextQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CulturalContextQueue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CulturalContextQueue>(value),
    );
  }
}

String _$culturalContextQueueHash() =>
    r'17a90a6ad56bdf04cd0af98f08f347164a405881';

/// Provider for cultural context analyzer (background service)

@ProviderFor(culturalContextAnalyzer)
const culturalContextAnalyzerProvider = CulturalContextAnalyzerProvider._();

/// Provider for cultural context analyzer (background service)

final class CulturalContextAnalyzerProvider
    extends
        $FunctionalProvider<
          CulturalContextAnalyzer,
          CulturalContextAnalyzer,
          CulturalContextAnalyzer
        >
    with $Provider<CulturalContextAnalyzer> {
  /// Provider for cultural context analyzer (background service)
  const CulturalContextAnalyzerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'culturalContextAnalyzerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$culturalContextAnalyzerHash();

  @$internal
  @override
  $ProviderElement<CulturalContextAnalyzer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CulturalContextAnalyzer create(Ref ref) {
    return culturalContextAnalyzer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CulturalContextAnalyzer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CulturalContextAnalyzer>(value),
    );
  }
}

String _$culturalContextAnalyzerHash() =>
    r'e7c4eb1d4794c05f916427ba7e0d2466885b7d0c';

/// Provider for cultural context state per message
///
/// This provider tracks the analysis state for a specific message.
/// Returns CulturalContextState (Loading, Success, or Error)

@ProviderFor(culturalContextState)
const culturalContextStateProvider = CulturalContextStateFamily._();

/// Provider for cultural context state per message
///
/// This provider tracks the analysis state for a specific message.
/// Returns CulturalContextState (Loading, Success, or Error)

final class CulturalContextStateProvider
    extends
        $FunctionalProvider<
          CulturalContextState,
          CulturalContextState,
          CulturalContextState
        >
    with $Provider<CulturalContextState> {
  /// Provider for cultural context state per message
  ///
  /// This provider tracks the analysis state for a specific message.
  /// Returns CulturalContextState (Loading, Success, or Error)
  const CulturalContextStateProvider._({
    required CulturalContextStateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'culturalContextStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$culturalContextStateHash();

  @override
  String toString() {
    return r'culturalContextStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<CulturalContextState> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CulturalContextState create(Ref ref) {
    final argument = this.argument as String;
    return culturalContextState(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CulturalContextState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CulturalContextState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CulturalContextStateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$culturalContextStateHash() =>
    r'b17462bfbf2755534aaddd047855e88cf00013f8';

/// Provider for cultural context state per message
///
/// This provider tracks the analysis state for a specific message.
/// Returns CulturalContextState (Loading, Success, or Error)

final class CulturalContextStateFamily extends $Family
    with $FunctionalFamilyOverride<CulturalContextState, String> {
  const CulturalContextStateFamily._()
    : super(
        retry: null,
        name: r'culturalContextStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for cultural context state per message
  ///
  /// This provider tracks the analysis state for a specific message.
  /// Returns CulturalContextState (Loading, Success, or Error)

  CulturalContextStateProvider call(String messageId) =>
      CulturalContextStateProvider._(argument: messageId, from: this);

  @override
  String toString() => r'culturalContextStateProvider';
}

/// Provider for queue statistics (for debugging)

@ProviderFor(culturalContextQueueStats)
const culturalContextQueueStatsProvider = CulturalContextQueueStatsProvider._();

/// Provider for queue statistics (for debugging)

final class CulturalContextQueueStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, int>>,
          Map<String, int>,
          FutureOr<Map<String, int>>
        >
    with $FutureModifier<Map<String, int>>, $FutureProvider<Map<String, int>> {
  /// Provider for queue statistics (for debugging)
  const CulturalContextQueueStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'culturalContextQueueStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$culturalContextQueueStatsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, int>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, int>> create(Ref ref) {
    return culturalContextQueueStats(ref);
  }
}

String _$culturalContextQueueStatsHash() =>
    r'7ee1fd7f46495dfa428a2068ea4f1125aa3230dc';
