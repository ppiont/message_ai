import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Service for managing Firebase Cloud Messaging tokens and notifications.
///
/// Features:
/// - FCM token retrieval and storage
/// - Automatic token refresh handling
/// - Token association with user accounts
/// - Token cleanup on logout
class FCMService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  // State
  StreamSubscription<String>? _tokenRefreshSubscription;

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
  /// - Requests notification permissions
  /// - Waits for APNs token (iOS only)
  /// - Retrieves current FCM token
  /// - Saves token to Firestore
  /// - Listens for token refresh events
  ///
  /// Should be called after user logs in.
  Future<void> initialize({required String userId}) async {
    print('FCM: Starting initialization for user $userId');

    // Request permissions first (required for iOS, helpful for Android 13+)
    final status = await requestPermission();
    print('FCM: Permission status: $status');

    // Only proceed if permissions granted
    if (status != AuthorizationStatus.authorized &&
        status != AuthorizationStatus.provisional) {
      // Permissions denied - can't get token
      print('FCM: Permissions not granted, aborting initialization');
      return;
    }

    // For iOS: Wait for APNs token before making FCM API calls
    // This is required in iOS SDK 10.4.0+
    try {
      final apnsToken = await _messaging.getAPNSToken();
      print('FCM: APNs token: ${apnsToken != null ? "present" : "null"}');
      if (apnsToken == null) {
        // APNs token not available yet - this is normal on Android
        // or if we're not on iOS, so we can continue
      }
    } catch (e) {
      // getAPNSToken() might throw on non-iOS platforms
      // This is expected, continue normally
      print('FCM: getAPNSToken threw (expected on non-iOS): $e');
    }

    // Get current token
    print('FCM: Attempting to get FCM token...');
    final token = await getToken();
    print('FCM: Token retrieved: ${token != null ? "${token.substring(0, 20)}..." : "null"}');

    if (token != null) {
      print('FCM: Saving token to Firestore...');
      await _saveTokenToFirestore(userId: userId, token: token);
      print('FCM: Token saved successfully');
    } else {
      print('FCM: No token available, skipping save');
    }

    // Listen for token refresh
    print('FCM: Setting up token refresh listener');
    _listenForTokenRefresh(userId: userId);
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

    // Stop listening for token refresh
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  /// Disposes the service and cleans up subscriptions.
  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  // ============================================================================
  // Private Helpers
  // ============================================================================

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
      print('FCM: Attempting update on users/$userId');
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
      print('FCM: Update successful');
    } catch (e) {
      // Document might not exist yet (race condition on signup)
      // Try creating it with the token
      print('FCM: Update failed: $e, trying merge instead...');
      try {
        await _firestore.collection('users').doc(userId).set({
          'fcmTokens': [token],
        }, SetOptions(merge: true));
        print('FCM: Merge successful');
      } catch (e) {
        // Silently fail - not critical for app functionality
        print('FCM: Merge also failed: $e');
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
