/// Formality adjuster widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/formality_adjustment/domain/entities/formality_level.dart';
import 'package:message_ai/features/formality_adjustment/presentation/providers/formality_providers.dart';

/// Widget for adjusting the formality level of the message being composed.
///
/// Displays ChoiceChips for selecting formality level (Casual, Neutral, Formal)
/// and triggers formality adjustment via Cloud Function.
class FormalityAdjuster extends ConsumerWidget {
  const FormalityAdjuster({
    required this.text,
    required this.onTextAdjusted,
    this.language,
    super.key,
  });

  final String text;
  final ValueChanged<String> onTextAdjusted;
  final String? language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(formalityControllerProvider);
    final controller = ref.read(formalityControllerProvider.notifier);

    // Don't show if text is empty
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
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
              ...FormalityLevel.values.map((level) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(level.displayName),
                  selected: state.selectedFormality == level,
                  onSelected: state.isAdjusting ? null : (selected) {
                    if (selected) {
                      controller.setSelectedFormality(level);
                      _adjustFormality(ref, level);
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: state.selectedFormality == level
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )),
              if (state.isAdjusting) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                state.error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _adjustFormality(
    WidgetRef ref,
    FormalityLevel targetFormality,
  ) async {
    final controller = ref.read(formalityControllerProvider.notifier);
    final adjustUseCase = ref.read(adjustMessageFormalityProvider);

    controller
      ..setAdjusting(isAdjusting: true)
      ..clearError();

    final result = await adjustUseCase(
      text: text,
      targetFormality: targetFormality,
      language: language ?? 'en',
    );

    result.fold(
      (failure) {
        controller.setError(failure.message);
      },
      (adjustedText) {
        controller.setAdjustedText(adjustedText);
        onTextAdjusted(adjustedText);
      },
    );
  }
}
