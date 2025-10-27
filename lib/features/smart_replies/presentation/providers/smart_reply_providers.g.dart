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

/// Provider for generating smart replies for a specific message
///
/// This simplified provider calls the unified Cloud Function that handles
/// the complete RAG pipeline server-side:
/// - Embedding generation with Vertex AI
/// - Vector search using Firestore find_nearest()
/// - User style fetching from Firestore
/// - Reply generation with GPT-4o-mini
///
/// Parameters:
/// - conversationId: The conversation context
/// - incomingMessageText: The message text to generate replies for
/// - userId: The current user's ID

@ProviderFor(generateSmartReplies)
const generateSmartRepliesProvider = GenerateSmartRepliesFamily._();

/// Provider for generating smart replies for a specific message
///
/// This simplified provider calls the unified Cloud Function that handles
/// the complete RAG pipeline server-side:
/// - Embedding generation with Vertex AI
/// - Vector search using Firestore find_nearest()
/// - User style fetching from Firestore
/// - Reply generation with GPT-4o-mini
///
/// Parameters:
/// - conversationId: The conversation context
/// - incomingMessageText: The message text to generate replies for
/// - userId: The current user's ID

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
  /// This simplified provider calls the unified Cloud Function that handles
  /// the complete RAG pipeline server-side:
  /// - Embedding generation with Vertex AI
  /// - Vector search using Firestore find_nearest()
  /// - User style fetching from Firestore
  /// - Reply generation with GPT-4o-mini
  ///
  /// Parameters:
  /// - conversationId: The conversation context
  /// - incomingMessageText: The message text to generate replies for
  /// - userId: The current user's ID
  const GenerateSmartRepliesProvider._({
    required GenerateSmartRepliesFamily super.from,
    required ({
      String conversationId,
      String incomingMessageText,
      String userId,
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
              String incomingMessageText,
              String userId,
            });
    return generateSmartReplies(
      ref,
      conversationId: argument.conversationId,
      incomingMessageText: argument.incomingMessageText,
      userId: argument.userId,
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
    r'73449813feeb62e700025d4644d5f74d9c813417';

/// Provider for generating smart replies for a specific message
///
/// This simplified provider calls the unified Cloud Function that handles
/// the complete RAG pipeline server-side:
/// - Embedding generation with Vertex AI
/// - Vector search using Firestore find_nearest()
/// - User style fetching from Firestore
/// - Reply generation with GPT-4o-mini
///
/// Parameters:
/// - conversationId: The conversation context
/// - incomingMessageText: The message text to generate replies for
/// - userId: The current user's ID

final class GenerateSmartRepliesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<SmartReply>>,
          ({String conversationId, String incomingMessageText, String userId})
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
  /// This simplified provider calls the unified Cloud Function that handles
  /// the complete RAG pipeline server-side:
  /// - Embedding generation with Vertex AI
  /// - Vector search using Firestore find_nearest()
  /// - User style fetching from Firestore
  /// - Reply generation with GPT-4o-mini
  ///
  /// Parameters:
  /// - conversationId: The conversation context
  /// - incomingMessageText: The message text to generate replies for
  /// - userId: The current user's ID

  GenerateSmartRepliesProvider call({
    required String conversationId,
    required String incomingMessageText,
    required String userId,
  }) => GenerateSmartRepliesProvider._(
    argument: (
      conversationId: conversationId,
      incomingMessageText: incomingMessageText,
      userId: userId,
    ),
    from: this,
  );

  @override
  String toString() => r'generateSmartRepliesProvider';
}
