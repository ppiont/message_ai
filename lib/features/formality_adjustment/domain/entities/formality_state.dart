/// State classes for formality adjustment
library;

import 'package:equatable/equatable.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/formality_adjustment/domain/entities/formality_level.dart';

/// Sealed class representing the state of formality adjustment
///
/// This sealed class pattern provides type-safe state management for
/// formality adjustment with three distinct states:
/// - Loading: Adjustment is in progress
/// - Success: Adjustment completed with adjusted text and detected formality
/// - Error: Adjustment failed with failure information
sealed class FormalityState extends Equatable {
  const FormalityState();

  /// Whether the state is loading
  bool get isLoading => this is FormalityStateLoading;

  /// Whether the state is success
  bool get isSuccess => this is FormalityStateSuccess;

  /// Whether the state is error
  bool get isError => this is FormalityStateError;

  /// Get the adjusted text if available, otherwise null
  String? get adjustedText => switch (this) {
        FormalityStateSuccess(adjustedText: final text) => text,
        _ => null,
      };

  /// Get the detected formality level if available, otherwise null
  FormalityLevel? get detectedFormality => switch (this) {
        FormalityStateSuccess(detectedFormality: final level) => level,
        _ => null,
      };

  /// Get the failure if available, otherwise null
  Failure? get failure => switch (this) {
        FormalityStateError(failure: final f) => f,
        _ => null,
      };

  @override
  List<Object?> get props => [];
}

/// Loading state - adjustment is in progress
class FormalityStateLoading extends FormalityState {
  const FormalityStateLoading();

  @override
  List<Object?> get props => [];
}

/// Success state - adjustment completed
///
/// Contains the adjusted text and the detected formality level
class FormalityStateSuccess extends FormalityState {
  const FormalityStateSuccess({
    required this.adjustedText,
    required this.detectedFormality,
  });

  /// The text after formality adjustment
  @override
  final String adjustedText;

  /// The detected formality level of the original text
  @override
  final FormalityLevel detectedFormality;

  @override
  List<Object?> get props => [adjustedText, detectedFormality];
}

/// Error state - adjustment failed
class FormalityStateError extends FormalityState {
  const FormalityStateError({required this.failure});

  /// The failure that occurred during adjustment
  @override
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
