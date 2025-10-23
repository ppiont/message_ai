# Display Name Refactoring Progress

## Goal
Remove cached `senderName` from messages and implement proper client-side user lookup pattern (used by WhatsApp, Slack, Discord, etc.).

## Why This Refactoring?

### Old Approach (Denormalized Cache)
```dart
// ❌ BAD: Cache name in every message
Message {
  id: "msg1",
  senderId: "user123",
  senderName: "John Doe",  // ❌ Cached - gets stale
}

// When name changes: Update THOUSANDS of message documents 💸💸💸
```

### New Approach (Normalized with Client Lookup)
```dart
// ✅ GOOD: Store only senderId
Message {
  id: "msg1",
  senderId: "user123",  // ✅ Only reference
}

// UI looks up name dynamically (with caching)
final name = await ref.read(userDisplayNameProvider("user123"));
// When name changes: ZERO message updates needed! 🎉
```

## Benefits
1. **Instant Propagation**: Name changes appear everywhere immediately
2. **Zero Write Cost**: No need to update millions of message documents
3. **Single Source of Truth**: User data lives only in users collection
4. **Scalable**: Works with billions of messages
5. **Industry Standard**: How all major chat apps work

## Progress

### ✅ Completed
1. Created `UserLookupProvider` with in-memory caching (5min TTL)
2. Removed `senderName` from `Message` entity (domain layer)
3. Removed `senderName` from `MessageModel` (data layer)
4. Committed first phase changes

### 🚧 In Progress
5. Update Drift schema - remove `senderName` column with migration

### 📋 Remaining
6. Update `MessageBubble` to lookup sender name dynamically
7. Update `ConversationListTile` to lookup last message sender
8. Update `SendMessage` use case - remove senderName
9. Update all repository/datasource methods
10. Remove `MessageDao.updateSenderNameForUser` method
11. Remove display name propagation from `SettingsPage`
12. Delete Firebase `propagate_display_name_changes` function
13. Update all tests to remove senderName
14. Run full test suite and verify changes

## Testing Strategy
- Unit tests: Update mocks to remove senderName
- Widget tests: Use `userDisplayNameProvider` in test harness
- Integration tests: Verify name lookup works end-to-end
- Manual testing: Change name, verify instant propagation

## Rollback Plan
If issues arise, we can:
1. Revert commits in order (git revert)
2. Re-add senderName fields (but keep lookup provider for future)
3. Run database migration to restore column

## References
- WhatsApp: Uses client-side contact name lookup
- Slack: Caches user data in client with periodic refresh
- Discord: Normalized user data with in-memory cache
