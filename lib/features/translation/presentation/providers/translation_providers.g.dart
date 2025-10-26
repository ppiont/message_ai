// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for TranslationService

@ProviderFor(translationService)
const translationServiceProvider = TranslationServiceProvider._();

/// Provider for TranslationService

final class TranslationServiceProvider
    extends
        $FunctionalProvider<
          TranslationService,
          TranslationService,
          TranslationService
        >
    with $Provider<TranslationService> {
  /// Provider for TranslationService
  const TranslationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'translationServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$translationServiceHash();

  @$internal
  @override
  $ProviderElement<TranslationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TranslationService create(Ref ref) {
    return translationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TranslationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TranslationService>(value),
    );
  }
}

String _$translationServiceHash() =>
    r'e97dbffea45ad9313746c8128a2484cc2db55963';

/// Provider for TranslateMessage use case

@ProviderFor(translateMessage)
const translateMessageProvider = TranslateMessageProvider._();

/// Provider for TranslateMessage use case

final class TranslateMessageProvider
    extends
        $FunctionalProvider<
          TranslateMessage,
          TranslateMessage,
          TranslateMessage
        >
    with $Provider<TranslateMessage> {
  /// Provider for TranslateMessage use case
  const TranslateMessageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'translateMessageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$translateMessageHash();

  @$internal
  @override
  $ProviderElement<TranslateMessage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TranslateMessage create(Ref ref) {
    return translateMessage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TranslateMessage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TranslateMessage>(value),
    );
  }
}

String _$translateMessageHash() => r'6b8f638d93a58995fce07c47b26ef5d97e7fcbd1';

/// Provider for AutoTranslationService
///
/// This service automatically translates incoming messages based on user preferences.
/// Properly disposes of the service and cancels all subscriptions when no longer needed.
/// The service instance is auto-disposed when not actively watched, preventing memory leaks.

@ProviderFor(autoTranslationService)
const autoTranslationServiceProvider = AutoTranslationServiceProvider._();

/// Provider for AutoTranslationService
///
/// This service automatically translates incoming messages based on user preferences.
/// Properly disposes of the service and cancels all subscriptions when no longer needed.
/// The service instance is auto-disposed when not actively watched, preventing memory leaks.

final class AutoTranslationServiceProvider
    extends
        $FunctionalProvider<
          AutoTranslationService,
          AutoTranslationService,
          AutoTranslationService
        >
    with $Provider<AutoTranslationService> {
  /// Provider for AutoTranslationService
  ///
  /// This service automatically translates incoming messages based on user preferences.
  /// Properly disposes of the service and cancels all subscriptions when no longer needed.
  /// The service instance is auto-disposed when not actively watched, preventing memory leaks.
  const AutoTranslationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoTranslationServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoTranslationServiceHash();

  @$internal
  @override
  $ProviderElement<AutoTranslationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AutoTranslationService create(Ref ref) {
    return autoTranslationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutoTranslationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutoTranslationService>(value),
    );
  }
}

String _$autoTranslationServiceHash() =>
    r'ec5c564c3633c9fae24eef1b7ffce5226e409725';
