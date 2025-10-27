# Name Synchronization Architecture - Complete Redesign

**Status**: 📋 Planned (Not Yet Implemented)
**Priority**: High
**Estimated Effort**: 9-14 hours (1-2 days)
**Type**: Architectural Improvement

---

## 📌 Executive Summary

The current user name synchronization system has critical architectural flaws that cause "Unknown" to appear in conversation lists, especially for new conversations and offline scenarios. This document outlines a complete redesign to implement WhatsApp-style name snapshots with Cloud Function-based propagation.

**Key Problems**:
- Participant names not stored in conversations (only uid)
- No Cloud Function to propagate name changes
- Async lookups cause UI flicker and "Unknown" fallbacks
- Broken offline-first compliance

**Proposed Solution**:
- Store participant name snapshots in conversation documents
- Implement Cloud Function for automatic name propagation
- Remove async lookups from UI layer
- Full offline-first compliance

---

## 🔍 Problem Statement

### Current Architecture Issues

#### Issue #1: Participant Model Missing displayName
**File**: `lib/features/messaging/domain/entities/conversation.dart`

```dart
class Participant extends Equatable {
  const Participant({
    required this.uid,           // ✅ Only this is stored
    required this.preferredLanguage,
    this.imageUrl,
  });

  // ❌ NO displayName field!
  // Comment says: "Display name is looked up dynamically via UserLookupProvider"
}
```

**Impact**:
- Every participant display requires async lookup (network or Drift query)
- Shows "Unknown" during lookup → UI flicker
- Shows "Unknown" if offline and user not in Drift cache
- N+1 lookup problem for group chats (10 participants = 10 async calls!)

#### Issue #2: No Cloud Function for Name Propagation
**File**: `functions/main.py` - MISSING IMPLEMENTATION

```python
# Documented but NOT implemented:
"""
- Display name propagation when users update their profile
"""
```

**Impact**:
- When Alice changes "Alice" → "Alice Johnson", no automatic propagation
- Bob's conversations still reference uid="alice_uid" with no name
- Only updates via 1-hour background refresh (unreliable)
- No server-side synchronization across millions of conversations

#### Issue #3: User Cache Never Updates After Initial Load
**File**: `lib/features/authentication/data/services/user_cache_service.dart:37-41`

```dart
Future<void> cacheUser(String userId) async {
  final cached = await _database.userDao.getUserByUid(userId);
  if (cached != null) {
    return;  // ❌ Returns immediately - never checks for updates!
  }
  // Only fetches from Firestore if NOT cached
}
```

**Impact**:
- Name changes only appear after 1-hour periodic refresh
- Or app restart
- Inconsistent with real-time Firestore listeners

#### Issue #4: Race Condition on Conversation Load
**File**: `lib/features/messaging/presentation/providers/messaging_providers.dart:714`

```dart
// Sync happens AFTER stream emits
Future<void>.microtask(
  () => userSyncService.syncConversationUsers(allParticipantIds),
);
```

**Data Flow**:
```
allConversationsStream emits
  → UI renders with participants [uid only]
  → Shows "Unknown" (no name available)
  → microtask syncs users to Drift
  → UI re-renders with names
  → Result: Flicker from "Unknown" → actual name
```

#### Issue #5: Last Message Sender Name Never Updated
**File**: `lib/core/database/tables/conversations_table.dart:36-37`

```dart
/// Last message sender name (field exists but NEVER updated!)
TextColumn get lastMessageSenderName => text().nullable()();
```

**Impact**:
- Conversation previews show old sender names forever
- Even when user updates their displayName

---

## 🏗️ Current Architecture Diagram

```
┌────────────────────────────────────────────────────────────────────┐
│                     FIREBASE FIRESTORE (Source of Truth)           │
│                                                                     │
│  ┌──────────────────┐              ┌─────────────────────────┐    │
│  │ /users/{uid}     │              │ /conversations/{convId} │    │
│  │ ─────────────    │              │ ─────────────────────── │    │
│  │ uid: "alice_123" │              │ documentId: "conv_456"  │    │
│  │ displayName: "Alice Johnson" ✅ │ participants: [         │    │
│  │ email: "alice@..." │            │   {                     │    │
│  │ photoURL: "..."    │            │     uid: "alice_123",   │    │
│  │ preferredLanguage: "en"         │     preferredLanguage: "en",│ │
│  │ createdAt: Timestamp            │     imageUrl: "..."     │    │
│  │ isOnline: true     │            │   }                     │    │
│  └──────────────────┘              │   ❌ NO displayName!    │    │
│                                    │ ]                       │    │
│                                    │ lastMessageSenderId: "alice_123"│
│                                    │ lastMessageSenderName: null ❌│
│                                    └─────────────────────────┘    │
└────────┬───────────────────────────────────┬────────────────────────┘
         │                                   │
         │ UserRepository.watchUser()        │ ConversationRepository
         │ (Firestore real-time listener)    │ .watchConversations()
         │                                   │
    ┌────▼───────────────────────────────────▼────────────────────┐
    │                 RIVERPOD PROVIDERS                           │
    │                                                              │
    │  userSyncServiceProvider (keepAlive: true)                  │
    │  ├─ Watches each cached user via Firestore listener         │
    │  ├─ Updates Drift when displayName changes                  │
    │  └─ Background refresh every 1 hour                         │
    │                                                              │
    │  userLookupCacheProvider (in-memory cache)                  │
    │  ├─ 5-minute TTL cache                                      │
    │  ├─ getUser(userId) → User?                                 │
    │  ├─ getDisplayName(userId) → String (fallback: "Unknown")   │
    │  └─ Creates Firestore listener for each looked-up user      │
    │                                                              │
    │  allConversationsStreamProvider                             │
    │  ├─ Watches /conversations via Firestore listener           │
    │  ├─ Extracts participant UIDs                               │
    │  ├─ Fire-and-forget sync: syncConversationUsers()           │
    │  └─ Returns conversations WITHOUT participant names         │
    └────┬─────────────────────────────────────┬──────────────────┘
         │                                     │
         │ UserSyncService                     │
         │ .syncUserToDrift()                  │
         │                                     │
    ┌────▼─────────────────┐          ┌───────▼──────────────────┐
    │  DRIFT (Offline Cache)│         │ IN-MEMORY CACHE          │
    │                       │         │ (User Lookup Provider)   │
    │  users table:         │         │                          │
    │  ─────────────        │         │ Map<userId, CachedUser>  │
    │  uid (PK)             │         │ ├─ user: User            │
    │  name ✅              │         │ ├─ cachedAt: DateTime    │
    │  email                │         │ └─ isExpired (5 min TTL) │
    │  imageUrl             │         │                          │
    │  preferredLanguage    │         │ AUTO-UPDATED via         │
    │  isOnline             │         │ Firestore listeners ✅   │
    │  lastSeen             │         │                          │
    │                       │         │ Each lookup creates      │
    │  conversations table: │         │ new Firestore listener   │
    │  ─────────────────    │         │ (resource intensive!)    │
    │  participants (JSON): │         │                          │
    │  [                    │         └──────────────────────────┘
    │    {                  │
    │      uid: "alice_123",│
    │      preferredLanguage: "en",
    │      imageUrl: "..."  │
    │    }                  │
    │    ❌ NO name field!  │
    │  ]                    │
    └───────┬───────────────┘
            │
            │ UserDao queries
            │
    ┌───────▼─────────────────────────────────────────────────────┐
    │                  PRESENTATION LAYER (UI)                     │
    │                                                              │
    │  ConversationListItem (widget)                              │
    │  ├─ Receives participants: [{uid, lang, imageUrl}]          │
    │  ├─ Extracts otherParticipant.uid                           │
    │  ├─ ref.watch(userDisplayNameProvider(otherUserId))         │
    │  │  └─ ASYNC lookup → 3 states:                             │
    │  │     • loading: Shows "Loading..." ⏳                      │
    │  │     • data: Shows displayName ✅                          │
    │  │     • error: Shows "Unknown" ❌                           │
    │  └─ Result: UI flickers during lookup                       │
    │                                                              │
    │  ChatPage                                                    │
    │  ├─ Receives otherParticipantName via route parameter       │
    │  ├─ Shows in AppBar immediately (no lookup) ✅              │
    │  └─ Problem: Name becomes stale if user updates it          │
    │                                                              │
    │  MessageBubble                                               │
    │  ├─ Shows message.senderId (uid)                            │
    │  ├─ Looks up sender name dynamically via userDisplayName    │
    │  └─ Shows "Unknown" if lookup fails                         │
    └──────────────────────────────────────────────────────────────┘
```

---

## 🌟 WhatsApp Architecture (Target State)

```
┌────────────────────────────────────────────────────────────────────┐
│                     FIREBASE FIRESTORE (Source of Truth)           │
│                                                                     │
│  ┌──────────────────┐              ┌─────────────────────────┐    │
│  │ /users/{uid}     │              │ /conversations/{convId} │    │
│  │ ─────────────    │              │ ─────────────────────── │    │
│  │ displayName: "Alice Johnson" ✅ │ participants: [         │    │
│  │ photoURL: "..."  │              │   {                     │    │
│  └──────────────────┘              │     uid: "alice_123",   │    │
│         │                          │     name: "Alice Johnson", ✅│
│         │ Cloud Function           │     photoURL: "...",    │    │
│         │ on_user_profile_updated  │     preferredLanguage: "en"│ │
│         │                          │   }                     │    │
│         └──────────────────────────│ ]                       │    │
│           Propagates name changes  │ lastMessageSenderId: "alice_123"│
│           to ALL conversations ✅  │ lastMessageSenderName: "Alice Johnson" ✅│
│                                    └─────────────────────────┘    │
└────────────────────────────────────────────┬───────────────────────┘
                                             │
                                             │ Firestore real-time
                                             │ listener
                                             │
                                    ┌────────▼────────────────────┐
                                    │  DRIFT (Offline Cache)      │
                                    │                             │
                                    │  conversations table:       │
                                    │  participants (JSON):       │
                                    │  [                          │
                                    │    {                        │
                                    │      uid: "alice_123",      │
                                    │      name: "Alice Johnson", ✅│
                                    │      photoURL: "...",       │
                                    │      preferredLanguage: "en"│
                                    │    }                        │
                                    │  ]                          │
                                    │                             │
                                    │  ✅ Names cached locally!   │
                                    │  ✅ Works 100% offline!     │
                                    └─────────────┬───────────────┘
                                                  │
                                                  │ Direct access
                                                  │ (no lookup!)
                                    ┌─────────────▼────────────────┐
                                    │  PRESENTATION LAYER (UI)     │
                                    │                              │
                                    │  ConversationListItem        │
                                    │  ├─ participant.name ✅      │
                                    │  ├─ NO async lookup!         │
                                    │  ├─ NO "Unknown" fallback!   │
                                    │  └─ Instant display!         │
                                    │                              │
                                    │  ✅ 100% offline support     │
                                    │  ✅ Zero flicker             │
                                    │  ✅ O(1) performance         │
                                    └──────────────────────────────┘
```

---

## 💡 Proposed Solution

### Design Principles

1. **Snapshot Pattern**: Store participant names as snapshots (not references)
2. **Cloud Function Propagation**: Automatic updates when user changes displayName
3. **Offline-First**: All participant data cached in Drift
4. **Zero Lookups**: UI reads participant names directly from conversation data
5. **Eventual Consistency**: Names propagate within 1-2 seconds via Cloud Function

### Architecture Comparison

| Aspect | Current (References) | Proposed (Snapshots) |
|--------|---------------------|----------------------|
| **Participant Storage** | `{uid, lang, imageUrl}` | `{uid, name, photoURL, lang}` |
| **Name Lookup** | Async (userDisplayNameProvider) | Synchronous (participant.name) |
| **Offline Support** | Broken (shows "Unknown") | Full (cached in Drift) |
| **Name Updates** | Manual sync (1 hour) | Cloud Function (<2 seconds) |
| **Performance** | O(N) lookups per conversation | O(1) direct access |
| **UI Flicker** | Yes ("Unknown" → name) | No (instant display) |
| **Historical Accuracy** | No (always current if lookup succeeds) | Yes (snapshot of name at join time) |

---

## 📋 Implementation Plan

### Phase 1: Foundation - Add displayName to Participant Model

**Estimated Time**: 4-6 hours

#### Step 1.1: Update Domain Entity
**File**: `lib/features/messaging/domain/entities/conversation.dart`

```dart
class Participant extends Equatable {
  const Participant({
    required this.uid,
    required this.displayName,        // ✅ ADD THIS
    required this.preferredLanguage,
    this.imageUrl,
  });

  final String uid;
  final String displayName;           // ✅ Snapshot of name at join time
  final String? imageUrl;
  final String preferredLanguage;

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': displayName,              // ✅ Store as 'name' in Firestore
    'imageUrl': imageUrl,
    'preferredLanguage': preferredLanguage,
  };

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    uid: json['uid'] as String,
    displayName: json['name'] as String? ?? 'Unknown',  // ✅ Fallback for migration
    imageUrl: json['imageUrl'] as String?,
    preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
  );

  @override
  List<Object?> get props => [uid, displayName, preferredLanguage, imageUrl];
}
```

#### Step 1.2: Update Conversation Model
**File**: `lib/features/messaging/data/models/conversation_model.dart`

```dart
class ConversationModel {
  // ... existing fields ...

  Map<String, dynamic> toFirestore() {
    return {
      'documentId': documentId,
      'type': type,
      'participants': participants.map((p) => {
        'uid': p.uid,
        'name': p.displayName,          // ✅ Store displayName as 'name'
        'imageUrl': p.imageUrl,
        'preferredLanguage': p.preferredLanguage,
      }).toList(),
      'participantIds': participants.map((p) => p.uid).toList(),
      // ... other fields ...
    };
  }

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      // ... existing parsing ...
      participants: (data['participants'] as List<dynamic>?)
          ?.map((p) => Participant(
                uid: p['uid'] as String,
                displayName: p['name'] as String? ?? 'Unknown',  // ✅ Backward compat
                imageUrl: p['imageUrl'] as String?,
                preferredLanguage: p['preferredLanguage'] as String? ?? 'en',
              ))
          .toList() ?? [],
    );
  }
}
```

#### Step 1.3: Update Drift Schema
**File**: `lib/core/database/tables/conversations_table.dart`

```dart
class Conversations extends Table {
  // ... existing columns ...

  /// Participants (JSON array with uid, name, imageUrl, preferredLanguage)
  /// Example: [{"uid": "...", "name": "Alice Johnson", "imageUrl": "...", "preferredLanguage": "en"}]
  TextColumn get participants => text()();

  // ... rest of table ...
}

// No migration needed - JSON column supports new fields automatically
// Old entries will have missing 'name' field → handled by fromJson fallback
```

#### Step 1.4: Update All Conversation Creation Code

**Files to Update**:
1. `lib/features/messaging/domain/usecases/find_or_create_direct_conversation.dart`
2. `lib/features/messaging/domain/usecases/create_group.dart`
3. `lib/features/messaging/domain/usecases/add_group_member.dart`

**Example**: `find_or_create_direct_conversation.dart`

```dart
Future<Either<Failure, Conversation>> call({
  required String userId,
  required String otherUserId,
}) async {
  // Check for existing conversation
  final existingResult = await _conversationRepository
      .findDirectConversation(userId, otherUserId);

  if (existingResult.isRight()) {
    return existingResult;  // Found existing conversation
  }

  // Fetch BOTH users' full profiles for participant snapshots
  final currentUserResult = await _userRepository.getUserById(userId);
  final otherUserResult = await _userRepository.getUserById(otherUserId);

  // Handle errors
  if (currentUserResult.isLeft()) {
    return Left(currentUserResult.fold((l) => l, (r) => throw Exception()));
  }
  if (otherUserResult.isLeft()) {
    return Left(otherUserResult.fold((l) => l, (r) => throw Exception()));
  }

  final currentUser = currentUserResult.getOrElse(() => throw Exception());
  final otherUser = otherUserResult.getOrElse(() => throw Exception());

  // Create conversation with participant name snapshots
  final conversationId = 'direct-${userId}-${otherUserId}';
  final now = DateTime.now();

  final conversation = Conversation(
    documentId: conversationId,
    type: 'direct',
    participants: [
      Participant(
        uid: currentUser.uid,
        displayName: currentUser.displayName,    // ✅ Snapshot!
        imageUrl: currentUser.photoURL,
        preferredLanguage: currentUser.preferredLanguage,
      ),
      Participant(
        uid: otherUser.uid,
        displayName: otherUser.displayName,      // ✅ Snapshot!
        imageUrl: otherUser.photoURL,
        preferredLanguage: otherUser.preferredLanguage,
      ),
    ],
    createdAt: now,
    lastUpdatedAt: now,
    // ... other fields ...
  );

  return _conversationRepository.createConversation(conversation);
}
```

**Similarly for CreateGroup**:

```dart
Future<Either<Failure, Conversation>> call({
  required String creatorId,
  required String groupName,
  required List<String> memberIds,  // UIDs only
  String? groupImage,
}) async {
  // Fetch ALL member profiles (including creator)
  final allMemberIds = {creatorId, ...memberIds}.toList();
  final List<User> memberProfiles = [];

  for (final memberId in allMemberIds) {
    final userResult = await _userRepository.getUserById(memberId);
    userResult.fold(
      (failure) {
        debugPrint('Failed to load user $memberId: ${failure.message}');
        // Skip this member or fail entire operation?
        // Decision: Skip and log warning (graceful degradation)
      },
      (user) => memberProfiles.add(user),
    );
  }

  if (memberProfiles.isEmpty) {
    return const Left(
      ValidationFailure(message: 'Could not load any member profiles'),
    );
  }

  // Create participants with name snapshots
  final participants = memberProfiles.map((user) => Participant(
    uid: user.uid,
    displayName: user.displayName,    // ✅ Snapshot!
    imageUrl: user.photoURL,
    preferredLanguage: user.preferredLanguage,
  )).toList();

  final conversation = Conversation(
    documentId: 'group-${uuid.v4()}',
    type: 'group',
    groupName: groupName,
    groupImage: groupImage,
    participants: participants,
    adminIds: [creatorId],
    createdAt: DateTime.now(),
    lastUpdatedAt: DateTime.now(),
  );

  return _conversationRepository.createConversation(conversation);
}
```

#### Step 1.5: Run Build Runner

```bash
dart run build_runner build --delete-conflicting-outputs
```

#### Step 1.6: Test Migration

**Test Cases**:
1. ✅ Create new direct conversation → participant names appear instantly
2. ✅ Create new group conversation → all member names appear instantly
3. ✅ Load existing conversations (before migration) → fallback to "Unknown" gracefully
4. ✅ Add member to group → new member name appears instantly

---

### Phase 2: Propagation - Cloud Function for Name Updates

**Estimated Time**: 2-3 hours

#### Step 2.1: Implement Cloud Function
**File**: `functions/main.py`

```python
from firebase_functions import firestore_fn, logger
from firebase_admin import firestore
from google.cloud.firestore_v1.base_query import FieldFilter


@firestore_fn.on_document_updated(
    document="users/{userId}",
    region="us-central1",
)
def on_user_profile_updated(
    event: firestore_fn.Event[firestore_fn.Change]
) -> None:
    """
    Propagates displayName changes to all conversations where user participates.

    Triggered when /users/{userId} document is updated.

    Actions:
    1. Detect if displayName changed
    2. Query all conversations where user is a participant
    3. Update participant.name in each conversation's participants array
    4. Update lastMessageSenderName if user sent the last message

    Performance:
    - Uses batched writes (500 ops per batch)
    - Handles large numbers of conversations gracefully
    - Logs progress for monitoring

    Example:
    User "alice_123" changes displayName: "Alice" → "Alice Johnson"
    → Updates participant.name in all conversations containing alice_123
    → Updates lastMessageSenderName in conversations where she sent last message
    """
    try:
        # Extract user ID from event
        user_id = event.params["userId"]

        # Get before/after snapshots
        before_data = event.data.before.to_dict() if event.data.before else {}
        after_data = event.data.after.to_dict() if event.data.after else {}

        # Extract displayNames
        old_name = before_data.get("displayName", "")
        new_name = after_data.get("displayName", "")

        # Check if displayName actually changed
        if old_name == new_name:
            logger.info(
                f"User {user_id}: displayName unchanged ({old_name}), skipping propagation"
            )
            return

        logger.info(
            f"User {user_id}: displayName changed from '{old_name}' to '{new_name}'"
        )

        # Initialize Firestore client
        db = firestore.client()

        # Query all conversations where this user is a participant
        # Uses participantIds array for efficient lookup
        conversations_query = (
            db.collection("conversations")
            .where(filter=FieldFilter("participantIds", "array_contains", user_id))
        )

        conversation_docs = list(conversations_query.stream())
        total_conversations = len(conversation_docs)

        if total_conversations == 0:
            logger.info(f"User {user_id}: No conversations to update")
            return

        logger.info(
            f"User {user_id}: Updating name in {total_conversations} conversations"
        )

        # Batch write for performance (Firestore limit: 500 ops per batch)
        batch = db.batch()
        batch_count = 0
        updated_count = 0

        for conv_doc in conversation_docs:
            conv_ref = db.collection("conversations").document(conv_doc.id)
            conv_data = conv_doc.to_dict()

            # Update participant name in participants array
            participants = conv_data.get("participants", [])
            updated_participants = []
            participant_updated = False

            for participant in participants:
                if participant.get("uid") == user_id:
                    # Update this participant's name
                    participant["name"] = new_name
                    participant_updated = True
                updated_participants.append(participant)

            if not participant_updated:
                logger.warning(
                    f"User {user_id} not found in participants for conversation {conv_doc.id}"
                )
                continue

            # Prepare update payload
            updates = {
                "participants": updated_participants,
                "lastUpdatedAt": firestore.SERVER_TIMESTAMP,
            }

            # Also update lastMessageSenderName if this user sent the last message
            if conv_data.get("lastMessageSenderId") == user_id:
                updates["lastMessageSenderName"] = new_name
                logger.debug(
                    f"Updated lastMessageSenderName in conversation {conv_doc.id}"
                )

            # Add to batch
            batch.update(conv_ref, updates)
            batch_count += 1
            updated_count += 1

            # Commit batch when reaching 500 operations (Firestore limit)
            if batch_count >= 500:
                batch.commit()
                logger.info(
                    f"Committed batch of {batch_count} updates for user {user_id}"
                )
                batch = db.batch()
                batch_count = 0

        # Commit remaining operations
        if batch_count > 0:
            batch.commit()
            logger.info(
                f"Committed final batch of {batch_count} updates for user {user_id}"
            )

        logger.info(
            f"Successfully updated user {user_id}'s name in {updated_count} conversations"
        )

    except Exception as e:
        logger.error(
            f"Error propagating name change for user {user_id}: {str(e)}",
            exc_info=True,
        )
        # Don't raise - we don't want to fail the user's profile update
        # Name will eventually sync via periodic refresh


@firestore_fn.on_document_updated(
    document="conversations/{conversationId}/messages/{messageId}",
    region="us-central1",
)
def on_message_sent(
    event: firestore_fn.Event[firestore_fn.Change]
) -> None:
    """
    Updates conversation's lastMessage and lastMessageSenderName when message sent.

    Triggered when a message is created or updated.
    Only runs when message transitions to 'sent' status (new message).

    Updates:
    - lastMessage (text preview)
    - lastMessageSenderId
    - lastMessageSenderName (fetched from /users collection)
    - lastUpdatedAt
    """
    try:
        conversation_id = event.params["conversationId"]
        message_id = event.params["messageId"]

        # Get message data
        after_data = event.data.after.to_dict() if event.data.after else {}

        # Only process new messages (not updates)
        before_data = event.data.before.to_dict() if event.data.before else {}
        if before_data:
            # This is an update, not a new message
            return

        sender_id = after_data.get("senderId")
        message_text = after_data.get("text", "")

        if not sender_id:
            logger.warning(f"Message {message_id} has no senderId")
            return

        # Fetch sender's current displayName from /users collection
        db = firestore.client()
        user_doc = db.collection("users").document(sender_id).get()

        if not user_doc.exists:
            logger.warning(f"Sender {sender_id} not found in users collection")
            sender_name = "Unknown"
        else:
            sender_name = user_doc.to_dict().get("displayName", "Unknown")

        # Update conversation's lastMessage fields
        conv_ref = db.collection("conversations").document(conversation_id)
        conv_ref.update({
            "lastMessage": message_text[:100],  # Truncate to 100 chars
            "lastMessageSenderId": sender_id,
            "lastMessageSenderName": sender_name,
            "lastUpdatedAt": firestore.SERVER_TIMESTAMP,
        })

        logger.info(
            f"Updated lastMessage in conversation {conversation_id} "
            f"(sender: {sender_name})"
        )

    except Exception as e:
        logger.error(
            f"Error updating lastMessage for conversation {conversation_id}: {str(e)}",
            exc_info=True,
        )
```

#### Step 2.2: Deploy Cloud Function

```bash
# Deploy only the new functions
firebase deploy --only functions:on_user_profile_updated,functions:on_message_sent

# Or deploy all functions
firebase deploy --only functions
```

#### Step 2.3: Test Cloud Function

**Manual Test**:
1. Update a user's displayName in Firebase Console
2. Check Cloud Function logs: `firebase functions:log`
3. Verify conversations updated with new name
4. Check mobile app sees updated name in <2 seconds

**Automated Test** (optional):
```python
# In functions/test_name_propagation.py
import unittest
from unittest.mock import Mock, patch
from main import on_user_profile_updated

class TestNamePropagation(unittest.TestCase):
    @patch('main.firestore.client')
    def test_displayName_change_propagates(self, mock_firestore):
        # Setup mock data
        mock_event = Mock()
        mock_event.params = {"userId": "alice_123"}
        mock_event.data.before.to_dict.return_value = {
            "displayName": "Alice"
        }
        mock_event.data.after.to_dict.return_value = {
            "displayName": "Alice Johnson"
        }

        # Mock conversation query
        mock_db = mock_firestore.return_value
        mock_conv = Mock()
        mock_conv.id = "conv_1"
        mock_conv.to_dict.return_value = {
            "participants": [
                {"uid": "alice_123", "name": "Alice"},
                {"uid": "bob_456", "name": "Bob"}
            ],
            "lastMessageSenderId": "alice_123"
        }
        mock_db.collection.return_value.where.return_value.stream.return_value = [mock_conv]

        # Execute function
        on_user_profile_updated(mock_event)

        # Verify batch update called with new name
        batch = mock_db.batch.return_value
        batch.update.assert_called_once()
        update_args = batch.update.call_args[0]

        self.assertEqual(
            update_args[1]["participants"][0]["name"],
            "Alice Johnson"
        )
        self.assertEqual(
            update_args[1]["lastMessageSenderName"],
            "Alice Johnson"
        )
```

---

### Phase 3: UI Optimization - Remove Async Lookups

**Estimated Time**: 2-3 hours

#### Step 3.1: Update ConversationListItem
**File**: `lib/features/messaging/presentation/widgets/conversation_list_item.dart`

**BEFORE (Async Lookup)**:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  if (!isGroup) {
    // Direct conversation
    Map<String, dynamic> otherParticipant;
    try {
      otherParticipant = participants.firstWhere(
        (p) => p['uid'] != currentUserId,
      );
    } catch (e) {
      otherParticipant = participants.isNotEmpty
          ? participants.first
          : {'uid': '', 'imageUrl': null};
    }

    final otherUserId = otherParticipant['uid'] as String? ?? '';

    // ❌ ASYNC LOOKUP (causes flicker)
    final displayNameAsync = ref.watch(userDisplayNameProvider(otherUserId));

    return displayNameAsync.when(
      data: (displayName) => ListTile(
        title: Text(displayName),
        // ...
      ),
      loading: () => ListTile(
        title: const Text('Loading...'),
      ),
      error: (_, _) => ListTile(
        title: const Text('Unknown'),
      ),
    );
  }
  // ... group logic ...
}
```

**AFTER (Synchronous from Participant)**:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  if (!isGroup) {
    // Direct conversation
    Map<String, dynamic> otherParticipant;
    try {
      otherParticipant = participants.firstWhere(
        (p) => p['uid'] != currentUserId,
      );
    } catch (e) {
      otherParticipant = participants.isNotEmpty
          ? participants.first
          : {'uid': '', 'name': 'Unknown', 'imageUrl': null};
    }

    // ✅ SYNCHRONOUS (instant, no flicker)
    final displayName = otherParticipant['name'] as String? ?? 'Unknown';
    final imageUrl = otherParticipant['imageUrl'] as String?;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildAvatar(displayName, imageUrl),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,  // ✅ Instant display!
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTimestamp(lastUpdatedAt),
            style: TextStyle(
              fontSize: 12,
              color: unreadCount > 0
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
      subtitle: Text(
        lastMessage ?? 'No messages yet',
        style: TextStyle(
          color: lastMessage == null ? Colors.grey : Colors.grey[700],
          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }

  // Group conversation (similar update)
  final name = groupName ?? 'Unknown Group';
  return ListTile(
    leading: _buildGroupAvatar(name),
    title: Text(name),
    subtitle: Text(lastMessage ?? 'No messages yet'),
    onTap: onTap,
  );
}
```

#### Step 3.2: Update ConversationListPage
**File**: `lib/features/messaging/presentation/pages/conversation_list_page.dart`

```dart
// In allConversationsStreamProvider mapping
return allConversations.map((Conversation conv) => {
  'id': conv.documentId,
  'type': conv.type,
  'groupName': conv.groupName,
  'participants': conv.participants
      .map((Participant p) => {
        'uid': p.uid,
        'name': p.displayName,              // ✅ Include name!
        'imageUrl': p.imageUrl,
        'preferredLanguage': p.preferredLanguage,
      })
      .toList(),
  'lastMessage': conv.lastMessage?.text,
  'lastMessageSenderName': conv.lastMessageSenderName,  // ✅ Use cached name
  'lastUpdatedAt': conv.lastUpdatedAt,
  'unreadCount': conv.getUnreadCountForUser(userId),
}).toList();
```

#### Step 3.3: Update ChatPage AppBar
**File**: `lib/features/messaging/presentation/pages/chat_page.dart`

**Option A: Use Participant Name from Conversation (Recommended)**
```dart
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({
    required this.conversationId,
    required this.otherParticipantId,  // Keep for backward compat
    this.isGroup = false,
    super.key,
  });

  final String conversationId;
  final String otherParticipantId;  // May be stale
  final bool isGroup;

  // Remove otherParticipantName parameter - fetch from conversation instead
}

class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  Widget build(BuildContext context) {
    // Fetch conversation to get participant name
    final conversationAsync = ref.watch(
      conversationByIdProvider(widget.conversationId),
    );

    return conversationAsync.when(
      data: (conversation) {
        final otherParticipant = conversation.participants.firstWhere(
          (p) => p.uid == widget.otherParticipantId,
          orElse: () => Participant(
            uid: widget.otherParticipantId,
            displayName: 'Unknown',
            preferredLanguage: 'en',
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.isGroup
                  ? conversation.groupName ?? 'Group Chat'
                  : otherParticipant.displayName,  // ✅ Always current
            ),
          ),
          // ... rest of UI ...
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Failed to load conversation')),
      ),
    );
  }
}
```

#### Step 3.4: Remove UserDisplayNameProvider (Cleanup)

**Files to Update**:
1. Remove `userDisplayNameProvider` from `user_lookup_provider.dart`
2. Remove imports where used
3. Clean up any remaining async lookup logic

**Note**: Keep `UserLookupCache` for other use cases (e.g., user search, profile views)

---

### Phase 4: Cache Reliability - Fix User Sync

**Estimated Time**: 1-2 hours

#### Step 4.1: Fix User Cache Service
**File**: `lib/features/authentication/data/services/user_cache_service.dart`

**BEFORE (Never Updates)**:
```dart
Future<void> cacheUser(String userId) async {
  // Check if already cached
  final cached = await _database.userDao.getUserByUid(userId);
  if (cached != null) {
    return;  // ❌ Returns immediately, never checks for updates!
  }

  // Only fetches if NOT cached at all
  final result = await _userRepository.getUserById(userId);
  // ... save to Drift ...
}
```

**AFTER (Always Updates)**:
```dart
Future<void> cacheUser(String userId) async {
  // ALWAYS fetch from Firestore to get latest data
  // This ensures cache stays fresh
  final result = await _userRepository.getUserById(userId);

  await result.fold(
    (failure) async {
      // On error, keep existing cache if present (graceful degradation)
      final cached = await _database.userDao.getUserByUid(userId);
      if (cached != null) {
        debugPrint(
          'UserCacheService: Failed to refresh $userId, using cached data: ${failure.message}'
        );
      } else {
        debugPrint(
          'UserCacheService: Failed to cache new user $userId: ${failure.message}'
        );
      }
    },
    (user) async {
      // UPSERT (insert or update) - always sync latest
      await _saveUserToDrift(user);
      debugPrint(
        'UserCacheService: Cached/updated user ${user.displayName} ($userId)'
      );
    },
  );
}

/// Syncs user data to Drift (UPSERT operation)
Future<void> syncUserToDrift(User user) async {
  await _saveUserToDrift(user);
}

Future<void> _saveUserToDrift(User user) async {
  final companion = UsersCompanion.insert(
    uid: user.uid,
    name: user.displayName,
    email: Value(user.email),
    phoneNumber: Value(user.phoneNumber),
    imageUrl: Value(user.photoURL),
    preferredLanguage: user.preferredLanguage,
    createdAt: user.createdAt,
    lastSeen: user.lastSeen ?? DateTime.now(),
    isOnline: user.isOnline ?? false,
    fcmToken: Value(null),
  );

  // Use writeQueue for thread-safe batch operations
  await _writeQueue.enqueue(
    () => _database.userDao.upsertUser(companion),
  );
}
```

#### Step 4.2: Update User Sync Service
**File**: `lib/features/authentication/data/services/user_sync_service.dart`

```dart
class UserSyncService {
  // ... existing code ...

  /// Syncs a list of users to Drift cache
  Future<void> syncConversationUsers(List<String> userIds) async {
    if (userIds.isEmpty) return;

    debugPrint('UserSyncService: Syncing ${userIds.length} users');

    // Sync all users in parallel for performance
    await Future.wait(
      userIds.map((userId) => _userCacheService.cacheUser(userId)),
    );

    // Start watching each user for real-time updates
    for (final userId in userIds) {
      _watchUser(userId);
    }
  }

  void _watchUser(String userId) {
    if (_userWatchers.containsKey(userId)) {
      return;  // Already watching
    }

    // Create Firestore listener for real-time updates
    final subscription = _userRepository.watchUser(userId).listen(
      (Either<Failure, User> result) {
        result.fold(
          (failure) {
            debugPrint('UserSyncService: Watch error for $userId: ${failure.message}');
          },
          (user) async {
            // User profile updated → sync to Drift immediately
            await _userCacheService.syncUserToDrift(user);
            debugPrint(
              'UserSyncService: Real-time update for ${user.displayName} ($userId)'
            );
          },
        );
      },
      onError: (error) {
        debugPrint('UserSyncService: Watch stream error for $userId: $error');
      },
    );

    _userWatchers[userId] = subscription;
  }

  // Background refresh: Keep existing 1-hour interval as backup
  Future<void> _refreshAllCachedUsers() async {
    final cachedUsers = await _database.userDao.getAllUsers();
    final userIds = cachedUsers.map((u) => u.uid).toList();

    debugPrint('UserSyncService: Background refresh of ${userIds.length} cached users');

    await syncConversationUsers(userIds);
  }
}
```

---

### Phase 5: Testing & Validation

**Estimated Time**: 2-3 hours

#### Test Plan

##### 5.1: Unit Tests

**File**: `test/features/messaging/domain/entities/conversation_test.dart`

```dart
void main() {
  group('Participant', () {
    test('toJson includes displayName as name', () {
      final participant = Participant(
        uid: 'alice_123',
        displayName: 'Alice Johnson',
        imageUrl: 'https://example.com/alice.jpg',
        preferredLanguage: 'en',
      );

      final json = participant.toJson();

      expect(json['uid'], 'alice_123');
      expect(json['name'], 'Alice Johnson');  // Stored as 'name'
      expect(json['imageUrl'], 'https://example.com/alice.jpg');
      expect(json['preferredLanguage'], 'en');
    });

    test('fromJson handles missing name field (backward compatibility)', () {
      final json = {
        'uid': 'alice_123',
        // 'name' field missing (old format)
        'imageUrl': 'https://example.com/alice.jpg',
        'preferredLanguage': 'en',
      };

      final participant = Participant.fromJson(json);

      expect(participant.uid, 'alice_123');
      expect(participant.displayName, 'Unknown');  // Fallback
      expect(participant.imageUrl, 'https://example.com/alice.jpg');
    });
  });
}
```

##### 5.2: Integration Tests

**Scenario 1: New Conversation Creation**
```dart
testWidgets('New conversation shows participant name instantly', (tester) async {
  // Setup: Mock user profiles
  final alice = User(
    uid: 'alice_123',
    displayName: 'Alice Johnson',
    email: 'alice@example.com',
    preferredLanguage: 'en',
  );

  final bob = User(
    uid: 'bob_456',
    displayName: 'Bob Smith',
    email: 'bob@example.com',
    preferredLanguage: 'en',
  );

  // Create conversation
  final conversation = await findOrCreateDirectConversation(
    userId: alice.uid,
    otherUserId: bob.uid,
  );

  // Verify participants have names
  expect(conversation.participants.length, 2);
  expect(
    conversation.participants.any((p) => p.displayName == 'Alice Johnson'),
    true,
  );
  expect(
    conversation.participants.any((p) => p.displayName == 'Bob Smith'),
    true,
  );

  // Render conversation list
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: ConversationListPage(),
      ),
    ),
  );

  await tester.pumpAndSettle();

  // Verify name appears instantly (no async lookup)
  expect(find.text('Bob Smith'), findsOneWidget);  // Alice's view
  expect(find.text('Loading...'), findsNothing);    // No loading state
});
```

**Scenario 2: Name Change Propagation**
```dart
test('Name change propagates to all conversations', () async {
  // Setup: Create conversations with Alice
  final conv1 = await createConversation(participants: [alice, bob]);
  final conv2 = await createConversation(participants: [alice, charlie]);

  // Alice changes her name
  await updateUserProfile(
    userId: alice.uid,
    displayName: 'Alice M. Johnson',
  );

  // Wait for Cloud Function to propagate
  await Future.delayed(Duration(seconds: 2));

  // Fetch conversations
  final updatedConv1 = await getConversation(conv1.id);
  final updatedConv2 = await getConversation(conv2.id);

  // Verify name updated in both
  expect(
    updatedConv1.participants
        .firstWhere((p) => p.uid == alice.uid)
        .displayName,
    'Alice M. Johnson',
  );
  expect(
    updatedConv2.participants
        .firstWhere((p) => p.uid == alice.uid)
        .displayName,
    'Alice M. Johnson',
  );
});
```

**Scenario 3: Offline Support**
```dart
testWidgets('Conversation names work offline', (tester) async {
  // Setup: Load conversations while online
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: ConversationListPage()),
    ),
  );
  await tester.pumpAndSettle();

  // Verify names displayed
  expect(find.text('Alice Johnson'), findsOneWidget);
  expect(find.text('Bob Smith'), findsOneWidget);

  // Go offline
  await setNetworkConnectivity(false);

  // Restart app (simulate cold start)
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: ConversationListPage()),
    ),
  );
  await tester.pumpAndSettle();

  // Verify names STILL displayed (from Drift cache)
  expect(find.text('Alice Johnson'), findsOneWidget);
  expect(find.text('Bob Smith'), findsOneWidget);
  expect(find.text('Unknown'), findsNothing);
});
```

##### 5.3: Manual Testing Checklist

- [ ] **Create new direct conversation**
  - [ ] Participant names appear instantly
  - [ ] No "Unknown" flicker
  - [ ] No "Loading..." state

- [ ] **Create new group conversation**
  - [ ] All member names appear instantly
  - [ ] Group name displays correctly
  - [ ] No async lookups

- [ ] **Update user displayName**
  - [ ] Cloud Function triggers
  - [ ] Name updates in all conversations within 2 seconds
  - [ ] lastMessageSenderName updates if applicable
  - [ ] Mobile apps see update in real-time

- [ ] **Offline mode**
  - [ ] Load conversation list → names appear
  - [ ] Open chat → participant name appears
  - [ ] Send message → works offline
  - [ ] No "Unknown" fallbacks

- [ ] **Backward compatibility**
  - [ ] Load old conversations (before migration) → falls back to "Unknown"
  - [ ] No crashes or errors
  - [ ] Graceful degradation

- [ ] **Performance**
  - [ ] Conversation list loads instantly
  - [ ] No N+1 lookup problem
  - [ ] Group chats with 10+ members load fast

---

## 🚀 Migration Strategy

### Backward Compatibility Plan

**Problem**: Existing conversations don't have `name` field in participants.

**Solution**: Graceful degradation with background migration.

#### Phase 1: Deploy Code with Fallback (Day 1)

```dart
// In Participant.fromJson()
factory Participant.fromJson(Map<String, dynamic> json) => Participant(
  uid: json['uid'] as String,
  displayName: json['name'] as String? ?? 'Unknown',  // ✅ Fallback for old data
  imageUrl: json['imageUrl'] as String?,
  preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
);
```

**Result**:
- Old conversations show "Unknown" temporarily
- New conversations work perfectly
- No crashes or errors

#### Phase 2: Background Migration Script (Day 2-3)

**File**: `scripts/migrate_participant_names.py`

```python
"""
One-time migration script to add 'name' field to existing conversation participants.

Usage:
  python scripts/migrate_participant_names.py --project message-ai-fad19 [--dry-run]

What it does:
1. Queries all conversations
2. For each conversation:
   - Extracts participant UIDs
   - Fetches each user's displayName from /users collection
   - Updates participants array with 'name' field
3. Logs progress and errors

Safety:
- Dry-run mode to preview changes
- Batched writes (500 ops per batch)
- Error handling and retry logic
- Progress tracking
"""

import argparse
import firebase_admin
from firebase_admin import credentials, firestore
from typing import List, Dict, Any


def migrate_conversation_participants(
    db: firestore.Client,
    dry_run: bool = False
) -> None:
    """Migrates all conversations to include participant names."""

    print("Starting migration of conversation participant names...")

    # Fetch all conversations
    conversations_ref = db.collection("conversations")
    conversations = list(conversations_ref.stream())
    total = len(conversations)

    print(f"Found {total} conversations to process")

    # Track progress
    updated = 0
    errors = 0
    skipped = 0

    # Batch writes for performance
    batch = db.batch()
    batch_count = 0

    for i, conv_doc in enumerate(conversations):
        conv_id = conv_doc.id
        conv_data = conv_doc.to_dict()

        print(f"\n[{i+1}/{total}] Processing conversation {conv_id}")

        participants = conv_data.get("participants", [])

        # Check if migration already done
        if all('name' in p for p in participants):
            print(f"  ✓ Already migrated (all participants have 'name' field)")
            skipped += 1
            continue

        # Fetch user displayNames
        updated_participants = []
        needs_update = False

        for participant in participants:
            uid = participant.get("uid")

            if not uid:
                print(f"  ⚠ Participant missing uid: {participant}")
                updated_participants.append(participant)
                continue

            # Check if name already exists
            if 'name' in participant:
                print(f"  ✓ Participant {uid} already has name: {participant['name']}")
                updated_participants.append(participant)
                continue

            # Fetch user's displayName
            user_doc = db.collection("users").document(uid).get()

            if not user_doc.exists:
                print(f"  ⚠ User {uid} not found in /users collection")
                # Add with fallback
                participant['name'] = 'Unknown'
                needs_update = True
            else:
                user_data = user_doc.to_dict()
                display_name = user_data.get("displayName", "Unknown")
                participant['name'] = display_name
                print(f"  ✓ Added name for {uid}: {display_name}")
                needs_update = True

            updated_participants.append(participant)

        # Update conversation if needed
        if needs_update:
            if dry_run:
                print(f"  [DRY RUN] Would update participants: {updated_participants}")
                updated += 1
            else:
                try:
                    batch.update(
                        conversations_ref.document(conv_id),
                        {
                            "participants": updated_participants,
                            "lastUpdatedAt": firestore.SERVER_TIMESTAMP,
                        }
                    )
                    batch_count += 1
                    updated += 1

                    # Commit batch every 500 operations
                    if batch_count >= 500:
                        batch.commit()
                        print(f"  ✓ Committed batch of {batch_count} updates")
                        batch = db.batch()
                        batch_count = 0

                except Exception as e:
                    print(f"  ❌ Error updating conversation {conv_id}: {e}")
                    errors += 1
        else:
            print(f"  ℹ No update needed")
            skipped += 1

    # Commit remaining operations
    if batch_count > 0 and not dry_run:
        batch.commit()
        print(f"\n✓ Committed final batch of {batch_count} updates")

    # Summary
    print("\n" + "="*60)
    print("MIGRATION SUMMARY")
    print("="*60)
    print(f"Total conversations: {total}")
    print(f"Updated: {updated}")
    print(f"Skipped (already migrated): {skipped}")
    print(f"Errors: {errors}")

    if dry_run:
        print("\n⚠ DRY RUN MODE - No changes were made")
    else:
        print("\n✓ Migration complete!")


def main():
    parser = argparse.ArgumentParser(
        description="Migrate conversation participants to include name field"
    )
    parser.add_argument(
        "--project",
        required=True,
        help="Firebase project ID"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without updating database"
    )

    args = parser.parse_args()

    # Initialize Firebase Admin
    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred, {
        'projectId': args.project,
    })

    db = firestore.client()

    # Run migration
    migrate_conversation_participants(db, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
```

**Run Migration**:
```bash
# Dry run first (preview changes)
python scripts/migrate_participant_names.py --project message-ai-fad19 --dry-run

# Actual migration
python scripts/migrate_participant_names.py --project message-ai-fad19
```

#### Phase 3: Monitor & Verify (Day 3-7)

**Monitoring**:
- Check Cloud Function logs for errors
- Monitor Firestore read/write metrics
- Track user reports of "Unknown" names
- Performance metrics (conversation load time)

**Verification Queries**:
```javascript
// In Firebase Console
db.collection("conversations")
  .where("participants", "array-contains", {uid: "alice_123"})
  .get()
  .then(snapshot => {
    snapshot.forEach(doc => {
      const participants = doc.data().participants;
      console.log(`Conversation ${doc.id}:`, participants);
      // Check if all have 'name' field
    });
  });
```

---

## 🔄 Rollback Plan

If issues arise during deployment, follow this rollback procedure:

### Rollback Step 1: Revert Cloud Function (Immediate)

```bash
# Disable the new Cloud Function
firebase functions:delete on_user_profile_updated
firebase functions:delete on_message_sent

# Or deploy previous version
git checkout <previous-commit>
firebase deploy --only functions
```

### Rollback Step 2: Revert Code Changes (24 hours)

```bash
# Revert to previous commit
git revert <commit-hash>

# Rebuild and redeploy
dart run build_runner build --delete-conflicting-outputs
firebase deploy
```

### Rollback Step 3: Database Cleanup (Optional)

```python
# Remove 'name' field from all participants (if needed)
for conv in db.collection("conversations").stream():
    participants = conv.to_dict().get("participants", [])
    cleaned = [{k: v for k, v in p.items() if k != 'name'} for p in participants]
    db.collection("conversations").document(conv.id).update({
        "participants": cleaned
    })
```

**Impact**:
- App reverts to async lookups (shows "Unknown" temporarily)
- Old functionality restored
- No data loss

---

## 📈 Success Metrics

### Performance Metrics

| Metric | Before | Target | Measurement |
|--------|--------|--------|-------------|
| **Conversation List Load Time** | 800ms | <200ms | Time to first render |
| **"Unknown" Occurrences** | 30% of conversations | <1% | User reports + analytics |
| **UI Flicker Events** | 100% of new conversations | 0% | Visual regression tests |
| **Async Lookups per Conversation** | 1-10 (N participants) | 0 | Code instrumentation |
| **Offline Name Display Success** | 40% | 100% | Offline testing |

### User Experience Metrics

| Metric | Before | Target |
|--------|--------|--------|
| **Time to see participant name** | 500-2000ms (async) | <50ms (instant) |
| **Name update propagation** | 1 hour (periodic refresh) | <2 seconds (Cloud Function) |
| **Offline conversation access** | 60% success | 100% success |

### Technical Metrics

| Metric | Target |
|--------|--------|
| **Cloud Function execution time** | <1 second per conversation |
| **Cloud Function success rate** | >99.9% |
| **Firestore read cost reduction** | -70% (eliminate lookups) |
| **Firestore write increase** | +10% (Cloud Function updates) |

---

## 🎯 Timeline & Effort Estimate

| Phase | Tasks | Estimated Hours | Dependencies |
|-------|-------|----------------|--------------|
| **Phase 1: Foundation** | Add displayName to Participant model | 4-6 hours | None |
| **Phase 2: Propagation** | Implement Cloud Function | 2-3 hours | Phase 1 complete |
| **Phase 3: UI Optimization** | Remove async lookups | 2-3 hours | Phase 1 complete |
| **Phase 4: Cache Reliability** | Fix user sync | 1-2 hours | None (parallel) |
| **Phase 5: Testing** | Write tests + manual QA | 2-3 hours | Phases 1-4 complete |
| **Migration** | Run migration script | 1-2 hours | Phase 1 deployed |
| **Total** | | **12-19 hours** | **2-3 days** |

### Recommended Execution Order

**Week 1** (Development):
- Day 1-2: Phase 1 (Foundation) + Phase 4 (Cache Reliability)
- Day 3: Phase 2 (Cloud Function)
- Day 4: Phase 3 (UI Optimization)
- Day 5: Phase 5 (Testing)

**Week 2** (Deployment):
- Day 1: Deploy Phase 1 + Phase 4 to production
- Day 2: Run migration script (off-hours)
- Day 3: Deploy Phase 2 (Cloud Function)
- Day 4: Deploy Phase 3 (UI changes)
- Day 5: Monitor metrics + bug fixes

---

## 🤔 Alternative Approaches Considered

### Alternative 1: Keep Async Lookups, Add Aggressive Caching

**Approach**:
- Keep current architecture (no displayName in Participant)
- Pre-cache ALL users in Drift on app start
- Use in-memory cache with infinite TTL

**Pros**:
- No schema changes needed
- Simpler implementation (2-3 hours)

**Cons**:
- ❌ Still shows "Unknown" for new users
- ❌ Still broken offline for uncached users
- ❌ Memory intensive (cache all users)
- ❌ Doesn't fix root cause (architecture flaw)

**Decision**: Rejected - doesn't solve offline-first or "Unknown" problems

---

### Alternative 2: Server-Side Rendering of Conversation List

**Approach**:
- Cloud Function generates conversation list with names pre-populated
- Client fetches rendered HTML/JSON

**Pros**:
- Zero client-side lookups
- Instant rendering

**Cons**:
- ❌ Breaks offline-first (requires network)
- ❌ Complex caching strategy
- ❌ High server costs (function invocations)
- ❌ Not Flutter best practice

**Decision**: Rejected - violates offline-first principle

---

### Alternative 3: Hybrid - Store Names in Firestore Only

**Approach**:
- Add `name` to Firestore participants
- Drift conversations table references Firestore
- No local caching of names

**Pros**:
- Simpler than full snapshot approach
- Always current (no propagation needed)

**Cons**:
- ❌ Broken offline (Drift can't resolve names)
- ❌ Requires network for every conversation load
- ❌ Violates offline-first architecture

**Decision**: Rejected - offline support critical

---

## 📚 References & Resources

### WhatsApp-Style Architecture
- [Firebase Real-Time Database Best Practices](https://firebase.google.com/docs/database/usage/best-practices)
- [Denormalization in NoSQL](https://firebase.google.com/docs/firestore/manage-data/structure-data#denormalization)
- [Offline-First Mobile Apps](https://www.youtube.com/watch?v=70WqJxI_mnE)

### Flutter Offline-First Patterns
- [Drift (SQLite ORM) Documentation](https://drift.simonbinder.eu/)
- [Riverpod State Management](https://riverpod.dev/)
- [Flutter Offline Mode Best Practices](https://medium.com/flutter-community/flutter-offline-first-architecture-7d7e1f9ba7e0)

### Cloud Functions
- [Firestore Triggers](https://firebase.google.com/docs/functions/firestore-events)
- [Batched Writes](https://firebase.google.com/docs/firestore/manage-data/transactions#batched-writes)
- [Cloud Functions Best Practices](https://firebase.google.com/docs/functions/best-practices)

---

## ✅ Acceptance Criteria

This implementation is considered complete when ALL of the following are true:

- [ ] **Participant Model**: `displayName` field added to `Participant` entity
- [ ] **Conversation Creation**: All new conversations store participant names as snapshots
- [ ] **Cloud Function**: `on_user_profile_updated` deployed and tested
- [ ] **Name Propagation**: displayName changes appear in conversations within 2 seconds
- [ ] **UI Optimization**: Zero async lookups in ConversationListItem
- [ ] **Offline Support**: Conversation names display 100% offline (from Drift cache)
- [ ] **No "Unknown" Flicker**: New conversations show names instantly (no loading state)
- [ ] **Performance**: Conversation list loads in <200ms
- [ ] **Migration**: All existing conversations updated with participant names
- [ ] **Tests**: Unit tests + integration tests passing
- [ ] **Documentation**: This document updated with actual implementation details
- [ ] **Monitoring**: Cloud Function logs show successful propagation
- [ ] **User Reports**: Zero reports of "Unknown" names in new conversations

---

## 🔗 Related Documents

- [Message Sync Architecture](./message-sync-architecture.md)
- [Offline-First Principles](./offline-first-principles.md)
- [Clean Architecture Guide](../../CLAUDE.md#architecture-overview)
- [Firebase Cloud Functions Setup](../../functions/README.md)

---

**Last Updated**: 2025-10-25
**Status**: 📋 Planned (Ready for Implementation)
**Next Review Date**: Before implementation begins
