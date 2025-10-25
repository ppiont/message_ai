import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/formality_adjustment/domain/entities/formality_level.dart';

/// Formality adjustment state for message composition
class FormalityAdjustmentState {
  const FormalityAdjustmentState({
    this.isAdjusting = false,
    this.error,
    this.adjustedText,
    this.selectedFormality = FormalityLevel.neutral,
  });

  final bool isAdjusting;
  final String? error;
  final String? adjustedText;
  final FormalityLevel selectedFormality;

  FormalityAdjustmentState copyWith({
    bool? isAdjusting,
    String? error,
    String? adjustedText,
    FormalityLevel? selectedFormality,
  }) => FormalityAdjustmentState(
    isAdjusting: isAdjusting ?? this.isAdjusting,
    error: error,
    adjustedText: adjustedText,
    selectedFormality: selectedFormality ?? this.selectedFormality,
  );

  /// Create a fresh state (clears adjusted text and errors)
  FormalityAdjustmentState clear() => FormalityAdjustmentState(
    selectedFormality: selectedFormality,
  );
}

/// Controller for managing formality adjustment state during message composition
class FormalityController extends Notifier<FormalityAdjustmentState> {
  @override
  FormalityAdjustmentState build() => const FormalityAdjustmentState();

  /// Set the selected formality level
  void setSelectedFormality(FormalityLevel formality) {
    state = state.copyWith(selectedFormality: formality);
  }

  /// Set loading state
  void setAdjusting({required bool isAdjusting}) {
    state = state.copyWith(isAdjusting: isAdjusting);
  }

  /// Set adjusted text
  void setAdjustedText(String text) {
    state = state.copyWith(adjustedText: text);
  }

  /// Set error state
  void setError(String error) {
    state = state.copyWith(
      error: error,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith();
  }

  /// Clear all state (used when message is sent or cleared)
  void clear() {
    state = state.clear();
  }
}

/// Provider for FormalityController
final formalityControllerProvider =
    NotifierProvider<FormalityController, FormalityAdjustmentState>(
  FormalityController.new,
);
