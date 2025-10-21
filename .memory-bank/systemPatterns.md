# System Patterns & Architecture

## Architecture Style
**Clean Architecture with Feature-First Organization**

### Layer Separation
```
Presentation Layer (UI) → Domain Layer (Business Logic) → Data Layer (Sources)
```

- **Presentation**: Riverpod providers, pages, widgets
- **Domain**: Entities, repositories (interfaces), use cases
- **Data**: Models, data sources (remote/local), repository implementations

### Dependency Rule
Inner layers never depend on outer layers. All dependencies point inward.

## Key Architectural Decisions

### 1. Database Strategy: Cloud Firestore
**Why Firestore over Realtime Database:**
- Real-time sync out of the box
- Compound queries (sort + filter on multiple fields)
- Shallow queries (doesn't fetch entire subtrees)
- Excellent offline support across platforms
- Easy to set up and deploy quickly

**Collections Structure:**
```
users/{userId}
conversations/{conversationId}
  └─ messages/{messageId}
group-conversations/{groupId}
  └─ messages/{messageId}
```

### 2. State Management: Riverpod 3.x
**Why Riverpod 3.x:**
- Compile-time safety (no runtime DI errors)
- StreamProvider with autoDispose for real-time data
- No BuildContext dependency
- Excellent testability with overrides
- Built-in dependency injection
- Improved async handling and lifecycle management

**Pattern:**
```dart
@riverpod
Stream<List<Message>> conversationMessages(ref, String conversationId) {
  return repository.watchMessages(conversationId);
}
```

**Import Pattern (avoiding conflicts):**
```dart
// When using firebase_auth, hide User to avoid conflicts with domain User
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth hide User;
// Domain User is now the default
import 'package:message_ai/features/authentication/domain/entities/user.dart';
```

### 3. Local Storage: drift
**Why drift over alternatives:**
- Type-safe SQL with compile-time validation
- Reactive streams for real-time UI updates
- Robust migration system
- Active maintenance (2025)
- Cross-platform including web

**Usage:**
- Offline message persistence
- Conversation caching
- User profile storage
- Message queue management

### 4. Offline-First Architecture

#### Sync Flow
```
User Action → Local DB (immediate) → UI Update →
Queue for Sync → Firestore (when online) →
Update Local DB with server data → UI Update
```

#### Conflict Resolution: Last-Write-Wins (LWW)
- Server timestamp is source of truth
- Temporary IDs map to server IDs after sync
- Duplicate detection via tempId field

#### Message Queue
- **Retry strategy**: Exponential backoff (2s, 4s, 8s, 16s, 32s)
- **Dead letter**: After 5 failures, mark for manual review
- **Jitter**: ±15% randomization to prevent thundering herd

### 5. AI Integration Pattern

#### Security Architecture
```
Flutter App → Firebase Cloud Functions → OpenAI API
              ↑
         Secret Manager (API keys)
         App Check (device verification)
```

**Why this approach:**
- API keys never exposed to clients
- Rate limiting enforced server-side
- App Check prevents API abuse
- Centralized cost monitoring

#### Caching Strategy
```
Request → Check Cache → Hit: Return
                      → Miss: OpenAI → Cache Result → Return
```

**Cache TTLs:**
- Thread summaries: 1 hour (Firestore)
- Smart replies: 2 minutes (Redis/Firestore)
- Action items: 30 minutes (Firestore)
- Translations: 24 hours (Firestore)

### 6. Real-Time Sync Pattern

#### Firestore Listeners
```dart
firestore.collection('conversations')
  .where('participantIds', arrayContains: userId)
  .orderBy('lastUpdatedAt', descending: true)
  .limit(20)
  .snapshots()
```

#### Optimistic UI Updates
1. Create temporary message with local ID
2. Update UI immediately (status: sending)
3. Send to Firestore
4. Replace with server message on success
5. Mark failed if error, allow retry

### 7. Translation Architecture

#### On-Device Language Detection
```
Message → MLKit Language ID → Detected Language
```

#### Translation Flow
```
Message Send → Detect Language → Get Target Languages →
Check Cache → Translate Missing → Store All Versions
```

**Storage Pattern:**
```json
{
  "text": "Original message",
  "detectedLanguage": "en",
  "translations": {
    "es": "Mensaje traducido",
    "fr": "Message traduit"
  }
}
```

## Component Relationships

### Feature Dependencies
```
Authentication (base)
  ↓
Messaging (core)
  ↓
├─ Translation (enhancement)
├─ AI Features (enhancement)
└─ Media (enhancement)
```

### Data Flow Patterns

#### Read Path (Online)
```
UI → Riverpod Provider → Repository →
Firestore Listener → Stream Controller → UI Update
```

#### Read Path (Offline)
```
UI → Riverpod Provider → Repository →
drift DAO → Stream Controller → UI Update
```

#### Write Path
```
UI → Provider Action → Repository →
drift (immediate) + Firestore Queue →
Background Sync → Server Response → Update Local
```

## Design Patterns in Use

### Repository Pattern
Abstract data source details, provide clean domain interface

### Use Case Pattern
Single-responsibility operations (SendMessage, TranslateMessage)

### Observer Pattern
Real-time updates via Streams/StreamProviders

### Factory Pattern
Model conversions (Firestore ↔ Entity ↔ drift)

### Strategy Pattern
Conflict resolution, retry logic

### Proxy Pattern
Cloud Functions as API gateway

## Performance Patterns

### Pagination
```dart
.limit(50)
.startAfter(lastDocument)
```

### Denormalization
Store `lastMessage` in conversation document to avoid extra reads

### Lazy Loading
Load message history on scroll, not all at once

### Image Optimization
- Compress before upload
- Generate thumbnails
- Use `cached_network_image` with memory cache

## Error Handling Strategy

### Error Types
1. **Network errors**: Retry with backoff
2. **Permission errors**: Show user-actionable message
3. **Validation errors**: Prevent at UI level
4. **Server errors**: Log + fallback gracefully

### User-Facing Errors
- Message send failed (with retry button)
- Translation unavailable (show original)
- AI feature timeout (fallback to manual)
- No internet (clear offline indicator)

## Test-Driven Development (TDD) Approach

### Testing Philosophy
**ALL code follows Test-Driven Development**
- Write tests BEFORE or DURING implementation
- Never skip tests for "simple" code
- Tests are part of the feature, not optional

### RED-GREEN-REFACTOR Cycle
```
1. RED:    Write failing test first
2. GREEN:  Write minimum code to pass
3. REFACTOR: Clean up while keeping tests green
```

### Test Hierarchy

#### 1. Unit Tests (Domain & Data Layers)
**What to test:**
- Entities, models, use cases, repositories
- Business logic and data transformations
- Exception handling and validation
- Edge cases and boundary conditions

**Pattern:**
```dart
group('UseCase', () {
  group('validation', () {
    test('should fail when input invalid', () { ... });
  });

  group('success cases', () {
    test('should return expected result', () { ... });
  });

  group('error cases', () {
    test('should handle exceptions', () { ... });
  });
});
```

#### 2. Widget Tests (Presentation Layer)
**What to test:**
- Widget rendering and state
- User interactions (tap, scroll, input)
- Navigation flows
- Error display

**Pattern:**
```dart
testWidgets('should show error when login fails', (tester) async {
  // Arrange: Mock dependencies
  // Act: Pump widget, interact
  // Assert: Verify UI state
});
```

#### 3. Integration Tests (Optional for MVP)
**What to test:**
- Complete feature flows end-to-end
- Real Firebase interactions (emulator)
- Cross-layer data flow

### Testing Tools & Frameworks

#### Core Dependencies
```yaml
dev_dependencies:
  flutter_test: sdk: flutter
  mocktail: ^1.0.4                    # Mocking
  fake_cloud_firestore: ^3.0.3       # Firestore mocking
  firebase_auth_mocks: ^0.14.1       # Auth mocking
```

#### Tool Usage
- **Mocktail**: Mock repositories, use cases, external services
- **fake_cloud_firestore**: Mock Firestore (realistic behavior)
- **firebase_auth_mocks**: Mock Firebase Auth
- **ProviderContainer**: Test Riverpod providers

### Test Patterns

#### AAA Pattern (Arrange-Act-Assert)
```dart
test('should create user successfully', () async {
  // Arrange
  const email = 'test@test.com';
  const password = 'password123';

  // Act
  final result = await useCase(email: email, password: password);

  // Assert
  expect(result.isRight(), true);
});
```

#### Mocking with Mocktail
```dart
class MockRepository extends Mock implements UserRepository {}

setUp(() {
  mockRepo = MockRepository();
  when(() => mockRepo.getUser(any()))
      .thenAnswer((_) async => Right(testUser));
});
```

#### Firestore Testing
```dart
setUp(() {
  fakeFirestore = FakeFirebaseFirestore();
  datasource = UserRemoteDataSourceImpl(fakeFirestore);
});

test('should create document', () async {
  await datasource.createUser(testUser);

  final doc = await fakeFirestore
      .collection('users')
      .doc(testUser.uid)
      .get();

  expect(doc.exists, true);
});
```

#### Stream Testing
```dart
test('should emit messages', () async {
  when(() => repo.watchMessages(any(), limit: any(named: 'limit')))
      .thenAnswer((_) => Stream.value(Right([message1, message2])));

  final stream = useCase(conversationId: 'conv-123');

  await expectLater(
    stream.first,
    completion(predicate<Either<Failure, List<Message>>>((result) {
      return result.isRight() &&
             result.fold((l) => null, (r) => r)!.length == 2;
    })),
  );
});
```

### Coverage Goals

#### By Layer
- **Domain Layer**: 100% (pure business logic)
- **Data Layer**: 90%+ (I/O operations)
- **Presentation Layer**: 80%+ (UI logic)
- **Overall Project**: 85%+ minimum

#### Checking Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Organization
```
test/
├── features/
│   ├── authentication/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── usecases/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── pages/
│   │       └── widgets/
│   └── messaging/
│       └── ... (same structure)
├── core/
│   ├── error/
│   └── network/
└── helpers/
    ├── test_helpers.dart
    └── mock_data.dart
```

### When to Write Tests

#### ✅ ALWAYS Test Before Implementation
- **New Features**: Write use case tests → repository tests → datasource tests → widget tests → implement
- **Bug Fixes**: Write test that reproduces bug (fails) → fix bug → verify test passes
- **Refactoring**: Ensure existing tests cover behavior → refactor with green tests

#### ✅ NEVER Skip Tests For
- Domain entities and value objects
- Use cases (business logic)
- Repositories (data orchestration)
- Data sources (external I/O)
- Complex widgets with state
- Data models (serialization/deserialization)

#### ⚠️ Optional Tests (but recommended)
- Simple stateless widgets (pure UI)
- Generated code (providers, models)
- Configuration files

### Testing Anti-Patterns to Avoid

#### ❌ DON'T: Test Implementation Details
```dart
// Bad: Testing private methods
test('should call _privateMethod', () { ... });

// Good: Test observable behavior
test('should return correct result', () { ... });
```

#### ❌ DON'T: Write Tests After Implementation
This leads to:
- Untestable code
- Missing edge cases
- Incomplete coverage
- False sense of security

#### ❌ DON'T: Mock Everything
```dart
// Bad: Over-mocking makes tests brittle
final mockString = MockString();

// Good: Use real objects when simple
final string = 'hello';
```

### Current Test Status

#### Completed (92 tests passing)
- ✅ Auth use cases: 20 tests
- ✅ Auth datasource: 17 tests
- ✅ Auth repository: 22 tests
- ✅ Messaging use cases: 33 tests

#### In Progress
- 🚧 Messaging datasources: ~30-40 tests
- 🚧 Messaging repositories: ~30-40 tests
- 🚧 Widget tests: ~15-20 tests

#### Target
- 📊 Total: ~150 tests
- 📊 Coverage: 85%+
