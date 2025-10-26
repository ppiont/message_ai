/// Retry policy with exponential backoff for network operations
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

/// Retry policy with exponential backoff and jitter.
///
/// **Problem:**
/// Transient network failures are common in mobile apps (poor connectivity,
/// server issues, rate limits). Naive retry strategies either:
/// - Retry too aggressively → Waste battery, hit rate limits
/// - Retry too slowly → Poor user experience
/// - Create thundering herd → All clients retry simultaneously
///
/// **Solution:**
/// Exponential backoff with jitter provides optimal retry behavior:
/// - Exponential: Delay doubles each attempt (1s → 2s → 4s → 8s → 16s → 32s)
/// - Jitter: Random ±20% prevents synchronized retries across clients
/// - Max delay cap: Prevents unbounded waits
/// - Max attempts: Eventually gives up on persistent failures
///
/// **Performance:**
/// - Initial retry: 1s (fast recovery for transient issues)
/// - Max delay: 32s (reasonable wait for persistent issues)
/// - Total time for 5 attempts: ~1 + 2 + 4 + 8 + 16 = 31s
///
/// **Use Cases:**
/// - Firestore sync operations (MessageSyncWorker)
/// - Cloud Function calls (translation, formality adjustment)
/// - Real-time Database presence updates
/// - Any network operation that can fail transiently
///
/// Example:
/// ```dart
/// final policy = RetryPolicy();
///
/// for (var attempt = 0; attempt < policy.maxAttempts; attempt++) {
///   try {
///     await performNetworkOperation();
///     break; // Success!
///   } catch (e) {
///     if (attempt < policy.maxAttempts - 1) {
///       final delay = policy.getDelay(attempt);
///       await Future.delayed(delay);
///     } else {
///       rethrow; // Max attempts reached
///     }
///   }
/// }
/// ```
class RetryPolicy {
  /// Create a retry policy with exponential backoff
  ///
  /// Parameters:
  /// - initialDelay: First retry delay (default: 1 second)
  /// - maxDelay: Maximum retry delay (default: 32 seconds)
  /// - multiplier: Delay multiplier for each attempt (default: 2.0)
  /// - jitterPercent: Random jitter as percentage (default: 0.2 = ±20%)
  /// - maxAttempts: Maximum number of retry attempts (default: 5)
  const RetryPolicy({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 32),
    this.multiplier = 2.0,
    this.jitterPercent = 0.2,
    this.maxAttempts = 5,
  });

  /// Initial delay before first retry
  final Duration initialDelay;

  /// Maximum delay between retries (cap for exponential growth)
  final Duration maxDelay;

  /// Multiplier for exponential backoff (delay *= multiplier each attempt)
  final double multiplier;

  /// Jitter as percentage of delay (0.2 = ±20%)
  ///
  /// Prevents thundering herd by randomizing retry times across clients.
  final double jitterPercent;

  /// Maximum number of retry attempts
  ///
  /// After this many attempts, the operation is considered failed.
  final int maxAttempts;

  /// Calculate delay for a given attempt number (0-indexed)
  ///
  /// Formula: min(initialDelay * multiplier^attempt, maxDelay) ± jitter
  ///
  /// Example with defaults:
  /// - Attempt 0: 1s ± 20% = 0.8s - 1.2s
  /// - Attempt 1: 2s ± 20% = 1.6s - 2.4s
  /// - Attempt 2: 4s ± 20% = 3.2s - 4.8s
  /// - Attempt 3: 8s ± 20% = 6.4s - 9.6s
  /// - Attempt 4: 16s ± 20% = 12.8s - 19.2s
  /// - Attempt 5+: 32s ± 20% = 25.6s - 38.4s (capped at maxDelay)
  Duration getDelay(int attemptNumber) {
    if (attemptNumber < 0) {
      return Duration.zero;
    }

    // Calculate exponential delay: initialDelay * multiplier^attempt
    final exponentialDelayMs = initialDelay.inMilliseconds *
        pow(multiplier, attemptNumber).toDouble();

    // Cap at maxDelay
    final cappedDelayMs = min(exponentialDelayMs, maxDelay.inMilliseconds.toDouble());

    // Add jitter: ±jitterPercent
    final jitterMs = cappedDelayMs * jitterPercent;
    final random = Random();
    final randomJitter = (random.nextDouble() * 2 - 1) * jitterMs; // Random value in [-jitterMs, +jitterMs]
    final finalDelayMs = cappedDelayMs + randomJitter;

    // Ensure non-negative
    final clampedDelayMs = max(0, finalDelayMs).toInt();

    debugPrint(
      '[RetryPolicy] Attempt $attemptNumber: delay ${clampedDelayMs}ms '
      '(exponential: ${exponentialDelayMs.toInt()}ms, '
      'capped: ${cappedDelayMs.toInt()}ms, '
      'jitter: ${randomJitter.toInt()}ms)',
    );

    return Duration(milliseconds: clampedDelayMs);
  }

  /// Check if retry should be attempted based on attempt number
  ///
  /// Returns true if attemptNumber < maxAttempts, false otherwise.
  bool shouldRetry(int attemptNumber) => attemptNumber < maxAttempts;

  /// Calculate total time spent on all retry attempts (without jitter)
  ///
  /// This is the sum of all delays: initialDelay * (1 + multiplier + multiplier^2 + ... + multiplier^(n-1))
  ///
  /// With defaults (5 attempts): 1 + 2 + 4 + 8 + 16 = 31 seconds
  Duration get totalRetryTime {
    var totalMs = 0.0;
    for (var i = 0; i < maxAttempts; i++) {
      final delayMs = min(
        initialDelay.inMilliseconds * pow(multiplier, i).toDouble(),
        maxDelay.inMilliseconds.toDouble(),
      );
      totalMs += delayMs;
    }
    return Duration(milliseconds: totalMs.toInt());
  }

  @override
  String toString() => 'RetryPolicy('
      'initialDelay: ${initialDelay.inSeconds}s, '
      'maxDelay: ${maxDelay.inSeconds}s, '
      'multiplier: $multiplier, '
      'jitter: ${(jitterPercent * 100).toInt()}%, '
      'maxAttempts: $maxAttempts, '
      'totalTime: ~${totalRetryTime.inSeconds}s '
      ')';
}

/// Default retry policy for Firestore sync operations
const firestoreSyncRetryPolicy = RetryPolicy();

/// Aggressive retry policy for time-sensitive operations
const aggressiveRetryPolicy = RetryPolicy(
  initialDelay: Duration(milliseconds: 500),
  maxDelay: Duration(seconds: 8),
  maxAttempts: 3,
);

/// Conservative retry policy for rate-limited operations
const conservativeRetryPolicy = RetryPolicy(
  initialDelay: Duration(seconds: 2),
  maxDelay: Duration(seconds: 60),
  maxAttempts: 4,
);
