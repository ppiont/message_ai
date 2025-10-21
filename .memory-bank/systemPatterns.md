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

### 2. State Management: Riverpod 3.0
**Why Riverpod:**
- Compile-time safety (no runtime DI errors)
- StreamProvider with autoDispose for real-time data
- No BuildContext dependency
- Excellent testability with overrides
- Built-in dependency injection

**Pattern:**
```dart
@riverpod
Stream<List<Message>> conversationMessages(ref, String conversationId) {
  return repository.watchMessages(conversationId);
}
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
