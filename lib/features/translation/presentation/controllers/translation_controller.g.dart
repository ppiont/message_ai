// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller for managing translation state across all messages

@ProviderFor(TranslationController)
const translationControllerProvider = TranslationControllerProvider._();

/// Controller for managing translation state across all messages
final class TranslationControllerProvider
    extends
        $NotifierProvider<
          TranslationController,
          Map<String, MessageTranslationState>
        > {
  /// Controller for managing translation state across all messages
  const TranslationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'translationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$translationControllerHash();

  @$internal
  @override
  TranslationController create() => TranslationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, MessageTranslationState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<String, MessageTranslationState>>(value),
    );
  }
}

String _$translationControllerHash() =>
    r'4419b77e13078fb4a0f2bc5487aa37d3a65b3551';

/// Controller for managing translation state across all messages

abstract class _$TranslationController
    extends $Notifier<Map<String, MessageTranslationState>> {
  Map<String, MessageTranslationState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              Map<String, MessageTranslationState>,
              Map<String, MessageTranslationState>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, MessageTranslationState>,
                Map<String, MessageTranslationState>
              >,
              Map<String, MessageTranslationState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
