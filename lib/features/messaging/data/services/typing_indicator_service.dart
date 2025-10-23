import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing typing indicators in conversations.
///
/// Features:
/// - Real-time typing status updates
/// - Debouncing to reduce Firestore writes
/// - Auto-timeout to clear stale status
/// - Watch other users' typing status
class TypingIndicatorService {
  TypingIndicatorService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  // Configuration
  static const Duration debounceDuration = Duration(milliseconds: 300);
  static const Duration typingTimeout = Duration(seconds: 3);

  // State
  final Map<String, Timer?> _debounceTimers = {};
  final Map<String, Timer?> _timeoutTimers = {};

  // ============================================================================
  // Public API
  // ============================================================================

  /// Updates the typing status for a user in a conversation.
  ///
  /// Uses debouncing to prevent excessive Firestore writes.
  /// Automatically clears the status after [typingTimeout] if not updated.
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
      // Debounce the typing update
      _debounceTimers[key] = Timer(debounceDuration, () async {
        await _updateTypingStatus(
          conversationId: conversationId,
          userId: userId,
          userName: userName,
          isTyping: true,
        );

        // Set timeout to auto-clear typing status
        _timeoutTimers[key]?.cancel();
        _timeoutTimers[key] = Timer(typingTimeout, () async {
          await _updateTypingStatus(
            conversationId: conversationId,
            userId: userId,
            userName: userName,
            isTyping: false,
          );
        });
      });
    } else {
      // Immediately clear typing status (no debounce)
      _timeoutTimers[key]?.cancel();
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
  /// Returns a list of users currently typing.
  Stream<List<TypingUser>> watchTypingUsers({
    required String conversationId,
    required String currentUserId,
  }) => _firestore
      .collection('conversations')
      .doc(conversationId)
      .collection('typingStatus')
      .where('isTyping', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final now = DateTime.now();

        return snapshot.docs
            .where((doc) {
              // Exclude current user
              if (doc.id == currentUserId) {
                return false;
              }

              // Check if status is still valid (not stale)
              final data = doc.data();
              final lastUpdated = (data['lastUpdated'] as Timestamp?)?.toDate();

              if (lastUpdated == null) {
                return false;
              }

              // Consider stale if older than timeout + 1 second buffer
              final staleDuration = typingTimeout + const Duration(seconds: 1);
              return now.difference(lastUpdated) < staleDuration;
            })
            .map(TypingUser.fromFirestore)
            .toList();
      });

  /// Clears typing status for a user in a conversation.
  ///
  /// Useful when user leaves the chat screen.
  Future<void> clearTyping({
    required String conversationId,
    required String userId,
    required String userName,
  }) async {
    final key = '$conversationId-$userId';

    // Cancel all timers
    _debounceTimers[key]?.cancel();
    _timeoutTimers[key]?.cancel();

    // Clear status
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
    for (final timer in _timeoutTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();
    _timeoutTimers.clear();
  }

  // ============================================================================
  // Private Methods
  // ============================================================================

  /// Updates the typing status in Firestore.
  Future<void> _updateTypingStatus({
    required String conversationId,
    required String userId,
    required String userName,
    required bool isTyping,
  }) async {
    final docRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('typingStatus')
        .doc(userId);

    if (isTyping) {
      await docRef.set({
        'userId': userId,
        'userName': userName,
        'isTyping': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } else {
      // Delete the document when not typing (cleaner than setting false)
      await docRef.delete();
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

  factory TypingUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return TypingUser(
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
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
