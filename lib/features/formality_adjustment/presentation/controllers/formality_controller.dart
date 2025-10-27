import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/formality_adjustment/domain/entities/formality_level.dart';

/// Formality adjustment state for message composition
class FormalityAdjustmentState {
  const FormalityAdjustmentState({
    this.originalText,
    this.cachedVersions = const {},
    this.currentLevel = FormalityLevel.original,
    this.loadingLevel,
    this.error,
  });

  final String? originalText;
  final Map<FormalityLevel, String> cachedVersions;
  final FormalityLevel currentLevel;
  final FormalityLevel? loadingLevel; // Which chip is currently loading
  final String? error;

  /// Check if we have a cached version for this level
  bool hasCachedVersion(FormalityLevel level) {
    if (level == FormalityLevel.original) {
      return true; // Always have original
    }
    return cachedVersions.containsKey(level);
  }

  /// Get text for a specific level
  String? getTextForLevel(FormalityLevel level) {
    if (level == FormalityLevel.original) {
      return originalText;
    }
    return cachedVersions[level];
  }

  FormalityAdjustmentState copyWith({
    String? originalText,
    Map<FormalityLevel, String>? cachedVersions,
    FormalityLevel? currentLevel,
    FormalityLevel? loadingLevel,
    String? error,
    bool clearError = false,
    bool clearLoadingLevel = false,
  }) => FormalityAdjustmentState(
    originalText: originalText ?? this.originalText,
    cachedVersions: cachedVersions ?? this.cachedVersions,
    currentLevel: currentLevel ?? this.currentLevel,
    loadingLevel: clearLoadingLevel ? null : loadingLevel ?? this.loadingLevel,
    error: clearError ? null : error ?? this.error,
  );

  /// Clear when message is sent or text changes significantly
  FormalityAdjustmentState clear() => const FormalityAdjustmentState();
}

/// Controller for managing formality adjustment state during message composition
class FormalityController extends Notifier<FormalityAdjustmentState> {
  @override
  FormalityAdjustmentState build() => const FormalityAdjustmentState();

  /// Set original text (when user starts typing new text)
  /// Clears cache if text changed
  void setOriginalText(String text) {
    if (state.originalText != text) {
      // Text changed → clear cache and reset to original
      state = FormalityAdjustmentState(originalText: text);
    }
  }

  /// Cache a generated version for a specific formality level
  void cacheVersion(FormalityLevel level, String text) {
    state = state.copyWith(
      cachedVersions: {...state.cachedVersions, level: text},
      clearLoadingLevel: true,
      clearError: true,
    );
  }

  /// Switch to a different formality level (instant if cached)
  void switchToLevel(FormalityLevel level) {
    state = state.copyWith(currentLevel: level, clearError: true);
  }

  /// Start loading a specific formality level
  void setLoadingLevel(FormalityLevel level) {
    state = state.copyWith(loadingLevel: level, clearError: true);
  }

  /// Set error message
  void setError(String error) {
    state = state.copyWith(error: error, clearLoadingLevel: true);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
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
