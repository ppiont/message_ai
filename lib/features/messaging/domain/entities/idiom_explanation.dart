/// Idiom explanation entity
library;

import 'package:equatable/equatable.dart';

/// Explanation of an idiom, slang term, or colloquial expression found in a message
///
/// Provides comprehensive information about idiomatic language including:
/// - The phrase and its literal meaning
/// - The actual cultural/colloquial meaning
/// - Cultural context and notes
/// - Equivalent expressions in other languages
class IdiomExplanation extends Equatable {
  const IdiomExplanation({
    required this.phrase,
    required this.meaning,
    required this.culturalNote,
    this.equivalents = const {},
  });

  /// Create from JSON
  factory IdiomExplanation.fromJson(Map<String, dynamic> json) => IdiomExplanation(
      phrase: json['phrase'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      culturalNote: json['culturalNote'] as String? ?? '',
      equivalents: _parseEquivalents(json['equivalents'] as dynamic),
    );

  /// The idiom phrase
  final String phrase;

  /// Meaning of the idiom
  final String meaning;

  /// Cultural context and explanation
  final String culturalNote;

  /// Equivalent expressions in other languages
  ///
  /// Keys are language names or codes, values are the equivalent expressions
  final Map<String, String> equivalents;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'phrase': phrase,
    'meaning': meaning,
    'culturalNote': culturalNote,
    'equivalents': equivalents,
  };

  /// Create a copy with updated fields
  IdiomExplanation copyWith({
    String? phrase,
    String? meaning,
    String? culturalNote,
    Map<String, String>? equivalents,
  }) =>
      IdiomExplanation(
        phrase: phrase ?? this.phrase,
        meaning: meaning ?? this.meaning,
        culturalNote: culturalNote ?? this.culturalNote,
        equivalents: equivalents ?? this.equivalents,
      );

  @override
  List<Object?> get props => [phrase, meaning, culturalNote, equivalents];
}

/// Parse equivalents from JSON (handles both Map and other formats)
Map<String, String> _parseEquivalents(dynamic equivalentsData) {
  if (equivalentsData is Map<dynamic, dynamic>) {
    return Map<String, String>.from(
      equivalentsData.cast<String, String>(),
    );
  }
  return {};
}
