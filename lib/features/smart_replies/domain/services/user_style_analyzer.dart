import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';
import 'package:message_ai/features/smart_replies/domain/entities/user_communication_style.dart';

/// Domain service for analyzing user communication patterns.
///
/// This service analyzes a user's message history within a specific conversation
/// to learn their communication style, enabling AI features like smart replies
/// to match the user's natural writing patterns.
///
/// Performance target: <500ms for analysis of 20 messages.
class UserStyleAnalyzer {
  UserStyleAnalyzer({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  final MessageRepository _messageRepository;

  // Casual language markers for casualty score calculation
  static const _contractions = [
    "'",
    'gonna',
    'wanna',
    'gotta',
    'kinda',
    'sorta',
    'ain',
  ];

  static const _slang = [
    'yeah',
    'nah',
    'lol',
    'omg',
    'tbh',
    'btw',
    'brb',
    'idk',
    'imo',
    'imho',
    'fwiw',
    'nvm',
    'np',
    'ty',
    'thx',
    'pls',
    'plz',
    'ur',
    'u',
    'r',
  ];

  /// Analyzes a user's communication style based on their message history.
  ///
  /// Fetches the user's last 20 messages from the conversation and analyzes:
  /// - Average message length
  /// - Emoji usage rate
  /// - Exclamation mark usage rate
  /// - Casualty score (based on contractions and slang)
  /// - Primary language
  ///
  /// Returns [UserCommunicationStyle.defaultStyle] if user has fewer than 5 messages.
  ///
  /// Performance: Single database query + single-pass analysis in <500ms.
  Future<UserCommunicationStyle> analyzeUserStyle(
    String userId,
    String conversationId,
  ) async {
    // Fetch user's last 20 messages from the conversation
    final messagesResult = await _messageRepository.getMessages(
      conversationId: conversationId,
      limit: 100, // Get more to filter by userId
    );

    return messagesResult.fold(
      // On failure, return default style
      (failure) => UserCommunicationStyle.defaultStyle(),
      (allMessages) {
        // Filter to only this user's messages, take last 20
        final userMessages = allMessages
            .where((msg) => msg.senderId == userId)
            .take(20)
            .toList();

        // If user has fewer than 5 messages, return default style
        if (userMessages.length < 5) {
          return UserCommunicationStyle.defaultStyle();
        }

        // Perform single-pass analysis
        return _performAnalysis(userMessages);
      },
    );
  }

  /// Performs the actual style analysis on a list of messages.
  ///
  /// Single-pass algorithm for efficiency.
  UserCommunicationStyle _performAnalysis(List<Message> messages) {
    if (messages.isEmpty) {
      return UserCommunicationStyle.defaultStyle();
    }

    // Single-pass analysis variables
    var totalChars = 0;
    var validMessageCount = 0; // Messages with >5 chars
    var emojiCount = 0;
    var exclamationCount = 0;
    var casualMarkerCount = 0;
    final languageCounts = <String, int>{};

    // Single pass through all messages
    for (final message in messages) {
      final text = message.text.toLowerCase();

      // Track language frequency
      if (message.detectedLanguage != null) {
        languageCounts[message.detectedLanguage!] =
            (languageCounts[message.detectedLanguage!] ?? 0) + 1;
      }

      // Count emojis
      if (_containsEmoji(message.text)) {
        emojiCount++;
      }

      // Count exclamations
      if (message.text.contains('!')) {
        exclamationCount++;
      }

      // Count casual markers
      if (_isCasual(text)) {
        casualMarkerCount++;
      }

      // Calculate average length (exclude very short messages)
      if (message.text.length >= 5) {
        totalChars += message.text.length;
        validMessageCount++;
      }
    }

    // Calculate metrics
    final messageCount = messages.length;
    final averageLength = validMessageCount > 0
        ? totalChars / validMessageCount
        : 50.0; // Default to 50 if no valid messages

    final emojiRate = emojiCount / messageCount;
    final exclamationRate = exclamationCount / messageCount;
    final casualityScore = (casualMarkerCount / messageCount).clamp(0.0, 1.0);

    // Detect primary language
    final primaryLanguage = _detectLanguage(languageCounts);

    // Generate style description
    final styleDescription = _generateStyleDescription(
      averageLength: averageLength,
      emojiRate: emojiRate,
      exclamationRate: exclamationRate,
      casualityScore: casualityScore,
    );

    return UserCommunicationStyle(
      averageMessageLength: averageLength,
      emojiUsageRate: emojiRate,
      exclamationRate: exclamationRate,
      casualityScore: casualityScore,
      styleDescription: styleDescription,
      primaryLanguage: primaryLanguage,
      lastAnalyzedAt: DateTime.now(),
    );
  }

  /// Detects if a message contains emojis.
  ///
  /// Uses Unicode ranges for emoji detection.
  bool _containsEmoji(String text) {
    // Unicode ranges for emojis
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|'
      r'[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]',
      unicode: true,
    );

    return emojiRegex.hasMatch(text);
  }

  /// Detects if a message contains casual language markers.
  ///
  /// Checks for contractions and slang terms.
  bool _isCasual(String text) {
    final lowerText = text.toLowerCase();

    // Check for contractions
    for (final contraction in _contractions) {
      if (lowerText.contains(contraction)) {
        return true;
      }
    }

    // Check for slang (word boundaries to avoid false positives)
    final words = lowerText.split(RegExp(r'\s+'));
    for (final word in words) {
      if (_slang.contains(word)) {
        return true;
      }
    }

    return false;
  }

  /// Detects the primary language from language frequency map.
  ///
  /// Returns the most frequently used language, or 'en' as default.
  String _detectLanguage(Map<String, int> languageCounts) {
    if (languageCounts.isEmpty) {
      return 'en';
    }

    // Find most frequent language
    var maxCount = 0;
    var primaryLang = 'en';

    for (final entry in languageCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        primaryLang = entry.key;
      }
    }

    return primaryLang;
  }

  /// Generates a human-readable style description.
  ///
  /// Combines multiple style indicators into a concise description.
  String _generateStyleDescription({
    required double averageLength,
    required double emojiRate,
    required double exclamationRate,
    required double casualityScore,
  }) {
    final descriptors = <String>[];

    // Length descriptor
    if (averageLength < 30) {
      descriptors.add('brief');
    } else if (averageLength > 100) {
      descriptors.add('detailed');
    }

    // Casualty descriptor
    if (casualityScore > 0.6) {
      descriptors.add('casual');
    } else if (casualityScore < 0.3) {
      descriptors.add('formal');
    }

    // Expressiveness descriptor
    if (emojiRate > 0.4 || exclamationRate > 0.4) {
      descriptors.add('expressive');
    }

    // Enthusiasm descriptor
    if (exclamationRate > 0.5) {
      descriptors.add('enthusiastic');
    }

    // Default to neutral if no strong patterns
    if (descriptors.isEmpty) {
      return 'neutral, conversational';
    }

    return descriptors.join(', ');
  }
}
