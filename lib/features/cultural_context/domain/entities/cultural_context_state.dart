/// State classes for cultural context analysis
library;

import 'package:equatable/equatable.dart';
import 'package:message_ai/core/error/failures.dart';

/// Sealed class representing the state of cultural context analysis
///
/// This sealed class pattern provides type-safe state management for
/// cultural context analysis with three distinct states:
/// - Loading: Analysis is in progress
/// - Success: Analysis completed with optional cultural hint
/// - Error: Analysis failed with failure information
sealed class CulturalContextState extends Equatable {
  const CulturalContextState();

  /// Whether the state is loading
  bool get isLoading => this is CulturalContextStateLoading;

  /// Whether the state is success
  bool get isSuccess => this is CulturalContextStateSuccess;

  /// Whether the state is error
  bool get isError => this is CulturalContextStateError;

  /// Get the cultural hint if available, otherwise null
  String? get culturalHint => switch (this) {
        CulturalContextStateSuccess(culturalHint: final hint) => hint,
        _ => null,
      };

  /// Get the failure if available, otherwise null
  Failure? get failure => switch (this) {
        CulturalContextStateError(failure: final f) => f,
        _ => null,
      };

  @override
  List<Object?> get props => [];
}

/// Loading state - analysis is in progress
class CulturalContextStateLoading extends CulturalContextState {
  const CulturalContextStateLoading();

  @override
  List<Object?> get props => [];
}

/// Success state - analysis completed
///
/// The [culturalHint] may be null if the message is straightforward
/// and doesn't require cultural explanation
class CulturalContextStateSuccess extends CulturalContextState {
  const CulturalContextStateSuccess({required this.culturalHint});

  /// Cultural hint explaining nuances, idioms, or formality
  /// Null if the message is straightforward
  @override
  final String? culturalHint;

  @override
  List<Object?> get props => [culturalHint];
}

/// Error state - analysis failed
class CulturalContextStateError extends CulturalContextState {
  const CulturalContextStateError({required this.failure});

  /// The failure that occurred during analysis
  @override
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
