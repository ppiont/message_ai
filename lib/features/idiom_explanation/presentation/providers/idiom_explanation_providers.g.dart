// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'idiom_explanation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for IdiomExplanationService
///
/// Singleton service for explaining idioms with PII detection,
/// retry logic, and caching

@ProviderFor(idiomExplanationService)
const idiomExplanationServiceProvider = IdiomExplanationServiceProvider._();

/// Provider for IdiomExplanationService
///
/// Singleton service for explaining idioms with PII detection,
/// retry logic, and caching

final class IdiomExplanationServiceProvider
    extends
        $FunctionalProvider<
          IdiomExplanationService,
          IdiomExplanationService,
          IdiomExplanationService
        >
    with $Provider<IdiomExplanationService> {
  /// Provider for IdiomExplanationService
  ///
  /// Singleton service for explaining idioms with PII detection,
  /// retry logic, and caching
  const IdiomExplanationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'idiomExplanationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$idiomExplanationServiceHash();

  @$internal
  @override
  $ProviderElement<IdiomExplanationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IdiomExplanationService create(Ref ref) {
    return idiomExplanationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdiomExplanationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IdiomExplanationService>(value),
    );
  }
}

String _$idiomExplanationServiceHash() =>
    r'170187870d481d0d250b8d60a902ac938e95098a';

/// Provider for idiom explanation state per message
///
/// This provider tracks the state of idiom explanation for a specific message.
/// The state includes loading, success with idiom list, or error with failure info.
///
/// Parameters:
/// - messageText: The message text to explain idioms for
/// - sourceLanguage: Source language code (e.g., 'en', 'es')
/// - targetLanguage: Target language code for equivalent expressions

@ProviderFor(IdiomExplanationStateNotifier)
const idiomExplanationStateProvider = IdiomExplanationStateNotifierFamily._();

/// Provider for idiom explanation state per message
///
/// This provider tracks the state of idiom explanation for a specific message.
/// The state includes loading, success with idiom list, or error with failure info.
///
/// Parameters:
/// - messageText: The message text to explain idioms for
/// - sourceLanguage: Source language code (e.g., 'en', 'es')
/// - targetLanguage: Target language code for equivalent expressions
final class IdiomExplanationStateNotifierProvider
    extends
        $NotifierProvider<
          IdiomExplanationStateNotifier,
          IdiomExplanationState
        > {
  /// Provider for idiom explanation state per message
  ///
  /// This provider tracks the state of idiom explanation for a specific message.
  /// The state includes loading, success with idiom list, or error with failure info.
  ///
  /// Parameters:
  /// - messageText: The message text to explain idioms for
  /// - sourceLanguage: Source language code (e.g., 'en', 'es')
  /// - targetLanguage: Target language code for equivalent expressions
  const IdiomExplanationStateNotifierProvider._({
    required IdiomExplanationStateNotifierFamily super.from,
    required ({
      String messageText,
      String sourceLanguage,
      String targetLanguage,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'idiomExplanationStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$idiomExplanationStateNotifierHash();

  @override
  String toString() {
    return r'idiomExplanationStateProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  IdiomExplanationStateNotifier create() => IdiomExplanationStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdiomExplanationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IdiomExplanationState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IdiomExplanationStateNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$idiomExplanationStateNotifierHash() =>
    r'f88b195c236358ba5a502648be6641c2bf60a879';

/// Provider for idiom explanation state per message
///
/// This provider tracks the state of idiom explanation for a specific message.
/// The state includes loading, success with idiom list, or error with failure info.
///
/// Parameters:
/// - messageText: The message text to explain idioms for
/// - sourceLanguage: Source language code (e.g., 'en', 'es')
/// - targetLanguage: Target language code for equivalent expressions

final class IdiomExplanationStateNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          IdiomExplanationStateNotifier,
          IdiomExplanationState,
          IdiomExplanationState,
          IdiomExplanationState,
          ({String messageText, String sourceLanguage, String targetLanguage})
        > {
  const IdiomExplanationStateNotifierFamily._()
    : super(
        retry: null,
        name: r'idiomExplanationStateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for idiom explanation state per message
  ///
  /// This provider tracks the state of idiom explanation for a specific message.
  /// The state includes loading, success with idiom list, or error with failure info.
  ///
  /// Parameters:
  /// - messageText: The message text to explain idioms for
  /// - sourceLanguage: Source language code (e.g., 'en', 'es')
  /// - targetLanguage: Target language code for equivalent expressions

  IdiomExplanationStateNotifierProvider call({
    required String messageText,
    required String sourceLanguage,
    required String targetLanguage,
  }) => IdiomExplanationStateNotifierProvider._(
    argument: (
      messageText: messageText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    ),
    from: this,
  );

  @override
  String toString() => r'idiomExplanationStateProvider';
}

/// Provider for idiom explanation state per message
///
/// This provider tracks the state of idiom explanation for a specific message.
/// The state includes loading, success with idiom list, or error with failure info.
///
/// Parameters:
/// - messageText: The message text to explain idioms for
/// - sourceLanguage: Source language code (e.g., 'en', 'es')
/// - targetLanguage: Target language code for equivalent expressions

abstract class _$IdiomExplanationStateNotifier
    extends $Notifier<IdiomExplanationState> {
  late final _$args =
      ref.$arg
          as ({
            String messageText,
            String sourceLanguage,
            String targetLanguage,
          });
  String get messageText => _$args.messageText;
  String get sourceLanguage => _$args.sourceLanguage;
  String get targetLanguage => _$args.targetLanguage;

  IdiomExplanationState build({
    required String messageText,
    required String sourceLanguage,
    required String targetLanguage,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      messageText: _$args.messageText,
      sourceLanguage: _$args.sourceLanguage,
      targetLanguage: _$args.targetLanguage,
    );
    final ref = this.ref as $Ref<IdiomExplanationState, IdiomExplanationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IdiomExplanationState, IdiomExplanationState>,
              IdiomExplanationState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for explaining idioms in a message
///
/// This is a convenience provider that automatically explains idioms
/// when first accessed.
///
/// Usage:
/// ```dart
/// final state = ref.watch(explainIdiomsProvider(
///   messageText: 'Break a leg!',
///   sourceLanguage: 'en',
///   targetLanguage: 'es',
/// ));
/// ```

@ProviderFor(explainIdioms)
const explainIdiomsProvider = ExplainIdiomsFamily._();

/// Provider for explaining idioms in a message
///
/// This is a convenience provider that automatically explains idioms
/// when first accessed.
///
/// Usage:
/// ```dart
/// final state = ref.watch(explainIdiomsProvider(
///   messageText: 'Break a leg!',
///   sourceLanguage: 'en',
///   targetLanguage: 'es',
/// ));
/// ```

final class ExplainIdiomsProvider
    extends
        $FunctionalProvider<
          AsyncValue<IdiomExplanationState>,
          IdiomExplanationState,
          FutureOr<IdiomExplanationState>
        >
    with
        $FutureModifier<IdiomExplanationState>,
        $FutureProvider<IdiomExplanationState> {
  /// Provider for explaining idioms in a message
  ///
  /// This is a convenience provider that automatically explains idioms
  /// when first accessed.
  ///
  /// Usage:
  /// ```dart
  /// final state = ref.watch(explainIdiomsProvider(
  ///   messageText: 'Break a leg!',
  ///   sourceLanguage: 'en',
  ///   targetLanguage: 'es',
  /// ));
  /// ```
  const ExplainIdiomsProvider._({
    required ExplainIdiomsFamily super.from,
    required ({
      String messageText,
      String sourceLanguage,
      String targetLanguage,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'explainIdiomsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$explainIdiomsHash();

  @override
  String toString() {
    return r'explainIdiomsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<IdiomExplanationState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<IdiomExplanationState> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String messageText,
              String sourceLanguage,
              String targetLanguage,
            });
    return explainIdioms(
      ref,
      messageText: argument.messageText,
      sourceLanguage: argument.sourceLanguage,
      targetLanguage: argument.targetLanguage,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExplainIdiomsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$explainIdiomsHash() => r'32cf6a8d7f2a08d5457e24e60f0671e2dd701849';

/// Provider for explaining idioms in a message
///
/// This is a convenience provider that automatically explains idioms
/// when first accessed.
///
/// Usage:
/// ```dart
/// final state = ref.watch(explainIdiomsProvider(
///   messageText: 'Break a leg!',
///   sourceLanguage: 'en',
///   targetLanguage: 'es',
/// ));
/// ```

final class ExplainIdiomsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<IdiomExplanationState>,
          ({String messageText, String sourceLanguage, String targetLanguage})
        > {
  const ExplainIdiomsFamily._()
    : super(
        retry: null,
        name: r'explainIdiomsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for explaining idioms in a message
  ///
  /// This is a convenience provider that automatically explains idioms
  /// when first accessed.
  ///
  /// Usage:
  /// ```dart
  /// final state = ref.watch(explainIdiomsProvider(
  ///   messageText: 'Break a leg!',
  ///   sourceLanguage: 'en',
  ///   targetLanguage: 'es',
  /// ));
  /// ```

  ExplainIdiomsProvider call({
    required String messageText,
    required String sourceLanguage,
    required String targetLanguage,
  }) => ExplainIdiomsProvider._(
    argument: (
      messageText: messageText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    ),
    from: this,
  );

  @override
  String toString() => r'explainIdiomsProvider';
}
