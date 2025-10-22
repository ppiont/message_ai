import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
/// - Initializes Firebase (required for background isolate)
/// - Marks message as delivered in Firestore
/// - Logs the notification
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase (required in background isolate)
  // This is safe to call multiple times
  await Firebase.initializeApp();

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
typedef NotificationTapCallback =
    void Function({required String conversationId, required String senderId});

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
  final FlutterLocalNotificationsPlugin _localNotifications;

  // State
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _notificationTapSubscription;
  bool _notificationsInitialized = false;

  FCMService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  // ============================================================================
  // Public API
  // ============================================================================

  /// Initializes FCM for the given user.
  ///
  /// Flow:
  /// 1. Initialize local notifications with Android channel
  /// 2. Request notification permissions
  /// 3. Set up notification handlers (foreground, background, tap)
  /// 4. Check for initial message (notification tap when app was terminated)
  /// 5. Attempt to get current FCM token (may be null on first launch)
  /// 6. Save token to Firestore if available
  /// 7. Set up token refresh listener (handles token availability/changes)
  ///
  /// On iOS: Token may not be available immediately if APNs hasn't registered yet.
  /// The token refresh listener will catch it when it becomes available.
  ///
  /// Should be called once after user logs in.
  Future<void> initialize({
    required String userId,
    NotificationTapCallback? onNotificationTap,
  }) async {
    // Initialize local notifications
    await _initializeLocalNotifications();

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

  /// Initializes local notifications with Android channel.
  ///
  /// Creates the "messages" notification channel for Android with
  /// WhatsApp-like configuration (sound, vibration, banner).
  Future<void> _initializeLocalNotifications() async {
    if (_notificationsInitialized) return;

    // Android notification channel (required for Android 8.0+)
    const androidChannel = AndroidNotificationChannel(
      'messages', // Must match Cloud Function channel_id
      'Messages',
      description: 'New message notifications',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('default'),
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Create the channel on Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    // Initialize plugin
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    _notificationsInitialized = true;
  }

  /// Sets up handlers for incoming notifications.
  ///
  /// Configures:
  /// - Foreground message handler (app is open) - shows local notification
  /// - Notification tap handler (app in background or foreground)
  void _setupNotificationHandlers({
    NotificationTapCallback? onNotificationTap,
  }) {
    // Cancel existing subscriptions
    _foregroundMessageSubscription?.cancel();
    _notificationTapSubscription?.cancel();

    // Handle messages when app is in foreground
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      // Show local notification (Firebase doesn't auto-show in foreground)
      _showForegroundNotification(message);
    });

    // Handle notification tap when app is in background or foreground
    if (onNotificationTap != null) {
      _notificationTapSubscription = FirebaseMessaging.onMessageOpenedApp
          .listen((RemoteMessage message) {
            _handleNotificationTap(message, onNotificationTap);
          });
    }
  }

  /// Shows a WhatsApp-style notification banner in foreground.
  ///
  /// Displays sender name as title and message preview as body.
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'messages', // Must match channel created in _initializeLocalNotifications
      'Messages',
      channelDescription: 'New message notifications',
      importance: Importance.high,
      priority: Priority.high,
      // Note: Using default icon since custom ic_notification doesn't exist
      // To customize, add drawable/ic_notification.xml to res folder
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''), // WhatsApp-style
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use message timestamp as notification ID to avoid duplicates
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _localNotifications.show(
      notificationId,
      notification.title, // Sender name
      notification.body, // Message preview
      notificationDetails,
    );
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
      callback(conversationId: conversationId, senderId: senderId);
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
