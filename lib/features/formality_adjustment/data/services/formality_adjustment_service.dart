/// Formality adjustment service
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/core/utils/pii_detector.dart';
import 'package:message_ai/features/formality_adjustment/domain/entities/formality_level.dart';

/// Response from formality adjustment cloud function
class _AdjustmentResponse {
  const _AdjustmentResponse({
    required this.adjustedText,
    required this.detectedFormality,
    required this.rateLimit,
  });

  /// Parse response from cloud function with type safety
  factory _AdjustmentResponse.fromData(Map<String, dynamic> data) {
    final adjustedText = data['adjustedText'] as String?;
    if (adjustedText == null || adjustedText.isEmpty) {
      throw const FormatException(
        'adjustedText is required and cannot be empty',
      );
    }

    final detectedFormality = data['detectedFormality'] as String? ?? 'neutral';
    final rateLimitData = data['rateLimit'];
    final rateLimit = rateLimitData != null
        ? _RateLimit.fromData(Map<String, dynamic>.from(rateLimitData as Map))
        : null;

    return _AdjustmentResponse(
      adjustedText: adjustedText,
      detectedFormality: detectedFormality,
      rateLimit: rateLimit,
    );
  }

  final String adjustedText;
  final String detectedFormality;
  final _RateLimit? rateLimit;
}

/// Rate limit information from cloud function
class _RateLimit {
  const _RateLimit({required this.remaining, required this.resetInSeconds});

  /// Parse rate limit data with type safety
  factory _RateLimit.fromData(Map<String, dynamic> data) {
    final remaining = data['remaining'] as int? ?? 0;
    final resetInSeconds = data['resetInSeconds'] as int? ?? 3600;
    return _RateLimit(remaining: remaining, resetInSeconds: resetInSeconds);
  }

  final int remaining;
  final int resetInSeconds;

  /// Check if rate limit is exceeded
  bool get isExceeded => remaining <= 0;
}

/// Cache entry for formality adjustments
class _CacheEntry {
  const _CacheEntry({
    required this.adjustedText,
    required this.detectedFormality,
    required this.timestamp,
  });

  final String adjustedText;
  final String detectedFormality;
  final DateTime timestamp;

  /// Check if cache entry is still valid (24-hour TTL)
  bool get isValid {
    final age = DateTime.now().difference(timestamp);
    return age.inHours < 24;
  }
}

/// Service for adjusting message formality using Cloud Functions
///
/// Enhanced with:
/// - PII detection and sanitization before adjustment
/// - Retry logic (3 attempts with exponential backoff)
/// - In-memory caching with 24-hour TTL
/// - Improved error handling with specific failure types
/// - Comprehensive debug logging
/// - Formality detection method
class FormalityAdjustmentService {
  FormalityAdjustmentService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// In-memory cache for formality adjustments (Map with cacheKey and CacheEntry)
  final Map<String, _CacheEntry> _cache = {};

  /// Maximum retry attempts
  static const int _maxRetries = 3;

  /// Adjust the formality level of a message
  ///
  /// Returns the adjusted text or a Failure
  ///
  /// Features:
  /// - PII detection and sanitization
  /// - Retry logic with exponential backoff
  /// - In-memory caching (24-hour TTL)
  /// - Detailed logging of PII detection and API calls
  Future<Either<Failure, String>> adjustFormality({
    required String text,
    required FormalityLevel targetFormality,
    FormalityLevel? currentFormality,
    String? language,
  }) async {
    try {
      // Validate input
      if (text.trim().isEmpty) {
        debugPrint('FormalityAdjustmentService: Empty text provided');
        return const Left(ValidationFailure(message: 'Text cannot be empty'));
      }

      // Detect and sanitize PII before sending to cloud function
      final piiResult = PIIDetector.detectAndSanitize(text);

      if (piiResult.containsPII) {
        debugPrint(
          'FormalityAdjustmentService: Detected PII - types: ${piiResult.detectedTypes}',
        );
        debugPrint(
          'FormalityAdjustmentService: Original text length: ${text.length}, Sanitized: ${piiResult.sanitizedText.length}',
        );
      }

      // Use sanitized text for adjustment
      final textToAdjust = piiResult.sanitizedText;
      final currentFormalityValue = currentFormality?.value ?? 'neutral';
      final languageCode = language ?? 'en';

      // Check cache first
      final cacheKey = _buildCacheKey(
        text: textToAdjust,
        targetFormality: targetFormality.value,
        currentFormality: currentFormalityValue,
        language: languageCode,
      );

      final cachedEntry = _cache[cacheKey];
      if (cachedEntry != null && cachedEntry.isValid) {
        debugPrint('FormalityAdjustmentService: Cache HIT for adjustment');
        return Right(cachedEntry.adjustedText);
      }

      // Cache miss - clean up expired entries
      _cleanExpiredCache();

      // Retry logic with exponential backoff
      var attempt = 0;
      Exception? lastException;

      while (attempt < _maxRetries) {
        try {
          debugPrint(
            'FormalityAdjustmentService: Attempt ${attempt + 1}/$_maxRetries - Adjusting text (target: ${targetFormality.value}, lang: $languageCode)',
          );

          final result = await _functions
              .httpsCallable('adjust_formality')
              .call<Map<String, dynamic>>({
                'text': textToAdjust,
                'target_formality': targetFormality.value,
                'current_formality': currentFormalityValue,
                'language': languageCode,
              });

          // Parse response with type safety
          final response = _AdjustmentResponse.fromData(
            Map<String, dynamic>.from(result.data as Map),
          );

          // Check for rate limit
          if (response.rateLimit != null && response.rateLimit!.isExceeded) {
            debugPrint('FormalityAdjustmentService: Rate limit exceeded');
            return Left(
              RateLimitExceededFailure(
                retryAfter: DateTime.now().add(
                  Duration(seconds: response.rateLimit!.resetInSeconds),
                ),
              ),
            );
          }

          debugPrint(
            'FormalityAdjustmentService: Adjustment successful - detected: ${response.detectedFormality}, target: ${targetFormality.value}',
          );

          // Cache the result
          _cache[cacheKey] = _CacheEntry(
            adjustedText: response.adjustedText,
            detectedFormality: response.detectedFormality,
            timestamp: DateTime.now(),
          );

          return Right(response.adjustedText);
        } on FirebaseFunctionsException catch (e) {
          lastException = e;
          debugPrint(
            'FormalityAdjustmentService: Firebase Functions error (attempt ${attempt + 1}): ${e.code} - ${e.message}',
          );

          // Handle specific error codes
          if (e.code == 'resource-exhausted') {
            debugPrint(
              'FormalityAdjustmentService: Rate limit exceeded (non-retryable)',
            );
            return Left(
              RateLimitExceededFailure(
                retryAfter: DateTime.now().add(const Duration(hours: 1)),
              ),
            );
          }

          // Don't retry on specific error codes
          if (e.code == 'unauthenticated' ||
              e.code == 'permission-denied' ||
              e.code == 'invalid-argument') {
            debugPrint(
              'FormalityAdjustmentService: Non-retryable error, failing immediately',
            );
            return Left(
              AIServiceFailure(
                message:
                    'Formality adjustment failed: ${e.message ?? "Unknown error"}',
                code: e.code,
              ),
            );
          }

          // Retry with exponential backoff
          attempt++;
          if (attempt < _maxRetries) {
            final backoffDuration = Duration(
              milliseconds: 1000 * (1 << (attempt - 1)), // 1s, 2s, 4s
            );
            debugPrint(
              'FormalityAdjustmentService: Retrying after ${backoffDuration.inSeconds}s backoff...',
            );
            await Future<void>.delayed(backoffDuration);
          }
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          debugPrint(
            'FormalityAdjustmentService: Unexpected error (attempt ${attempt + 1}): $e',
          );

          attempt++;
          if (attempt < _maxRetries) {
            final backoffDuration = Duration(
              milliseconds: 1000 * (1 << (attempt - 1)),
            );
            await Future<void>.delayed(backoffDuration);
          }
        }
      }

      // All retries exhausted
      debugPrint(
        'FormalityAdjustmentService: All $attempt retry attempts exhausted',
      );
      return Left(
        AIServiceFailure(
          message:
              'Formality adjustment failed after $_maxRetries attempts: ${lastException?.toString() ?? "Unknown error"}',
        ),
      );
    } catch (e) {
      debugPrint('FormalityAdjustmentService: Fatal error: $e');
      return Left(AIServiceFailure(message: 'Formality adjustment failed: $e'));
    }
  }

  /// Detect the current formality level of a message
  ///
  /// Returns the detected formality level (casual, neutral, or formal)
  ///
  /// Features:
  /// - PII detection and sanitization
  /// - Retry logic with exponential backoff
  /// - In-memory caching (24-hour TTL)
  /// - Uses GPT-4o-mini for detection
  Future<Either<Failure, FormalityLevel>> detectFormality({
    required String text,
    String? language,
  }) async {
    try {
      // Validate input
      if (text.trim().isEmpty) {
        debugPrint(
          'FormalityAdjustmentService: Empty text provided for detection',
        );
        return const Left(ValidationFailure(message: 'Text cannot be empty'));
      }

      // Detect and sanitize PII before sending to cloud function
      final piiResult = PIIDetector.detectAndSanitize(text);

      if (piiResult.containsPII) {
        debugPrint(
          'FormalityAdjustmentService: Detected PII in detection - types: ${piiResult.detectedTypes}',
        );
      }

      // Use sanitized text for detection
      final textToAnalyze = piiResult.sanitizedText;
      final languageCode = language ?? 'en';

      // Check cache first (use a special detection cache key)
      final cacheKey = _buildDetectionCacheKey(
        text: textToAnalyze,
        language: languageCode,
      );

      final cachedEntry = _cache[cacheKey];
      if (cachedEntry != null && cachedEntry.isValid) {
        debugPrint('FormalityAdjustmentService: Cache HIT for detection');
        return Right(FormalityLevel.fromString(cachedEntry.detectedFormality));
      }

      // Cache miss - clean up expired entries
      _cleanExpiredCache();

      // Retry logic with exponential backoff
      var attempt = 0;
      Exception? lastException;

      while (attempt < _maxRetries) {
        try {
          debugPrint(
            'FormalityAdjustmentService: Attempt ${attempt + 1}/$_maxRetries - Detecting formality (lang: $languageCode)',
          );

          // Use adjust_formality with target = current to get detection only
          // This is a clever reuse of the existing cloud function
          final result = await _functions
              .httpsCallable('adjust_formality')
              .call<Map<String, dynamic>>({
                'text': textToAnalyze,
                'target_formality': 'neutral', // Doesn't matter for detection
                'current_formality': 'neutral', // Will be detected
                'language': languageCode,
              });

          // Parse response with type safety
          final response = _AdjustmentResponse.fromData(
            Map<String, dynamic>.from(result.data as Map),
          );

          debugPrint(
            'FormalityAdjustmentService: Detection successful - detected: ${response.detectedFormality}',
          );

          // Cache the result
          _cache[cacheKey] = _CacheEntry(
            adjustedText: textToAnalyze, // Not used for detection
            detectedFormality: response.detectedFormality,
            timestamp: DateTime.now(),
          );

          return Right(FormalityLevel.fromString(response.detectedFormality));
        } on FirebaseFunctionsException catch (e) {
          lastException = e;
          debugPrint(
            'FormalityAdjustmentService: Firebase Functions error in detection (attempt ${attempt + 1}): ${e.code} - ${e.message}',
          );

          // Don't retry on specific error codes
          if (e.code == 'unauthenticated' ||
              e.code == 'permission-denied' ||
              e.code == 'invalid-argument' ||
              e.code == 'resource-exhausted') {
            debugPrint(
              'FormalityAdjustmentService: Non-retryable error in detection',
            );
            return Left(
              AIServiceFailure(
                message:
                    'Formality detection failed: ${e.message ?? "Unknown error"}',
                code: e.code,
              ),
            );
          }

          // Retry with exponential backoff
          attempt++;
          if (attempt < _maxRetries) {
            final backoffDuration = Duration(
              milliseconds: 1000 * (1 << (attempt - 1)),
            );
            debugPrint(
              'FormalityAdjustmentService: Retrying detection after ${backoffDuration.inSeconds}s backoff...',
            );
            await Future<void>.delayed(backoffDuration);
          }
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          debugPrint(
            'FormalityAdjustmentService: Unexpected error in detection (attempt ${attempt + 1}): $e',
          );

          attempt++;
          if (attempt < _maxRetries) {
            final backoffDuration = Duration(
              milliseconds: 1000 * (1 << (attempt - 1)),
            );
            await Future<void>.delayed(backoffDuration);
          }
        }
      }

      // All retries exhausted
      debugPrint(
        'FormalityAdjustmentService: All $attempt detection retry attempts exhausted',
      );
      return Left(
        AIServiceFailure(
          message:
              'Formality detection failed after $_maxRetries attempts: ${lastException?.toString() ?? "Unknown error"}',
        ),
      );
    } catch (e) {
      debugPrint('FormalityAdjustmentService: Fatal error in detection: $e');
      return Left(AIServiceFailure(message: 'Formality detection failed: $e'));
    }
  }

  /// Build cache key for formality adjustment
  String _buildCacheKey({
    required String text,
    required String targetFormality,
    required String currentFormality,
    required String language,
  }) =>
      // Use a simple concatenation with separators
      // Note: This is a basic cache key. For production, consider hashing
      '$text|$currentFormality|$targetFormality|$language';

  /// Build cache key for formality detection
  String _buildDetectionCacheKey({
    required String text,
    required String language,
  }) => 'DETECT|$text|$language';

  /// Clean up expired cache entries
  void _cleanExpiredCache() {
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (!entry.value.isValid) {
        expiredKeys.add(entry.key);
      }
    }

    expiredKeys.forEach(_cache.remove);

    if (expiredKeys.isNotEmpty) {
      debugPrint(
        'FormalityAdjustmentService: Cleaned ${expiredKeys.length} expired cache entries',
      );
    }
  }

  /// Clear all cache entries (useful for testing or manual cache invalidation)
  void clearCache() {
    final count = _cache.length;
    _cache.clear();
    debugPrint('FormalityAdjustmentService: Cleared $count cache entries');
  }
}
