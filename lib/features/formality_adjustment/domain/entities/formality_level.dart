/// Formality level entity
library;

/// Represents the formality level of a message
enum FormalityLevel {
  original('original', 'Original'),
  casual('casual', 'Casual'),
  neutral('neutral', 'Neutral'),
  formal('formal', 'Formal');

  const FormalityLevel(this.value, this.displayName);

  final String value;
  final String displayName;

  /// Create FormalityLevel from string value
  static FormalityLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'original':
        return FormalityLevel.original;
      case 'casual':
        return FormalityLevel.casual;
      case 'neutral':
        return FormalityLevel.neutral;
      case 'formal':
        return FormalityLevel.formal;
      default:
        return FormalityLevel.neutral;
    }
  }

  @override
  String toString() => value;
}
