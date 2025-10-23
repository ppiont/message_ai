/// Idiom explanation entity
library;

/// Represents an explanation of an idiom, slang, or colloquial expression
class IdiomExplanation {
  const IdiomExplanation({
    required this.phrase,
    required this.meaning,
    required this.culturalNote,
    required this.equivalents,
  });

  /// The idiomatic phrase or slang term
  final String phrase;

  /// The meaning or explanation of the idiom
  final String meaning;

  /// Cultural context or note about the idiom
  final String culturalNote;

  /// Equivalent expressions in other languages
  /// Map of language code to equivalent phrase
  final Map<String, String> equivalents;

  /// Create IdiomExplanation from JSON
  factory IdiomExplanation.fromJson(Map<String, dynamic> json) {
    // Handle equivalentIn map properly
    Map<String, String> parseEquivalents(dynamic equivalentIn) {
      if (equivalentIn == null) return {};
      if (equivalentIn is Map) {
        return equivalentIn.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
      return {};
    }

    return IdiomExplanation(
      phrase: json['phrase'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      culturalNote: json['culturalNote'] as String? ?? '',
      equivalents: parseEquivalents(json['equivalentIn']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'phrase': phrase,
      'meaning': meaning,
      'culturalNote': culturalNote,
      'equivalentIn': equivalents,
    };
  }
}

/// Container for a list of idiom explanations
class IdiomExplanationResult {
  const IdiomExplanationResult({
    required this.idioms,
  });

  /// List of idiom explanations found in the message
  final List<IdiomExplanation> idioms;

  /// Whether any idioms were found
  bool get hasIdioms => idioms.isNotEmpty;

  /// Create from JSON
  factory IdiomExplanationResult.fromJson(Map<String, dynamic> json) {
    final idiomsJson = json['idioms'] as List<dynamic>? ?? [];
    final idiomsList = idiomsJson.map((idiom) {
      if (idiom is Map) {
        final idiomMap = Map<String, dynamic>.from(idiom);
        return IdiomExplanation.fromJson(idiomMap);
      }
      // Skip invalid entries
      return null;
    }).whereType<IdiomExplanation>().toList();

    return IdiomExplanationResult(idioms: idiomsList);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'idioms': idioms.map((idiom) => idiom.toJson()).toList(),
    };
  }
}
