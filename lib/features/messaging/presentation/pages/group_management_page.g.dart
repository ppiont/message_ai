// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_management_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for getting a conversation by ID.

@ProviderFor(getConversationById)
const getConversationByIdProvider = GetConversationByIdFamily._();

/// Provider for getting a conversation by ID.

final class GetConversationByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Conversation>,
          Conversation,
          FutureOr<Conversation>
        >
    with $FutureModifier<Conversation>, $FutureProvider<Conversation> {
  /// Provider for getting a conversation by ID.
  const GetConversationByIdProvider._({
    required GetConversationByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getConversationByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getConversationByIdHash();

  @override
  String toString() {
    return r'getConversationByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Conversation> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Conversation> create(Ref ref) {
    final argument = this.argument as String;
    return getConversationById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetConversationByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getConversationByIdHash() =>
    r'68c5958370dd9de3a0126f84c95da7eeec423c8e';

/// Provider for getting a conversation by ID.

final class GetConversationByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Conversation>, String> {
  const GetConversationByIdFamily._()
    : super(
        retry: null,
        name: r'getConversationByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting a conversation by ID.

  GetConversationByIdProvider call(String conversationId) =>
      GetConversationByIdProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'getConversationByIdProvider';
}
