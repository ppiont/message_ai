// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_core_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the FirebaseFirestore instance for messaging operations.

@ProviderFor(messagingFirestore)
const messagingFirestoreProvider = MessagingFirestoreProvider._();

/// Provides the FirebaseFirestore instance for messaging operations.

final class MessagingFirestoreProvider
    extends
        $FunctionalProvider<
          FirebaseFirestore,
          FirebaseFirestore,
          FirebaseFirestore
        >
    with $Provider<FirebaseFirestore> {
  /// Provides the FirebaseFirestore instance for messaging operations.
  const MessagingFirestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagingFirestoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagingFirestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return messagingFirestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$messagingFirestoreHash() =>
    r'4ff31a34ec4cb93c8424dba92ae379f9738a20a2';
