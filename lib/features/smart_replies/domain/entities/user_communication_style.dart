import 'package:equatable/equatable.dart';

/// Domain entity representing a user's learned communication style.
///
/// This entity captures patterns in how a user communicates within a specific
/// conversation, enabling AI-powered features like smart replies to match
/// the user's natural writing style.
class UserCommunicationStyle extends Equatable {
  const UserCommunicationStyle({
    required this.averageMessageLength,
    required this.emojiUsageRate,
    required this.exclamationRate,
    required this.casualityScore,
    required this.styleDescription,
    required this.primaryLanguage,
    required this.lastAnalyzedAt,
  });

  /// Factory constructor for default/neutral style (new users with <5 messages).
  factory UserCommunicationStyle.defaultStyle({
    String primaryLanguage = 'en',
  }) => UserCommunicationStyle(
    averageMessageLength: 50,
    emojiUsageRate: 0,
    exclamationRate: 0,
    casualityScore: 0.5,
    styleDescription: 'neutral, conversational',
    primaryLanguage: primaryLanguage,
    lastAnalyzedAt: DateTime.now(),
  );

  /// Average message length in characters.
  ///
  /// Calculated as total characters across all messages / message count.
  /// Very short messages (<5 chars) are excluded from this calculation.
  final double averageMessageLength;

  /// Rate of emoji usage across messages (0.0 to 1.0).
  ///
  /// Calculated as: messages containing emojis / total messages.
  final double emojiUsageRate;

  /// Rate of exclamation mark usage (0.0 to 1.0).
  ///
  /// Calculated as: messages containing '!' / total messages.
  final double exclamationRate;

  /// Score indicating how casual the user's language is (0.0 to 1.0).
  ///
  /// Based on frequency of:
  /// - Contractions: don't, won't, gonna, wanna, gotta
  /// - Slang: yeah, nah, lol, omg, tbh, etc.
  ///
  /// 0.0 = very formal, 0.5 = neutral, 1.0 = very casual.
  final double casualityScore;

  /// Human-readable description of the communication style.
  ///
  /// Examples:
  /// - "brief, casual, enthusiastic"
  /// - "detailed, formal, neutral"
  /// - "expressive, casual"
  /// - "neutral, conversational"
  final String styleDescription;

  /// ISO language code of the user's primary language in this conversation.
  ///
  /// Detected from the most frequently used language in messages.
  /// Examples: 'en', 'es', 'fr', 'de'
  final String primaryLanguage;

  /// Timestamp of the last style analysis.
  ///
  /// Used for cache invalidation - analysis should be refreshed
  /// after every ~20 new messages from the user.
  final DateTime lastAnalyzedAt;

  /// Converts the style to JSON for use in GPT prompts.
  ///
  /// Returns a compact, prompt-friendly representation of the style.
  Map<String, dynamic> toJson() => {
    'averageMessageLength': averageMessageLength.toStringAsFixed(1),
    'emojiUsageRate': '${(emojiUsageRate * 100).toStringAsFixed(0)}%',
    'exclamationRate': '${(exclamationRate * 100).toStringAsFixed(0)}%',
    'casualityScore': casualityScore.toStringAsFixed(2),
    'styleDescription': styleDescription,
    'primaryLanguage': primaryLanguage,
  };

  /// Creates a copy with specified fields replaced.
  UserCommunicationStyle copyWith({
    double? averageMessageLength,
    double? emojiUsageRate,
    double? exclamationRate,
    double? casualityScore,
    String? styleDescription,
    String? primaryLanguage,
    DateTime? lastAnalyzedAt,
  }) => UserCommunicationStyle(
    averageMessageLength: averageMessageLength ?? this.averageMessageLength,
    emojiUsageRate: emojiUsageRate ?? this.emojiUsageRate,
    exclamationRate: exclamationRate ?? this.exclamationRate,
    casualityScore: casualityScore ?? this.casualityScore,
    styleDescription: styleDescription ?? this.styleDescription,
    primaryLanguage: primaryLanguage ?? this.primaryLanguage,
    lastAnalyzedAt: lastAnalyzedAt ?? this.lastAnalyzedAt,
  );

  @override
  List<Object?> get props => [
    averageMessageLength,
    emojiUsageRate,
    exclamationRate,
    casualityScore,
    styleDescription,
    primaryLanguage,
    lastAnalyzedAt,
  ];
}
