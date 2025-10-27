/// Formality adjuster widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/formality_adjustment/domain/entities/formality_level.dart';
import 'package:message_ai/features/formality_adjustment/presentation/providers/formality_providers.dart';

/// Widget for adjusting the formality level of the message being composed.
///
/// Features:
/// - Lazy loading: Generates formality versions only when requested
/// - Instant switching: Caches versions for instant toggling
/// - Preserves original: User's exact text is never modified at "Original" level
/// - Per-chip loading indicators
/// - Auto-clears cache when text changes
class FormalityAdjuster extends ConsumerWidget {
  const FormalityAdjuster({
    required this.text,
    required this.onTextAdjusted,
    required this.language,
    super.key,
  });

  final String text;
  final ValueChanged<String> onTextAdjusted;
  final String language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Don't show if text is empty
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final state = ref.watch(formalityControllerProvider);
    final controller = ref.read(formalityControllerProvider.notifier);

    // Update original text if it changed (clears cache)
    if (state.originalText != text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setOriginalText(text);
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Formality:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),

              // Show all formality level chips
              ...FormalityLevel.values.map(
                (level) => _buildChip(
                  context: context,
                  ref: ref,
                  level: level,
                  state: state,
                ),
              ),
            ],
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required WidgetRef ref,
    required FormalityLevel level,
    required FormalityAdjustmentState state,
  }) {
    final isSelected = state.currentLevel == level;
    final isLoading = state.loadingLevel == level;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(level.displayName),
                  const SizedBox(width: 4),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              )
            : Text(level.displayName),
        selected: isSelected,
        onSelected: isLoading
            ? null // Disable while loading
            : (selected) {
                if (!selected) {
                  return;
                }
                _handleLevelSelected(ref, level, state);
              },
        selectedColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _handleLevelSelected(
    WidgetRef ref,
    FormalityLevel level,
    FormalityAdjustmentState state,
  ) {
    final controller = ref.read(formalityControllerProvider.notifier);

    // If it's original or already cached → instant switch
    if (level == FormalityLevel.original || state.hasCachedVersion(level)) {
      controller.switchToLevel(level);
      final textForLevel = state.getTextForLevel(level);
      if (textForLevel != null) {
        onTextAdjusted(textForLevel);
      }
      return;
    }

    // Need to generate → call API
    _generateLevel(ref, level, state);
  }

  Future<void> _generateLevel(
    WidgetRef ref,
    FormalityLevel level,
    FormalityAdjustmentState state,
  ) async {
    final controller = ref.read(formalityControllerProvider.notifier);
    final adjustUseCase = ref.read(adjustMessageFormalityProvider);

    controller.setLoadingLevel(level);

    final result = await adjustUseCase(
      text: state.originalText!,
      targetFormality: level,
      language: language,
    );

    result.fold(
      (failure) {
        controller.setError(failure.message);
      },
      (adjustedText) {
        controller
          ..cacheVersion(level, adjustedText)
          ..switchToLevel(level);

        // Update TextField
        onTextAdjusted(adjustedText);
      },
    );
  }
}
