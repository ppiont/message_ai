/// Riverpod providers for presence tracking and FCM notifications
library;

import 'package:firebase_database/firebase_database.dart';
import 'package:message_ai/features/messaging/data/services/fcm_service.dart';
import 'package:message_ai/features/messaging/data/services/rtdb_presence_service.dart'
    show RtdbPresenceService, UserPresence;
import 'package:message_ai/features/messaging/presentation/providers/messaging_core_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'presence_providers.g.dart';

// ========== Presence Providers ==========

/// Provides the [RtdbPresenceService] instance for presence tracking.
///
/// Uses Firebase Realtime Database with automatic offline detection via
/// onDisconnect() callbacks. No heartbeat mechanism needed.
@Riverpod(keepAlive: true)
RtdbPresenceService presenceService(Ref ref) =>
    RtdbPresenceService(database: FirebaseDatabase.instance);

/// Provides the [FCMService] instance for push notifications.
@Riverpod(keepAlive: true)
FCMService fcmService(Ref ref) {
  final service = FCMService(firestore: ref.watch(messagingFirestoreProvider));

  // Dispose when provider is disposed
  ref.onDispose(service.dispose);

  return service;
}

/// Watches presence status for a specific user.
///
/// Returns a stream of presence data including:
/// - isOnline: true if user is currently online
/// - lastSeen: timestamp of last activity
/// - userName: display name
@riverpod
Stream<Map<String, dynamic>?> userPresence(Ref ref, String userId) {
  final service = ref.watch(presenceServiceProvider);
  return service.watchUserPresence(userId: userId).map((presence) {
    if (presence == null) {
      return null;
    }
    return {
      'isOnline': presence.isOnline,
      'lastSeen': presence.lastSeen,
      'userName': presence.userName,
    };
  });
}

/// Batch presence lookup for multiple users (optimized for conversation lists).
///
/// **Performance Optimization:**
/// Instead of creating N individual stream subscriptions (one per conversation),
/// this provider creates a single subscription that watches all user IDs at once.
///
/// **Usage:**
/// ```dart
/// // In ConversationListPage: extract all user IDs from visible conversations
/// final allUserIds = conversations
///     .expand((conv) => conv['participants'] as List)
///     .map((p) => p['uid'] as String)
///     .toSet()
///     .toList();
///
/// // Watch batch presence (1 subscription instead of N)
/// final presenceMapAsync = ref.watch(batchUserPresenceProvider(allUserIds));
///
/// // Pass to child widgets as prop
/// ConversationListItem(
///   presenceMap: presenceMapAsync.value ?? {},
///   ...
/// )
/// ```
///
/// **Returns:**
/// Map of userId -> presence data:
/// - 'isOnline': bool
/// - 'lastSeen': DateTime?
/// - 'userName': String
@riverpod
Stream<Map<String, Map<String, dynamic>>> batchUserPresence(
  Ref ref,
  List<String> userIds,
) {
  final presenceService = ref.watch(presenceServiceProvider);

  if (userIds.isEmpty) {
    return Stream<Map<String, Map<String, dynamic>>>.value(
      <String, Map<String, dynamic>>{},
    );
  }

  // Watch presence for all users using a single RTDB subscription
  // Transform UserPresence objects to Map format for UI consistency
  return presenceService.watchUsersPresence(userIds: userIds).map(
    (Map<String, UserPresence> presenceMap) => presenceMap.map(
      (String userId, UserPresence presence) => MapEntry(
        userId,
        <String, dynamic>{
          'isOnline': presence.isOnline,
          'lastSeen': presence.lastSeen,
          'userName': presence.userName,
        },
      ),
    ),
  );
}

// ========== Group Presence Provider ==========

/// Provides aggregated online status for a group conversation.
///
/// Returns a map with:
/// - 'onlineCount': Number of members currently online
/// - 'totalCount': Total number of members
/// - 'onlineMembers': List of online member IDs
/// - 'displayText': Human-readable status (e.g., "3/5 online")
@riverpod
Stream<Map<String, dynamic>> groupPresenceStatus(
  Ref ref,
  List<String> participantIds,
) {
  final presenceService = ref.watch(presenceServiceProvider);

  if (participantIds.isEmpty) {
    return Stream<Map<String, dynamic>>.value(<String, dynamic>{
      'onlineCount': 0,
      'totalCount': 0,
      'onlineMembers': <String>[],
      'displayText': 'No members',
    });
  }

  // Watch presence for all participants using Firestore real-time listener
  return presenceService.watchUsersPresence(userIds: participantIds).map((
    Map<String, UserPresence> presenceMap,
  ) {
    final onlineMembers = presenceMap.entries
        .where((MapEntry<String, UserPresence> entry) => entry.value.isOnline)
        .map((MapEntry<String, UserPresence> entry) => entry.key)
        .toList();

    return <String, dynamic>{
      'onlineCount': onlineMembers.length,
      'totalCount': participantIds.length,
      'onlineMembers': onlineMembers,
      'displayText': onlineMembers.isEmpty
          ? 'All offline'
          : '${onlineMembers.length}/${participantIds.length} online',
    };
  });
}
