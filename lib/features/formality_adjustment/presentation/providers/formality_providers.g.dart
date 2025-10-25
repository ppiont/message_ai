// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'formality_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for FormalityAdjustmentService

@ProviderFor(formalityService)
const formalityServiceProvider = FormalityServiceProvider._();

/// Provider for FormalityAdjustmentService

final class FormalityServiceProvider
    extends
        $FunctionalProvider<
          FormalityAdjustmentService,
          FormalityAdjustmentService,
          FormalityAdjustmentService
        >
    with $Provider<FormalityAdjustmentService> {
  /// Provider for FormalityAdjustmentService
  const FormalityServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'formalityServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$formalityServiceHash();

  @$internal
  @override
  $ProviderElement<FormalityAdjustmentService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FormalityAdjustmentService create(Ref ref) {
    return formalityService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FormalityAdjustmentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FormalityAdjustmentService>(value),
    );
  }
}

String _$formalityServiceHash() => r'1cb5d4e22b33d9f3c6b41e7de30bbb0f45de4b06';

/// Provider for AdjustMessageFormality use case

@ProviderFor(adjustMessageFormality)
const adjustMessageFormalityProvider = AdjustMessageFormalityProvider._();

/// Provider for AdjustMessageFormality use case

final class AdjustMessageFormalityProvider
    extends
        $FunctionalProvider<
          AdjustMessageFormality,
          AdjustMessageFormality,
          AdjustMessageFormality
        >
    with $Provider<AdjustMessageFormality> {
  /// Provider for AdjustMessageFormality use case
  const AdjustMessageFormalityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adjustMessageFormalityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adjustMessageFormalityHash();

  @$internal
  @override
  $ProviderElement<AdjustMessageFormality> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdjustMessageFormality create(Ref ref) {
    return adjustMessageFormality(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdjustMessageFormality value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdjustMessageFormality>(value),
    );
  }
}

String _$adjustMessageFormalityHash() =>
    r'ef10f7cdcf7d9ea64528ee50273ef3002d0b8fc0';

/// Provider for adjusting formality with state management
///
/// This provider takes the parameters and returns a FormalityState
/// representing the current state of the adjustment operation.

@ProviderFor(adjustFormality)
const adjustFormalityProvider = AdjustFormalityFamily._();

/// Provider for adjusting formality with state management
///
/// This provider takes the parameters and returns a FormalityState
/// representing the current state of the adjustment operation.

final class AdjustFormalityProvider
    extends
        $FunctionalProvider<
          AsyncValue<FormalityState>,
          FormalityState,
          FutureOr<FormalityState>
        >
    with $FutureModifier<FormalityState>, $FutureProvider<FormalityState> {
  /// Provider for adjusting formality with state management
  ///
  /// This provider takes the parameters and returns a FormalityState
  /// representing the current state of the adjustment operation.
  const AdjustFormalityProvider._({
    required AdjustFormalityFamily super.from,
    required ({
      String text,
      FormalityLevel targetFormality,
      FormalityLevel? currentFormality,
      String? language,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'adjustFormalityProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$adjustFormalityHash();

  @override
  String toString() {
    return r'adjustFormalityProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<FormalityState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FormalityState> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String text,
              FormalityLevel targetFormality,
              FormalityLevel? currentFormality,
              String? language,
            });
    return adjustFormality(
      ref,
      text: argument.text,
      targetFormality: argument.targetFormality,
      currentFormality: argument.currentFormality,
      language: argument.language,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdjustFormalityProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adjustFormalityHash() => r'b0bd861fb82b29c83ab3df74cc6c8e64359fec69';

/// Provider for adjusting formality with state management
///
/// This provider takes the parameters and returns a FormalityState
/// representing the current state of the adjustment operation.

final class AdjustFormalityFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<FormalityState>,
          ({
            String text,
            FormalityLevel targetFormality,
            FormalityLevel? currentFormality,
            String? language,
          })
        > {
  const AdjustFormalityFamily._()
    : super(
        retry: null,
        name: r'adjustFormalityProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for adjusting formality with state management
  ///
  /// This provider takes the parameters and returns a FormalityState
  /// representing the current state of the adjustment operation.

  AdjustFormalityProvider call({
    required String text,
    required FormalityLevel targetFormality,
    FormalityLevel? currentFormality,
    String? language,
  }) => AdjustFormalityProvider._(
    argument: (
      text: text,
      targetFormality: targetFormality,
      currentFormality: currentFormality,
      language: language,
    ),
    from: this,
  );

  @override
  String toString() => r'adjustFormalityProvider';
}

/// Provider for detecting formality level
///
/// This provider detects the formality level of a message without adjusting it.

@ProviderFor(detectFormality)
const detectFormalityProvider = DetectFormalityFamily._();

/// Provider for detecting formality level
///
/// This provider detects the formality level of a message without adjusting it.

final class DetectFormalityProvider
    extends
        $FunctionalProvider<
          AsyncValue<Either<Failure, FormalityLevel>>,
          Either<Failure, FormalityLevel>,
          FutureOr<Either<Failure, FormalityLevel>>
        >
    with
        $FutureModifier<Either<Failure, FormalityLevel>>,
        $FutureProvider<Either<Failure, FormalityLevel>> {
  /// Provider for detecting formality level
  ///
  /// This provider detects the formality level of a message without adjusting it.
  const DetectFormalityProvider._({
    required DetectFormalityFamily super.from,
    required ({String text, String? language}) super.argument,
  }) : super(
         retry: null,
         name: r'detectFormalityProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$detectFormalityHash();

  @override
  String toString() {
    return r'detectFormalityProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Either<Failure, FormalityLevel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Either<Failure, FormalityLevel>> create(Ref ref) {
    final argument = this.argument as ({String text, String? language});
    return detectFormality(
      ref,
      text: argument.text,
      language: argument.language,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DetectFormalityProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$detectFormalityHash() => r'6acd5bb0f561d15d279385a119446a6482cd13ad';

/// Provider for detecting formality level
///
/// This provider detects the formality level of a message without adjusting it.

final class DetectFormalityFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Either<Failure, FormalityLevel>>,
          ({String text, String? language})
        > {
  const DetectFormalityFamily._()
    : super(
        retry: null,
        name: r'detectFormalityProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for detecting formality level
  ///
  /// This provider detects the formality level of a message without adjusting it.

  DetectFormalityProvider call({required String text, String? language}) =>
      DetectFormalityProvider._(
        argument: (text: text, language: language),
        from: this,
      );

  @override
  String toString() => r'detectFormalityProvider';
}

/// State provider for formality adjustment with FormalityState
///
/// This is an alternative to the existing FormalityController for components
/// that want to use the sealed FormalityState pattern.

@ProviderFor(FormalityStateNotifier)
const formalityStateProvider = FormalityStateNotifierProvider._();

/// State provider for formality adjustment with FormalityState
///
/// This is an alternative to the existing FormalityController for components
/// that want to use the sealed FormalityState pattern.
final class FormalityStateNotifierProvider
    extends $NotifierProvider<FormalityStateNotifier, FormalityState> {
  /// State provider for formality adjustment with FormalityState
  ///
  /// This is an alternative to the existing FormalityController for components
  /// that want to use the sealed FormalityState pattern.
  const FormalityStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'formalityStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$formalityStateNotifierHash();

  @$internal
  @override
  FormalityStateNotifier create() => FormalityStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FormalityState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FormalityState>(value),
    );
  }
}

String _$formalityStateNotifierHash() =>
    r'dd64e8dd3e8e6e6a7add34427f12c8254f0c681b';

/// State provider for formality adjustment with FormalityState
///
/// This is an alternative to the existing FormalityController for components
/// that want to use the sealed FormalityState pattern.

abstract class _$FormalityStateNotifier extends $Notifier<FormalityState> {
  FormalityState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<FormalityState, FormalityState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FormalityState, FormalityState>,
              FormalityState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
