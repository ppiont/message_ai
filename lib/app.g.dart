// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Initializes app services asynchronously without blocking the UI
///
/// This provider ensures services are initialized AFTER the widget tree is built,
/// preventing main thread blocking during app startup.

@ProviderFor(servicesInitializer)
const servicesInitializerProvider = ServicesInitializerProvider._();

/// Initializes app services asynchronously without blocking the UI
///
/// This provider ensures services are initialized AFTER the widget tree is built,
/// preventing main thread blocking during app startup.

final class ServicesInitializerProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Initializes app services asynchronously without blocking the UI
  ///
  /// This provider ensures services are initialized AFTER the widget tree is built,
  /// preventing main thread blocking during app startup.
  const ServicesInitializerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'servicesInitializerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$servicesInitializerHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return servicesInitializer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$servicesInitializerHash() =>
    r'e48bc0933cb6574667b26458df3e554868b3594f';
