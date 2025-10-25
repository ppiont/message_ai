// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_reply_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for SmartReplyService

@ProviderFor(smartReplyService)
const smartReplyServiceProvider = SmartReplyServiceProvider._();

/// Provider for SmartReplyService

final class SmartReplyServiceProvider
    extends
        $FunctionalProvider<
          SmartReplyService,
          SmartReplyService,
          SmartReplyService
        >
    with $Provider<SmartReplyService> {
  /// Provider for SmartReplyService
  const SmartReplyServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartReplyServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartReplyServiceHash();

  @$internal
  @override
  $ProviderElement<SmartReplyService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SmartReplyService create(Ref ref) {
    return smartReplyService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SmartReplyService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SmartReplyService>(value),
    );
  }
}

String _$smartReplyServiceHash() => r'c4c1e209d6a201ea0b575f68bbd717f96c82febd';

/// Provider for SmartReplyGenerator

@ProviderFor(smartReplyGenerator)
const smartReplyGeneratorProvider = SmartReplyGeneratorProvider._();

/// Provider for SmartReplyGenerator

final class SmartReplyGeneratorProvider
    extends
        $FunctionalProvider<
          SmartReplyGenerator,
          SmartReplyGenerator,
          SmartReplyGenerator
        >
    with $Provider<SmartReplyGenerator> {
  /// Provider for SmartReplyGenerator
  const SmartReplyGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'smartReplyGeneratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$smartReplyGeneratorHash();

  @$internal
  @override
  $ProviderElement<SmartReplyGenerator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SmartReplyGenerator create(Ref ref) {
    return smartReplyGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SmartReplyGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SmartReplyGenerator>(value),
    );
  }
}

String _$smartReplyGeneratorHash() =>
    r'd21618ac372cc9bef451c19f19f079d384424931';

/// Provider for generating smart replies for a specific message
///
/// This is a FutureProvider that orchestrates the complete RAG pipeline:
/// - Embedding generation
/// - Semantic search
/// - Style analysis
/// - Reply generation
///
/// Parameters (via family):
/// - conversationId: The conversation context
/// - incomingMessage: The message to generate replies for
/// - currentUserId: The user who will be replying

@ProviderFor(generateSmartReplies)
const generateSmartRepliesProvider = GenerateSmartRepliesFamily._();

/// Provider for generating smart replies for a specific message
///
/// This is a FutureProvider that orchestrates the complete RAG pipeline:
/// - Embedding generation
/// - Semantic search
/// - Style analysis
/// - Reply generation
///
/// Parameters (via family):
/// - conversationId: The conversation context
/// - incomingMessage: The message to generate replies for
/// - currentUserId: The user who will be replying

final class GenerateSmartRepliesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SmartReply>>,
          List<SmartReply>,
          FutureOr<List<SmartReply>>
        >
    with $FutureModifier<List<SmartReply>>, $FutureProvider<List<SmartReply>> {
  /// Provider for generating smart replies for a specific message
  ///
  /// This is a FutureProvider that orchestrates the complete RAG pipeline:
  /// - Embedding generation
  /// - Semantic search
  /// - Style analysis
  /// - Reply generation
  ///
  /// Parameters (via family):
  /// - conversationId: The conversation context
  /// - incomingMessage: The message to generate replies for
  /// - currentUserId: The user who will be replying
  const GenerateSmartRepliesProvider._({
    required GenerateSmartRepliesFamily super.from,
    required ({
      String conversationId,
      Message incomingMessage,
      String currentUserId,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'generateSmartRepliesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$generateSmartRepliesHash();

  @override
  String toString() {
    return r'generateSmartRepliesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<SmartReply>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SmartReply>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String conversationId,
              Message incomingMessage,
              String currentUserId,
            });
    return generateSmartReplies(
      ref,
      conversationId: argument.conversationId,
      incomingMessage: argument.incomingMessage,
      currentUserId: argument.currentUserId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GenerateSmartRepliesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$generateSmartRepliesHash() =>
    r'87fde756ba9ffe0e99b16cb8db54a4c3bacc6688';

/// Provider for generating smart replies for a specific message
///
/// This is a FutureProvider that orchestrates the complete RAG pipeline:
/// - Embedding generation
/// - Semantic search
/// - Style analysis
/// - Reply generation
///
/// Parameters (via family):
/// - conversationId: The conversation context
/// - incomingMessage: The message to generate replies for
/// - currentUserId: The user who will be replying

final class GenerateSmartRepliesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<SmartReply>>,
          ({
            String conversationId,
            Message incomingMessage,
            String currentUserId,
          })
        > {
  const GenerateSmartRepliesFamily._()
    : super(
        retry: null,
        name: r'generateSmartRepliesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for generating smart replies for a specific message
  ///
  /// This is a FutureProvider that orchestrates the complete RAG pipeline:
  /// - Embedding generation
  /// - Semantic search
  /// - Style analysis
  /// - Reply generation
  ///
  /// Parameters (via family):
  /// - conversationId: The conversation context
  /// - incomingMessage: The message to generate replies for
  /// - currentUserId: The user who will be replying

  GenerateSmartRepliesProvider call({
    required String conversationId,
    required Message incomingMessage,
    required String currentUserId,
  }) => GenerateSmartRepliesProvider._(
    argument: (
      conversationId: conversationId,
      incomingMessage: incomingMessage,
      currentUserId: currentUserId,
    ),
    from: this,
  );

  @override
  String toString() => r'generateSmartRepliesProvider';
}
