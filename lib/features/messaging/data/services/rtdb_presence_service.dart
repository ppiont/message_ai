import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

/// Service for managing user online/offline presence using Firebase Realtime Database.
///
/// Features:
/// - **Automatic offline detection** via RTDB's `onDisconnect()` server-side callbacks
/// - **App lifecycle awareness** (set offline when app backgrounds)
/// - Real-time presence updates with WebSocket connection
/// - No heartbeat mechanism needed (RTDB handles connection state)
///
/// Architecture:
/// - Uses Firebase Realtime Database (NOT Firestore) for ephemeral presence data
/// - Data structure: `/presence/{userId}` → `{isOnline, lastSeen, userName}`
/// - `onDisconnect()` automatically sets user offline when WebSocket connection drops
/// - Works even if app is force-killed, network lost, or device goes to sleep
///
/// This is the standard Firebase pattern used by WhatsApp and similar apps.
class RtdbPresenceService {
  RtdbPresenceService({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  /// Sets user as online and configures automatic offline on disconnect.
  ///
  /// **IMPORTANT**: This must be called:
  /// - When user signs in
  /// - When app comes to foreground (AppLifecycleState.resumed)
  ///
  /// The `onDisconnect()` callback ensures the user is automatically marked
  /// offline when the WebSocket connection to Firebase drops (app closed,
  /// network lost, device killed, etc.).
  Future<void> setOnline({
    required String userId,
    required String userName,
  }) async {
    final presenceRef = _database.ref('presence/$userId');

    // First, set up onDisconnect callback (server-side)
    // This will execute automatically when the client disconnects
    await presenceRef.onDisconnect().set({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
      'userName': userName,
    });

    // Then, set the user as online
    await presenceRef.set({
      'isOnline': true,
      'lastSeen': ServerValue.timestamp,
      'userName': userName,
    });
  }

  /// Sets user as offline and cancels onDisconnect callback.
  ///
  /// **IMPORTANT**: This should be called:
  /// - When user explicitly logs out
  /// - When app goes to background (AppLifecycleState.paused/inactive) as backup
  /// - When app is about to be killed (AppLifecycleState.detached)
  ///
  /// Note: The onDisconnect() callback will still trigger if connection drops
  /// before this is called, so this is mainly for explicit logout or app backgrounding.
  Future<void> setOffline({
    required String userId,
    required String userName,
  }) async {
    final presenceRef = _database.ref('presence/$userId');

    // Cancel any pending onDisconnect operations
    await presenceRef.onDisconnect().cancel();

    // Set user as offline
    await presenceRef.set({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
      'userName': userName,
    });
  }

  /// Watches presence status for a specific user in real-time.
  ///
  /// Returns a stream that emits whenever the user's presence changes.
  /// The stream will emit `null` if no presence data exists for the user.
  Stream<UserPresence?> watchUserPresence({required String userId}) {
    final presenceRef = _database.ref('presence/$userId');

    return presenceRef.onValue.map((event) {
      if (!event.snapshot.exists) {
        return null;
      }

      final data = event.snapshot.value as Map<Object?, Object?>?;
      if (data == null) {
        return null;
      }

      return UserPresence.fromRtdb(userId, data);
    });
  }

  /// Watches presence status for multiple users in real-time.
  ///
  /// Returns a stream of a map from userId → UserPresence.
  /// Users without presence data will not appear in the map.
  ///
  /// Note: This creates individual listeners for each user. For very large
  /// groups (>50 users), consider implementing a server-side aggregation endpoint.
  Stream<Map<String, UserPresence>> watchUsersPresence({
    required List<String> userIds,
  }) {
    if (userIds.isEmpty) {
      return Stream.value({});
    }

    // Create a stream for each user
    final streams = userIds.map((userId) {
      return watchUserPresence(userId: userId).map((presence) {
        return MapEntry(userId, presence);
      });
    }).toList();

    // Combine all streams into a single stream
    // This uses RxDart's combineLatest or manual stream merging
    return _combinePresenceStreams(streams);
  }

  /// Combines multiple presence streams into a single map stream.
  Stream<Map<String, UserPresence>> _combinePresenceStreams(
    List<Stream<MapEntry<String, UserPresence?>>> streams,
  ) async* {
    final controllers = streams.map((stream) {
      return StreamController<MapEntry<String, UserPresence?>>.broadcast();
    }).toList();

    // Subscribe to each stream
    final subscriptions =
        <StreamSubscription<MapEntry<String, UserPresence?>>>[];
    for (var i = 0; i < streams.length; i++) {
      subscriptions.add(
        streams[i].listen(
          (entry) => controllers[i].add(entry),
          onError: (error) => controllers[i].addError(error),
        ),
      );
    }

    // Combine latest values from all streams
    final latestValues = <String, UserPresence?>{};

    await for (final _ in Stream.periodic(const Duration(milliseconds: 100))) {
      // Collect latest values from each controller
      for (var i = 0; i < controllers.length; i++) {
        if (controllers[i].hasListener && !controllers[i].isClosed) {
          await for (final entry in controllers[i].stream.take(1)) {
            latestValues[entry.key] = entry.value;
            break;
          }
        }
      }

      // Emit map with non-null presences
      final result = <String, UserPresence>{};
      for (final entry in latestValues.entries) {
        if (entry.value != null) {
          result[entry.key] = entry.value!;
        }
      }
      yield result;
    }

    // Cleanup
    for (final sub in subscriptions) {
      await sub.cancel();
    }
    for (final controller in controllers) {
      await controller.close();
    }
  }
}

// ============================================================================
// Data Classes
// ============================================================================

/// Represents a user's presence status from Realtime Database.
class UserPresence {
  UserPresence({
    required this.userId,
    required this.userName,
    required this.isOnline,
    required this.lastSeen,
  });

  factory UserPresence.fromRtdb(String userId, Map<Object?, Object?> data) {
    final isOnline = data['isOnline'] as bool? ?? false;
    final lastSeenValue = data['lastSeen'];
    final userName = data['userName'] as String? ?? 'Unknown';

    // lastSeen can be either a timestamp (int) or ServerValue.timestamp placeholder
    DateTime lastSeen;
    if (lastSeenValue is int) {
      lastSeen = DateTime.fromMillisecondsSinceEpoch(lastSeenValue);
    } else {
      lastSeen = DateTime.now();
    }

    return UserPresence(
      userId: userId,
      userName: userName,
      isOnline: isOnline,
      lastSeen: lastSeen,
    );
  }

  final String userId;
  final String userName;
  final bool isOnline;
  final DateTime lastSeen;

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
    if (identical(this, other)) {
      return true;
    }

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
