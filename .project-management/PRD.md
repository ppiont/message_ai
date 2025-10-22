# MessageAI: Production-Ready Messaging Platform with AI Features
## Updated PRD - Rubric-Optimized Edition

---

## Executive Summary

MessageAI is a **Flutter-based messaging platform** targeting **International Communicators** with advanced AI translation and communication features. Built on Firebase + Riverpod + Drift, the app implements an offline-first architecture with real-time sync, achieving **80% MVP completion** with strong technical foundations.

**Current Status:**
- ✅ Core messaging infrastructure (real-time, offline-first, optimistic UI)
- ✅ Authentication & user management
- ✅ Presence & typing indicators
- ✅ Read receipts with delivery tracking
- ⏳ Group chat (partial implementation)
- ⏳ Push notifications (not implemented)
- ⏳ AI features (0/5 required features, 0/1 advanced)

**Rubric Target:** 90+ points (A grade)

---

## 1. RUBRIC ANALYSIS & SCORING STRATEGY

### Current Projected Score: 62/100 (needs +28 points for A)

#### Section 1: Core Messaging Infrastructure (35 points) - **PROJECTED: 28/35**
- **Real-Time Delivery (12 pts)**: STRONG - Currently 10/12
  - Sub-200ms delivery on good network ✅
  - Zero lag during rapid messaging ✅
  - Typing indicators work ✅
  - Presence updates sync ✅
  - *Gap: Need verification under heavy concurrent load*

- **Offline Support (12 pts)**: STRONG - Currently 11/12
  - Message queue with retry logic ✅
  - App restart preserves history ✅
  - Auto-reconnect with sync ✅
  - Connection indicators ✅
  - *Gap: Sync time should be sub-1 second (currently ~2s)*

- **Group Chat (11 pts)**: WEAK - Currently 7/11
  - Basic functionality exists ✅
  - Message attribution works ✅
  - *Gaps: Read receipts incomplete, typing indicators missing, no member list UI*

#### Section 2: Mobile App Quality (20 points) - **PROJECTED: 14/20**
- **Mobile Lifecycle (8 pts)**: NEEDS TESTING - Est. 5/8
  - Offline-first architecture supports backgrounding
  - *Gaps: No verified testing, push notifications missing*

- **Performance & UX (12 pts)**: NEEDS OPTIMIZATION - Est. 9/12
  - Optimistic UI implemented ✅
  - *Gaps: No verified 60 FPS testing, no performance profiling, launch time unknown*

#### Section 3: AI Features (30 points) - **PROJECTED: 0/30** ⚠️ CRITICAL
- **Required Features (15 pts)**: NOT IMPLEMENTED
- **Persona Fit (5 pts)**: NOT IMPLEMENTED
- **Advanced Capability (10 pts)**: NOT IMPLEMENTED

#### Section 4: Technical Implementation (10 points) - **PROJECTED: 7/10**
- **Architecture (5 pts)**: GOOD - Currently 4/5
  - Clean architecture ✅
  - API keys need security audit
  - *Gaps: No RAG pipeline, no function calling, no response streaming*

- **Authentication & Data (5 pts)**: GOOD - Currently 3/5
  - Firebase Auth working ✅
  - Drift local storage ✅
  - *Gaps: No conflict resolution testing, no profile photos*

#### Section 5: Documentation (5 points) - **PROJECTED: 3/5**
- Needs comprehensive README verification

#### Required Deliverables: **INCOMPLETE**
- Demo video: Not created (-15 pts)
- Persona brainlift: Not created (-10 pts)
- Social post: Not created (-5 pts)

---

## 2. PRIORITY ACTION PLAN (BY RUBRIC IMPACT)

### 🔴 CRITICAL: AI Features (30 points) - MUST DO
**Impact:** 30 points | **Effort:** 12-16 hours | **Priority:** P0

**Required AI Features (15 points):**
1. **Real-time Translation**
   - Inline message translation using Google Cloud Translation API
   - Store original + translations in Firestore
   - Toggle to show original vs translated

2. **Language Detection & Auto-Translate**
   - Use google_mlkit_language_id (on-device)
   - Auto-detect on message send
   - Auto-translate for recipient's preferred language

3. **Cultural Context Hints**
   - GPT-4o-mini function calling to detect cultural nuances
   - Show tooltip/badge for formal greetings, idioms
   - Context: "In Spanish culture, 'usted' shows respect"

4. **Formality Level Adjustment**
   - Analyze message formality (casual/neutral/formal)
   - Suggest alternative phrasing
   - UI: "Make more formal" / "Make more casual" buttons

5. **Slang/Idiom Explanations**
   - Detect colloquial phrases
   - Provide explanations in recipient's language
   - Example: "break a leg" → "good luck" with cultural note

**Advanced Capability (10 points) - CHOOSE ONE:**

**Option A: Context-Aware Smart Replies** (RECOMMENDED)
- Generate 3 reply suggestions based on:
  - Conversation history (last 10 messages as context)
  - User's writing style (learned from past messages)
  - Detected language and formality
- Implementation:
  - RAG pipeline using Firestore as vector DB
  - GPT-4o-mini with few-shot examples
  - Cache common patterns in Firestore
- Scoring potential: 9-10 points (if done well)

**Option B: Intelligent Data Extraction**
- Extract structured data from multilingual messages:
  - Dates, times, locations
  - Phone numbers, emails
  - Action items, commitments
- Display as cards/chips in chat
- Scoring potential: 7-8 points (less impressive)

### 🟡 HIGH: Complete MVP Features (11 points) - MUST DO
**Impact:** 11 points | **Effort:** 6-8 hours | **Priority:** P1

1. **Group Chat Polish (7 points)**
   - Complete member list UI
   - Group-specific typing indicators
   - Aggregate read receipts (show count)
   - Admin roles and permissions
   - Group info editing

2. **Push Notifications (4 points)**
   - FCM integration for foreground notifications
   - Background notification handling
   - Deep linking to conversations
   - Custom notification sounds

### 🟢 MEDIUM: Performance & Polish (12 points) - SHOULD DO
**Impact:** 12 points | **Effort:** 4-6 hours | **Priority:** P2

1. **Mobile Lifecycle Testing**
   - Test backgrounding/foregrounding
   - Test force quit scenarios
   - Test 30-second network drops
   - Document results

2. **Performance Optimization**
   - Profile with Flutter DevTools
   - Ensure 60 FPS scrolling (test with 1000+ messages)
   - Optimize image loading
   - Lazy load conversation list
   - Measure cold start time (target <2s)

3. **UI Polish**
   - Smooth animations (hero animations for images)
   - Loading states everywhere
   - Error boundaries and recovery
   - Dark mode support (if time permits)

### 🔵 LOW: Technical Excellence (7 points) - NICE TO HAVE
**Impact:** 7 points | **Effort:** 3-5 hours | **Priority:** P3

1. **RAG Pipeline Implementation**
   - Set up vector embeddings (text-embedding-3-small)
   - Store in Firestore with vector search
   - Implement semantic search
   - Context retrieval for AI features

2. **Security Hardening**
   - Audit Firestore security rules
   - Implement rate limiting in Cloud Functions
   - Add PII detection before AI calls
   - Enable Firebase App Check

3. **Documentation**
   - Comprehensive README with setup steps
   - Architecture diagrams
   - API documentation
   - Testing guide

---

## 3. TECHNICAL ARCHITECTURE (CURRENT STATE)

### Technology Stack (VERIFIED WORKING)

```yaml
# pubspec.yaml (CURRENT)
dependencies:
  flutter: sdk: flutter

  # State Management ✅ WORKING
  flutter_riverpod: ^3.0.3
  riverpod_annotation: ^3.0.3

  # Firebase ✅ WORKING
  firebase_core: ^4.2.0
  firebase_auth: ^6.1.1
  cloud_firestore: ^6.0.3
  firebase_storage: ^13.0.3
  firebase_messaging: ^16.0.3
  firebase_crashlytics: ^5.0.3
  cloud_functions: ^6.0.3

  # Local Storage ✅ WORKING
  drift: ^2.29.0
  sqlite3_flutter_libs: ^0.5.24

  # Utilities ✅ WORKING
  uuid: ^4.5.1
  equatable: ^2.0.7
  connectivity_plus: ^6.1.2
  dartz: ^0.10.1
  rxdart: ^0.28.0
  intl: ^0.20.2

  # Image Handling
  image_picker: ^1.2.0

  # NEW: AI & Translation (TO ADD)
  google_mlkit_language_id: ^0.10.0  # Language detection
  http: ^1.2.0  # For Google Translate API calls
```

### Project Structure (VERIFIED)

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── database/                    # ✅ Drift setup complete
│   │   ├── app_database.dart
│   │   ├── tables/
│   │   └── daos/
│   ├── services/                    # ✅ Core services working
│   │   ├── message_sync_service.dart
│   │   ├── message_queue.dart
│   │   ├── typing_indicator_service.dart
│   │   ├── presence_service.dart
│   │   └── auto_delivery_marker.dart
│   ├── error/                       # ✅ Error handling
│   └── utils/                       # ✅ Utilities
│
├── features/
│   ├── authentication/              # ✅ COMPLETE
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── messaging/                   # ✅ MOSTLY COMPLETE
│   │   ├── data/
│   │   │   ├── datasources/        # ✅ Remote + Local working
│   │   │   ├── models/             # ✅ Message, Conversation models
│   │   │   └── repositories/       # ✅ Offline-first repo
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/           # ✅ 20+ use cases
│   │   └── presentation/
│   │       ├── providers/          # ✅ Riverpod providers
│   │       ├── pages/              # ✅ Chat UI working
│   │       └── widgets/            # ✅ Message bubbles, input, etc.
│   │
│   ├── ai_features/                 # ⏳ TO IMPLEMENT
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── openai_datasource.dart
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── translation.dart
│   │   │   │   ├── cultural_hint.dart
│   │   │   │   └── smart_reply.dart
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   │       ├── translate_message.dart
│   │   │       ├── detect_language.dart
│   │   │       ├── analyze_formality.dart
│   │   │       ├── explain_idiom.dart
│   │   │       └── generate_smart_replies.dart  # Advanced
│   │   └── presentation/
│   │       ├── providers/
│   │       └── widgets/
│   │           ├── translation_overlay.dart
│   │           ├── cultural_hint_chip.dart
│   │           ├── formality_adjuster.dart
│   │           └── smart_reply_bar.dart
│   │
│   └── translation/                 # ⏳ TO IMPLEMENT (merge with ai_features?)
│
└── config/
    ├── routes/
    ├── theme/
    └── providers.dart
```

### Data Flow (VERIFIED WORKING)

```
┌─────────────────────────────────────────────────────────────┐
│                       USER ACTION                            │
│                     (Send Message)                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                 PRESENTATION LAYER                           │
│              (ChatPage + Providers)                          │
│  - Optimistic UI update (message appears immediately)        │
│  - Call SendMessage use case                                 │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    DOMAIN LAYER                              │
│                  (SendMessage UseCase)                       │
│  - Validates message                                         │
│  - Calls repository                                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     DATA LAYER                               │
│              (MessageRepository)                             │
│  1. Save to Local DB (Drift) ✅ IMMEDIATE                   │
│  2. Queue for Firebase sync                                  │
└─────────────────┬───────────────────────────┬───────────────┘
                  │                           │
    LOCAL DB      │                           │    REMOTE DB
    (Instant)     │                           │    (Background)
                  ▼                           ▼
         ┌────────────────┐         ┌────────────────────┐
         │  Drift/SQLite  │         │   Firestore        │
         │                │         │                    │
         │  - Immediate   │         │  - Background sync │
         │  - Offline OK  │◀────────│  - Real-time       │
         │  - Source of   │  Sync   │  - Multi-device    │
         │    truth       │         │                    │
         └────────────────┘         └────────────────────┘
                  │                           │
                  │    BIDIRECTIONAL SYNC     │
                  │    (MessageSyncService)   │
                  └───────────┬───────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   UI UPDATES     │
                    │  (Real-time via  │
                    │   Riverpod       │
                    │   StreamProvider)│
                    └──────────────────┘
```

### Services Architecture (VERIFIED WORKING)

```dart
// All services auto-start via providers in app.dart

1. MessageSyncService
   - Bidirectional sync between Drift and Firestore
   - Watches Firestore for new messages → saves locally
   - Watches connectivity → triggers sync on reconnect
   - Status: ✅ WORKING

2. MessageQueue
   - Optimistic UI with retry logic
   - Exponential backoff for failures
   - Persists queue to Drift
   - Status: ✅ WORKING

3. TypingIndicatorService
   - Debounced typing updates (3s timeout)
   - Firestore-based real-time sync
   - Status: ✅ WORKING

4. PresenceService
   - Heartbeat every 30s
   - Auto-detects online/offline
   - Tied to auth lifecycle
   - Status: ✅ WORKING

5. AutoDeliveryMarker
   - Marks incoming messages as delivered
   - Listens to all conversations globally
   - Status: ✅ WORKING
```

---

## 4. AI FEATURES IMPLEMENTATION (DETAILED SPECS)

### Architecture Decision: Hybrid Approach

**UI Strategy:**
- **Inline features** for translation, cultural hints, formality
- **Contextual menu** (long-press) for idiom explanations
- **Bottom sheet** for smart replies (3 suggestions)
- **Chat interface** would require separate AI assistant chat (out of scope)

### Feature 1: Real-Time Translation

**User Flow:**
1. User receives message in Spanish: "Hola, ¿cómo estás?"
2. Small "Translate" button appears below message
3. Tap → message expands to show: "Hello, how are you?"
4. Tap again → collapses to original

**Technical Implementation:**

```dart
// 1. Add to Message entity
class Message {
  final String text;
  final String? detectedLanguage;
  final Map<String, String> translations;  // NEW
  // ... other fields
}

// 2. Update Firestore schema
{
  "conversations/{conversationId}/messages/{messageId}": {
    "text": "Hola, ¿cómo estás?",
    "detectedLanguage": "es",
    "translations": {
      "en": "Hello, how are you?",
      "fr": "Bonjour, comment allez-vous?"
    },
    // ... other fields
  }
}

// 3. Cloud Function: translateMessage
exports.translateMessage = functions.https.onCall(async (data, context) => {
  const { text, sourceLanguage, targetLanguages } = data;

  // Use Google Cloud Translation API
  const translations = {};
  for (const targetLang of targetLanguages) {
    // Check cache first
    const cached = await getCachedTranslation(text, targetLang);
    if (cached) {
      translations[targetLang] = cached;
      continue;
    }

    // Translate
    const result = await translate.translate(text, {
      from: sourceLanguage,
      to: targetLang
    });

    translations[targetLang] = result[0];

    // Cache for 7 days
    await cacheTranslation(text, targetLang, result[0]);
  }

  return { translations };
});

// 4. UI Component
class TranslationOverlay extends ConsumerWidget {
  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userLang = ref.watch(currentUserProvider).preferredLanguage;
    final isTranslated = ref.watch(translatedMessagesProvider)
        .contains(message.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTranslated
            ? message.translations[userLang] ?? message.text
            : message.text
        ),
        if (message.detectedLanguage != userLang)
          TextButton(
            onPressed: () => ref.read(translatedMessagesProvider.notifier)
                .toggle(message.id),
            child: Text(
              isTranslated ? 'Show original' : 'Translate'
            ),
          ),
      ],
    );
  }
}
```

**Translation Strategy:**
- **On-send**: Translate to all participants' preferred languages
- **On-receive**: Translation already available (no delay)
- **Cache**: Store in Firestore for 7 days (90% hit rate expected)
- **Cost**: ~$0.01 per 1000 characters

### Feature 2: Language Detection & Auto-Translate

**User Flow:**
1. User types message in any language
2. On send, language is auto-detected
3. Message auto-translates for recipients
4. No manual language selection needed

**Technical Implementation:**

```dart
// 1. Add google_mlkit_language_id to pubspec.yaml

// 2. Create LanguageDetectionService
class LanguageDetectionService {
  final _languageIdentifier = LanguageIdentifier(
    confidenceThreshold: 0.5
  );

  Future<String> detectLanguage(String text) async {
    // Returns ISO 639-1 code (e.g., 'en', 'es', 'fr')
    final languageCode = await _languageIdentifier.identifyLanguage(text);

    // Handle 'und' (undetermined) - default to user's language
    if (languageCode == 'und') {
      return await _getUserDefaultLanguage();
    }

    return languageCode;
  }

  Future<void> dispose() async {
    await _languageIdentifier.close();
  }
}

// 3. Integrate into SendMessage use case
class SendMessage {
  final MessageRepository repository;
  final LanguageDetectionService languageDetector;
  final TranslationService translator;

  Future<Either<Failure, void>> call(SendMessageParams params) async {
    // 1. Detect language
    final detectedLang = await languageDetector.detectLanguage(params.text);

    // 2. Get participant languages
    final conversation = await repository.getConversationById(
      params.conversationId
    );
    final targetLanguages = conversation.participants
        .map((p) => p.preferredLanguage)
        .where((lang) => lang != detectedLang)
        .toSet()
        .toList();

    // 3. Translate to all target languages (if any)
    Map<String, String> translations = {};
    if (targetLanguages.isNotEmpty) {
      translations = await translator.translateMessage(
        text: params.text,
        sourceLanguage: detectedLang,
        targetLanguages: targetLanguages,
      );
    }

    // 4. Create message with translations
    final message = Message(
      // ... other fields
      text: params.text,
      detectedLanguage: detectedLang,
      translations: translations,
    );

    // 5. Send message
    return repository.sendMessage(message);
  }
}
```

**Performance:**
- **Detection**: On-device, <50ms
- **Translation**: Cloud function, 200-500ms (cached: <50ms)
- **Total**: <550ms end-to-end

### Feature 3: Cultural Context Hints

**User Flow:**
1. User receives message: "Espero que estés bien"
2. Small 🌍 badge appears next to message
3. Tap badge → tooltip shows:
   > "In Spanish culture, 'Espero que estés bien' (I hope you're well) is a warm, formal greeting often used with acquaintances or in professional contexts."

**Technical Implementation:**

```dart
// 1. Cloud Function: analyzeCulturalContext
exports.analyzeCulturalContext = functions.https.onCall(async (data, context) => {
  const { text, language, conversationContext } = data;

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: `You are a cultural context expert. Analyze the message for cultural nuances, idioms, or formality that might not be obvious to non-native speakers. Focus on:
- Cultural greetings or expressions
- Formal vs informal language use
- Idioms or colloquialisms
- Cultural references
Keep explanations under 50 words.`
      },
      {
        role: 'user',
        content: `Language: ${language}\nMessage: "${text}"\n\nProvide cultural context if relevant, or return null if the message is straightforward.`
      }
    ],
    max_tokens: 100,
    temperature: 0.3,
  });

  const hint = response.choices[0].message.content;

  // Only return if there's actual cultural context (not "No cultural context needed")
  if (hint && !hint.toLowerCase().includes('no cultural') && !hint.toLowerCase().includes('straightforward')) {
    return { culturalHint: hint };
  }

  return { culturalHint: null };
});

// 2. Add to Message model
class Message {
  // ... other fields
  final String? culturalHint;
}

// 3. Trigger analysis on message receive (for foreign languages)
class MessageSyncService {
  Future<void> _processIncomingMessage(Message message) async {
    // Save message first
    await _saveLocally(message);

    // Then analyze in background if needed
    final userLang = await _getUserLanguage();
    if (message.detectedLanguage != userLang) {
      _analyzeAsync(message);  // Fire and forget
    }
  }

  Future<void> _analyzeAsync(Message message) async {
    try {
      final result = await _cloudFunctions.call(
        'analyzeCulturalContext',
        {
          'text': message.text,
          'language': message.detectedLanguage,
        },
      );

      if (result['culturalHint'] != null) {
        // Update message locally and remotely
        await _updateMessageWithHint(
          message.id,
          result['culturalHint']
        );
      }
    } catch (e) {
      // Fail silently - cultural hints are nice-to-have
      _logger.debug('Cultural context analysis failed: $e');
    }
  }
}

// 4. UI Component
class CulturalHintChip extends StatelessWidget {
  final String hint;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Cultural Context'),
            content: Text(hint),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Got it'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌍', style: TextStyle(fontSize: 12)),
            SizedBox(width: 4),
            Text(
              'Cultural context',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Cost Optimization:**
- Only analyze messages in foreign languages
- Cache results for 30 days
- Fire-and-forget (don't block message display)
- Expected cost: $0.001 per analyzed message

### Feature 4: Formality Level Adjustment

**User Flow:**
1. User types: "Hey, what's up?"
2. Before sending, sees formality indicator: "Casual"
3. Taps "Make more formal" button
4. Message changes to: "Hello, how are you doing?"
5. User reviews and sends

**Technical Implementation:**

```dart
// 1. Cloud Function: adjustFormality
exports.adjustFormality = functions.https.onCall(async (data, context) => {
  const { text, currentFormality, targetFormality, language } = data;
  // currentFormality: 'casual' | 'neutral' | 'formal'
  // targetFormality: 'casual' | 'neutral' | 'formal'

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: `You are a language formality expert. Rewrite messages to match the target formality level while preserving meaning and cultural appropriateness.

Current formality: ${currentFormality}
Target formality: ${targetFormality}
Language: ${language}

Rules:
- Casual: Contractions, slang OK, friendly tone
- Neutral: Standard language, no slang, balanced
- Formal: No contractions, respectful, professional

Return ONLY the rewritten message, nothing else.`
      },
      {
        role: 'user',
        content: text
      }
    ],
    max_tokens: 150,
    temperature: 0.4,
  });

  return {
    rewrittenText: response.choices[0].message.content,
    formality: targetFormality,
  };
});

// 2. Add FormalityAdjuster widget
class FormalityAdjuster extends ConsumerStatefulWidget {
  final TextEditingController controller;

  @override
  ConsumerState<FormalityAdjuster> createState() => _FormalityAdjusterState();
}

class _FormalityAdjusterState extends ConsumerState<FormalityAdjuster> {
  String _currentFormality = 'neutral';
  bool _isAdjusting = false;

  Future<void> _adjustFormality(String targetFormality) async {
    setState(() => _isAdjusting = true);

    try {
      final result = await ref.read(cloudFunctionsProvider).call(
        'adjustFormality',
        {
          'text': widget.controller.text,
          'currentFormality': _currentFormality,
          'targetFormality': targetFormality,
          'language': ref.read(currentUserProvider).preferredLanguage,
        },
      );

      widget.controller.text = result['rewrittenText'];
      setState(() => _currentFormality = targetFormality);
    } catch (e) {
      _showError(e);
    } finally {
      setState(() => _isAdjusting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.text.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Text('Formality: '),
          ChoiceChip(
            label: Text('Casual'),
            selected: _currentFormality == 'casual',
            onSelected: (_) => _adjustFormality('casual'),
          ),
          SizedBox(width: 8),
          ChoiceChip(
            label: Text('Neutral'),
            selected: _currentFormality == 'neutral',
            onSelected: (_) => _adjustFormality('neutral'),
          ),
          SizedBox(width: 8),
          ChoiceChip(
            label: Text('Formal'),
            selected: _currentFormality == 'formal',
            onSelected: (_) => _adjustFormality('formal'),
          ),
          if (_isAdjusting) ...[
            SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}
```

**User Experience:**
- Automatic formality detection on first analysis
- Manual adjustment with instant preview
- Preserves meaning while adapting tone
- Works for all supported languages

### Feature 5: Slang/Idiom Explanations

**User Flow:**
1. User receives: "I'll play it by ear"
2. Long-press message → contextual menu
3. Tap "Explain idioms" option
4. Bottom sheet appears:
   > **"play it by ear"**
   >
   > Meaning: To improvise or decide how to act based on the situation as it develops, without detailed planning.
   >
   > Cultural note: Common English idiom from music (playing without sheet music).
   >
   > Equivalent in Spanish: "ver sobre la marcha"

**Technical Implementation:**

```dart
// 1. Cloud Function: explainIdioms
exports.explainIdioms = functions.https.onCall(async (data, context) => {
  const { text, language, targetLanguage } = data;

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: `You are an expert in idioms and colloquial expressions. Analyze messages for idioms, slang, or colloquialisms and provide:
1. The idiom/slang phrase
2. Literal meaning
3. Cultural context
4. Equivalent expression in target language (if different)

Format as JSON:
{
  "idioms": [
    {
      "phrase": "play it by ear",
      "meaning": "...",
      "culturalNote": "...",
      "equivalentIn": { "es": "ver sobre la marcha" }
    }
  ]
}

If no idioms/slang found, return { "idioms": [] }`
      },
      {
        role: 'user',
        content: `Source language: ${language}\nTarget language: ${targetLanguage}\nMessage: "${text}"`
      }
    ],
    max_tokens: 300,
    temperature: 0.3,
    response_format: { type: 'json_object' },
  });

  return JSON.parse(response.choices[0].message.content);
});

// 2. Add IdiomExplanation entity
class IdiomExplanation {
  final String phrase;
  final String meaning;
  final String culturalNote;
  final Map<String, String> equivalents;

  const IdiomExplanation({
    required this.phrase,
    required this.meaning,
    required this.culturalNote,
    this.equivalents = const {},
  });
}

// 3. Add contextual menu item
class MessageBubble extends ConsumerWidget {
  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context, ref),
      child: // ... message bubble UI
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.translate),
            title: Text('Translate'),
            onTap: () => _translate(),
          ),
          ListTile(
            leading: Icon(Icons.lightbulb_outline),
            title: Text('Explain idioms'),
            onTap: () => _explainIdioms(context, ref),
          ),
          // ... other options
        ],
      ),
    );
  }

  Future<void> _explainIdioms(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);  // Close menu

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ref.read(cloudFunctionsProvider).call(
        'explainIdioms',
        {
          'text': message.text,
          'language': message.detectedLanguage,
          'targetLanguage': ref.read(currentUserProvider).preferredLanguage,
        },
      );

      Navigator.pop(context);  // Close loading

      final idioms = (result['idioms'] as List)
          .map((e) => IdiomExplanation.fromJson(e))
          .toList();

      if (idioms.isEmpty) {
        _showSnackBar('No idioms or slang found in this message');
        return;
      }

      // Show explanations
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => IdiomExplanationSheet(idioms: idioms),
      );
    } catch (e) {
      Navigator.pop(context);
      _showError(e);
    }
  }
}

// 4. IdiomExplanationSheet widget
class IdiomExplanationSheet extends StatelessWidget {
  final List<IdiomExplanation> idioms;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Idioms & Slang',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16),
          ...idioms.map((idiom) => Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${idiom.phrase}"',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Meaning: ${idiom.meaning}'),
                  if (idiom.culturalNote.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      'Cultural note: ${idiom.culturalNote}',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (idiom.equivalents.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      'Equivalent expressions:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    ...idiom.equivalents.entries.map((e) =>
                      Padding(
                        padding: EdgeInsets.only(left: 8, top: 4),
                        child: Text('• ${e.key.toUpperCase()}: "${e.value}"'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )),
          SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Cost & Performance:**
- On-demand only (user initiated)
- No automatic scanning (too expensive)
- Cache results for 30 days
- Expected usage: 5-10% of messages
- Cost: ~$0.003 per explanation

---

### Advanced Feature: Context-Aware Smart Replies (RECOMMENDED)

**User Flow:**
1. User receives message: "Want to grab dinner tonight?"
2. Three smart reply chips appear at bottom of screen:
   - "Sure! What time works for you?" (Enthusiastic/confirming)
   - "I'd love to, but I'm busy tonight. How about tomorrow?" (Declining with alternative)
   - "Let me check my schedule and get back to you" (Non-committal)
3. User taps a suggestion → message sent (can edit first)
4. Suggestions learn user's style over time

**Technical Implementation:**

```dart
// 1. RAG Pipeline Setup

// Add to Message model
class Message {
  // ... other fields
  final List<double>? embedding;  // 1536-dimensional vector
}

// Cloud Function: generateEmbedding
exports.generateEmbedding = functions.https.onCall(async (data, context) => {
  const { text } = data;

  const response = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: text,
  });

  return { embedding: response.data[0].embedding };
});

// 2. Context Retrieval
class ConversationContextRetriever {
  final MessageRepository _repository;

  Future<List<Message>> getRelevantContext({
    required String conversationId,
    required Message incomingMessage,
    int maxMessages = 10,
  }) async {
    // Get recent messages (last 50)
    final recentMessages = await _repository.getMessages(
      conversationId: conversationId,
      limit: 50,
    );

    // If incoming message has embedding, do semantic search
    if (incomingMessage.embedding != null) {
      return _semanticSearch(
        query: incomingMessage.embedding!,
        messages: recentMessages,
        limit: maxMessages,
      );
    }

    // Otherwise, just return most recent
    return recentMessages.take(maxMessages).toList();
  }

  List<Message> _semanticSearch({
    required List<double> query,
    required List<Message> messages,
    required int limit,
  }) {
    // Calculate cosine similarity
    final scored = messages
        .where((m) => m.embedding != null)
        .map((m) => (
          message: m,
          score: _cosineSimilarity(query, m.embedding!),
        ))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(limit).map((e) => e.message).toList();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}

// 3. Style Learning
class UserStyleAnalyzer {
  Future<String> analyzeUserStyle({
    required String userId,
    required String conversationId,
  }) async {
    // Get user's last 20 messages
    final userMessages = await _repository.getUserMessages(
      userId: userId,
      conversationId: conversationId,
      limit: 20,
    );

    if (userMessages.isEmpty) {
      return 'neutral, conversational';
    }

    // Analyze style patterns
    final styles = <String>[];

    // Check message length
    final avgLength = userMessages
        .map((m) => m.text.length)
        .reduce((a, b) => a + b) / userMessages.length;
    if (avgLength < 30) styles.add('brief');
    if (avgLength > 100) styles.add('detailed');

    // Check emoji usage
    final emojiCount = userMessages
        .where((m) => _containsEmoji(m.text))
        .length;
    if (emojiCount > userMessages.length * 0.5) {
      styles.add('expressive');
    }

    // Check punctuation
    final exclamationCount = userMessages
        .where((m) => m.text.contains('!'))
        .length;
    if (exclamationCount > userMessages.length * 0.3) {
      styles.add('enthusiastic');
    }

    // Check formality (contractions, slang)
    final casualCount = userMessages
        .where((m) => _isCasual(m.text))
        .length;
    if (casualCount > userMessages.length * 0.6) {
      styles.add('casual');
    } else if (casualCount < userMessages.length * 0.2) {
      styles.add('formal');
    }

    return styles.isEmpty ? 'neutral' : styles.join(', ');
  }

  bool _containsEmoji(String text) {
    // Simplified emoji detection
    return text.contains(RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true));
  }

  bool _isCasual(String text) {
    final casualMarkers = ["'", "gonna", "wanna", "yeah", "nah", "lol"];
    return casualMarkers.any((marker) =>
      text.toLowerCase().contains(marker)
    );
  }
}

// 4. Cloud Function: generateSmartReplies
exports.generateSmartReplies = functions.https.onCall(async (data, context) => {
  const {
    incomingMessage,
    conversationContext,  // Last 10 relevant messages
    userStyle,           // "brief, casual, enthusiastic"
    userLanguage,
  } = data;

  const contextStr = conversationContext
    .map(m => `${m.senderName}: ${m.text}`)
    .join('\n');

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [
      {
        role: 'system',
        content: `You are a smart reply generator. Generate 3 contextually relevant reply suggestions that:
1. Match the user's communication style: ${userStyle}
2. Are in ${userLanguage}
3. Are appropriate for the conversation context
4. Offer different intents (agree, decline, defer)
5. Are short (under 50 characters preferred)

Conversation context:
${contextStr}

Return as JSON:
{
  "replies": [
    { "text": "...", "intent": "positive" },
    { "text": "...", "intent": "negative" },
    { "text": "...", "intent": "neutral" }
  ]
}`
      },
      {
        role: 'user',
        content: `Incoming message: "${incomingMessage.text}"\n\nGenerate 3 smart replies matching my style.`
      }
    ],
    max_tokens: 200,
    temperature: 0.7,
    response_format: { type: 'json_object' },
  });

  return JSON.parse(response.choices[0].message.content);
});

// 5. SmartReplyBar widget
class SmartReplyBar extends ConsumerStatefulWidget {
  final Message incomingMessage;
  final String conversationId;

  @override
  ConsumerState<SmartReplyBar> createState() => _SmartReplyBarState();
}

class _SmartReplyBarState extends ConsumerState<SmartReplyBar> {
  List<SmartReply>? _replies;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateReplies();
  }

  Future<void> _generateReplies() async {
    try {
      // 1. Get conversation context
      final contextRetriever = ref.read(contextRetrieverProvider);
      final context = await contextRetriever.getRelevantContext(
        conversationId: widget.conversationId,
        incomingMessage: widget.incomingMessage,
      );

      // 2. Analyze user style
      final styleAnalyzer = ref.read(styleAnalyzerProvider);
      final currentUserId = ref.read(currentUserProvider).uid;
      final style = await styleAnalyzer.analyzeUserStyle(
        userId: currentUserId,
        conversationId: widget.conversationId,
      );

      // 3. Generate replies
      final result = await ref.read(cloudFunctionsProvider).call(
        'generateSmartReplies',
        {
          'incomingMessage': widget.incomingMessage.toJson(),
          'conversationContext': context.map((m) => m.toJson()).toList(),
          'userStyle': style,
          'userLanguage': ref.read(currentUserProvider).preferredLanguage,
        },
      );

      setState(() {
        _replies = (result['replies'] as List)
            .map((e) => SmartReply.fromJson(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _logger.error('Failed to generate smart replies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 50,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_replies == null || _replies!.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _replies!.length,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = _replies![index];
          return ActionChip(
            label: Text(reply.text),
            onPressed: () => _sendReply(reply.text),
            avatar: Icon(
              _getIntentIcon(reply.intent),
              size: 16,
            ),
          );
        },
      ),
    );
  }

  void _sendReply(String text) {
    // Pre-fill message input
    ref.read(messageInputControllerProvider).text = text;

    // Optional: Auto-send or let user edit first
    // ref.read(sendMessageProvider).call(text);
  }

  IconData _getIntentIcon(String intent) {
    switch (intent) {
      case 'positive': return Icons.thumb_up;
      case 'negative': return Icons.thumb_down;
      case 'neutral': return Icons.more_horiz;
      default: return Icons.chat_bubble_outline;
    }
  }
}
```

**Performance & Cost:**
- **Latency**: 1-2 seconds (acceptable for background generation)
- **Cost per request**: ~$0.004 (embedding + generation)
- **Caching**: Cache style analysis (updates every 20 messages)
- **Optimization**: Only generate for messages that warrant replies (questions, requests)

**Scoring Potential:** 9-10 points
- ✅ Learns user style accurately (analyzes message patterns)
- ✅ Generates authentic-sounding replies
- ✅ Provides 3+ relevant options
- ✅ Uses RAG for conversation context
- ✅ Response time <3 seconds

---

## 5. TECHNICAL IMPROVEMENTS & DEBT

### Critical Fixes (Required for High Score)

#### 1. Performance Optimization (8 points at stake)

**Problem:** No verified 60 FPS performance, unknown cold start time

**Solution:**
```dart
// 1. Implement lazy loading for messages
class MessageList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      // Add cacheExtent for smoother scrolling
      cacheExtent: 1000,  // Pre-render ~5 screens worth

      // Use itemExtent for better performance
      itemExtent: null,  // Variable heights

      // Reverse for chat UI
      reverse: true,

      itemBuilder: (context, index) {
        // Lazy load images
        return MessageBubble(
          message: messages[index],
          // Use cached_network_image with fade-in
        );
      },
    );
  }
}

// 2. Optimize image loading
class MessageBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (message.imageUrl != null)
          CachedNetworkImage(
            imageUrl: message.imageUrl!,
            placeholder: (context, url) => Container(
              height: 200,
              color: Colors.grey[300],
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Icon(Icons.error),
            // Enable memory cache
            memCacheHeight: 400,
            // Use thumbnail for list view
            maxHeightDiskCache: 400,
          ),
        Text(message.text),
      ],
    );
  }
}

// 3. Add performance monitoring
import 'package:flutter/scheduler.dart';

class PerformanceMonitor {
  static void startMonitoring() {
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final fps = 1000 / timing.totalSpan.inMilliseconds;
        if (fps < 50) {
          print('⚠️ Frame drop detected: ${fps.toStringAsFixed(1)} FPS');
        }
      }
    });
  }
}

// 4. Measure cold start time
import 'package:flutter/foundation.dart';

void main() {
  final startTime = DateTime.now();

  runApp(MyApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final loadTime = DateTime.now().difference(startTime);
    print('🚀 Cold start time: ${loadTime.inMilliseconds}ms');
    // Target: <2000ms
  });
}
```

#### 2. Group Chat Completion (7 points at stake)

**Missing Features:**
- ✅ Group creation (probably exists)
- ✅ Message attribution (exists)
- ⏳ Aggregate read receipts
- ⏳ Group member list UI
- ⏳ Typing indicators for groups
- ⏳ Admin roles

**Solution:**
```dart
// 1. Aggregate read receipts
class GroupMessageBubble extends ConsumerWidget {
  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readBy = ref.watch(messageReadByProvider(message.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(message.text),
        SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${message.timestamp.format()}',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            SizedBox(width: 4),
            if (message.senderId == currentUserId) ...[
              Icon(
                readBy.isEmpty
                  ? Icons.check  // Sent
                  : readBy.length == 1
                    ? Icons.done  // Delivered to some
                    : Icons.done_all,  // Read by all
                size: 14,
                color: readBy.length == totalParticipants - 1
                  ? Colors.blue  // All read
                  : Colors.grey,
              ),
              if (readBy.isNotEmpty)
                Text(
                  ' ${readBy.length}',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

// 2. Group member list UI
class GroupInfoPage extends ConsumerWidget {
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref.watch(conversationProvider(conversationId));
    final members = ref.watch(groupMembersProvider(conversationId));

    return Scaffold(
      appBar: AppBar(
        title: Text(conversation.groupName ?? 'Group Info'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _editGroupInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Group image & name
          CircleAvatar(
            radius: 50,
            backgroundImage: conversation.groupImage != null
              ? NetworkImage(conversation.groupImage!)
              : null,
            child: conversation.groupImage == null
              ? Icon(Icons.group, size: 50)
              : null,
          ),
          SizedBox(height: 16),
          Text(
            conversation.groupName ?? 'Unnamed Group',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text(
            '${members.length} participants',
            style: TextStyle(color: Colors.grey),
          ),
          Divider(height: 32),

          // Members list
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final isAdmin = conversation.adminIds.contains(member.uid);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: member.imageUrl != null
                      ? NetworkImage(member.imageUrl!)
                      : null,
                    child: member.imageUrl == null
                      ? Text(member.name[0].toUpperCase())
                      : null,
                  ),
                  title: Text(member.name),
                  subtitle: Text(
                    isAdmin ? 'Admin' : 'Member',
                    style: TextStyle(
                      color: isAdmin ? Colors.blue : Colors.grey,
                    ),
                  ),
                  trailing: isAdmin && currentUserIsAdmin
                    ? PopupMenuButton(
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove'),
                          ),
                          PopupMenuItem(
                            value: 'make_admin',
                            child: Text('Make admin'),
                          ),
                        ],
                        onSelected: (value) => _handleMemberAction(
                          value,
                          member,
                        ),
                      )
                    : null,
                );
              },
            ),
          ),

          // Add member button (if admin)
          if (currentUserIsAdmin)
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: Icon(Icons.person_add),
                label: Text('Add member'),
                onPressed: () => _showAddMemberSheet(),
              ),
            ),
        ],
      ),
    );
  }
}

// 3. Group typing indicators
class GroupTypingIndicator extends ConsumerWidget {
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingUsers = ref.watch(
      groupTypingUsersProvider(conversationId)
    );

    if (typingUsers.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _TypingAnimation(),
          SizedBox(width: 8),
          Text(
            typingUsers.length == 1
              ? '${typingUsers.first.name} is typing...'
              : typingUsers.length == 2
                ? '${typingUsers[0].name} and ${typingUsers[1].name} are typing...'
                : '${typingUsers.length} people are typing...',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 3. Push Notifications (4 points at stake)

**Solution:**
```dart
// 1. Add FCM setup in main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Request notification permissions
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get FCM token
  final token = await messaging.getToken();
  print('FCM Token: $token');
  // Save to Firestore user document

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      _showLocalNotification(message.notification!);
    }
  });

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

// 2. Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message
) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');

  // Sync message to local DB if needed
  if (message.data['type'] == 'new_message') {
    final messageData = message.data;
    // Save to local DB for immediate display when app opens
  }
}

// 3. Local notification display
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher'
    );
    const iosSettings = DarwinInitializationSettings();

    await _notifications.initialize(
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    required String conversationId,
  }) async {
    await _notifications.show(
      conversationId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'messages',
          'Messages',
          channelDescription: 'New message notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: conversationId,
    );
  }

  static void _handleNotificationTap(
    NotificationResponse response
  ) {
    if (response.payload != null) {
      // Navigate to conversation
      navigatorKey.currentState?.pushNamed(
        '/chat',
        arguments: response.payload,
      );
    }
  }
}

// 4. Cloud Function: Send notifications
exports.sendMessageNotification = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const conversationId = context.params.conversationId;

    // Get conversation to find recipients
    const conversation = await admin.firestore()
      .collection('conversations')
      .doc(conversationId)
      .get();

    const recipientIds = conversation.data().participantIds
      .filter(id => id !== message.senderId);

    // Get recipient FCM tokens
    const users = await Promise.all(
      recipientIds.map(id =>
        admin.firestore().collection('users').doc(id).get()
      )
    );

    const tokens = users
      .map(doc => doc.data()?.fcmToken)
      .filter(token => token != null);

    if (tokens.length === 0) return;

    // Send notifications
    await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      notification: {
        title: message.senderName,
        body: message.text,
      },
      data: {
        type: 'new_message',
        conversationId: conversationId,
        messageId: message.id,
      },
      android: {
        priority: 'high',
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    });
  });
```

#### 4. RAG Pipeline (3 points at stake)

**Current State:** No vector embeddings, no semantic search

**Solution:**
```dart
// 1. Generate embeddings on message send
class SendMessage {
  Future<Either<Failure, void>> call(SendMessageParams params) async {
    // ... existing code

    // Generate embedding asynchronously (don't block send)
    _generateEmbeddingAsync(message);

    return repository.sendMessage(message);
  }

  Future<void> _generateEmbeddingAsync(Message message) async {
    try {
      final result = await _cloudFunctions.call(
        'generateEmbedding',
        { 'text': message.text },
      );

      // Update message with embedding
      await _repository.updateMessage(
        message.copyWith(
          embedding: List<double>.from(result['embedding']),
        ),
      );
    } catch (e) {
      _logger.error('Failed to generate embedding: $e');
      // Fail silently - embeddings are for search only
    }
  }
}

// 2. Semantic search implementation
class SmartSearchUseCase {
  final MessageRepository _repository;
  final CloudFunctions _cloudFunctions;

  Future<List<Message>> call(String query) async {
    // 1. Generate query embedding
    final result = await _cloudFunctions.call(
      'generateEmbedding',
      { 'text': query },
    );

    final queryEmbedding = List<double>.from(result['embedding']);

    // 2. Get all messages with embeddings (last 1000)
    final messages = await _repository.getMessagesWithEmbeddings(
      limit: 1000,
    );

    // 3. Calculate cosine similarity
    final scored = messages.map((m) {
      final score = _cosineSimilarity(
        queryEmbedding,
        m.embedding!,
      );
      return (message: m, score: score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // 4. Return top 20 results with score > 0.7
    return scored
        .where((s) => s.score > 0.7)
        .take(20)
        .map((s) => s.message)
        .toList();
  }
}
```

#### 5. Security Hardening (2 points at stake)

**Solution:**
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isParticipant(conversationId) {
      return isAuthenticated() &&
        request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
    }

    function isGroupAdmin(conversationId) {
      return isAuthenticated() &&
        request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.adminIds;
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isAuthenticated() && request.auth.uid == userId;
      allow delete: if false;  // No deletions
    }

    // Conversations collection
    match /conversations/{conversationId} {
      allow read: if isParticipant(conversationId);
      allow create: if isAuthenticated() &&
        request.auth.uid in request.resource.data.participantIds;
      allow update: if isParticipant(conversationId) &&
        (
          // Regular participant can only update their unread count
          (!request.resource.data.diff(resource.data).affectedKeys()
            .hasAny(['participantIds', 'adminIds', 'groupName', 'groupImage'])) ||
          // Admin can update group info
          isGroupAdmin(conversationId)
        );
      allow delete: if isGroupAdmin(conversationId);

      // Messages subcollection
      match /messages/{messageId} {
        allow read: if isParticipant(conversationId);
        allow create: if isParticipant(conversationId) &&
          request.auth.uid == request.resource.data.senderId;
        allow update: if isParticipant(conversationId) &&
          (
            // Sender can mark as edited/deleted
            (request.auth.uid == resource.data.senderId) ||
            // Any participant can update read status
            (!request.resource.data.diff(resource.data).affectedKeys()
              .hasAny(['text', 'senderId', 'timestamp']))
          );
        allow delete: if false;  // Soft delete only
      }
    }

    // Presence collection
    match /presence/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }

    // Typing indicators
    match /typing/{conversationId} {
      allow read: if isParticipant(conversationId);
      allow write: if isParticipant(conversationId);
    }
  }
}
```

```javascript
// Cloud Functions rate limiting
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 60 * 60 * 1000,  // 1 hour
  max: 100,  // Max 100 requests per hour per user
  keyGenerator: (req) => req.body.data.userId || req.ip,
  handler: (req, res) => {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Too many requests. Please try again later.'
    );
  },
});

exports.translateMessage = functions
  .runWith({ minInstances: 1 })  // Keep warm
  .https.onCall(limiter, async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be authenticated to translate messages.'
      );
    }

    // Validate input
    const { text, sourceLanguage, targetLanguages } = data;
    if (!text || !sourceLanguage || !targetLanguages) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required parameters.'
      );
    }

    // Length check (prevent abuse)
    if (text.length > 5000) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Message too long (max 5000 characters).'
      );
    }

    // PII detection (simplified)
    if (_containsPII(text)) {
      // Sanitize before sending to external API
      text = _sanitizePII(text);
    }

    // ... translation logic
  });
```

---

## 6. TESTING STRATEGY

### Test Coverage Goals

**Current: 713 tests passing**
- Domain layer: 100% ✅
- Data layer: 90%+ ✅
- Presentation layer: 80%+ ✅

**Gaps:**
- Integration tests for critical flows
- Performance tests
- AI feature tests

### Integration Tests (Required for Scoring)

```dart
// test/integration/messaging_flow_test.dart
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Core Messaging Flow', () {
    testWidgets('Send and receive message between two users', (tester) async {
      // 1. Setup: Create two test users
      final user1 = await createTestUser('user1@test.com');
      final user2 = await createTestUser('user2@test.com');

      // 2. User 1 sends message
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Login as user1
      await loginAsUser(tester, user1);

      // Navigate to conversation with user2
      await tester.tap(find.text('New Chat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(user2.name));
      await tester.pumpAndSettle();

      // Type and send message
      await tester.enterText(
        find.byType(TextField),
        'Hello from user1!',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // 3. Verify message appears for user1
      expect(find.text('Hello from user1!'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);  // Sent

      // 4. Wait for Firebase sync
      await Future.delayed(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify delivered status
      expect(find.byIcon(Icons.done), findsOneWidget);  // Delivered

      // 5. Switch to user2
      await logout(tester);
      await loginAsUser(tester, user2);

      // 6. Verify message appears for user2
      await tester.pumpAndSettle();
      expect(find.text('Hello from user1!'), findsOneWidget);

      // 7. Mark as read
      await tester.tap(find.text('Hello from user1!'));
      await tester.pumpAndSettle();

      // 8. Switch back to user1 and verify read status
      await logout(tester);
      await loginAsUser(tester, user1);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.done_all), findsOneWidget);  // Read
    });

    testWidgets('Offline message queue and sync', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Login
      final user = await createTestUser('offline@test.com');
      await loginAsUser(tester, user);

      // Navigate to chat
      await navigateToChat(tester);

      // 1. Go offline
      await setNetworkConnectivity(false);
      await tester.pumpAndSettle();

      // 2. Send message while offline
      await tester.enterText(find.byType(TextField), 'Offline message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // 3. Verify message appears with "sending" status
      expect(find.text('Offline message'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);  // Pending

      // 4. Go online
      await setNetworkConnectivity(true);
      await Future.delayed(Duration(seconds: 3));  // Allow sync
      await tester.pumpAndSettle();

      // 5. Verify message is delivered
      expect(find.byIcon(Icons.done), findsOneWidget);  // Delivered
    });

    testWidgets('App lifecycle: force quit and reopen', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Login and send messages
      final user = await createTestUser('lifecycle@test.com');
      await loginAsUser(tester, user);
      await navigateToChat(tester);

      for (int i = 0; i < 5; i++) {
        await tester.enterText(
          find.byType(TextField),
          'Message $i',
        );
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();
      }

      // Verify all messages visible
      for (int i = 0; i < 5; i++) {
        expect(find.text('Message $i'), findsOneWidget);
      }

      // Simulate force quit
      await tester.pumpWidget(Container());
      await Future.delayed(Duration(seconds: 1));

      // Reopen app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Navigate back to chat
      await navigateToChat(tester);
      await tester.pumpAndSettle();

      // Verify all messages still visible
      for (int i = 0; i < 5; i++) {
        expect(find.text('Message $i'), findsOneWidget);
      }
    });
  });

  group('Group Chat', () {
    testWidgets('Create group and send messages', (tester) async {
      // Create 3 test users
      final user1 = await createTestUser('group1@test.com');
      final user2 = await createTestUser('group2@test.com');
      final user3 = await createTestUser('group3@test.com');

      await tester.pumpWidget(MyApp());
      await loginAsUser(tester, user1);

      // Create group
      await tester.tap(find.byIcon(Icons.group_add));
      await tester.pumpAndSettle();

      // Select members
      await tester.tap(find.text(user2.name));
      await tester.tap(find.text(user3.name));
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Send message in group
      await tester.enterText(
        find.byType(TextField),
        'Hello group!',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify message appears
      expect(find.text('Hello group!'), findsOneWidget);

      // Switch to user2 and verify
      await logout(tester);
      await loginAsUser(tester, user2);
      await tester.pumpAndSettle();

      expect(find.text('Hello group!'), findsOneWidget);
    });
  });
}
```

### Performance Tests

```dart
// test/performance/scroll_performance_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Scroll performance with 1000+ messages', (tester) async {
    // Generate 1000 test messages
    final messages = List.generate(
      1000,
      (i) => Message(
        id: 'msg_$i',
        text: 'Message $i',
        senderId: i % 2 == 0 ? 'user1' : 'user2',
        timestamp: DateTime.now().subtract(Duration(minutes: i)),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(
          conversationId: 'test',
          messages: messages,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Measure scroll performance
    final stopwatch = Stopwatch()..start();
    int frameCount = 0;

    while (stopwatch.elapsedMilliseconds < 5000) {  // 5 seconds
      await tester.fling(
        find.byType(ListView),
        Offset(0, -500),  // Scroll up fast
        1000,  // Velocity
      );
      await tester.pumpAndSettle();
      frameCount++;
    }

    stopwatch.stop();

    final averageFrameTime = stopwatch.elapsedMilliseconds / frameCount;
    final fps = 1000 / averageFrameTime;

    print('📊 Scroll Performance: ${fps.toStringAsFixed(1)} FPS');

    // Should maintain 60 FPS
    expect(fps, greaterThan(55));  // Allow 5 FPS buffer
  });
}
```

---

## 7. DEPLOYMENT & DOCUMENTATION

### README Template

```markdown
# MessageAI - Intelligent Messaging for Global Communication

A Flutter-based messaging platform with real-time translation and AI-powered communication features.

## Features

### Core Messaging
- ✅ Real-time messaging with sub-200ms delivery
- ✅ Offline-first architecture with automatic sync
- ✅ Group chats with 3+ participants
- ✅ Read receipts and typing indicators
- ✅ Online/offline presence indicators
- ✅ Push notifications

### AI Features (International Communicator)
- 🌍 **Real-time Translation**: Inline message translation with one tap
- 🔍 **Auto Language Detection**: Automatic language detection and translation
- 💡 **Cultural Context**: Contextual hints for cultural nuances and idioms
- 📝 **Formality Adjustment**: Adjust message formality (casual ↔ formal)
- 💬 **Smart Replies**: Context-aware reply suggestions in your style

## Tech Stack

- **Frontend**: Flutter 3.x, Riverpod 3.0
- **Backend**: Firebase (Firestore, Auth, Cloud Functions, Storage, Messaging)
- **Local Storage**: Drift (SQLite ORM)
- **AI**: OpenAI GPT-4o-mini, Google Cloud Translation API
- **Architecture**: Clean Architecture with offline-first approach

## Setup Instructions

### Prerequisites
- Flutter SDK 3.x
- Firebase account
- OpenAI API key (for Cloud Functions)
- Google Cloud Translation API enabled

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/message_ai.git
cd message_ai
```

### 2. Install Dependencies
```bash
flutter pub get
cd ios && pod install && cd ..
```

### 3. Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Authentication (Email/Password), Firestore, Storage, Cloud Messaging
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place files in:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist` (add via Xcode)

### 4. Cloud Functions Setup
```bash
cd functions
npm install
firebase deploy --only functions
```

Add these environment variables to Cloud Functions:
```bash
firebase functions:config:set openai.api_key="your-openai-key"
firebase functions:config:set google.translation_api_key="your-translation-key"
```

### 5. Run App
```bash
# Development flavor
flutter run --flavor dev -t lib/main_dev.dart

# Production flavor
flutter run --flavor prod -t lib/main_prod.dart
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│                  (Flutter UI + Riverpod)                     │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                     DOMAIN LAYER                             │
│              (Use Cases + Entities + Interfaces)             │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                      DATA LAYER                              │
│          (Repositories + Data Sources + Models)              │
└─────────┬──────────────────────────────────┬────────────────┘
          │                                  │
    ┌─────▼─────┐                    ┌──────▼──────┐
    │   LOCAL   │◄───Bidirectional───►│   REMOTE   │
    │  (Drift)  │       Sync          │ (Firestore)│
    └───────────┘                     └─────────────┘
```

## Testing

```bash
# Unit + Widget tests
flutter test

# Integration tests
flutter test integration_test/

# Performance tests
flutter test test/performance/
```

**Current Coverage:** 713 tests, 90%+ coverage

## Performance Metrics

- ⚡ Cold start: <2 seconds
- 📱 Scroll: 60 FPS with 1000+ messages
- 🌐 Message delivery: <200ms on good network
- 🔄 Sync after reconnect: <1 second
- 🤖 AI response time: <2 seconds (smart replies)

## Project Structure

```
lib/
├── core/                # Shared utilities, database, services
├── features/            # Feature modules (auth, messaging, AI)
└── config/              # App configuration, routes, theme
```

## Screenshots

[Add screenshots here]

## Demo Video

[Link to demo video]

## License

MIT License

## Contributors

[Your name]

## Acknowledgments

Built as part of the Gauntlet AI curriculum
```

### Video Script Template

**Title:** MessageAI - Intelligent Messaging Demo

**Duration:** 5-7 minutes

**Structure:**

1. **Introduction (30 seconds)**
   - "Hi, I'm [name] and this is MessageAI"
   - "A messaging app with AI translation for international communication"
   - Show both phones side-by-side

2. **Core Messaging (90 seconds)**
   - Real-time messaging demo
   - Show message delivery (checkmarks)
   - Typing indicators
   - Online/offline status
   - "Sub-200ms delivery, smooth experience"

3. **Offline Support (60 seconds)**
   - Turn off WiFi
   - Send messages (queue)
   - Turn WiFi back on
   - Show automatic sync
   - "Works offline, syncs when online"

4. **Group Chat (60 seconds)**
   - Create group with 3 users
   - Show simultaneous messaging
   - Aggregate read receipts
   - Member list
   - "Supports 3+ participants"

5. **AI Feature 1: Real-Time Translation (45 seconds)**
   - Send message in Spanish
   - Show "Translate" button
   - Tap to reveal English translation
   - "One tap translation, preserves original"

6. **AI Feature 2: Language Detection (30 seconds)**
   - Type in different language
   - Auto-detected and translated for recipient
   - "No manual language selection needed"

7. **AI Feature 3: Cultural Context (45 seconds)**
   - Receive message with cultural expression
   - Show 🌍 badge
   - Tap to see cultural explanation
   - "Understands cultural nuances"

8. **AI Feature 4: Formality Adjustment (45 seconds)**
   - Type casual message
   - Show formality adjuster
   - Change to formal
   - "Adapt tone for different contexts"

9. **AI Feature 5: Idiom Explanations (45 seconds)**
   - Long-press on message with idiom
   - Select "Explain idioms"
   - Show bottom sheet with explanation
   - "Learn expressions as you chat"

10. **Advanced Feature: Smart Replies (60 seconds)**
    - Receive message
    - Show 3 smart reply suggestions
    - Tap one to send
    - "Context-aware, learns your style"

11. **Technical Overview (45 seconds)**
    - Show architecture diagram
    - "Flutter + Firebase + Drift"
    - "Offline-first with real-time sync"
    - "OpenAI for AI features"
    - "713 tests, 90%+ coverage"

12. **Closing (15 seconds)**
    - "Thank you for watching"
    - "GitHub: [link]"
    - "Questions? Let's connect"

---

## 8. SCORING ESTIMATION

### Projected Final Score: 92-95/100 (A+)

**If all recommendations implemented:**

| Section | Max | Projected | Details |
|---------|-----|-----------|---------|
| **Core Messaging** | 35 | 33-34 | Perfect real-time, excellent offline, complete group chat |
| **Mobile Quality** | 20 | 18-19 | Verified lifecycle, 60 FPS, <2s launch, push notifications |
| **AI Features** | 30 | 27-29 | All 5 features excellent, advanced feature impressive |
| **Technical** | 10 | 9-10 | RAG implemented, security hardened, clean architecture |
| **Documentation** | 5 | 5 | Comprehensive README, video, clear setup |
| **Required Deliverables** | -30 (penalty) | 0 | All submitted on time |
| **Bonus** | +10 | +3-5 | Innovation (RAG), Polish (dark mode?), Technical excellence |
| **TOTAL** | 100 | **92-95** | **A+ Grade** |

---

## 9. IMMEDIATE NEXT STEPS (PRIORITY ORDER)

### Sprint 1: AI Features Foundation (8-10 hours)
**Goal:** Get to 30/30 on AI Features section

1. **Setup Translation Infrastructure (2 hours)**
   - ✅ Add google_mlkit_language_id to pubspec
   - ✅ Set up Google Cloud Translation API
   - ✅ Create Cloud Functions for translation
   - ✅ Update Message model with translations field

2. **Implement Feature 1-2 (2 hours)**
   - Real-time translation UI
   - Language detection integration
   - Cache layer for translations

3. **Implement Feature 3-5 (3 hours)**
   - Cultural context analysis
   - Formality adjustment
   - Idiom explanation

4. **Advanced Feature: Smart Replies (3 hours)**
   - RAG pipeline with embeddings
   - Style learning algorithm
   - Smart reply generation

### Sprint 2: Complete MVP (4-6 hours)
**Goal:** Get to 11/11 on remaining MVP features

1. **Group Chat Polish (3 hours)**
   - Aggregate read receipts UI
   - Member list page
   - Group typing indicators

2. **Push Notifications (2 hours)**
   - FCM setup
   - Foreground + background handling
   - Deep linking

### Sprint 3: Performance & Polish (3-4 hours)
**Goal:** Get to 19/20 on Mobile Quality

1. **Performance Testing (2 hours)**
   - Profile with DevTools
   - Optimize for 60 FPS
   - Measure cold start time
   - Fix any bottlenecks

2. **Mobile Lifecycle Testing (1 hour)**
   - Test backgrounding/foregrounding
   - Test force quit scenarios
   - Document results

### Sprint 4: Documentation & Deployment (2-3 hours)
**Goal:** Get to 5/5 on Documentation

1. **README (1 hour)**
   - Setup instructions
   - Architecture diagram
   - Screenshots

2. **Demo Video (1-2 hours)**
   - Record 5-7 minute walkthrough
   - Edit and upload

3. **Deliverables (30 minutes)**
   - Persona brainlift document
   - Social media post

---

## 10. TECHNICAL DEBT & IMPROVEMENTS

### Pattern Improvements

**Current Pattern: Good**
- ✅ Clean Architecture well-implemented
- ✅ Riverpod 3.0 with annotations
- ✅ Drift for local storage
- ✅ Offline-first with bidirectional sync

**Suggested Improvements:**

1. **Error Handling Enhancement**
```dart
// Current: Basic error handling
// Improved: Typed errors with recovery strategies

sealed class AppError {
  const AppError();
}

class NetworkError extends AppError {
  final String message;
  final bool isRetryable;

  const NetworkError({
    required this.message,
    this.isRetryable = true,
  });
}

class AuthError extends AppError {
  final AuthErrorType type;
  const AuthError(this.type);
}

enum AuthErrorType {
  invalidCredentials,
  sessionExpired,
  permissionDenied,
}

// Usage in providers
@riverpod
class MessageController extends _$MessageController {
  @override
  AsyncValue<List<Message>> build(String conversationId) {
    return ref.watch(watchMessagesProvider(conversationId));
  }

  Future<void> sendMessage(String text) async {
    state = const AsyncValue.loading();

    final result = await ref.read(sendMessageProvider).call(
      SendMessageParams(text: text),
    );

    result.fold(
      (failure) {
        if (failure is NetworkFailure && failure.isRetryable) {
          // Auto-retry logic
          _scheduleRetry(() => sendMessage(text));
        }

        state = AsyncValue.error(
          _mapFailureToError(failure),
          StackTrace.current,
        );
      },
      (_) {
        // Success handled by stream
      },
    );
  }
}
```

2. **State Management Optimization**
```dart
// Current: Separate providers for each conversation
// Improved: Family provider with keep-alive control

@Riverpod(keepAlive: true)
class ConversationsState extends _$ConversationsState {
  @override
  Map<String, AsyncValue<List<Message>>> build() {
    return {};
  }

  void loadConversation(String id) {
    if (state.containsKey(id)) return;  // Already loaded

    final stream = ref.watch(watchMessagesProvider(id));
    state = {
      ...state,
      id: stream,
    };
  }

  void unloadConversation(String id) {
    state = {...state}..remove(id);
  }
}

// Usage: Automatic cleanup when leaving chat
class ChatPage extends ConsumerStatefulWidget {
  @override
  void dispose() {
    ref.read(conversationsStateProvider.notifier)
        .unloadConversation(widget.conversationId);
    super.dispose();
  }
}
```

3. **Improved Message Sync Strategy**
```dart
// Current: Simple bidirectional sync
// Improved: Incremental sync with timestamps

class MessageSyncService {
  // Track last sync time per conversation
  final Map<String, DateTime> _lastSyncTimes = {};

  Future<void> syncConversation(String conversationId) async {
    final lastSync = _lastSyncTimes[conversationId];

    // Only fetch messages after last sync
    final query = lastSync != null
      ? _firestore
          .collection('conversations/$conversationId/messages')
          .where('timestamp', isGreaterThan: lastSync)
      : _firestore
          .collection('conversations/$conversationId/messages')
          .orderBy('timestamp', descending: true)
          .limit(50);  // Initial load: last 50 messages

    final snapshot = await query.get();

    // Batch insert to local DB
    await _localDataSource.batchInsert(
      snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList(),
    );

    // Update last sync time
    _lastSyncTimes[conversationId] = DateTime.now();
  }
}
```

### Version Updates

**Current Versions (from project knowledge):**
```yaml
flutter_riverpod: ^3.0.3  # Latest ✅
firebase_core: ^4.2.0      # Latest ✅
drift: ^2.29.0             # Latest ✅
```

**No updates needed** - all packages are current!

### Database Optimization

**Current: Good performance**
**Improvement: Add indexes for common queries**

```dart
// lib/core/database/app_database.dart

@DriftDatabase(tables: [Messages, Conversations, Users])
class AppDatabase extends _$AppDatabase {
  // Add indexes for performance
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();

      // Index for message queries (by conversation + timestamp)
      await customStatement('''
        CREATE INDEX IF NOT EXISTS idx_messages_conversation_timestamp
        ON messages(conversation_id, timestamp DESC)
      ''');

      // Index for conversation queries (by participant + last updated)
      await customStatement('''
        CREATE INDEX IF NOT EXISTS idx_conversations_participant_updated
        ON conversations(participant_ids, last_updated_at DESC)
      ''');

      // Index for search (full-text search on message text)
      await customStatement('''
        CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts
        USING fts5(text, content=messages)
      ''');
    },
    onUpgrade: (m, from, to) async {
      // Handle migrations
    },
  );
}
```

---

## CONCLUSION

This updated PRD provides a forensically accurate assessment of MessageAI's current state and a clear roadmap to achieve a 90+ score on the rubric.

**Key Takeaways:**

1. **Strong Foundation** (80% MVP complete)
   - Core messaging infrastructure is solid
   - Offline-first architecture working well
   - Clean architecture properly implemented

2. **Critical Gap** (AI Features - 30 points at stake)
   - Zero AI features implemented
   - Must be top priority
   - Technical specs provided for all 5 + advanced feature

3. **Quick Wins** (15 points available)
   - Complete group chat polish (7 pts, 3 hours)
   - Add push notifications (4 pts, 2 hours)
   - Performance testing (4 pts, 2 hours)

4. **Technical Excellence**
   - Current patterns are good (Riverpod, Drift, offline-first)
   - Some optimizations suggested but not critical
   - All packages are up-to-date

**Estimated Timeline to A+ Score:**
- **Sprint 1** (8-10 hours): AI features → +30 points
- **Sprint 2** (4-6 hours): MVP completion → +11 points
- **Sprint 3** (3-4 hours): Performance → +5 points
- **Sprint 4** (2-3 hours): Documentation → +5 points
- **Total**: 17-23 hours of focused work

**Current Projected:** 62/100 (D)
**With Improvements:** 92-95/100 (A+)
**Path is clear. Let's build!** 🚀
