# Push Notifications Setup Guide

This document outlines the setup required for Firebase Cloud Messaging (FCM) push notifications.

## Current Status

- ✅ **Android**: Fully configured and working
  - FCM tokens generate successfully
  - Tokens save to Firestore
  - Ready for notification delivery

- ⚠️ **iOS**: Code ready, infrastructure pending
  - Code follows Firebase best practices
  - Requires Apple Developer Account setup (not yet done)
  - See iOS setup requirements below

---

## Android Setup (Completed)

### What's Configured:
1. ✅ `google-services.json` in `android/app/`
2. ✅ `POST_NOTIFICATIONS` permission in `AndroidManifest.xml` (Android 13+)
3. ✅ Firebase dependencies in `pubspec.yaml`
4. ✅ FCM service implementation

### Testing:
- Works on physical devices and emulators
- Tokens appear in Firestore: `users/{uid}/fcmTokens`

---

## iOS Setup (Pending)

### Required Steps:

#### 1. Firebase Console Configuration
**Location**: [Firebase Console](https://console.firebase.google.com) → Project Settings → Cloud Messaging

**Required**: Upload APNs Authentication Key
- Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
- Create new key → Enable "Apple Push Notifications service (APNs)"
- Download `.p8` file (**ONLY ONCE** - cannot re-download!)
- Upload to Firebase with:
  - Key ID (from Apple Developer portal)
  - Team ID (your Apple Team ID)

**Alternative**: APNs Certificates (per-app, more complex)

#### 2. Xcode Configuration
**Location**: `ios/Runner.xcworkspace` → Runner target → Signing & Capabilities

**Required Capabilities**:
1. ✅ **Push Notifications**
   - Currently: ❌ Not enabled
   - Action: Click "+ Capability" → Add "Push Notifications"

2. ✅ **Background Modes**
   - Currently: ✅ Configured in `Info.plist`
   - Remote notifications: ✅ Enabled

3. ✅ **Entitlements**
   - Currently: ✅ `Runner.entitlements` exists
   - `aps-environment`: development ✅

### What's Already Done:
- ✅ `Info.plist`: Background modes configured
- ✅ `Runner.entitlements`: APNs environment set
- ✅ FCM service: Following best practices
- ✅ Permissions requested on login

### Why iOS Token is Null:
Without the APNs authentication key in Firebase Console, Firebase cannot communicate with Apple's push notification servers. The device registers with APNs, but Firebase has no way to retrieve/verify the APNs token, so FCM token generation fails.

---

## Code Architecture

### FCM Service (`lib/features/messaging/data/services/fcm_service.dart`)

**Initialization Flow**:
1. Request notification permissions
2. Set up token refresh listener (primary mechanism)
3. Attempt to get current token
4. Save token to Firestore if available

**Token Lifecycle**:
- **Android**: Token available immediately after permission grant
- **iOS**: Token available after:
  1. User grants permission
  2. Device registers with APNs (async)
  3. Firebase validates with APNs server (requires auth key)
  4. FCM token generated
  5. Token refresh listener fires
  6. Saved to Firestore

**Key Design Decisions**:
- Token refresh listener is the **primary** mechanism (not a fallback)
- No artificial delays or retries
- Graceful handling of null tokens
- Simple, production-ready code

---

## Testing Checklist

### Android:
- [x] Permission dialog appears on Android 13+
- [x] Token saved to Firestore
- [x] Token persists across app restarts
- [x] Multiple devices can have different tokens

### iOS (When Setup Complete):
- [ ] Permission dialog appears
- [ ] Token saved to Firestore within 30 seconds
- [ ] Token persists across app restarts
- [ ] Testing on **real device** (simulators unreliable for APNs)

---

## Firestore Structure

```
users/{userId}/
  fcmTokens: string[]  // Array of FCM tokens for all user's devices
```

**Benefits**:
- Supports multiple devices per user
- Automatic deduplication via `arrayUnion`
- Easy cleanup via `arrayRemove` on logout

---

## Next Steps for iOS

1. **Get Apple Developer Account** (if not already)
2. **Generate APNs Authentication Key**
3. **Upload to Firebase Console**
4. **Enable Push Notifications in Xcode**
5. **Test on real iOS device**

---

## Troubleshooting

### Android:
- **No token**: Check `POST_NOTIFICATIONS` permission granted
- **Token null**: Check `google-services.json` is correct flavor
- **Not saving**: Check Firestore security rules allow writes

### iOS (Future):
- **No token**: Check APNs key uploaded to Firebase Console
- **Permission denied**: User must grant in Settings → MessageAI → Notifications
- **APNs unreliable**: Test on physical device, not simulator

---

## References

- [Firebase Cloud Messaging for Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [Firebase Console](https://console.firebase.google.com)
- [Apple Developer Portal](https://developer.apple.com/account)
