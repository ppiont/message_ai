import 'package:equatable/equatable.dart';

/// Domain entity representing a single smart reply suggestion.
///
/// Smart replies are AI-generated response suggestions that match the user's
/// communication style and are contextually relevant to the incoming message.
class SmartReply extends Equatable {
  const SmartReply({
    required this.text,
    required this.intent,
  });

  /// Creates a SmartReply from JSON data.
  ///
  /// Used to parse Cloud Function responses.
  factory SmartReply.fromJson(Map<String, dynamic> json) => SmartReply(
    text: json['text'] as String,
    intent: json['intent'] as String,
  );

  /// The suggested reply text (typically <50 characters).
  final String text;

  /// The intent/tone of the reply.
  ///
  /// Valid values: 'positive', 'neutral', 'question'
  /// - positive: Affirmative, friendly responses
  /// - neutral: Balanced, informational responses
  /// - question: Follow-up questions or clarifications
  final String intent;

  /// Converts the SmartReply to JSON.
  Map<String, dynamic> toJson() => {
    'text': text,
    'intent': intent,
  };

  @override
  List<Object?> get props => [text, intent];

  @override
  String toString() => 'SmartReply(text: $text, intent: $intent)';
}
