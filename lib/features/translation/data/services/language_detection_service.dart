import 'package:flutter/foundation.dart';

import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

/// Service for detecting the language of text using Google ML Kit.
///
/// Provides on-device language detection with caching to optimize performance.
/// Uses a confidence threshold of 0.5 to filter out unreliable detections.
class LanguageDetectionService {
  LanguageDetectionService()
    : _languageIdentifier = LanguageIdentifier(
        confidenceThreshold: confidenceThreshold,
      );
  final LanguageIdentifier _languageIdentifier;

  /// Cache for detected languages to avoid redundant processing.
  /// Key: message text, Value: detected language result
  final Map<String, IdentifiedLanguage> _detectionCache = {};

  /// Confidence threshold for language detection.
  /// Detections below this threshold are considered unreliable.
  static const double confidenceThreshold = 0.5;

  /// Detects the language of the given text.
  ///
  /// Returns a language code (e.g., 'en', 'es', 'fr') if detection is successful
  /// and confidence is above the threshold. Returns null if:
  /// - Text is empty or too short
  /// - Detection confidence is below threshold
  /// - Language is 'und' (undetermined)
  ///
  /// Results are cached to optimize performance for duplicate texts.
  ///
  /// Example:
  /// ```dart
  /// final service = LanguageDetectionService();
  /// final language = await service.detectLanguage('Hello world');
  /// // Returns: 'en'
  /// ```
  Future<String?> detectLanguage(String text) async {
    // Validate input
    if (text.trim().isEmpty || text.trim().length < 3) {
      return null;
    }

    // Check cache first
    if (_detectionCache.containsKey(text)) {
      final cached = _detectionCache[text]!;
      return cached.languageTag != 'und' &&
              cached.confidence >= confidenceThreshold
          ? cached.languageTag
          : null;
    }

    try {
      // Perform language identification
      // This returns a list of possible languages with confidence scores
      final possibleLanguages = await _languageIdentifier
          .identifyPossibleLanguages(text);

      // Check if any languages were detected
      if (possibleLanguages.isEmpty) {
        return null;
      }

      // Get the most likely language (first in the list)
      final topLanguage = possibleLanguages.first;

      // Cache the result
      _detectionCache[text] = topLanguage;

      // Check if language was successfully identified
      // 'und' means undetermined - language couldn't be detected
      if (topLanguage.languageTag == 'und' ||
          topLanguage.confidence < confidenceThreshold) {
        return null;
      }

      return topLanguage.languageTag;
    } catch (e) {
      // Log error but don't throw - graceful degradation
      debugPrint('Language detection error: $e');
      return null;
    }
  }

  /// Detects language with detailed confidence information.
  ///
  /// Returns a result containing:
  /// - 'languageCode': detected language code
  /// - 'confidence': confidence score (0.0 to 1.0)
  ///
  /// Returns null if detection fails or confidence is below threshold.
  Future<LanguageDetectionResult?> detectLanguageWithConfidence(
    String text,
  ) async {
    if (text.trim().isEmpty || text.trim().length < 3) {
      return null;
    }

    try {
      // Check cache first
      if (_detectionCache.containsKey(text)) {
        final cached = _detectionCache[text]!;
        if (cached.languageTag == 'und' ||
            cached.confidence < confidenceThreshold) {
          return null;
        }
        return LanguageDetectionResult(
          languageCode: cached.languageTag,
          confidence: cached.confidence,
        );
      }

      // Perform detection
      final possibleLanguages = await _languageIdentifier
          .identifyPossibleLanguages(text);

      if (possibleLanguages.isEmpty) {
        return null;
      }

      final topLanguage = possibleLanguages.first;
      _detectionCache[text] = topLanguage;

      if (topLanguage.languageTag == 'und' ||
          topLanguage.confidence < confidenceThreshold) {
        return null;
      }

      return LanguageDetectionResult(
        languageCode: topLanguage.languageTag,
        confidence: topLanguage.confidence,
      );
    } catch (e) {
      debugPrint('Language detection error: $e');
      return null;
    }
  }

  /// Clears the detection cache.
  ///
  /// Useful for testing or memory management.
  void clearCache() {
    _detectionCache.clear();
  }

  /// Returns the current cache size.
  int get cacheSize => _detectionCache.length;

  /// Disposes of the language identifier and clears the cache.
  ///
  /// Should be called when the service is no longer needed.
  void dispose() {
    _languageIdentifier.close();
    _detectionCache.clear();
  }
}

/// Result of language detection with confidence information.
class LanguageDetectionResult {
  const LanguageDetectionResult({
    required this.languageCode,
    required this.confidence,
  });
  final String languageCode;
  final double confidence;

  @override
  String toString() =>
      'LanguageDetectionResult(language: $languageCode, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}
