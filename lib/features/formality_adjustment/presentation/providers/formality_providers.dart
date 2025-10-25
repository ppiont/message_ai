/// Formality adjustment providers
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/formality_adjustment/data/services/formality_adjustment_service.dart';
import 'package:message_ai/features/formality_adjustment/domain/entities/formality_level.dart';
import 'package:message_ai/features/formality_adjustment/domain/entities/formality_state.dart';
import 'package:message_ai/features/formality_adjustment/domain/usecases/adjust_message_formality.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Export the controller for backward compatibility
export 'package:message_ai/features/formality_adjustment/presentation/controllers/formality_controller.dart';

part 'formality_providers.g.dart';

/// Provider for FormalityAdjustmentService
@riverpod
FormalityAdjustmentService formalityService(Ref ref) =>
    FormalityAdjustmentService();

/// Provider for AdjustMessageFormality use case
@riverpod
AdjustMessageFormality adjustMessageFormality(Ref ref) =>
    AdjustMessageFormality(ref.watch(formalityServiceProvider));

/// Provider for adjusting formality with state management
///
/// This provider takes the parameters and returns a FormalityState
/// representing the current state of the adjustment operation.
@riverpod
Future<FormalityState> adjustFormality(
  Ref ref, {
  required String text,
  required FormalityLevel targetFormality,
  FormalityLevel? currentFormality,
  String? language,
}) async {
  final service = ref.watch(formalityServiceProvider);

  final result = await service.adjustFormality(
    text: text,
    targetFormality: targetFormality,
    currentFormality: currentFormality,
    language: language,
  );

  return result.fold(
    (Failure failure) => FormalityStateError(failure: failure),
    (String adjustedText) => FormalityStateSuccess(
      adjustedText: adjustedText,
      detectedFormality: currentFormality ?? FormalityLevel.neutral,
    ),
  );
}

/// Provider for detecting formality level
///
/// This provider detects the formality level of a message without adjusting it.
@riverpod
Future<Either<Failure, FormalityLevel>> detectFormality(
  Ref ref, {
  required String text,
  String? language,
}) async {
  final service = ref.watch(formalityServiceProvider);

  return service.detectFormality(text: text, language: language);
}

/// State provider for formality adjustment with FormalityState
///
/// This is an alternative to the existing FormalityController for components
/// that want to use the sealed FormalityState pattern.
@riverpod
class FormalityStateNotifier extends _$FormalityStateNotifier {
  @override
  FormalityState build() =>
      // Initial state is success with empty values
      // We could use a separate "Initial" state if needed
      const FormalityStateSuccess(
        adjustedText: '',
        detectedFormality: FormalityLevel.neutral,
      );

  /// Adjust the formality of text
  Future<void> adjust({
    required String text,
    required FormalityLevel targetFormality,
    FormalityLevel? currentFormality,
    String? language,
  }) async {
    // Set loading state
    state = const FormalityStateLoading();

    final service = ref.read(formalityServiceProvider);

    final result = await service.adjustFormality(
      text: text,
      targetFormality: targetFormality,
      currentFormality: currentFormality,
      language: language,
    );

    state = result.fold<FormalityState>(
      (Failure failure) => FormalityStateError(failure: failure),
      (String adjustedText) => FormalityStateSuccess(
        adjustedText: adjustedText,
        detectedFormality: currentFormality ?? FormalityLevel.neutral,
      ),
    );
  }

  /// Detect the formality level of text
  Future<void> detect({required String text, String? language}) async {
    // Set loading state
    state = const FormalityStateLoading();

    final service = ref.read(formalityServiceProvider);

    final result = await service.detectFormality(
      text: text,
      language: language,
    );

    state = result.fold<FormalityState>(
      (Failure failure) => FormalityStateError(failure: failure),
      (FormalityLevel detectedLevel) => FormalityStateSuccess(
        adjustedText: text, // No adjustment, return original
        detectedFormality: detectedLevel,
      ),
    );
  }

  /// Clear the state
  void clear() {
    state = const FormalityStateSuccess(
      adjustedText: '',
      detectedFormality: FormalityLevel.neutral,
    );
  }
}
