import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Service for managing user online/offline presence using Firebase Realtime Database.
///
/// **Simple lifecycle-based pattern**:
/// - setOnline() when user is in foreground
/// - setOffline() when user goes to background/signs out
/// - onDisconnect() automatically handles connection drops
class RtdbPresenceService {
  RtdbPresenceService({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  /// Sets user as online in RTDB.
  ///
  /// Writes { isOnline: true, timestamp, userName }
  /// Also configures onDisconnect() to auto-set offline if connection drops
  Future<void> setOnline({
    required String userId,
    required String userName,
  }) async {
    debugPrint('🟢 Presence: Setting $userName ONLINE');
    final presenceRef = _database.ref('presence/$userId');

    try {
      // Set up onDisconnect to auto-set offline (handles network drops, app kill)
      await presenceRef.onDisconnect().set({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
        'userName': userName,
      });

      // Set user online
      await presenceRef.set({
        'isOnline': true,
        'timestamp': ServerValue.timestamp,
        'userName': userName,
      });

      debugPrint('✅ Presence: $userName is ONLINE');
    } catch (e) {
      debugPrint('❌ Presence: Failed to set online: $e');
    }
  }

  /// Sets user as offline in RTDB.
  ///
  /// Writes { isOnline: false, lastSeen, userName }
  /// Cancels onDisconnect() since we're manually setting offline
  Future<void> setOffline({
    required String userId,
    required String userName,
  }) async {
    debugPrint('🔴 Presence: Setting $userName OFFLINE');
    final presenceRef = _database.ref('presence/$userId');

    try {
      // Cancel onDisconnect since we're manually going offline
      await presenceRef.onDisconnect().cancel();

      // Set user offline with last seen timestamp
      await presenceRef.set({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
        'userName': userName,
      });

      debugPrint('✅ Presence: $userName is OFFLINE');
    } catch (e) {
      debugPrint('❌ Presence: Failed to set offline: $e');
    }
  }

  /// Clears presence data (for sign out).
  ///
  /// Removes all presence data for the user
  Future<void> clearPresence({required String userId}) async {
    debugPrint('🔴 Presence: Clearing presence for $userId');
    final presenceRef = _database.ref('presence/$userId');

    try {
      await presenceRef.onDisconnect().cancel();
      await presenceRef.remove();
      debugPrint('✅ Presence: Cleared');
    } catch (e) {
      debugPrint('❌ Presence: Failed to clear: $e');
    }
  }

  /// Watches presence for a specific user.
  ///
  /// Returns stream of boolean indicating if user is online
  Stream<bool> watchUserPresence({required String userId}) {
    final presenceRef = _database.ref('presence/$userId');

    return presenceRef.onValue.map((event) {
      if (!event.snapshot.exists) {
        return false;
      }

      final data = event.snapshot.value as Map<Object?, Object?>?;
      if (data == null) {
        return false;
      }

      final isOnline = data['isOnline'] as bool? ?? false;
      return isOnline;
    }).handleError((Object error) {
      debugPrint('⚠️ Presence: Error watching $userId: $error');
      return false;
    });
  }

  /// Gets last seen time for a user.
  Future<DateTime?> getLastSeen({required String userId}) async {
    final presenceRef = _database.ref('presence/$userId');

    try {
      final snapshot = await presenceRef.get();
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.value as Map<Object?, Object?>?;
      final lastSeen = data?['lastSeen'] as int?;

      if (lastSeen == null) {
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(lastSeen);
    } catch (e) {
      debugPrint('❌ Presence: Failed to get last seen: $e');
      return null;
    }
  }

  /// Watches presence for multiple users.
  ///
  /// Returns a stream of Map<userId, isOnline>
  Stream<Map<String, bool>> watchUsersPresence({
    required List<String> userIds,
  }) async* {
    if (userIds.isEmpty) {
      yield {};
      return;
    }

    // Watch all users and combine results
    await for (final _ in _database.ref('presence').onValue) {
      final presenceMap = <String, bool>{};

      for (final userId in userIds) {
        final ref = _database.ref('presence/$userId');
        try {
          final snapshot = await ref.get();
          if (snapshot.exists) {
            final data = snapshot.value as Map<Object?, Object?>?;
            presenceMap[userId] = data?['isOnline'] as bool? ?? false;
          } else {
            presenceMap[userId] = false;
          }
        } catch (e) {
          debugPrint('⚠️ Presence: Error watching $userId: $e');
          presenceMap[userId] = false;
        }
      }

      yield presenceMap;
    }
  }
}

/// Simple presence data model.
class UserPresence {
  const UserPresence({
    required this.timestamp,
    required this.userName,
  });

  factory UserPresence.fromMap(Map<Object?, Object?> map) => UserPresence(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']! as int),
      userName: map['userName'] as String? ?? 'Unknown',
    );

  final DateTime timestamp;
  final String userName;

  /// Check if user is currently online (active in last 60 seconds).
  bool get isOnline {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inSeconds < 60;
  }
}
