import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

/// Service for managing typing indicators using Firebase Realtime Database.
///
/// Features:
/// - Real-time typing status updates
/// - Debouncing to reduce RTDB writes (300ms)
/// - **Automatic cleanup** via `onDisconnect()` when user disconnects
/// - No manual timeout needed - RTDB handles connection state
///
/// Architecture:
/// - Uses Firebase Realtime Database (NOT Firestore) for ephemeral typing data
/// - Data structure: `/typing/{conversationId}/{userId}` → `{isTyping, userName, timestamp}`
/// - `onDisconnect()` automatically removes typing status when WebSocket drops
/// - Works even if app is force-killed or network is lost
class RtdbTypingService {
  RtdbTypingService({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  // Configuration
  static const Duration debounceDuration = Duration(milliseconds: 300);

  // State
  final Map<String, Timer?> _debounceTimers = {};

  // ============================================================================
  // Public API
  // ============================================================================

  /// Updates the typing status for a user in a conversation.
  ///
  /// Uses debouncing to prevent excessive RTDB writes (only writes after 300ms
  /// of no typing activity).
  ///
  /// Automatically sets up `onDisconnect().remove()` to clear typing status
  /// when the user's connection drops (app closed, network lost, etc.).
  Future<void> setTyping({
    required String conversationId,
    required String userId,
    required String userName,
    required bool isTyping,
  }) async {
    final key = '$conversationId-$userId';

    // Cancel existing debounce timer
    _debounceTimers[key]?.cancel();

    if (isTyping) {
      // Debounce the typing update to reduce writes
      _debounceTimers[key] = Timer(debounceDuration, () async {
        await _updateTypingStatus(
          conversationId: conversationId,
          userId: userId,
          userName: userName,
          isTyping: true,
        );
      });
    } else {
      // Immediately clear typing status (no debounce)
      await _updateTypingStatus(
        conversationId: conversationId,
        userId: userId,
        userName: userName,
        isTyping: false,
      );
    }
  }

  /// Watches typing status for other users in a conversation.
  ///
  /// Excludes the current user from the stream.
  /// Returns a list of users currently typing in real-time.
  ///
  /// The stream automatically updates when:
  /// - Users start typing (isTyping = true)
  /// - Users stop typing (isTyping = false or entry removed)
  /// - Users disconnect (entry automatically removed by onDisconnect)
  Stream<List<TypingUser>> watchTypingUsers({
    required String conversationId,
    required String currentUserId,
  }) {
    final typingRef = _database.ref('typing/$conversationId');

    return typingRef.onValue.map((event) {
      if (!event.snapshot.exists) {
        return <TypingUser>[];
      }

      final data = event.snapshot.value as Map<Object?, Object?>?;
      if (data == null) {
        return <TypingUser>[];
      }

      final typingUsers = <TypingUser>[];

      for (final entry in data.entries) {
        final userId = entry.key! as String;

        // Exclude current user
        if (userId == currentUserId) {
          continue;
        }

        final userData = entry.value as Map<Object?, Object?>?;
        if (userData == null) {
          continue;
        }

        final isTyping = userData['isTyping'] as bool? ?? false;
        if (!isTyping) {
          continue;
        }

        final userName = userData['userName'] as String? ?? 'Unknown';
        final timestampValue = userData['timestamp'];

        DateTime timestamp;
        if (timestampValue is int) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue);
        } else {
          timestamp = DateTime.now();
        }

        typingUsers.add(
          TypingUser(
            userId: userId,
            userName: userName,
            lastUpdated: timestamp,
          ),
        );
      }

      return typingUsers;
    });
  }

  /// Clears typing status for a user in a conversation.
  ///
  /// Useful when user leaves the chat screen or explicitly stops composing.
  /// Also cancels the onDisconnect() callback for this conversation.
  Future<void> clearTyping({
    required String conversationId,
    required String userId,
    required String userName,
  }) async {
    final key = '$conversationId-$userId';

    // Cancel debounce timer
    _debounceTimers[key]?.cancel();

    // Clear typing status
    await _updateTypingStatus(
      conversationId: conversationId,
      userId: userId,
      userName: userName,
      isTyping: false,
    );
  }

  /// Disposes all timers.
  ///
  /// Call this when the service is no longer needed.
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();
  }

  // ============================================================================
  // Private Methods
  // ============================================================================

  /// Updates the typing status in Realtime Database.
  ///
  /// When `isTyping` is true:
  /// - Sets typing data at `/typing/{conversationId}/{userId}`
  /// - Configures `onDisconnect().remove()` to auto-clear on disconnect
  ///
  /// When `isTyping` is false:
  /// - Removes the typing entry
  /// - Cancels any pending onDisconnect operations
  Future<void> _updateTypingStatus({
    required String conversationId,
    required String userId,
    required String userName,
    required bool isTyping,
  }) async {
    final typingRef = _database.ref('typing/$conversationId/$userId');

    if (isTyping) {
      // Set up onDisconnect to automatically remove typing status
      // This ensures typing status is cleared even if app crashes or network drops
      await typingRef.onDisconnect().remove();

      // Set typing status
      await typingRef.set({
        'userId': userId,
        'userName': userName,
        'isTyping': true,
        'timestamp': ServerValue.timestamp,
      });
    } else {
      // Cancel onDisconnect operation
      await typingRef.onDisconnect().cancel();

      // Remove typing status (cleaner than setting false)
      await typingRef.remove();
    }
  }
}

// ============================================================================
// Data Classes
// ============================================================================

/// Represents a user who is currently typing.
class TypingUser {
  TypingUser({
    required this.userId,
    required this.userName,
    required this.lastUpdated,
  });

  final String userId;
  final String userName;
  final DateTime lastUpdated;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is TypingUser &&
        other.userId == userId &&
        other.userName == userName;
  }

  @override
  int get hashCode => userId.hashCode ^ userName.hashCode;

  @override
  String toString() => 'TypingUser(userId: $userId, userName: $userName)';
}
