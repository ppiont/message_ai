/// Message context dialog widget
library;

import 'package:flutter/material.dart';
import 'package:message_ai/features/messaging/domain/entities/idiom_explanation.dart';
import 'package:message_ai/features/messaging/domain/entities/message_context_details.dart';

/// Dialog displaying cultural context, formality, and idioms for a message
///
/// Shows comprehensive message analysis including:
/// - Formality level
/// - Cultural notes and explanations
/// - Idioms with meanings and equivalents in other languages
class MessageContextDialog extends StatelessWidget {
  const MessageContextDialog({required this.contextDetails, super.key});

  final MessageContextDetails contextDetails;

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.translate, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Message Context',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

          // Check if no context
          if (!contextDetails.hasContent)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No cultural context needed for this message.',
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
              ),
            )
          else
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Formality level
                    if (contextDetails.formality != null)
                      _buildFormalitySection(context),

                    // Cultural note
                    if (contextDetails.culturalNote != null)
                      _buildCulturalNoteSection(context),

                    // Idioms
                    if (contextDetails.hasIdioms)
                      _buildIdiomsSection(context),
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
    ),
  );

  Widget _buildFormalitySection(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getFormalityIcon(),
                color: _getFormalityColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Formality Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getFormalityDescription(),
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildCulturalNoteSection(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Cultural Context',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            contextDetails.culturalNote!,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildIdiomsSection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text(
              'Idioms & Slang',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
      for (final idiom in contextDetails.idioms)
        _buildIdiomCard(context, idiom),
    ],
  );

  Widget _buildIdiomCard(BuildContext context, IdiomExplanation idiom) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  /// Get formality icon based on level
  IconData _getFormalityIcon() {
    final formality = contextDetails.formality?.toLowerCase();
    if (formality == null) return Icons.help_outline;
    if (formality.contains('very formal')) return Icons.business_center;
    if (formality.contains('formal')) return Icons.business;
    if (formality.contains('casual')) return Icons.chat_bubble_outline;
    if (formality.contains('very casual')) return Icons.emoji_emotions;
    return Icons.message;
  }

  /// Get formality color based on level
  Color _getFormalityColor() {
    final formality = contextDetails.formality?.toLowerCase();
    if (formality == null) return Colors.grey;
    if (formality.contains('very formal')) return Colors.indigo;
    if (formality.contains('formal')) return Colors.blue;
    if (formality.contains('casual')) return Colors.orange;
    if (formality.contains('very casual')) return Colors.deepOrange;
    return Colors.green;
  }

  /// Get formality description text
  String _getFormalityDescription() {
    final formality = contextDetails.formality!;
    return 'This message has a $formality tone.';
  }

  /// Get language name from language code
  String _getLanguageName(final String code) {
    const languageNames = <String, String>{
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

  /// Show the message context dialog
  static void show(
    final BuildContext context,
    final MessageContextDetails contextDetails,
  ) {
    showDialog<void>(
      context: context,
      builder: (final BuildContext context) =>
          MessageContextDialog(contextDetails: contextDetails),
    );
  }
}
