import 'package:riverpod/riverpod.dart';

/// Translation state for a single message
class MessageTranslationState {
  const MessageTranslationState({
    this.isTranslated = false,
    this.isLoading = false,
    this.error,
  });

  final bool isTranslated;
  final bool isLoading;
  final String? error;

  MessageTranslationState copyWith({
    bool? isTranslated,
    bool? isLoading,
    String? error,
  }) =>
      MessageTranslationState(
        isTranslated: isTranslated ?? this.isTranslated,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

/// Controller for managing translation state across all messages
class TranslationController extends StateNotifier<Map<String, MessageTranslationState>> {
  TranslationController() : super({});

  /// Toggle translation display for a message
  /// Just toggles the UI state - translation should already exist
  void toggleTranslation(String messageId) {
    final currentState = state[messageId] ?? const MessageTranslationState();
    state = {
      ...state,
      messageId: currentState.copyWith(
        isTranslated: !currentState.isTranslated,
      ),
    };
  }

  /// Set loading state for a message
  void setLoading(String messageId, bool isLoading) {
    final currentState = state[messageId] ?? const MessageTranslationState();
    state = {
      ...state,
      messageId: currentState.copyWith(
        isLoading: isLoading,
      ),
    };
  }

  /// Set error state for a message
  void setError(String messageId, String error) {
    final currentState = state[messageId] ?? const MessageTranslationState();
    state = {
      ...state,
      messageId: currentState.copyWith(
        isLoading: false,
        error: error,
      ),
    };
  }

  /// Clear error for a message
  void clearError(String messageId) {
    final currentState = state[messageId] ?? const MessageTranslationState();
    state = {
      ...state,
      messageId: currentState.copyWith(),
    };
  }

  /// Get translation state for a specific message
  MessageTranslationState getState(String messageId) =>
      state[messageId] ?? const MessageTranslationState();
}

/// Provider for TranslationController
final translationControllerProvider =
    StateNotifierProvider<TranslationController, Map<String, MessageTranslationState>>(
  (ref) => TranslationController(),
);
