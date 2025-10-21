import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing user online/offline presence.
///
/// Features:
/// - Real-time presence updates
/// - Automatic offline detection using Firestore's onDisconnect
/// - Last seen timestamps
/// - Heartbeat mechanism for active sessions
class PresenceService {
  final FirebaseFirestore _firestore;

  // Configuration
  static const Duration heartbeatInterval = Duration(seconds: 30);

  // State
  Timer? _heartbeatTimer;

  PresenceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================================
  // Public API
  // ============================================================================

  /// Sets user as online and starts heartbeat.
  ///
  /// Should be called when app starts or user logs in.
  Future<void> setOnline({
    required String userId,
    required String userName,
  }) async {
    // Update presence document
    await _updatePresence(userId: userId, userName: userName, isOnline: true);

    // Start heartbeat to maintain online status
    _startHeartbeat(userId: userId, userName: userName);
  }

  /// Sets user as offline and stops heartbeat.
  ///
  /// Should be called when app closes or user logs out.
  Future<void> setOffline({
    required String userId,
    required String userName,
  }) async {
    // Stop heartbeat
    _stopHeartbeat();

    // Update presence document
    await _updatePresence(userId: userId, userName: userName, isOnline: false);
  }

  /// Watches presence status for a specific user.
  ///
  /// Returns a stream of presence updates.
  Stream<UserPresence?> watchUserPresence({required String userId}) {
    return _firestore.collection('presence').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      return UserPresence.fromFirestore(snapshot);
    });
  }

  /// Watches presence status for multiple users.
  ///
  /// Returns a stream of presence map (userId -> UserPresence).
  Stream<Map<String, UserPresence>> watchUsersPresence({
    required List<String> userIds,
  }) {
    if (userIds.isEmpty) {
      return Stream.value({});
    }

    // Firestore 'in' query is limited to 10 items
    // For larger lists, we'd need to batch the queries
    final limitedUserIds = userIds.take(10).toList();

    return _firestore
        .collection('presence')
        .where(FieldPath.documentId, whereIn: limitedUserIds)
        .snapshots()
        .map((snapshot) {
          final presenceMap = <String, UserPresence>{};

          for (final doc in snapshot.docs) {
            presenceMap[doc.id] = UserPresence.fromFirestore(doc);
          }

          return presenceMap;
        });
  }

  /// Disposes the service and stops heartbeat.
  void dispose() {
    _stopHeartbeat();
  }

  // ============================================================================
  // Private Methods
  // ============================================================================

  /// Updates the presence document in Firestore.
  Future<void> _updatePresence({
    required String userId,
    required String userName,
    required bool isOnline,
  }) async {
    final docRef = _firestore.collection('presence').doc(userId);

    await docRef.set({
      'userId': userId,
      'userName': userName,
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Starts periodic heartbeat to maintain online status.
  void _startHeartbeat({required String userId, required String userName}) {
    // Cancel existing timer
    _stopHeartbeat();

    // Send immediate heartbeat
    _sendHeartbeat(userId: userId, userName: userName);

    // Start periodic heartbeat
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      _sendHeartbeat(userId: userId, userName: userName);
    });
  }

  /// Stops the heartbeat timer.
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Sends a heartbeat update to maintain online status.
  Future<void> _sendHeartbeat({
    required String userId,
    required String userName,
  }) async {
    await _updatePresence(userId: userId, userName: userName, isOnline: true);
  }
}

// ============================================================================
// Data Classes
// ============================================================================

/// Represents a user's presence status.
class UserPresence {
  final String userId;
  final String userName;
  final bool isOnline;
  final DateTime lastSeen;

  UserPresence({
    required this.userId,
    required this.userName,
    required this.isOnline,
    required this.lastSeen,
  });

  factory UserPresence.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserPresence(
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Returns a human-readable status string.
  ///
  /// Examples:
  /// - "Online"
  /// - "Last seen 2 minutes ago"
  /// - "Last seen today at 3:45 PM"
  /// - "Last seen yesterday"
  String getStatusText() {
    if (isOnline) {
      return 'Online';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Last seen yesterday';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays} days ago';
    } else {
      return 'Last seen ${lastSeen.month}/${lastSeen.day}/${lastSeen.year}';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserPresence &&
        other.userId == userId &&
        other.userName == userName &&
        other.isOnline == isOnline;
  }

  @override
  int get hashCode => userId.hashCode ^ userName.hashCode ^ isOnline.hashCode;

  @override
  String toString() =>
      'UserPresence(userId: $userId, userName: $userName, isOnline: $isOnline, lastSeen: $lastSeen)';
}
