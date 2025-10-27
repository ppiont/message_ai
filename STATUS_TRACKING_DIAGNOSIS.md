# Message Status Tracking System - Diagnostic Guide

## ✅ FIXED: Sender Now Sees Delivery Status

**Issue:** Senders could never see when their messages were delivered/read because they were only querying their local database.

**Fix Applied:** When displaying messages sent by the current user, the system now:
1. Queries local MessageStatus table (for any local status)
2. **Also queries Firestore subcollections** to get recipients' delivery/read status
3. Merges both sources (Firestore takes precedence)
4. Displays the aggregate status in the UI

## Current Architecture (Post-Refactoring)

### 1. Local Status Tracking (PRIMARY SOURCE OF TRUTH for UI)
- **Table:** `MessageStatus` in Drift database
- **Columns:** `messageId`, `userId`, `status` ('sent', 'delivered', 'read'), `timestamp`
- **Purpose:** Offline-first status tracking, fast queries for UI

### 2. Remote Status Tracking (Firestore Subcollections)
- **Structure:** `messages/{messageId}/status/{userId}`
- **Fields:** `status`, `timestamp`, `userId`
- **Purpose:** Sync status across devices, backup

### 3. Legacy Fields (DEPRECATED - DO NOT USE)
- **Old structure:** `deliveredTo` and `readBy` maps in message document
- **Status:** These fields may still exist on old messages but are NO LONGER written by new code
- **Migration:** Not required - old fields are ignored by MessageModel.fromJson()

## How Status Updates Work

### When User Opens a Conversation (Delivery)

1. **chat_page.dart** line 72:
   ```dart
   ref.read(markMessagesDeliveredProvider(widget.conversationId, currentUser.uid));
   ```

2. **markMessagesDelivered()** provider (messaging_providers.dart:359-385):
   - Writes to LOCAL MessageStatus table via `messageStatusDao.markAllAsDelivered()`
   - Schedules WorkManager task for background Firestore sync
   - Returns immediately (non-blocking)

3. **DeliveryTrackingWorker** (runs periodically in background):
   - Reads pending status from MessageStatus table
   - Syncs to Firestore subcollections at `messages/{messageId}/status/{userId}`

### When User Reads a Message

1. (Not yet implemented - would be similar to delivery)
2. Call `messageStatusDao.markAsRead()`
3. ReadReceiptWorker syncs to Firestore

### How UI Displays Status

1. **conversationMessagesStream** provider (messaging_providers.dart:207-314):
   - Watches messages from Firestore
   - For EACH message, queries MessageStatus table: `messageStatusDao.getStatusForMessage(msg.id)`
   - Builds `MessageWithStatus` object with computed aggregate status
   - Returns Map with `status`, `readCount`, `deliveredCount` fields

2. **Status Computation Logic** (message_with_status.dart):
   - **For sent messages:** Aggregates status across all recipients (group chat support)
   - **For received messages:** Simple lookup of current user's status
   - **Returns:** 'sent', 'delivered', or 'read'

## Debugging Steps

### Step 1: Check if Local Status is Being Written

Run this SQL query in the app's Drift database to see if status records exist:

```sql
SELECT * FROM message_status WHERE messageId = '<your-message-id>';
```

**Expected result:** Should see records with status='delivered' for messages in open conversations.

**If empty:** The `markMessagesDelivered` provider is not being called or failing silently.

### Step 2: Check Debug Logs

When opening a conversation, you should see these logs:

```
[markMessagesDelivered] Marked messages in <conversationId> as delivered for <userId>
```

When watching messages, you should see:

```
📊 Message <id>: computed status=delivered (participantIds=[...])
```

**If you see status=sent:** MessageStatus table has no records for that message.

### Step 3: Check Firestore Subcollections

In Firebase Console:
1. Navigate to `conversations/{conversationId}/messages/{messageId}`
2. Look for **subcollection** named `status`
3. Check if there are documents with userId as document ID

**If missing:** WorkManager task hasn't run yet or failed.

### Step 4: Check WorkManager Registration

Look for this log on app startup:

```
[WorkManager] Periodic tasks registered
```

And when tasks run:

```
[WorkManager] delivery-tracking complete: X synced, Y failed
```

## Common Issues

### Issue: Status always shows "sent", never "delivered"

**Possible Causes:**
1. `markMessagesDelivered` not being called when conversation opens
2. MessageStatusDao.markAllAsDelivered() failing silently
3. Messages sent by current user (sender doesn't get delivery status)
4. Participant IDs not matching (userId mismatch)

**Fix:** Check debug logs for Step 2 above. Add breakpoint in `markMessagesDelivered()`.

### Issue: Old messages have deliveredTo map field in Firestore

**Cause:** These are messages created before the refactoring.

**Fix:** No action needed. MessageModel.fromJson() ignores these fields. They don't affect the new system.

### Issue: Firestore subcollections not being created

**Possible Causes:**
1. WorkManager tasks not registered
2. Network constraint preventing background sync
3. DeliveryTrackingWorker throwing exceptions

**Fix:** Check WorkManager logs. Try running app on WiFi to satisfy network constraints.

## Testing Checklist

- [ ] Send a message in a conversation
- [ ] Check Drift database for MessageStatus records (should be empty for sender's own messages)
- [ ] Open conversation as RECIPIENT
- [ ] Check debug logs for "Marked messages... as delivered"
- [ ] Check Drift database for MessageStatus records (should now have delivered status)
- [ ] Check UI - message bubble should show "delivered" indicator
- [ ] Wait 15 minutes for WorkManager periodic task
- [ ] Check Firestore for status subcollections
- [ ] Check WorkManager logs for sync confirmation

## Next Steps for User

Please run through the debugging steps above and report:
1. What you see in the debug logs when opening a conversation
2. Whether MessageStatus records are being created in Drift
3. The actual status value being computed in the "📊 Message" debug log

This will help identify exactly where the flow is breaking.
