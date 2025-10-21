# WhatsApp Clone with AI Features: Production Technical Architecture & PRD

## Executive Summary

This PRD defines a **production-ready messaging platform** built on Flutter + Firebase with advanced AI capabilities targeting international communicators. The architecture leverages **Firestore for scalable real-time messaging**, **Riverpod for state management**, **drift for offline persistence**, and **OpenAI GPT-4o-mini for cost-effective AI features**. The system supports **1M+ concurrent users** with proper optimization and implements **context-aware smart replies in multiple languages**.

**Key Technical Decisions:**
- **Database:** Cloud Firestore (superior querying, auto-scaling, 99.999% SLA)
- **State Management:** Riverpod 3.0 (compile-time safety, built-in DI, real-time support)
- **Local Storage:** drift (type-safe SQL ORM, reactive streams, robust migrations)
- **AI Integration:** Firebase Cloud Functions + OpenAI GPT-4o-mini (85-90% cost savings)
- **Architecture:** Clean Architecture with feature-first organization
- **Testing:** TDD approach with 80%+ coverage (mocktail + fake_cloud_firestore)

**Cost Projections:**
- 10K users: $82/month
- 100K users: $1,005/month
- 1M users: $10,051/month

---

## 1. TECHNICAL STACK WITH JUSTIFICATIONS

### Database Selection: Firestore vs Realtime Database

**DECISION: Cloud Firestore** ✅

**5 Key Reasons:**
1. **Better Scalability:** Auto-scales automatically; RTDB requires manual sharding after 200K concurrent connections
2. **Superior Querying:** Compound queries with sorting + filtering on multiple fields. RTDB only allows sort OR filter
3. **Shallow Queries:** Queries don't fetch entire subtrees, crucial for chat apps with nested messages
4. **Multi-region Support:** Built-in multi-region replication (99.999% SLA vs 99.95% for RTDB)
5. **Better Offline Support:** Works across web, iOS, and Android (RTDB lacks web offline support)

**Cost Consideration:** Firestore charges per operation; RTDB charges for bandwidth. For chat apps with frequent small updates, Firestore is more cost-effective at scale.

### State Management: Riverpod 3.0

**Why Riverpod over Bloc/Provider/GetX:**
- ✅ Compile-time safety eliminates runtime DI errors
- ✅ Built-in state management + DI in one solution
- ✅ StreamProvider with autoDispose perfect for real-time messaging
- ✅ No BuildContext dependency, works outside widget tree
- ✅ Excellent testability with provider overrides
- ✅ Type-safe, IDE-friendly autocomplete

**Alternative:** Bloc (also excellent, use if team prefers strict event/state architecture)

### Local Storage: drift

**Why drift over Hive/Isar/sqflite:**
- ✅ Type-safe SQL queries with compile-time validation
- ✅ Reactive streams for real-time UI updates
- ✅ Robust migration system
- ✅ Active maintenance (2025)
- ✅ Cross-platform including web
- ✅ Perfect for relational data (conversations, users, messages)

**Performance:** While Isar is faster (70x sqflite), it's been abandoned by author. drift offers best balance of performance, reliability, and maintainability.

### AI: OpenAI GPT-4o-mini

**Why GPT-4o-mini:**
- 16x cheaper than GPT-4o ($0.15/1M vs $2.50/1M input tokens)
- 50% savings with prompt caching (automatic for prompts >1024 tokens)
- Excellent multilingual support (50+ languages)
- Structured JSON outputs
- Combined savings: 85-90% vs baseline

---

## 2. FIRESTORE DATA MODELS (EXACT SCHEMAS)

### Users Collection
```json
{
  "users/{userId}": {
    "uid": "userId_123",
    "email": "user@example.com",
    "phoneNumber": "+1234567890",
    "name": "John Doe",
    "imageUrl": "https://storage.googleapis.com/...",
    "fcmToken": "device_fcm_token_xyz",
    "preferredLanguage": "en",
    "createdAt": "2024-01-01T00:00:00Z",
    "lastSeen": "2024-01-01T12:30:00Z",
    "isOnline": false
  }
}
```

**Firestore Indexes:**
```
- Single field: phoneNumber (ASC)
- Composite: email (ASC), createdAt (DESC)
```

### Conversations Collection (1-to-1)
```json
{
  "conversations/{conversationId}": {
    "documentId": "conversationId_abc",
    "type": "direct",
    "participantIds": ["userId_123", "userId_456"],
    "participants": [
      {"uid": "userId_123", "name": "John", "imageUrl": "...", "preferredLanguage": "en"},
      {"uid": "userId_456", "name": "Jane", "imageUrl": "...", "preferredLanguage": "es"}
    ],
    "lastMessage": {
      "text": "Hey, how are you?",
      "senderId": "userId_123",
      "senderName": "John Doe",
      "timestamp": "2024-01-01T12:30:00Z",
      "type": "text",
      "translations": {"es": "Hola, ¿cómo estás?"}
    },
    "lastUpdatedAt": "2024-01-01T12:30:00Z",
    "initiatedAt": "2024-01-01T10:00:00Z",
    "unreadCount": {"userId_123": 0, "userId_456": 3},
    "translationEnabled": true,
    "autoDetectLanguage": true
  }
}
```

**Firestore Indexes:**
```
- Composite: participantIds (ARRAY), lastUpdatedAt (DESC)
```

### Messages Subcollection
```json
{
  "conversations/{conversationId}/messages/{messageId}": {
    "id": "messageId_xyz",
    "text": "Hello, this is a message",
    "senderId": "userId_123",
    "senderName": "John Doe",
    "timestamp": "2024-01-01T12:30:00Z",
    "type": "text",
    "status": "delivered",
    "detectedLanguage": "en",
    "translations": {
      "es": "Hola, esto es un mensaje",
      "fr": "Bonjour, c'est un message"
    },
    "replyTo": null,
    "metadata": {
      "edited": false,
      "deleted": false,
      "priority": "medium",
      "hasIdioms": false
    },
    "embedding": [0.123, 0.456, ...],
    "aiAnalysis": {
      "priority": "medium",
      "actionItems": [],
      "sentiment": "neutral"
    }
  }
}
```

**Firestore Indexes:**
```
- Single field: timestamp (DESC)
- Vector index: embedding (COSINE, 1536 dimensions)
```

### Group Conversations
```json
{
  "group-conversations/{groupId}": {
    "documentId": "groupId_789",
    "type": "group",
    "groupName": "Project Team",
    "groupImage": "https://...",
    "participantIds": ["userId_123", "userId_456", "userId_789"],
    "adminIds": ["userId_123"],
    "lastMessage": {
      "text": "Meeting at 3pm",
      "senderId": "userId_456",
      "timestamp": "2024-01-01T14:00:00Z",
      "type": "text"
    },
    "lastUpdatedAt": "2024-01-01T14:00:00Z",
    "initiatedAt": "2024-01-01T09:00:00Z"
  }
}
```

**Query Pattern:**
```dart
firestore.collection('group-conversations')
  .where('participantIds', arrayContains: userId)
  .orderBy('lastUpdatedAt', descending: true)
```

---

## 3. FLUTTER PROJECT STRUCTURE

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── database/
│   │   ├── app_database.dart              # drift database
│   │   ├── tables/
│   │   │   ├── messages_table.dart
│   │   │   ├── conversations_table.dart
│   │   │   └── users_table.dart
│   │   └── daos/
│   │       ├── message_dao.dart
│   │       └── conversation_dao.dart
│   ├── error/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── network/
│   │   └── network_info.dart
│   ├── constants/
│   │   └── api_constants.dart
│   └── utils/
│       ├── date_formatter.dart
│       └── validators.dart
│
├── features/
│   ├── authentication/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── sign_in.dart
│   │   │       └── sign_out.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart
│   │       ├── pages/
│   │       │   └── login_page.dart
│   │       └── widgets/
│   │
│   ├── messaging/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── message_remote_datasource.dart
│   │   │   │   └── message_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── message_model.dart
│   │   │   └── repositories/
│   │   │       └── message_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── message.dart
│   │   │   │   └── conversation.dart
│   │   │   ├── repositories/
│   │   │   │   └── message_repository.dart
│   │   │   └── usecases/
│   │   │       ├── send_message.dart
│   │   │       ├── get_messages.dart
│   │   │       └── sync_messages.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── message_provider.dart
│   │       │   └── conversation_provider.dart
│   │       ├── pages/
│   │       │   ├── conversation_list_page.dart
│   │       │   └── chat_page.dart
│   │       └── widgets/
│   │           ├── message_bubble.dart
│   │           ├── message_input.dart
│   │           └── typing_indicator.dart
│   │
│   ├── ai_features/
│   │   ├── data/
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       ├── generate_smart_replies.dart
│   │   │       ├── summarize_thread.dart
│   │   │       ├── extract_action_items.dart
│   │   │       ├── detect_priority.dart
│   │   │       └── track_decisions.dart
│   │   └── presentation/
│   │       └── widgets/
│   │           ├── smart_reply_chips.dart
│   │           └── thread_summary_card.dart
│   │
│   └── translation/
│       ├── data/
│       ├── domain/
│       │   └── usecases/
│       │       ├── translate_message.dart
│       │       └── detect_language.dart
│       └── presentation/
│
├── config/
│   ├── routes/
│   │   └── app_router.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── providers.dart                      # Global Riverpod providers
│
└── l10n/
    ├── intl_en.arb
    ├── intl_es.arb
    └── intl_fr.arb
```

---

## 4. STATE MANAGEMENT IMPLEMENTATION (RIVERPOD)

### Provider Setup

```dart
// config/providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

// Database
@riverpod
AppDatabase appDatabase(AppDatabaseRef ref) {
  return AppDatabase();
}

// Firestore
@riverpod
FirebaseFirestore firestore(FirestoreRef ref) {
  return FirebaseFirestore.instance;
}

// Repositories
@riverpod
MessageRepository messageRepository(MessageRepositoryRef ref) {
  final remoteDS = ref.watch(messageRemoteDataSourceProvider);
  final localDS = ref.watch(messageLocalDataSourceProvider);
  return MessageRepositoryImpl(
    remoteDataSource: remoteDS,
    localDataSource: localDS,
  );
}

// Real-time messages stream
@riverpod
Stream<List<Message>> conversationMessages(
  ConversationMessagesRef ref,
  String conversationId,
) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchMessages(conversationId);
}

// Usage in widget
class ChatPage extends ConsumerWidget {
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(conversationMessagesProvider(conversationId));

    return messagesAsync.when(
      data: (messages) => MessageList(messages: messages),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}
```

### Optimistic UI Pattern

```dart
class MessageNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final MessageRepository _repository;

  MessageNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> sendMessage(String text, String conversationId) async {
    // 1. Create optimistic message
    final optimisticMessage = Message(
      id: const Uuid().v4(),
      text: text,
      senderId: currentUserId,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );

    // 2. Update UI immediately
    state.whenData((messages) {
      state = AsyncValue.data([...messages, optimisticMessage]);
    });

    try {
      // 3. Send to Firebase
      final sentMessage = await _repository.sendMessage(optimisticMessage);

      // 4. Replace with server message
      state.whenData((messages) {
        final updated = messages.map((m) =>
          m.id == optimisticMessage.id ? sentMessage : m
        ).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      // 5. Mark failed, allow retry
      state.whenData((messages) {
        final updated = messages.map((m) =>
          m.id == optimisticMessage.id
            ? m.copyWith(status: MessageStatus.failed)
            : m
        ).toList();
        state = AsyncValue.data(updated);
      });
    }
  }
}
```

---

## 5. REAL-TIME SYNC & OFFLINE-FIRST ARCHITECTURE

### Offline-First Flow

```
User Action → Local DB (immediate) → UI Update →
Queue for Sync → Firestore (when online) →
Update Local DB → UI Update
```

### Conflict Resolution: Last-Write-Wins (LWW)

```dart
class MessageSyncService {
  Future<void> syncMessages(String conversationId) async {
    // 1. Send local unsynced messages
    final localUnsynced = await localDB.getUnsyncedMessages(conversationId);

    for (var msg in localUnsynced) {
      final serverDoc = await firestore.collection('messages').add({
        'content': msg.text,
        'senderId': msg.senderId,
        'timestamp': FieldValue.serverTimestamp(),
        'tempId': msg.tempId,
      });

      // Update local with server ID
      await localDB.updateMessage(msg.tempId, id: serverDoc.id);
    }

    // 2. Fetch new server messages
    final lastSync = await localDB.getLastSyncTime(conversationId);
    final serverMsgs = await firestore
      .collection('messages')
      .where('conversationId', isEqualTo: conversationId)
      .where('timestamp', isGreaterThan: Timestamp.fromDate(lastSync))
      .get();

    // 3. Merge with deduplication
    for (var doc in serverMsgs.docs) {
      final existing = await localDB.findByTempId(doc['tempId']);
      if (existing != null) {
        await localDB.updateWithServerVersion(existing.tempId, doc);
      } else {
        await localDB.insertMessage(Message.fromFirestore(doc));
      }
    }
  }
}
```

### Exponential Backoff Retry

```dart
class MessageQueue {
  Future<void> processQueue() async {
    final pending = await localDB.getPendingMessages();

    for (var message in pending) {
      try {
        await _sendWithRetry(message);
        await localDB.markAsSynced(message.id);
      } catch (e) {
        message.retryCount++;
        if (message.retryCount >= 5) {
          await localDB.markAsDeadLetter(message.id);
        } else {
          await localDB.updateRetryCount(message.id, message.retryCount);
          await Future.delayed(_calculateBackoff(message.retryCount));
        }
      }
    }
  }

  Duration _calculateBackoff(int retryCount) {
    final baseDelay = min(pow(2, retryCount).toInt(), 60);
    final jitter = Random().nextDouble() * 0.3 - 0.15;
    return Duration(seconds: (baseDelay * (1 + jitter)).round());
  }
}
```

**Retry Schedule:**
- Attempt 1: 2 seconds
- Attempt 2: 4 seconds
- Attempt 3: 8 seconds
- Attempt 4: 16 seconds
- Attempt 5: 32 seconds
- After 5 failures: Dead letter queue

---

## 6. AI INTEGRATION ARCHITECTURE

### Security: Firebase Cloud Functions as Proxy

```javascript
// functions/index.js
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const OpenAI = require('openai');

const secretClient = new SecretManagerServiceClient();

async function getOpenAIKey() {
  const [version] = await secretClient.accessSecretVersion({
    name: 'projects/PROJECT_ID/secrets/openai-api-key/versions/latest',
  });
  return version.payload.data.toString();
}

exports.processAIRequest = functions.https.onCall(async (data, context) => {
  // Verify App Check
  if (context.app === undefined) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Must be called from verified app'
    );
  }

  const apiKey = await getOpenAIKey();
  const openai = new OpenAI({ apiKey });

  // Rate limiting
  await checkRateLimit(context.auth.uid, 100); // 100 requests/hour

  return await openai.chat.completions.create({
    model: data.model || 'gpt-4o-mini',
    messages: data.messages,
    max_tokens: data.maxTokens || 500
  });
});
```

### Five Required AI Features

#### 1. Thread Summarization

```javascript
exports.summarizeThread = functions.https.onCall(async (data, context) => {
  const { threadId } = data;

  // Check cache
  const cached = await getFromCache('summary', threadId);
  if (cached) return cached;

  const messages = await getThreadMessages(threadId);

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [{
      role: 'system',
      content: 'Summarize this conversation. Extract: key topics, decisions, open questions.'
    }, {
      role: 'user',
      content: formatMessages(messages)
    }],
    temperature: 0.3
  });

  const result = response.choices[0].message.content;
  await cacheResult('summary', threadId, result, 3600); // 1 hour TTL
  return result;
});
```

#### 2. Action Item Extraction

```javascript
exports.extractActionItems = functions.https.onCall(async (data, context) => {
  const { threadId } = data;
  const messages = await getThreadMessages(threadId);

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [{
      role: 'system',
      content: `Extract action items. Return JSON:
      [{"task": "description", "assignee": "name or null", "deadline": "date or null", "status": "pending"}]`
    }, {
      role: 'user',
      content: formatMessages(messages)
    }],
    response_format: { type: "json_object" },
    temperature: 0.2
  });

  return JSON.parse(response.choices[0].message.content);
});
```

#### 3. Smart Search (RAG)

```javascript
exports.smartSearch = functions.https.onCall(async (data, context) => {
  const { query, userId } = data;

  // Generate embedding
  const queryEmbedding = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: query
  });

  // Vector search in Firestore
  const results = await admin.firestore()
    .collection('messages')
    .where('userId', '==', userId)
    .findNearest('embedding', queryEmbedding.data[0].embedding, {
      limit: 10,
      distanceMeasure: 'COSINE'
    }).get();

  return results.docs.map(d => d.data());
});
```

#### 4. Priority Detection

```javascript
exports.detectPriority = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();

    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{
        role: 'system',
        content: `Analyze priority. Return JSON: {"priority": "urgent|high|medium|low", "reason": "explanation"}`
      }, {
        role: 'user',
        content: `Message: ${message.text}`
      }],
      response_format: { type: "json_object" },
      temperature: 0.1
    });

    const priority = JSON.parse(response.choices[0].message.content);
    await snap.ref.update({ priority: priority.priority });

    if (['urgent', 'high'].includes(priority.priority)) {
      await sendPriorityNotification(message);
    }
  });
```

#### 5. Decision Tracking

```javascript
exports.trackDecisions = functions.https.onCall(async (data, context) => {
  const { threadId } = data;
  const messages = await getThreadMessages(threadId);

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [{
      role: 'system',
      content: `Extract decisions. Return JSON:
      [{"decision": "what", "rationale": "why", "alternatives": [], "decider": "who", "impact": "high|medium|low"}]`
    }, {
      role: 'user',
      content: formatMessages(messages)
    }],
    response_format: { type: "json_object" },
    temperature: 0.2
  });

  const decisions = JSON.parse(response.choices[0].message.content);
  await storeDecisions(threadId, decisions);
  return decisions;
});
```

### Context-Aware Smart Replies (Advanced Feature)

```javascript
exports.generateSmartReplies = functions.https.onCall(async (data, context) => {
  const { messageId, threadId } = data;

  // Get recent context
  const recentMessages = await getRecentMessages(threadId, 10);
  const currentMessage = await getMessage(messageId);

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [{
      role: 'system',
      content: `Generate 3 contextual replies in the SAME LANGUAGE as the last message.
      Consider: conversation context, tone (formal/casual), cultural norms.
      Return JSON: {"language": "detected", "replies": ["short", "medium", "detailed"]}`
    }, {
      role: 'user',
      content: `Context:\n${formatMessages(recentMessages)}\n\nLatest: "${currentMessage.text}"`
    }],
    response_format: { type: "json_object" },
    temperature: 0.8,
    max_tokens: 300
  });

  const suggestions = JSON.parse(response.choices[0].message.content);
  await cacheSmartReplies(messageId, suggestions, 120); // 2 min cache
  return suggestions.replies;
});
```

### RAG Pipeline (Vector Search)

```javascript
// Real-time embedding indexing
exports.indexMessage = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();

    const embedding = await openai.embeddings.create({
      model: 'text-embedding-3-small',
      input: `${message.text}\nContext: ${message.threadTitle}`,
      dimensions: 1536
    });

    await snap.ref.update({
      embedding: admin.firestore.FieldValue.vector(embedding.data[0].embedding)
    });
  });
```

### Caching Strategy

| Feature | Cache Location | TTL | Rationale |
|---------|---------------|-----|-----------|
| Thread Summaries | Firestore | 1 hour | Updates infrequently |
| Action Items | Firestore | 30 min | May change as thread progresses |
| Smart Replies | Redis | 2 min | Real-time, high volume |
| Priority Detection | Firestore | 5 min | Semi-static per message |
| Smart Search | Redis | 15 min | Results change with new messages |
| Decision Tracking | Firestore | 24 hours | Rarely changes |

---

## 7. INTERNATIONAL COMMUNICATOR FEATURES

### Language Detection

**Implementation:** google_mlkit_language_id (on-device)

```dart
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

final languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);

Future<String> detectLanguage(String text) async {
  final language = await languageIdentifier.identifyLanguage(text);
  return language; // Returns ISO 639-1 code (e.g., 'en', 'es')
}
```

### Real-Time Translation

**Service:** Google Cloud Translation API (primary), DeepL (for quality/formality)

**Architecture:** Translate on-send, store original + translations

```dart
class TranslationService {
  Future<Map<String, String>> translateMessage(
    String text,
    String sourceLanguage,
    List<String> targetLanguages,
  ) async {
    final translations = <String, String>{};

    for (var targetLang in targetLanguages) {
      final cached = await getFromCache(text, targetLang);
      if (cached != null) {
        translations[targetLang] = cached;
        continue;
      }

      final translated = await googleTranslate.translate(
        text,
        from: sourceLanguage,
        to: targetLang,
      );

      translations[targetLang] = translated;
      await cacheTranslation(text, targetLang, translated);
    }

    return translations;
  }
}
```

### Multi-Language Data Modeling

Messages store original + translations:

```json
{
  "text": "Hello, how are you?",
  "detectedLanguage": "en",
  "translations": {
    "es": "Hola, ¿cómo estás?",
    "fr": "Bonjour, comment allez-vous?",
    "de": "Hallo, wie geht es dir?"
  }
}
```

**Optimization:** Only translate to languages of active participants

### Cultural Context & Formality Detection

```javascript
exports.detectFormality = functions.https.onCall(async (data, context) => {
  const { text, language } = data;

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [{
      role: 'system',
      content: `Analyze formality level. Return JSON: {"formality": "formal|informal|neutral", "reason": "brief explanation"}`
    }, {
      role: 'user',
      content: `Language: ${language}\nText: ${text}`
    }],
    response_format: { type: "json_object" },
    temperature: 0.1
  });

  return JSON.parse(response.choices[0].message.content);
});
```

### Translation Cost Optimization

**Strategy:**
- 70% cache hit rate reduces cost by 70%
- Translation memory for common phrases
- Batch translations for group chats
- Skip translation for same-language pairs

**Cost Estimate (100K users, 50 msgs/day):**
- Characters/month: 15B
- With 70% cache: 4.5B billable
- Google Translate: $90/month
- Azure Translator: $45/month (recommended for cost)

---

## 8. TESTING STRATEGY

### Test Pyramid

```
Integration: 10-15%  (End-to-end flows)
Widget:      25-30%  (UI components)
Unit:        55-65%  (Business logic)
```

### Coverage Targets
- Overall: 80%+
- Business Logic: 90%+
- Critical Paths: 95%+ (messaging, auth, sync)

### Testing Packages

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mocktail: ^1.0.1
  fake_cloud_firestore: ^2.5.0
  firebase_auth_mocks: ^0.13.0
  http_mock_adapter: ^0.6.1
  coverage: ^1.7.0
```

### Unit Test Example

```dart
void main() {
  group('MessageRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MessageRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = MessageRepositoryImpl(
        remoteDataSource: MessageRemoteDataSourceImpl(fakeFirestore),
      );
    });

    test('should send message successfully', () async {
      final message = Message(text: 'Hello', senderId: 'user1');

      await repository.sendMessage(message);

      final snapshot = await fakeFirestore.collection('messages').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['text'], 'Hello');
    });
  });
}
```

### Widget Test Example

```dart
testWidgets('displays messages correctly', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: ChatScreen(conversationId: 'test')),
    ),
  );

  expect(find.text('Hello'), findsOneWidget);
  expect(find.byType(MessageBubble), findsWidgets);
});
```

---

## 9. DEPLOYMENT & CI/CD

### Environment Management

**2 Firebase Projects:**
- message-ai (Development)
- message-ai-prod (Production)

**Flutter Flavors:**

```dart
// Run commands
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor prod -t lib/main_prod.dart
```

### CI/CD Pipeline (GitHub Actions + Fastlane)

```yaml
# .github/workflows/deploy.yml
name: Flutter CI/CD

on:
  push:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Get dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test --coverage

      - name: Check coverage
        run: |
          dart pub global activate coverage
          dart pub global run coverage:test_with_coverage --min-coverage 80

  deploy_ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2

      - name: Install Fastlane
        run: gem install fastlane

      - name: Deploy to TestFlight
        run: |
          cd ios
          fastlane beta
```

**Fastlane Setup (ios/fastlane/Fastfile):**

```ruby
lane :beta do
  build_app(scheme: "Runner")
  upload_to_testflight(skip_waiting_for_build_processing: true)
end
```

---

## 10. COST OPTIMIZATION

### Firebase Optimization (50-70% savings)

1. **Pagination:** Reduce reads by 90-99%
   ```dart
   .limit(50)
   .startAfter(lastDocument)
   ```

2. **Timestamp queries:** Only fetch new data
   ```dart
   .where('timestamp', isGreaterThan: lastFetchTime)
   ```

3. **Offline caching:** 30-50% read reduction
   ```dart
   FirebaseFirestore.instance.settings = Settings(
     persistenceEnabled: true,
     cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
   );
   ```

4. **Denormalization:** Store lastMessage in conversation doc
   - Saves 1 read per conversation in list view

5. **Firestore listeners scope:**
   ```dart
   .where('participantIds', arrayContains: userId)
   .limit(20)
   ```

### OpenAI Optimization (85-90% savings)

1. **Prompt caching:** 50% automatic savings
2. **Model selection:** gpt-4o-mini for 85% of requests (16x cheaper)
3. **Batch API:** 50% savings for non-real-time
4. **Token limits:** Set max_tokens appropriately
5. **Application caching:** Firestore/Redis for responses

### Cost Projections

**10K Users (1K DAU):**
- Firestore: $8/month
- Firebase Storage: $6/month
- OpenAI: $63/month
- Cloud Functions: $5/month
- **Total: $82/month**

**100K Users (10K DAU):**
- Firestore: $80/month
- Firebase Storage: $244/month
- OpenAI: $630/month
- Cloud Functions: $51/month
- **Total: $1,005/month**

**1M Users (100K DAU):**
- Firestore: $804/month
- Firebase Storage: $2,439/month
- OpenAI: $6,300/month
- Cloud Functions: $508/month
- **Total: $10,051/month**

---

## 11. DEVELOPMENT PHASES (30 WEEKS)

### Phase 1: Foundation (Weeks 1-4)
- [ ] Project structure with clean architecture
- [ ] Firebase setup (dev/prod)
- [ ] Authentication (phone auth)
- [ ] Basic user profile
- [ ] CI/CD pipeline

### Phase 2: Core Messaging (Weeks 5-8)
- [ ] 1-to-1 messaging with real-time sync
- [ ] Message delivery states
- [ ] Optimistic UI updates
- [ ] Conversation list
- [ ] Typing indicators
- [ ] Push notifications

### Phase 3: Offline-First (Weeks 9-10)
- [ ] drift local database
- [ ] Message queue with retry logic
- [ ] Conflict resolution (LWW)
- [ ] Background sync (WorkManager)

### Phase 4: Media Handling (Weeks 11-12)
- [ ] Image upload (Firebase Storage)
- [ ] cached_network_image integration
- [ ] Compression and thumbnails

### Phase 5: Group Chats (Weeks 13-15)
- [ ] Group creation and management
- [ ] Group messages
- [ ] Aggregate read receipts

### Phase 6: AI Features - Core (Weeks 16-19)
- [ ] Cloud Functions with Secret Manager
- [ ] Thread summarization
- [ ] Action item extraction
- [ ] Priority detection
- [ ] Decision tracking
- [ ] Smart search with RAG

### Phase 7: International Features (Weeks 20-23)
- [ ] Language detection
- [ ] Real-time translation
- [ ] Multilingual message storage
- [ ] Context-aware smart replies

### Phase 8: Advanced AI (Weeks 24-25)
- [ ] Vector search indexing
- [ ] RAG pipeline
- [ ] Idiom/slang detection

### Phase 9: Polish (Weeks 26-28)
- [ ] Performance optimization
- [ ] Error handling improvements
- [ ] Animations and transitions

### Phase 10: Production (Weeks 29-30)
- [ ] Security audit
- [ ] Load testing
- [ ] Beta testing
- [ ] App Store submission

---

## 12. SECURITY CHECKLIST

- ✅ OpenAI API keys in Google Secret Manager
- ✅ Firebase App Check enabled
- ✅ Firestore Security Rules with participantIds checks
- ✅ Rate limiting (100 req/hour per user)
- ✅ Input validation and sanitization
- ✅ PII detection before sending to OpenAI
- ✅ Local database encryption (drift built-in)
- ✅ Secure FCM token storage
- ✅ HTTPS/TLS for all network communication

---

## 13. KEY DEPENDENCIES

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3

  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  firebase_messaging: ^14.7.9
  firebase_crashlytics: ^3.4.8
  cloud_functions: ^4.5.11

  # Local Storage
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0

  # UI
  cached_network_image: ^3.3.0
  flutter_cache_manager: ^3.3.1

  # Language
  google_mlkit_language_id: ^0.10.0
  intl: ^0.18.1

  # Utilities
  uuid: ^4.2.2
  equatable: ^2.0.5
  connectivity_plus: ^5.0.2
  workmanager: ^0.5.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.6
  riverpod_generator: ^2.3.9
  drift_dev: ^2.14.0
  mocktail: ^1.0.1
  fake_cloud_firestore: ^2.5.0
  firebase_auth_mocks: ^0.13.0
```

---

## 14. SUCCESS CRITERIA

### Technical Metrics
- ✅ 80%+ test coverage
- ✅ 60 FPS scroll performance
- ✅ < 500ms AI response (cached)
- ✅ < 3s cold start
- ✅ 99.9% message delivery rate

### Business Metrics
- ✅ 40%+ smart reply acceptance rate
- ✅ 70%+ translation cache hit rate
- ✅ < $0.01 AI cost per user per day
- ✅ 4.5+ star app store rating

---

## CONCLUSION

This PRD provides a complete, production-ready specification for building a WhatsApp clone with AI features using Flutter + Firebase. The architecture supports:

- **Scale:** 1M+ concurrent users with proper optimization
- **Reliability:** 99.9%+ uptime, offline-first design
- **Performance:** 60 FPS, sub-500ms AI responses
- **Cost-Efficiency:** 85-90% AI cost savings
- **Quality:** 80%+ test coverage from day one

All technical decisions are justified with 2024-2025 best practices, and implementation details are specific enough for AI coding agents to execute. The 30-week development plan ensures logical feature progression with clear dependencies.
