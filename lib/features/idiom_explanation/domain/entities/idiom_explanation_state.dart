/// State classes for idiom explanation
library;

import 'package:equatable/equatable.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/idiom_explanation/domain/entities/idiom_explanation.dart';

/// Sealed class representing the state of idiom explanation
///
/// This sealed class pattern provides type-safe state management for
/// idiom explanation with three distinct states:
/// - Loading: Explanation is in progress
/// - Success: Explanation completed with list of idiom explanations
/// - Error: Explanation failed with failure information
sealed class IdiomExplanationState extends Equatable {
  const IdiomExplanationState();

  /// Whether the state is loading
  bool get isLoading => this is IdiomExplanationStateLoading;

  /// Whether the state is success
  bool get isSuccess => this is IdiomExplanationStateSuccess;

  /// Whether the state is error
  bool get isError => this is IdiomExplanationStateError;

  /// Get the idiom explanations if available, otherwise null
  List<IdiomExplanation>? get idioms => switch (this) {
    IdiomExplanationStateSuccess(idioms: final list) => list,
    _ => null,
  };

  /// Get the failure if available, otherwise null
  Failure? get failure => switch (this) {
    IdiomExplanationStateError(failure: final f) => f,
    _ => null,
  };

  @override
  List<Object?> get props => [];
}

/// Loading state - explanation is in progress
class IdiomExplanationStateLoading extends IdiomExplanationState {
  const IdiomExplanationStateLoading();

  @override
  List<Object?> get props => [];
}

/// Success state - explanation completed
///
/// Contains a list of idiom explanations found in the message.
/// The list may be empty if no idioms were detected.
class IdiomExplanationStateSuccess extends IdiomExplanationState {
  const IdiomExplanationStateSuccess({required this.idioms});

  /// List of idiom explanations found in the message
  @override
  final List<IdiomExplanation> idioms;

  /// Whether any idioms were found
  bool get hasIdioms => idioms.isNotEmpty;

  @override
  List<Object?> get props => [idioms];
}

/// Error state - explanation failed
class IdiomExplanationStateError extends IdiomExplanationState {
  const IdiomExplanationStateError({required this.failure});

  /// The failure that occurred during explanation
  @override
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
