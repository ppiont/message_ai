import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Background message handler.
///
/// MUST be a top-level function (not inside a class) because it runs in a
/// separate isolate when the app is in the background or terminated.
///
/// Triggered when:
/// - App is in background
/// - App is terminated
/// - Notification is received
///
/// Limitations:
/// - Runs in separate isolate (no access to app state)
/// - Cannot update UI
/// - Cannot navigate
/// - Can only perform background operations
///
/// Current implementation:
/// - Marks message as delivered in Firestore
/// - Logs the notification
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background notification: ${message.notification?.title}');

  // Mark message as delivered if we have the necessary data
  final conversationId = message.data['conversationId'] as String?;
  final messageId = message.messageId;

  if (conversationId != null && messageId != null) {
    try {
      // Determine which collection to use
      final isGroup = conversationId.startsWith('group-');
      final collection = isGroup ? 'group-conversations' : 'conversations';

      // Mark as delivered
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection(collection)
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      print('Marked message $messageId as delivered');
    } catch (e) {
      print('Failed to mark message as delivered: $e');
    }
  }
}

/// Callback for handling notification navigation.
///
/// Called when user taps a notification with conversation data.
typedef NotificationTapCallback = void Function({
  required String conversationId,
  required String senderId,
});

/// Service for managing Firebase Cloud Messaging tokens and notifications.
///
/// Features:
/// - FCM token retrieval and storage
/// - Automatic token refresh handling
/// - Token association with user accounts
/// - Token cleanup on logout
/// - Foreground notification handling
/// - Background notification handling
/// - Notification tap handling with navigation
class FCMService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  // State
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _notificationTapSubscription;

  FCMService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================================
  // Public API
  // ============================================================================

  /// Initializes FCM for the given user.
  ///
  /// Flow:
  /// 1. Request notification permissions
  /// 2. Set up notification handlers (foreground, background, tap)
  /// 3. Check for initial message (notification tap when app was terminated)
  /// 4. Attempt to get current FCM token (may be null on first launch)
  /// 5. Save token to Firestore if available
  /// 6. Set up token refresh listener (handles token availability/changes)
  ///
  /// On iOS: Token may not be available immediately if APNs hasn't registered yet.
  /// The token refresh listener will catch it when it becomes available.
  ///
  /// Should be called once after user logs in.
  Future<void> initialize({
    required String userId,
    NotificationTapCallback? onNotificationTap,
  }) async {
    // Request permissions (required for iOS, Android 13+)
    final status = await requestPermission();

    if (status != AuthorizationStatus.authorized &&
        status != AuthorizationStatus.provisional) {
      // User denied permissions - cannot receive notifications
      return;
    }

    // Set up notification handlers
    _setupNotificationHandlers(onNotificationTap: onNotificationTap);

    // Check if app was opened from a notification while terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && onNotificationTap != null) {
      _handleNotificationTap(initialMessage, onNotificationTap);
    }

    // Set up token refresh listener
    // This ensures we catch the token when it becomes available (especially iOS)
    _listenForTokenRefresh(userId: userId);

    // Try to get current token
    // May be null on iOS if APNs hasn't registered yet - that's ok,
    // the refresh listener will handle it when it arrives
    final token = await getToken();
    if (token != null) {
      await _saveTokenToFirestore(userId: userId, token: token);
    }
  }

  /// Retrieves the current FCM token.
  ///
  /// Returns null if:
  /// - Permissions not granted
  /// - Device doesn't support FCM
  /// - Network error
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      // Token retrieval failed (likely permissions or network issue)
      return null;
    }
  }

  /// Requests notification permissions from the user.
  ///
  /// Returns the authorization status after request.
  ///
  /// On iOS: Shows system permission dialog
  /// On Android 12+: Shows permission dialog
  /// On older Android: Automatically granted
  Future<AuthorizationStatus> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    return settings.authorizationStatus;
  }

  /// Checks current notification permission status.
  ///
  /// Does NOT request permissions - use [requestPermission] for that.
  Future<AuthorizationStatus> checkPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// Removes the current FCM token for the user.
  ///
  /// Should be called on logout to prevent sending notifications
  /// to logged-out users.
  Future<void> removeToken({required String userId}) async {
    final token = await getToken();
    if (token != null) {
      await _removeTokenFromFirestore(userId: userId, token: token);
    }

    // Clean up all subscriptions
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = null;
    await _notificationTapSubscription?.cancel();
    _notificationTapSubscription = null;
  }

  /// Disposes the service and cleans up subscriptions.
  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = null;
    await _notificationTapSubscription?.cancel();
    _notificationTapSubscription = null;
  }

  // ============================================================================
  // Private Helpers
  // ============================================================================

  /// Sets up handlers for incoming notifications.
  ///
  /// Configures:
  /// - Foreground message handler (app is open)
  /// - Notification tap handler (app in background or foreground)
  void _setupNotificationHandlers({
    NotificationTapCallback? onNotificationTap,
  }) {
    // Cancel existing subscriptions
    _foregroundMessageSubscription?.cancel();
    _notificationTapSubscription?.cancel();

    // Handle messages when app is in foreground
    _foregroundMessageSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // In foreground: System doesn't show notification automatically
      // We could show an in-app notification here if desired
      // For now, just log it - the message will still sync via Firestore
      print('Foreground notification: ${message.notification?.title}');
    });

    // Handle notification tap when app is in background or foreground
    if (onNotificationTap != null) {
      _notificationTapSubscription = FirebaseMessaging.onMessageOpenedApp
          .listen((RemoteMessage message) {
        _handleNotificationTap(message, onNotificationTap);
      });
    }
  }

  /// Handles notification tap events.
  ///
  /// Extracts conversation data from notification payload and triggers navigation.
  void _handleNotificationTap(
    RemoteMessage message,
    NotificationTapCallback callback,
  ) {
    final data = message.data;
    final conversationId = data['conversationId'] as String?;
    final senderId = data['senderId'] as String?;

    if (conversationId != null && senderId != null) {
      callback(
        conversationId: conversationId,
        senderId: senderId,
      );
    }
  }

  /// Listens for FCM token refresh events.
  ///
  /// When the token changes:
  /// - Updates Firestore with new token
  /// - Removes old token if it exists
  void _listenForTokenRefresh({required String userId}) {
    _tokenRefreshSubscription?.cancel();

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(userId: userId, token: newToken);
    });
  }

  /// Saves FCM token to user's Firestore document.
  ///
  /// Adds token to user's fcmTokens array (deduplicates automatically).
  Future<void> _saveTokenToFirestore({
    required String userId,
    required String token,
  }) async {
    try {
      // Try to update existing document
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      // Document might not exist yet (race condition on signup)
      // Fall back to merge operation
      try {
        await _firestore.collection('users').doc(userId).set({
          'fcmTokens': [token],
        }, SetOptions(merge: true));
      } catch (e) {
        // Silently fail - not critical for app functionality
      }
    }
  }

  /// Removes FCM token from user's Firestore document.
  ///
  /// Removes token from user's fcmTokens array.
  Future<void> _removeTokenFromFirestore({
    required String userId,
    required String token,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      // Document might not exist - silently fail
    }
  }
}
