// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_detection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the language detection service.
///
/// Creates a single instance of [LanguageDetectionService] that is shared
/// across the app. Uses keepAlive to maintain singleton pattern and prevent
/// multiple instances from being created on every MessageBubble render.
/// The service is properly disposed when no longer needed.

@ProviderFor(languageDetectionService)
const languageDetectionServiceProvider = LanguageDetectionServiceProvider._();

/// Provider for the language detection service.
///
/// Creates a single instance of [LanguageDetectionService] that is shared
/// across the app. Uses keepAlive to maintain singleton pattern and prevent
/// multiple instances from being created on every MessageBubble render.
/// The service is properly disposed when no longer needed.

final class LanguageDetectionServiceProvider
    extends
        $FunctionalProvider<
          LanguageDetectionService,
          LanguageDetectionService,
          LanguageDetectionService
        >
    with $Provider<LanguageDetectionService> {
  /// Provider for the language detection service.
  ///
  /// Creates a single instance of [LanguageDetectionService] that is shared
  /// across the app. Uses keepAlive to maintain singleton pattern and prevent
  /// multiple instances from being created on every MessageBubble render.
  /// The service is properly disposed when no longer needed.
  const LanguageDetectionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'languageDetectionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$languageDetectionServiceHash();

  @$internal
  @override
  $ProviderElement<LanguageDetectionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LanguageDetectionService create(Ref ref) {
    return languageDetectionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LanguageDetectionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LanguageDetectionService>(value),
    );
  }
}

String _$languageDetectionServiceHash() =>
    r'2fe82b441799e952f349ad61edc633291bbbd173';
