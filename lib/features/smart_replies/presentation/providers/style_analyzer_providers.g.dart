// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'style_analyzer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for UserStyleAnalyzer service (domain layer).
///
/// This service analyzes user communication patterns to enable
/// AI features like smart replies to match the user's writing style.

@ProviderFor(userStyleAnalyzer)
const userStyleAnalyzerProvider = UserStyleAnalyzerProvider._();

/// Provider for UserStyleAnalyzer service (domain layer).
///
/// This service analyzes user communication patterns to enable
/// AI features like smart replies to match the user's writing style.

final class UserStyleAnalyzerProvider
    extends
        $FunctionalProvider<
          UserStyleAnalyzer,
          UserStyleAnalyzer,
          UserStyleAnalyzer
        >
    with $Provider<UserStyleAnalyzer> {
  /// Provider for UserStyleAnalyzer service (domain layer).
  ///
  /// This service analyzes user communication patterns to enable
  /// AI features like smart replies to match the user's writing style.
  const UserStyleAnalyzerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userStyleAnalyzerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userStyleAnalyzerHash();

  @$internal
  @override
  $ProviderElement<UserStyleAnalyzer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserStyleAnalyzer create(Ref ref) {
    return userStyleAnalyzer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserStyleAnalyzer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserStyleAnalyzer>(value),
    );
  }
}

String _$userStyleAnalyzerHash() => r'c1c24cb05dc6d21677133d2c9ddcf51dcd4986bc';

/// State provider for cached user communication styles.
///
/// Caching strategy:
/// - Cache key: userId-conversationId
/// - TTL: Invalidate after ~20 new messages (managed by consumer)
/// - Storage: In-memory map for fast access
///
/// This avoids re-analyzing the same user's style repeatedly
/// within a short time frame, improving performance.

@ProviderFor(UserStyleCache)
const userStyleCacheProvider = UserStyleCacheProvider._();

/// State provider for cached user communication styles.
///
/// Caching strategy:
/// - Cache key: userId-conversationId
/// - TTL: Invalidate after ~20 new messages (managed by consumer)
/// - Storage: In-memory map for fast access
///
/// This avoids re-analyzing the same user's style repeatedly
/// within a short time frame, improving performance.
final class UserStyleCacheProvider
    extends
        $NotifierProvider<
          UserStyleCache,
          Map<_StyleCacheKey, UserCommunicationStyle>
        > {
  /// State provider for cached user communication styles.
  ///
  /// Caching strategy:
  /// - Cache key: userId-conversationId
  /// - TTL: Invalidate after ~20 new messages (managed by consumer)
  /// - Storage: In-memory map for fast access
  ///
  /// This avoids re-analyzing the same user's style repeatedly
  /// within a short time frame, improving performance.
  const UserStyleCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userStyleCacheProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userStyleCacheHash();

  @$internal
  @override
  UserStyleCache create() => UserStyleCache();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    Map<_StyleCacheKey, UserCommunicationStyle> value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<_StyleCacheKey, UserCommunicationStyle>>(
            value,
          ),
    );
  }
}

String _$userStyleCacheHash() => r'c862fda4120fcc7bdd5b2fd84cf4c4bf1c48f611';

/// State provider for cached user communication styles.
///
/// Caching strategy:
/// - Cache key: userId-conversationId
/// - TTL: Invalidate after ~20 new messages (managed by consumer)
/// - Storage: In-memory map for fast access
///
/// This avoids re-analyzing the same user's style repeatedly
/// within a short time frame, improving performance.

abstract class _$UserStyleCache
    extends $Notifier<Map<_StyleCacheKey, UserCommunicationStyle>> {
  Map<_StyleCacheKey, UserCommunicationStyle> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              Map<_StyleCacheKey, UserCommunicationStyle>,
              Map<_StyleCacheKey, UserCommunicationStyle>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<_StyleCacheKey, UserCommunicationStyle>,
                Map<_StyleCacheKey, UserCommunicationStyle>
              >,
              Map<_StyleCacheKey, UserCommunicationStyle>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// FutureProvider for analyzing a user's communication style.
///
/// This provider:
/// 1. Checks the cache first for recent analysis
/// 2. If not cached or stale, performs fresh analysis
/// 3. Caches the result for future access
///
/// Usage:
/// ```dart
/// final styleAsync = ref.watch(
///   analyzeUserStyleProvider(userId: 'user123', conversationId: 'conv456'),
/// );
/// styleAsync.when(
///   data: (style) => Text('Style: ${style.styleDescription}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error analyzing style'),
/// );
/// ```

@ProviderFor(analyzeUserStyle)
const analyzeUserStyleProvider = AnalyzeUserStyleFamily._();

/// FutureProvider for analyzing a user's communication style.
///
/// This provider:
/// 1. Checks the cache first for recent analysis
/// 2. If not cached or stale, performs fresh analysis
/// 3. Caches the result for future access
///
/// Usage:
/// ```dart
/// final styleAsync = ref.watch(
///   analyzeUserStyleProvider(userId: 'user123', conversationId: 'conv456'),
/// );
/// styleAsync.when(
///   data: (style) => Text('Style: ${style.styleDescription}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error analyzing style'),
/// );
/// ```

final class AnalyzeUserStyleProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserCommunicationStyle>,
          UserCommunicationStyle,
          FutureOr<UserCommunicationStyle>
        >
    with
        $FutureModifier<UserCommunicationStyle>,
        $FutureProvider<UserCommunicationStyle> {
  /// FutureProvider for analyzing a user's communication style.
  ///
  /// This provider:
  /// 1. Checks the cache first for recent analysis
  /// 2. If not cached or stale, performs fresh analysis
  /// 3. Caches the result for future access
  ///
  /// Usage:
  /// ```dart
  /// final styleAsync = ref.watch(
  ///   analyzeUserStyleProvider(userId: 'user123', conversationId: 'conv456'),
  /// );
  /// styleAsync.when(
  ///   data: (style) => Text('Style: ${style.styleDescription}'),
  ///   loading: () => CircularProgressIndicator(),
  ///   error: (err, stack) => Text('Error analyzing style'),
  /// );
  /// ```
  const AnalyzeUserStyleProvider._({
    required AnalyzeUserStyleFamily super.from,
    required ({String userId, String conversationId}) super.argument,
  }) : super(
         retry: null,
         name: r'analyzeUserStyleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$analyzeUserStyleHash();

  @override
  String toString() {
    return r'analyzeUserStyleProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<UserCommunicationStyle> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UserCommunicationStyle> create(Ref ref) {
    final argument = this.argument as ({String userId, String conversationId});
    return analyzeUserStyle(
      ref,
      userId: argument.userId,
      conversationId: argument.conversationId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AnalyzeUserStyleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$analyzeUserStyleHash() => r'7943b5d5c9b799c2a9b48cc569af96b1046fc129';

/// FutureProvider for analyzing a user's communication style.
///
/// This provider:
/// 1. Checks the cache first for recent analysis
/// 2. If not cached or stale, performs fresh analysis
/// 3. Caches the result for future access
///
/// Usage:
/// ```dart
/// final styleAsync = ref.watch(
///   analyzeUserStyleProvider(userId: 'user123', conversationId: 'conv456'),
/// );
/// styleAsync.when(
///   data: (style) => Text('Style: ${style.styleDescription}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error analyzing style'),
/// );
/// ```

final class AnalyzeUserStyleFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<UserCommunicationStyle>,
          ({String userId, String conversationId})
        > {
  const AnalyzeUserStyleFamily._()
    : super(
        retry: null,
        name: r'analyzeUserStyleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// FutureProvider for analyzing a user's communication style.
  ///
  /// This provider:
  /// 1. Checks the cache first for recent analysis
  /// 2. If not cached or stale, performs fresh analysis
  /// 3. Caches the result for future access
  ///
  /// Usage:
  /// ```dart
  /// final styleAsync = ref.watch(
  ///   analyzeUserStyleProvider(userId: 'user123', conversationId: 'conv456'),
  /// );
  /// styleAsync.when(
  ///   data: (style) => Text('Style: ${style.styleDescription}'),
  ///   loading: () => CircularProgressIndicator(),
  ///   error: (err, stack) => Text('Error analyzing style'),
  /// );
  /// ```

  AnalyzeUserStyleProvider call({
    required String userId,
    required String conversationId,
  }) => AnalyzeUserStyleProvider._(
    argument: (userId: userId, conversationId: conversationId),
    from: this,
  );

  @override
  String toString() => r'analyzeUserStyleProvider';
}
