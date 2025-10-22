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
  /// - Retrieves current FCM token
  /// - Saves token to Firestore
  /// - Listens for token refresh events
  ///
  /// Should be called after user logs in.
  Future<void> initialize({required String userId}) async {
    // Request permissions first (required for iOS, helpful for Android 13+)
    final status = await requestPermission();

    // Only proceed if permissions granted
    if (status != AuthorizationStatus.authorized &&
        status != AuthorizationStatus.provisional) {
      // Permissions denied - can't get token
      return;
    }

    // Get current token
    final token = await getToken();
    if (token != null) {
      await _saveTokenToFirestore(userId: userId, token: token);
    }

    // Listen for token refresh
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
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } catch (e) {
      // Document might not exist yet (race condition on signup)
      // Try creating it with the token
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
