/// Idiom explanation providers
library;

import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/idiom_explanation/data/services/idiom_explanation_service.dart';
import 'package:message_ai/features/idiom_explanation/domain/entities/idiom_explanation.dart';
import 'package:message_ai/features/idiom_explanation/domain/entities/idiom_explanation_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'idiom_explanation_providers.g.dart';

/// Provider for IdiomExplanationService
///
/// Singleton service for explaining idioms with PII detection,
/// retry logic, and caching
@Riverpod(keepAlive: true)
IdiomExplanationService idiomExplanationService(Ref ref) =>
    IdiomExplanationService();

/// Provider for idiom explanation state per message
///
/// This provider tracks the state of idiom explanation for a specific message.
/// The state includes loading, success with idiom list, or error with failure info.
///
/// Parameters:
/// - messageText: The message text to explain idioms for
/// - sourceLanguage: Source language code (e.g., 'en', 'es')
/// - targetLanguage: Target language code for equivalent expressions
@riverpod
class IdiomExplanationStateNotifier extends _$IdiomExplanationStateNotifier {
  @override
  IdiomExplanationState build({
    required String messageText,
    required String sourceLanguage,
    required String targetLanguage,
  }) =>
      // Initial state is loading
      const IdiomExplanationStateLoading();

  /// Explain idioms in the message
  Future<void> explainIdioms() async {
    // Set loading state
    state = const IdiomExplanationStateLoading();

    // Get service
    final service = ref.read(idiomExplanationServiceProvider);

    // Call service to explain idioms
    final result = await service.explainIdioms(
      text: messageText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    // Update state based on result
    result.fold(
      (final Failure failure) => state = IdiomExplanationStateError(failure: failure),
      (final IdiomExplanationResult explanationResult) => state =
          IdiomExplanationStateSuccess(idioms: explanationResult.idioms),
    );
  }
}

/// Provider for explaining idioms in a message
///
/// This is a convenience provider that automatically explains idioms
/// when first accessed.
///
/// Usage:
/// ```dart
/// final state = ref.watch(explainIdiomsProvider(
///   messageText: 'Break a leg!',
///   sourceLanguage: 'en',
///   targetLanguage: 'es',
/// ));
/// ```
@riverpod
Future<IdiomExplanationState> explainIdioms(
  Ref ref, {
  required String messageText,
  required String sourceLanguage,
  required String targetLanguage,
}) async {
  final service = ref.watch(idiomExplanationServiceProvider);

  final result = await service.explainIdioms(
    text: messageText,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
  );

  return result.fold(
    (final Failure failure) => IdiomExplanationStateError(failure: failure),
    (final IdiomExplanationResult explanationResult) =>
        IdiomExplanationStateSuccess(idioms: explanationResult.idioms),
  );
}
