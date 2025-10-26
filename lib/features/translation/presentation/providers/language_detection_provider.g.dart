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

/// Batch language detection listener for message lists.
///
/// **Problem:**
/// When loading conversations with many old messages without detected
/// languages, individual MessageBubbles trigger sequential detection,
/// blocking the UI and causing jank.
///
/// **Solution:**
/// Watch message lists and proactively trigger batch detection in background
/// isolate when 10+ messages need detection. Cache results for MessageBubbles.
///
/// **Integration:**
/// Call this provider in ChatPage's build method to activate batch detection:
/// ```dart
/// // Trigger batch detection for messages without detected language
/// ref.watch(batchLanguageDetectionListenerProvider((
///   conversationId: widget.conversationId,
///   messages: messages, // from conversationMessagesStreamProvider
/// )));
/// ```

@ProviderFor(batchLanguageDetectionListener)
const batchLanguageDetectionListenerProvider =
    BatchLanguageDetectionListenerFamily._();

/// Batch language detection listener for message lists.
///
/// **Problem:**
/// When loading conversations with many old messages without detected
/// languages, individual MessageBubbles trigger sequential detection,
/// blocking the UI and causing jank.
///
/// **Solution:**
/// Watch message lists and proactively trigger batch detection in background
/// isolate when 10+ messages need detection. Cache results for MessageBubbles.
///
/// **Integration:**
/// Call this provider in ChatPage's build method to activate batch detection:
/// ```dart
/// // Trigger batch detection for messages without detected language
/// ref.watch(batchLanguageDetectionListenerProvider((
///   conversationId: widget.conversationId,
///   messages: messages, // from conversationMessagesStreamProvider
/// )));
/// ```

final class BatchLanguageDetectionListenerProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Batch language detection listener for message lists.
  ///
  /// **Problem:**
  /// When loading conversations with many old messages without detected
  /// languages, individual MessageBubbles trigger sequential detection,
  /// blocking the UI and causing jank.
  ///
  /// **Solution:**
  /// Watch message lists and proactively trigger batch detection in background
  /// isolate when 10+ messages need detection. Cache results for MessageBubbles.
  ///
  /// **Integration:**
  /// Call this provider in ChatPage's build method to activate batch detection:
  /// ```dart
  /// // Trigger batch detection for messages without detected language
  /// ref.watch(batchLanguageDetectionListenerProvider((
  ///   conversationId: widget.conversationId,
  ///   messages: messages, // from conversationMessagesStreamProvider
  /// )));
  /// ```
  const BatchLanguageDetectionListenerProvider._({
    required BatchLanguageDetectionListenerFamily super.from,
    required ({String conversationId, List<Map<String, dynamic>> messages})
    super.argument,
  }) : super(
         retry: null,
         name: r'batchLanguageDetectionListenerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$batchLanguageDetectionListenerHash();

  @override
  String toString() {
    return r'batchLanguageDetectionListenerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument =
        this.argument
            as ({String conversationId, List<Map<String, dynamic>> messages});
    return batchLanguageDetectionListener(
      ref,
      conversationId: argument.conversationId,
      messages: argument.messages,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BatchLanguageDetectionListenerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$batchLanguageDetectionListenerHash() =>
    r'edbdbe6288b3f4427d7886e5f8d48ebf7e82b6fe';

/// Batch language detection listener for message lists.
///
/// **Problem:**
/// When loading conversations with many old messages without detected
/// languages, individual MessageBubbles trigger sequential detection,
/// blocking the UI and causing jank.
///
/// **Solution:**
/// Watch message lists and proactively trigger batch detection in background
/// isolate when 10+ messages need detection. Cache results for MessageBubbles.
///
/// **Integration:**
/// Call this provider in ChatPage's build method to activate batch detection:
/// ```dart
/// // Trigger batch detection for messages without detected language
/// ref.watch(batchLanguageDetectionListenerProvider((
///   conversationId: widget.conversationId,
///   messages: messages, // from conversationMessagesStreamProvider
/// )));
/// ```

final class BatchLanguageDetectionListenerFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<void>,
          ({String conversationId, List<Map<String, dynamic>> messages})
        > {
  const BatchLanguageDetectionListenerFamily._()
    : super(
        retry: null,
        name: r'batchLanguageDetectionListenerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Batch language detection listener for message lists.
  ///
  /// **Problem:**
  /// When loading conversations with many old messages without detected
  /// languages, individual MessageBubbles trigger sequential detection,
  /// blocking the UI and causing jank.
  ///
  /// **Solution:**
  /// Watch message lists and proactively trigger batch detection in background
  /// isolate when 10+ messages need detection. Cache results for MessageBubbles.
  ///
  /// **Integration:**
  /// Call this provider in ChatPage's build method to activate batch detection:
  /// ```dart
  /// // Trigger batch detection for messages without detected language
  /// ref.watch(batchLanguageDetectionListenerProvider((
  ///   conversationId: widget.conversationId,
  ///   messages: messages, // from conversationMessagesStreamProvider
  /// )));
  /// ```

  BatchLanguageDetectionListenerProvider call({
    required String conversationId,
    required List<Map<String, dynamic>> messages,
  }) => BatchLanguageDetectionListenerProvider._(
    argument: (conversationId: conversationId, messages: messages),
    from: this,
  );

  @override
  String toString() => r'batchLanguageDetectionListenerProvider';
}

/// Provider-level language detection cache.
///
/// **Problem:**
/// MessageBubble widgets call ML Kit language detection for every message
/// without detected language. When scrolling through message lists, this
/// results in redundant detection calls for the same messages, wasting CPU
/// and battery.
///
/// **Solution:**
/// Cache detection results at the provider level so all MessageBubble
/// instances can share results. Prevents redundant ML Kit calls for messages
/// that have already been detected.
///
/// **Performance:**
/// - Expected cache hit rate: >90% when scrolling through viewed messages
/// - ML Kit detection time: ~50ms per message
/// - Cache lookup time: <1ms
/// - Memory overhead: ~32 bytes per cached entry
/// - Max cache size: 1000 entries (~32KB)
///
/// **Cache Eviction:**
/// When cache exceeds 1000 entries, entire cache is cleared to prevent
/// unbounded memory growth. This simple strategy works well because:
/// - Users typically view <100 messages per conversation
/// - Recent messages are re-detected quickly (<5s total for 100 messages)
/// - Avoids complexity of LRU or TTL strategies
///
/// Example:
/// ```dart
/// final cache = ref.read(languageDetectionCacheProvider.notifier);
///
/// // Check cache before detection
/// final cached = cache.getCached(messageId);
/// if (cached != null) {
///   return cached;
/// }
///
/// // Detect and cache result
/// final detected = await languageDetectionService.detectLanguage(text);
/// cache.cache(messageId, detected);
/// ```

@ProviderFor(LanguageDetectionCache)
const languageDetectionCacheProvider = LanguageDetectionCacheProvider._();

/// Provider-level language detection cache.
///
/// **Problem:**
/// MessageBubble widgets call ML Kit language detection for every message
/// without detected language. When scrolling through message lists, this
/// results in redundant detection calls for the same messages, wasting CPU
/// and battery.
///
/// **Solution:**
/// Cache detection results at the provider level so all MessageBubble
/// instances can share results. Prevents redundant ML Kit calls for messages
/// that have already been detected.
///
/// **Performance:**
/// - Expected cache hit rate: >90% when scrolling through viewed messages
/// - ML Kit detection time: ~50ms per message
/// - Cache lookup time: <1ms
/// - Memory overhead: ~32 bytes per cached entry
/// - Max cache size: 1000 entries (~32KB)
///
/// **Cache Eviction:**
/// When cache exceeds 1000 entries, entire cache is cleared to prevent
/// unbounded memory growth. This simple strategy works well because:
/// - Users typically view <100 messages per conversation
/// - Recent messages are re-detected quickly (<5s total for 100 messages)
/// - Avoids complexity of LRU or TTL strategies
///
/// Example:
/// ```dart
/// final cache = ref.read(languageDetectionCacheProvider.notifier);
///
/// // Check cache before detection
/// final cached = cache.getCached(messageId);
/// if (cached != null) {
///   return cached;
/// }
///
/// // Detect and cache result
/// final detected = await languageDetectionService.detectLanguage(text);
/// cache.cache(messageId, detected);
/// ```
final class LanguageDetectionCacheProvider
    extends $NotifierProvider<LanguageDetectionCache, Map<String, String>> {
  /// Provider-level language detection cache.
  ///
  /// **Problem:**
  /// MessageBubble widgets call ML Kit language detection for every message
  /// without detected language. When scrolling through message lists, this
  /// results in redundant detection calls for the same messages, wasting CPU
  /// and battery.
  ///
  /// **Solution:**
  /// Cache detection results at the provider level so all MessageBubble
  /// instances can share results. Prevents redundant ML Kit calls for messages
  /// that have already been detected.
  ///
  /// **Performance:**
  /// - Expected cache hit rate: >90% when scrolling through viewed messages
  /// - ML Kit detection time: ~50ms per message
  /// - Cache lookup time: <1ms
  /// - Memory overhead: ~32 bytes per cached entry
  /// - Max cache size: 1000 entries (~32KB)
  ///
  /// **Cache Eviction:**
  /// When cache exceeds 1000 entries, entire cache is cleared to prevent
  /// unbounded memory growth. This simple strategy works well because:
  /// - Users typically view <100 messages per conversation
  /// - Recent messages are re-detected quickly (<5s total for 100 messages)
  /// - Avoids complexity of LRU or TTL strategies
  ///
  /// Example:
  /// ```dart
  /// final cache = ref.read(languageDetectionCacheProvider.notifier);
  ///
  /// // Check cache before detection
  /// final cached = cache.getCached(messageId);
  /// if (cached != null) {
  ///   return cached;
  /// }
  ///
  /// // Detect and cache result
  /// final detected = await languageDetectionService.detectLanguage(text);
  /// cache.cache(messageId, detected);
  /// ```
  const LanguageDetectionCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'languageDetectionCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$languageDetectionCacheHash();

  @$internal
  @override
  LanguageDetectionCache create() => LanguageDetectionCache();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, String>>(value),
    );
  }
}

String _$languageDetectionCacheHash() =>
    r'8e364de8c2db5747998e557e7c279beae542f912';

/// Provider-level language detection cache.
///
/// **Problem:**
/// MessageBubble widgets call ML Kit language detection for every message
/// without detected language. When scrolling through message lists, this
/// results in redundant detection calls for the same messages, wasting CPU
/// and battery.
///
/// **Solution:**
/// Cache detection results at the provider level so all MessageBubble
/// instances can share results. Prevents redundant ML Kit calls for messages
/// that have already been detected.
///
/// **Performance:**
/// - Expected cache hit rate: >90% when scrolling through viewed messages
/// - ML Kit detection time: ~50ms per message
/// - Cache lookup time: <1ms
/// - Memory overhead: ~32 bytes per cached entry
/// - Max cache size: 1000 entries (~32KB)
///
/// **Cache Eviction:**
/// When cache exceeds 1000 entries, entire cache is cleared to prevent
/// unbounded memory growth. This simple strategy works well because:
/// - Users typically view <100 messages per conversation
/// - Recent messages are re-detected quickly (<5s total for 100 messages)
/// - Avoids complexity of LRU or TTL strategies
///
/// Example:
/// ```dart
/// final cache = ref.read(languageDetectionCacheProvider.notifier);
///
/// // Check cache before detection
/// final cached = cache.getCached(messageId);
/// if (cached != null) {
///   return cached;
/// }
///
/// // Detect and cache result
/// final detected = await languageDetectionService.detectLanguage(text);
/// cache.cache(messageId, detected);
/// ```

abstract class _$LanguageDetectionCache extends $Notifier<Map<String, String>> {
  Map<String, String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Map<String, String>, Map<String, String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, String>, Map<String, String>>,
              Map<String, String>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
