# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MessageAI is a Flutter messaging application with real-time translation, AI-powered features (formality adjustment), and Firebase backend integration. The app uses Clean Architecture with feature-based organization.

## Essential Commands

### Code Generation
```bash
# Run after modifying Riverpod providers or Drift tables
dart run build_runner build --delete-conflicting-outputs

# Watch mode for continuous generation during development
dart run build_runner watch --delete-conflicting-outputs
```

### Running the App
```bash
# Run Flutter app
flutter run

# Run on specific device
flutter devices
flutter run -d <device-id>

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal
```

### Code Analysis
```bash
# Analyze Dart code (no need to set roots manually if using MCP)
dart analyze

# Fix auto-fixable issues
dart fix --apply

# Format code
dart format lib/
```

### Firebase Cloud Functions
```bash
# Deploy all functions (from project root, not functions directory)
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:translate_message

# View function logs
firebase functions:log
```

### Testing
**CRITICAL**: This project has NO TESTING. Never write tests or suggest testing. See [testing.mdc](mdc:.cursor/rules/testing.mdc).

## Architecture Overview

### Clean Architecture with Feature-Based Organization

The app follows Clean Architecture with features organized into three layers:

```
lib/
├── core/                    # Shared infrastructure
│   ├── database/           # Drift database setup, DAOs
│   ├── error/              # Failure classes
│   ├── network/            # Connectivity, network info
│   └── providers/          # Core Riverpod providers
│
├── features/               # Feature modules
│   ├── authentication/
│   ├── messaging/
│   ├── translation/
│   └── formality_adjustment/
│
└── config/                 # App-wide configuration
    ├── routes/            # Navigation
    └── theme/             # Theming
```

### Feature Structure (e.g., `features/messaging/`)

Each feature follows Clean Architecture layers:

```
feature/
├── data/
│   ├── datasources/       # Remote (Firestore) & Local (Drift)
│   ├── models/            # Data transfer objects (DTOs)
│   ├── repositories/      # Repository implementations
│   └── services/          # Additional data services
│
├── domain/
│   ├── entities/          # Business objects (used throughout app)
│   ├── repositories/      # Repository interfaces
│   └── usecases/          # Business logic (one class per use case)
│
└── presentation/
    ├── pages/             # Full screen widgets
    ├── providers/         # Riverpod providers (state management)
    └── widgets/           # Reusable UI components
```

### Critical Layer Boundaries

**NEVER mix these concepts:**

1. **Entities** (domain layer) - Pure business objects, used throughout the app
2. **Models** (data layer) - DTOs for serialization (Firestore, JSON)
3. **Repositories** - Handle Entity ↔ Model conversion
4. **Data Sources** - Work with Models (remote) or Entities (local via DAOs)

**Example Data Flow:**
```
UI → UseCase → Repository → DataSource → Firestore
   ← Entity  ← Entity    ← Model      ← JSON
```

**Before implementing ANY feature**, read existing similar components to understand patterns. See [understand_before_implementing.mdc](mdc:.cursor/rules/understand_before_implementing.mdc).

## State Management (Riverpod)

### Provider Generation

All providers use `riverpod_annotation` for code generation:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_providers.g.dart';  // Generated file

@riverpod
MyService myService(Ref ref) {
  return MyService(ref.watch(dependencyProvider));
}
```

**After modifying providers**, run code generation:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Provider Types

- **Sync providers**: `@riverpod` returns value directly
- **Async providers**: `@riverpod Future<T>` returns Future
- **Stream providers**: `@riverpod Stream<T>` returns Stream
- **Keepalive**: `@Riverpod(keepAlive: true)` for singletons

### Important Provider Patterns

**User Authentication State:**
- `currentUserProvider` - Firebase Auth user (DEPRECATED for language preference)
- `currentUserWithFirestoreProvider` - **USE THIS** for full user data including `preferredLanguage`
- `authStateProvider` - Stream of auth state changes

**Always invalidate providers after state changes:**
```dart
// After updating user profile
await userRepository.updateUser(updatedUser);
ref.invalidate(currentUserProvider);  // Force refresh
```

## Database (Drift ORM)

### CRITICAL: Column Syntax

Drift columns require **TWO sets of parentheses** `()()`:

```dart
class MyTable extends Table {
  // ✅ CORRECT
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();

  // ❌ WRONG - Missing second ()
  TextColumn get id => text();
  TextColumn get name => text().nullable();
}
```

See full Drift patterns in [drift.mdc](mdc:.cursor/rules/drift.mdc).

### Code Generation

After modifying tables:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Dual Storage Pattern

**Messages and Conversations use dual storage:**
1. **Firestore (remote)** - Source of truth, real-time sync
2. **Drift (local)** - Offline cache, faster queries

**Data Flow:**
- Writes go to Firestore (via repository)
- Firestore triggers update Drift via sync service
- Reads come from Drift for speed
- Background sync handles offline writes

## Firebase Cloud Functions (Python)

Located in `functions/main.py`:

### Available Functions

1. **`translate_message`** (HTTPS callable) - Real-time translation using Google Translate API
2. **`adjust_formality`** (HTTPS callable) - Formality adjustment using GPT-4o-mini
3. **`on_message_created`** (Firestore trigger) - Push notifications
4. **`on_user_profile_updated`** (Firestore trigger) - Display name propagation

### Function Patterns

All HTTPS callable functions follow this pattern:
```python
@https_fn.on_call()
def my_function(req: https_fn.CallableRequest) -> dict[str, Any]:
    # 1. Validate auth
    if req.auth is None:
        raise https_fn.HttpsError("unauthenticated", "User must be signed in")

    # 2. Extract & validate parameters
    data = req.data
    required_param = data.get("requiredParam")
    if not required_param:
        raise https_fn.HttpsError("invalid-argument", "requiredParam is required")

    # 3. Rate limiting (if applicable)

    # 4. Business logic

    # 5. Return response
    return {"result": "success"}
```

### Calling from Flutter

```dart
final functions = FirebaseFunctions.instance;
final result = await functions.httpsCallable('my_function').call({
  'requiredParam': value,
});
```

## Key Features Implementation

### Translation Feature

**Architecture:**
- ML Kit Language Detection (on-device, <50ms)
- Google Translate API (via Cloud Function)
- Translations cached in Firestore message documents
- UI toggle between original/translated text

**Translation Button Logic:**
- Only shows for received messages (`isMe == false`)
- Only shows when `detectedLanguage != userPreferredLanguage`
- Uses fallback detection for old messages without `detectedLanguage`

### Formality Adjustment Feature

**Architecture:**
- GPT-4o-mini via OpenAI API (Cloud Function)
- Rate limiting: 100 requests/hour per user
- 24-hour cache for identical requests
- Three levels: Casual, Neutral, Formal

**UI Pattern:**
- ChoiceChip selector in message input
- Auto-hides when input is empty
- Shows loading indicator during adjustment
- Updates TextField with adjusted text

### Presence & Typing Indicators

**Architecture:**
- **Firebase Realtime Database (RTDB)** for ephemeral real-time data (NOT Firestore)
- **Automatic offline detection** via RTDB `onDisconnect()` server-side callbacks
- **Connection-based presence** - no app lifecycle tracking needed
- No heartbeat mechanism needed - RTDB handles connection state automatically
- Last seen timestamps with millisecond precision
- Group presence aggregation for "X/Y online" status
- Typing indicators with automatic cleanup

**How it works (Simple):**
1. User signs in → `presenceController` calls `setOnline()`
2. `setOnline()` writes `{isOnline: true}` and configures server-side `onDisconnect()` callback
3. User signs out → `presenceController` calls `clearPresence()`
4. Connection drops (any reason: app kill, background, network loss) → RTDB server executes `onDisconnect()` automatically → sets `{isOnline: false}`
5. **That's it** - connection state IS presence state. No lifecycle tracking needed.

**Key Insight:**
RTDB is designed for presence. The `onDisconnect()` callback executes **server-side** when the client connection drops for ANY reason. You don't need to manually track app lifecycle - let RTDB handle it via connection state.

**Key Files:**
- `lib/features/messaging/data/services/rtdb_presence_service.dart` - RTDB presence service
- `lib/features/messaging/data/services/rtdb_typing_service.dart` - RTDB typing service
- `lib/features/authentication/presentation/providers/auth_providers.dart` - presenceController (sign-in/out only)
- `database.rules.json` - RTDB security rules

**Data Structure (RTDB):**
- `/presence/{userId}` → `{isOnline: bool, lastSeen: timestamp, userName: string}`
- `/typing/{conversationId}/{userId}` → `{isTyping: bool, userName: string, timestamp: number}`

**Why RTDB instead of Firestore?**
- RTDB has `onDisconnect()` callbacks that execute server-side when client disconnects
- Firestore lacks this feature - would require heartbeats and stale data cleanup
- RTDB optimized for ephemeral real-time data like presence and typing
- Lower latency and simpler architecture for this use case

## Common Patterns

### Error Handling (Either Pattern)

Uses `dartz` for functional error handling:

```dart
import 'package:dartz/dartz.dart';

// Repository method signature
Future<Either<Failure, User>> getUser(String id);

// Usage in use case
final result = await repository.getUser(id);
return result.fold(
  (failure) => Left(failure),  // Error case
  (user) => Right(user),       // Success case
);

// Usage in UI
result.fold(
  (failure) => showError(failure.message),
  (user) => displayUser(user),
);
```

### Provider Dependencies

```dart
@riverpod
MyUseCase myUseCase(Ref ref) {
  // Watch providers to get dependencies
  final repository = ref.watch(myRepositoryProvider);
  return MyUseCase(repository);
}
```

### ConsumerWidget vs ConsumerStatefulWidget

```dart
// For stateless UI with provider dependencies
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    return Text(state);
  }
}

// For stateful UI with provider dependencies (e.g., language detection fallback)
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  String? _localState;

  @override
  Widget build(BuildContext context) {
    final providerState = ref.watch(myProvider);
    return Text(_localState ?? providerState);
  }
}
```

## Development Workflow

### Typical Feature Implementation

1. **Understand existing patterns** - Read similar features first
2. **Domain layer** - Define entities, repository interface, use cases
3. **Data layer** - Create models, data sources, repository implementation
4. **Generate code** - Run build_runner for providers/Drift
5. **Presentation layer** - Build UI, create providers, wire everything up
6. **Manual testing** - Run the app and verify functionality

### Provider Updates

When providers change behavior or return types:
```dart
// Invalidate dependent providers
ref.invalidate(dependentProvider);

// Or listen for changes
ref.listen(sourceProvider, (previous, next) {
  // React to changes
});
```

## Important Gotchas

### Drift Testing Import Conflicts

Drift exports `isNull`/`isNotNull` which conflict with `flutter_test`:
```dart
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
```

### Firebase Auth vs Firestore User Data

- **Firebase Auth** - Authentication data (email, uid, displayName, photoURL)
- **Firestore `/users/{uid}`** - Extended profile (preferredLanguage, bio, etc.)

**Always use `currentUserWithFirestoreProvider`** when you need `preferredLanguage` or other Firestore-only fields.

### Hot Reload Limitations

Hot reload doesn't work for:
- Provider structure changes (use hot restart)
- New dependencies (restart app)
- Database schema changes (restart app)

## MCP Tool Usage

This project uses Dart MCP server. Key tools:

- **`mcp__dart__analyze_files`** - Analyze Dart code (roots auto-set)
- **`mcp__dart__dart_format`** - Format Dart code
- **`mcp__dart__run_tests`** - Run tests (BUT DON'T - testing disabled)
- **`mcp__dart__hot_reload`** - Hot reload running app
- **`mcp__dart__add_roots`** - Set project roots (if needed)

**IMPORTANT**: Always prefer MCP tools over bash commands (`dart analyze` vs `mcp__dart__analyze_files`).

## Firebase Structure

### Firestore Collections

- `/users/{uid}` - User profiles
- `/conversations/{conversationId}` - Conversation metadata
- `/conversations/{conversationId}/messages/{messageId}` - Messages
- `/conversations/{conversationId}/participants/{participantId}` - Participants

### Realtime Database (RTDB)

Used exclusively for ephemeral real-time data (presence and typing indicators):

- `/presence/{userId}` - User presence status (online/offline, last seen)
- `/typing/{conversationId}/{userId}` - Active typing indicators

**Why separate databases?**
- Firestore: Permanent data with complex queries (messages, users, conversations)
- RTDB: Ephemeral data with automatic cleanup via `onDisconnect()` (presence, typing)

### Cloud Functions Environment

Functions use Secret Manager for API keys:
- `TRANSLATION_API_KEY_SECRET` - Google Translate API
- `OPENAI_API_KEY_SECRET` - OpenAI API (GPT-4o-mini)

## Git Workflow

**Main branch:** `master`
**Development branch:** `dev`

When creating PRs, target `master` branch.

## References

See `.cursor/rules/` for additional guidelines:
- [understand_before_implementing.mdc](mdc:.cursor/rules/understand_before_implementing.mdc) - **READ FIRST**
- [drift.mdc](mdc:.cursor/rules/drift.mdc) - Database patterns
- [dart_flutter_mcp.mdc](mdc:.cursor/rules/dart_flutter_mcp.mdc) - MCP usage
- [testing.mdc](mdc:.cursor/rules/testing.mdc) - Testing policy (disabled)

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
