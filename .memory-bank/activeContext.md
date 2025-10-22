# Active Context

## 🎯 Current Focus: Online/Offline Presence Indicators

**Session Goal**: Implement UI for online/offline status indicators to complete this MVP requirement

**Status**: PresenceService fully implemented (22 tests passing), needs UI integration only

## 📍 Where We Are

### Just Completed (This Session)
1. ✅ Fixed bidirectional message sync (Firestore ↔ Local ↔ UI)
2. ✅ Fixed message ordering (ascending, oldest first)
3. ✅ Fixed ROLLBACK errors with upsert mode
4. ✅ Updated memory bank with Sprint 4 completion
5. ✅ Verified Taskmaster status vs actual code

### Current Implementation Status

**Offline-First Architecture**: FULLY WORKING ✅
- Messages save locally immediately
- Background sync to Firestore
- Incoming messages: Firestore → Local DB → UI
- Optimistic UI with instant feedback
- Works offline, syncs when online

**PresenceService**: IMPLEMENTED but NOT IN UI ⚠️
- Service class exists: `lib/features/messaging/data/services/presence_service.dart`
- 22 passing tests
- Methods: `setOnline()`, `setOffline()`, `watchUser()`, heartbeat timer
- **Missing**: Provider integration, UI components

## 🎯 Next Task: Online/Offline Indicators

### Implementation Plan

**Step 1: Add Provider** (5 min)
```dart
// In messaging_providers.dart
@Riverpod(keepAlive: true)
PresenceService presenceService(Ref ref) {
  final service = PresenceService(firestore: ref.watch(firestoreProvider));
  ref.onDispose(() => service.dispose());
  return service;
}

@riverpod
Stream<Map<String, dynamic>?> userPresence(
  Ref ref,
  String userId,
) {
  final service = ref.watch(presenceServiceProvider);
  return service.watchUser(userId: userId);
}
```

**Step 2: Update Auth to Set Presence** (5 min)
```dart
// In auth flow after successful login
await presenceService.setOnline(
  userId: currentUser.uid,
  userName: currentUser.displayName,
);
```

**Step 3: UI - Conversation List Item** (10 min)
```dart
// In conversation_list_item.dart
final presenceAsync = ref.watch(userPresenceProvider(otherParticipantUid));

presenceAsync.when(
  data: (presence) {
    final isOnline = presence?['isOnline'] as bool? ?? false;
    // Show green dot if online, grey if offline
  },
  loading: () => ...,
  error: (_, __) => ...,
)
```

**Step 4: UI - Chat Page Header** (10 min)
```dart
// In chat_page.dart AppBar
final presenceAsync = ref.watch(userPresenceProvider(otherParticipantId));
// Show "Online" or "Last seen X ago" below name
```

**Step 5: Cleanup on Logout** (5 min)
```dart
// In sign out flow
await presenceService.setOffline(userId: currentUserId);
```

**Estimated Time**: 30-45 minutes

## 📊 MVP Progress

| Feature | Status | Notes |
|---------|--------|-------|
| One-on-one chat | ✅ | Done |
| Real-time delivery | ✅ | Done |
| Message persistence | ✅ | Drift |
| Optimistic UI | ✅ | Done |
| **Online/offline status** | 🔄 | **Next task (backend done)** |
| Timestamps | ✅ | Done |
| Authentication | ✅ | Done |
| Read receipts | ✅ | Done |
| **Push notifications** | ❌ | After presence |
| **Group chat** | ❌ | After push |

**MVP Completion**: 70% → **80%** (after presence indicators)

## 🔍 Key Files for This Task

**Providers**:
- `lib/features/messaging/presentation/providers/messaging_providers.dart`
- `lib/features/authentication/presentation/providers/auth_providers.dart`

**UI Components**:
- `lib/features/messaging/presentation/widgets/conversation_list_item.dart`
- `lib/features/messaging/presentation/pages/chat_page.dart`

**Service (already done)**:
- `lib/features/messaging/data/services/presence_service.dart` ✅

**Tests (already done)**:
- `test/features/messaging/data/services/presence_service_test.dart` ✅ (22 tests)

## 💭 Current Architecture Understanding

### Data Flow
```
User logs in
  ↓
Auth provider calls presenceService.setOnline()
  ↓
Firestore /presence/{userId} updated with isOnline: true
  ↓
Heartbeat timer keeps updating lastSeen every 30s
  ↓
UI watches userPresenceProvider(userId)
  ↓
Stream emits presence updates → UI rebuilds
  ↓
User logs out → presenceService.setOffline()
```

### Firestore Structure
```json
{
  "presence/{userId}": {
    "uid": "userId",
    "userName": "John Doe",
    "isOnline": true,
    "lastSeen": Timestamp,
    "lastUpdated": Timestamp
  }
}
```

## ⚠️ Important Considerations

1. **Battery Life**: Heartbeat every 30s - acceptable for MVP
2. **Offline Detection**: Firestore onDisconnect() not yet implemented (use manual setOffline)
3. **Privacy**: Consider letting users hide online status (post-MVP)
4. **Accuracy**: Heartbeat approach is "good enough" for MVP

## 🎯 Success Criteria

After implementing presence indicators:
- [ ] Green dot shows on conversation list for online users
- [ ] Grey dot shows for offline users
- [ ] Chat page shows "Online" or "Last seen X ago"
- [ ] Presence updates in real-time (within 30s)
- [ ] Tests verify provider integration
- [ ] No performance impact

## 📝 Next After This

1. **Push Notifications** (Task #42) - 2-3 hours
2. **Group Chat** (Tasks #49-58) - 4-6 hours
3. **MVP Complete!** 🎉

---

**Last Updated**: 2025-10-22
**Current Task**: Online/Offline Presence Indicators
**Estimated Completion**: 30-45 minutes
**Blocker**: None
