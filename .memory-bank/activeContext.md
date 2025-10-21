# Active Context

## Current Focus: Test Coverage Sprint (Day 1)
**Status**: Following Test-Driven Development (TDD) Guidelines
**Goal**: Achieve 85%+ test coverage before moving to AI features

## What We're Working On Right Now

### Testing Progress (92/~150 tests complete - 61%)

#### ✅ Completed Testing (59 tests)
**Authentication Layer - COMPLETE**
1. ✅ Auth Use Cases (20 tests):
   - SignInWithEmail, SignUpWithEmail, SignOut
   - GetCurrentUser, SendPasswordResetEmail
   - UpdateUserProfile

2. ✅ User Firestore Datasource (17 tests):
   - CRUD operations, queries, streams
   - Exception handling and validation
   - Uses fake_cloud_firestore

3. ✅ User Repository (22 tests):
   - Repository implementation
   - Exception → Failure mapping
   - Stream testing

#### ✅ Completed Testing (33 tests)
**Messaging Use Cases - COMPLETE**
1. ✅ SendMessage (6 tests): validation, success, non-critical conversation update failure
2. ✅ WatchMessages (5 tests): validation, streams, empty states
3. ✅ MarkMessageAsRead (5 tests): validation, success, errors
4. ✅ FindOrCreateDirectConversation (7 tests): validation, find/create logic, errors
5. ✅ WatchConversations (5 tests): validation, streams, empty states
6. ✅ GetConversationById (5 tests): validation, success, errors

#### 🚧 In Progress
**Messaging Datasources (0 tests)**
- [ ] message_remote_datasource_impl_test.dart (~15-20 tests)
  - createMessage, getMessages, watchMessages
  - markAsRead, markAsDelivered
  - Firestore exception mapping
  - fake_cloud_firestore mocking

- [ ] conversation_remote_datasource_impl_test.dart (~15-20 tests)
  - CRUD operations
  - findDirectConversation
  - watchConversationsForUser
  - updateLastMessage, unread counts

#### ⏳ Next Up
**Messaging Repositories (~30-40 tests)**
- message_repository_impl_test.dart
- conversation_repository_impl_test.dart

**Widget Tests (~15-20 tests)**
- Auth UI: sign_up_page, sign_in_page, profile_setup_page
- Messaging UI: conversation_list_page, chat_page, user_selection_page

**Coverage Verification**
- Run `flutter test --coverage`
- Generate HTML report
- Verify 85%+ overall coverage

## Recent Changes (Last Session)

### Bug Fixes
1. **Firestore Timestamp Casting Issue**:
   - Problem: `Timestamp` vs `String` type mismatch in ConversationModel
   - Fix: Updated `updateLastMessage` to use `Timestamp.fromDate()`
   - Added `type: 'text'` field to lastMessage

2. **Error Mapper Missing Exception**:
   - Problem: `RecordAlreadyExistsException` not mapped
   - Fix: Added mapping to `DatabaseFailure` in error_mapper.dart

3. **AppException Wrapping Bug**:
   - Problem: `createUser` wrapped `RecordAlreadyExistsException` in `UnknownException`
   - Fix: Added `if (e is AppException) rethrow;` before wrapping

### Tests Written (Today)
- user_remote_datasource_impl_test.dart (17 tests)
- user_repository_impl_test.dart (22 tests)
- send_message_test.dart (6 tests)
- watch_messages_test.dart (5 tests)
- mark_message_as_read_test.dart (5 tests)
- find_or_create_direct_conversation_test.dart (7 tests)
- watch_conversations_test.dart (5 tests)
- get_conversation_by_id_test.dart (5 tests)

### Documentation Created
- `.cursor/rules/testing.mdc`: Comprehensive TDD guidelines
  - RED-GREEN-REFACTOR cycle
  - Test hierarchy (unit, widget, integration)
  - Coverage goals by layer
  - Testing tools and patterns
  - When to write tests (always!)

## Next Actions (Immediate)

### 1. Complete Messaging Datasource Tests
**File**: `test/features/messaging/domain/usecases/message_remote_datasource_impl_test.dart`

Test cases needed:
```dart
- createMessage: success, validation, FirebaseException
- getMessages: success, empty list, pagination
- watchMessages: stream emissions, errors
- markAsRead: success, not found
- markAsDelivered: success, not found
- updateMessage: success, not found
- deleteMessage: success, not found
- Firestore exception mapping
```

### 2. Complete Conversation Datasource Tests
**File**: `test/features/messaging/domain/usecases/conversation_remote_datasource_impl_test.dart`

Test cases needed:
```dart
- createConversation: success, already exists
- getConversationById: success, not found
- findDirectConversation: found, not found, null
- watchConversationsForUser: stream, multiple, empty
- updateConversation: success, not found
- updateLastMessage: success, proper Timestamp handling
- updateUnreadCount: increment, decrement
- deleteConversation: success (soft delete)
- Firestore exception mapping
```

### 3. Write Repository Tests
Follow the same pattern as `user_repository_impl_test.dart`:
- Mock the datasource
- Test all repository methods
- Verify exception → failure mapping
- Test stream transformations

### 4. Write Critical Widget Tests
Focus on key user flows:
- Sign up flow
- Sign in flow
- Start new conversation
- Send message
- Display conversation list

### 5. Verify Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

Check that:
- Domain layer: 100%
- Data layer: 90%+
- Presentation layer: 80%+
- Overall: 85%+

## Key Technical Decisions

### Testing Approach
- **TDD**: Write tests before/during implementation
- **fake_cloud_firestore**: Use for Firestore testing (not mocks)
- **Mocktail**: Use for mocking repositories and use cases
- **AAA Pattern**: Arrange-Act-Assert for all tests
- **Comprehensive Coverage**: Validation, success, error cases

### Test File Organization
```
test/
├── features/
│   ├── authentication/
│   │   ├── domain/usecases/
│   │   ├── data/datasources/
│   │   ├── data/repositories/
│   │   └── presentation/pages/
│   └── messaging/
│       ├── domain/usecases/
│       ├── data/datasources/
│       ├── data/repositories/
│       └── presentation/widgets/
```

### Dependencies for Testing
```yaml
dev_dependencies:
  flutter_test: sdk: flutter
  mocktail: ^1.0.4
  fake_cloud_firestore: ^3.0.3
  firebase_auth_mocks: ^0.14.1
```

## Current Architecture State

### Fully Implemented & Tested
- ✅ Authentication domain layer (entities, use cases, repositories)
- ✅ Authentication data layer (models, datasources, repositories)
- ✅ Authentication presentation layer (pages, providers)
- ✅ Messaging domain layer (entities, use cases)
- ✅ User Firestore integration (datasource + repository)

### Partially Tested
- 🚧 Messaging data layer (models exist, tests needed)
- 🚧 Messaging presentation layer (UI exists, widget tests needed)

### Not Yet Started
- ⏳ Group chat feature
- ⏳ Offline support (Drift integration)
- ⏳ Message delivery status
- ⏳ Push notifications
- ⏳ AI features (all 5 + advanced)

## Blockers & Decisions Needed

### Current Blockers
- None (all tests passing, clear path forward)

### Upcoming Decisions
1. **Group Chat Model**: How to structure participants list?
2. **Offline Queue**: How to handle message retry logic?
3. **AI Integration**: Which Cloud Functions framework to use?
4. **Advanced Feature**: Smart replies or data extraction?

## Context for Next Session

### When Resuming
1. **Current Task**: Writing messaging datasource tests
2. **Files to Focus On**:
   - `test/features/messaging/data/datasources/message_remote_datasource_impl_test.dart`
   - `test/features/messaging/data/datasources/conversation_remote_datasource_impl_test.dart`
3. **Reference Files**:
   - `test/features/authentication/data/datasources/user_remote_datasource_impl_test.dart` (pattern)
   - `.cursor/rules/testing.mdc` (guidelines)
4. **Goal**: Complete all datasource tests, then move to repositories

### Test Patterns to Follow
1. Use `fake_cloud_firestore` for Firestore mocking
2. Set up test data in `setUp()`
3. Group tests by method and by case type (validation, success, errors)
4. Test all exception mappings
5. Verify stream behavior with `expectLater`
6. Check that proper Firestore queries are constructed

### Known Gotchas
- Firestore Timestamp serialization (use `Timestamp.fromDate()`)
- lastMessage needs `type` field
- RecordAlreadyExistsException needs explicit handling
- Stream tests need named parameter mocking

## Success Criteria for This Phase

### Testing Complete When:
- [ ] All datasource tests written and passing (~30-40 tests)
- [ ] All repository tests written and passing (~30-40 tests)
- [ ] Critical widget tests written and passing (~15-20 tests)
- [ ] Coverage report shows 85%+ overall
- [ ] Domain layer at 100%
- [ ] No failing tests
- [ ] All linter warnings resolved

### Ready to Move On When:
- [ ] All above criteria met
- [ ] Tests committed to git
- [ ] Memory bank updated
- [ ] Ready to implement MVP polish (delivery status, offline, groups)

## Links & References

### Documentation
- `.cursor/rules/testing.mdc` - TDD guidelines
- `.cursor/rules/drift.mdc` - Drift ORM patterns
- `.cursor/rules/dart_flutter_mcp.mdc` - Dart MCP usage

### Key Files
- `lib/core/error/error_mapper.dart` - Exception mapping
- `lib/core/error/failures.dart` - Failure types
- `lib/core/error/exceptions.dart` - Exception types

### Test Examples
- `test/features/authentication/data/datasources/user_remote_datasource_impl_test.dart` - Firestore testing pattern
- `test/features/authentication/data/repositories/user_repository_impl_test.dart` - Repository testing pattern
- `test/features/messaging/domain/usecases/send_message_test.dart` - Use case testing pattern
