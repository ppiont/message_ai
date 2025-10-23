/// Idiom explanation bottom sheet widget
library;

import 'package:flutter/material.dart';
import 'package:message_ai/features/idiom_explanation/domain/entities/idiom_explanation.dart';

/// Bottom sheet displaying explanations for idioms, slang, and colloquialisms
class IdiomExplanationBottomSheet extends StatelessWidget {
  const IdiomExplanationBottomSheet({
    required this.result,
    super.key,
  });

  final IdiomExplanationResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Idioms & Slang',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Check if no idioms found
          if (!result.hasIdioms)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No idioms or slang detected in this message.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            // List of idiom explanations
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final idiom in result.idioms)
                      _buildIdiomCard(context, idiom),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Got it button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdiomCard(BuildContext context, IdiomExplanation idiom) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phrase (bold)
            Text(
              idiom.phrase,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Meaning
            Text(
              idiom.meaning,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),

            // Cultural note (italic, grey)
            if (idiom.culturalNote.isNotEmpty)
              Text(
                idiom.culturalNote,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),

            // Equivalent expressions
            if (idiom.equivalents.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Equivalents in other languages:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              for (final entry in idiom.equivalents.entries)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getLanguageName(entry.key)}:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get language name from language code
  String _getLanguageName(String code) {
    const languageNames = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ar': 'Arabic',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'hi': 'Hindi',
      'it': 'Italian',
      'ko': 'Korean',
    };

    return languageNames[code] ?? code.toUpperCase();
  }

  /// Show the idiom explanation bottom sheet
  static void show(BuildContext context, IdiomExplanationResult result) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IdiomExplanationBottomSheet(result: result),
    );
  }
}
