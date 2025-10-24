/// Idiom explanation entity
library;

import 'package:equatable/equatable.dart';

/// Represents an explanation of an idiom, slang, or colloquial expression
class IdiomExplanation extends Equatable {
  const IdiomExplanation({
    required this.phrase,
    required this.meaning,
    required this.culturalNote,
    required this.equivalents,
  });

  /// Create IdiomExplanation from JSON
  factory IdiomExplanation.fromJson(Map<String, dynamic> json) =>
      IdiomExplanation(
        phrase: json['phrase'] as String? ?? '',
        meaning: json['meaning'] as String? ?? '',
        culturalNote: json['culturalNote'] as String? ?? '',
        equivalents: _parseEquivalents(json['equivalentIn']),
      );

  /// Parse equivalents map from dynamic type
  // ignore: prefer_final_locals
  static Map<String, String> _parseEquivalents(final Object? equivalentIn) =>
      switch (equivalentIn) {
        null => <String, String>{},
        // ignore: prefer_final_locals
        Map<Object?, Object?> map => <String, String>{
          for (final MapEntry<Object?, Object?> mapEntry in map.entries)
            mapEntry.key.toString(): mapEntry.value.toString(),
        },
        _ => <String, String>{},
      };

  /// The idiomatic phrase or slang term
  final String phrase;

  /// The meaning or explanation of the idiom
  final String meaning;

  /// Cultural context or note about the idiom
  final String culturalNote;

  /// Equivalent expressions in other languages
  /// Map of language code to equivalent phrase
  final Map<String, String> equivalents;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'phrase': phrase,
    'meaning': meaning,
    'culturalNote': culturalNote,
    'equivalentIn': equivalents,
  };

  @override
  List<Object?> get props => [phrase, meaning, culturalNote, equivalents];
}

/// Container for a list of idiom explanations
class IdiomExplanationResult {
  const IdiomExplanationResult({required this.idioms});

  /// Create from JSON
  factory IdiomExplanationResult.fromJson(Map<String, dynamic> json) {
    final idiomsJson = json['idioms'] as List<dynamic>? ?? <dynamic>[];
    final idiomsList = idiomsJson
        .map<IdiomExplanation?>((final Object? idiom) {
          if (idiom is Map<Object?, Object?>) {
            final idiomMap = Map<String, dynamic>.from(idiom);
            return IdiomExplanation.fromJson(idiomMap);
          }
          // Skip invalid entries
          return null;
        })
        .whereType<IdiomExplanation>()
        .toList();

    return IdiomExplanationResult(idioms: idiomsList);
  }

  /// List of idiom explanations found in the message
  final List<IdiomExplanation> idioms;

  /// Whether any idioms were found
  bool get hasIdioms => idioms.isNotEmpty;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'idioms': idioms.map((idiom) => idiom.toJson()).toList(),
  };
}
