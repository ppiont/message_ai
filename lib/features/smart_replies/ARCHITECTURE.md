# Smart Replies Feature - Architecture Overview

## Layer Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Providers (embedding_providers.dart)                 │  │
│  │  - embeddingServiceProvider                           │  │
│  │  - embeddingGeneratorProvider                         │  │
│  │  - semanticSearchServiceProvider         [NEW]       │  │
│  │  - searchRelevantContextProvider          [NEW]       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Services (domain/services/)                          │  │
│  │  - EmbeddingGenerator                                 │  │
│  │  - SemanticSearchService             [NEW]           │  │
│  │  - UserStyleAnalyzer                                  │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Entities (domain/entities/)                          │  │
│  │  - UserCommunicationStyle                             │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Services (data/services/)                            │  │
│  │  - EmbeddingService                                   │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   EXTERNAL SERVICES                          │
│  - Cloud Function: generate_embeddings                       │
│  - MessageRepository (Messaging Feature)                     │
│  - Drift Database (Local Storage)                            │
└─────────────────────────────────────────────────────────────┘
```

## Semantic Search Data Flow

### 1. Embedding Generation Flow (Background)
```
Message Created
    ↓
EmbeddingGenerator.generateForMessage()
    ↓
EmbeddingService.generateEmbedding() → Cloud Function
    ↓
Message.copyWith(embedding: [...])
    ↓
MessageLocalDataSource.updateMessage() → Drift
    ↓
MessageRepository.updateMessage() → Firestore (async)
```

### 2. Semantic Search Flow
```
Incoming Message (with embedding)
    ↓
SemanticSearchService.searchRelevantContext()
    ↓
MessageRepository.getMessages(limit: 100) → Drift (FAST)
    ↓
Filter: messages.where(msg => msg.embedding != null)
    ↓
Calculate: cosineSimilarity(incoming.embedding, msg.embedding)
    ↓
Calculate: recencyBoost(msg.timestamp)
    ↓
Calculate: finalScore = similarity + recencyBoost
    ↓
Sort: by finalScore (descending)
    ↓
Return: top N messages (default: 10)
```

## Component Interactions (Subtask 132.3)

```
┌──────────────────────────────────────────────────────────────┐
│                    UI Widget / Use Case                       │
│                                                               │
│  final messages = await ref.read(                            │
│    searchRelevantContextProvider(conversationId, message)    │
│  );                                                           │
└────────────────────────┬─────────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────────┐
│         searchRelevantContextProvider (Riverpod)            │
│                                                              │
│  - Type: FutureProvider<List<Message>>                      │
│  - Auto-disposes after use                                  │
│  - Caches result per (conversationId, message, limit)       │
└────────────────────────┬───────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────────┐
│            SemanticSearchService (Domain)                   │
│                                                              │
│  searchRelevantContext(conversationId, message, limit)      │
│  ├─ Fetch messages via MessageRepository                   │
│  ├─ Filter to messages with embeddings                      │
│  ├─ Calculate cosine similarity for each                    │
│  ├─ Apply recency bias                                      │
│  ├─ Sort by final score                                     │
│  └─ Return top N results                                    │
└────────────────────────┬───────────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────────────┐
│           MessageRepository (Messaging Feature)             │
│                                                              │
│  getMessages(conversationId, limit: 100)                    │
│  └─ MessageLocalDataSource → Drift (OFFLINE-FIRST)         │
└─────────────────────────────────────────────────────────────┘
```

## Cosine Similarity Algorithm

### Mathematical Formula
```
Given two vectors a and b:

         a · b
cos(θ = ─────────
       ||a|| ||b||

Where:
- a · b = dot product = Σ(aᵢ × bᵢ)
- ||a|| = norm of a = √(Σ(aᵢ²))
- ||b|| = norm of b = √(Σ(bᵢ²))
```

### Single-Pass Implementation
```dart
double _cosineSimilarity(List<double> a, List<double> b) {
  var dotProduct = 0.0;
  var normA = 0.0;
  var normB = 0.0;

  // Single loop calculates all three values
  for (var i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];  // Σ(aᵢ × bᵢ)
    normA += a[i] * a[i];       // Σ(aᵢ²)
    normB += b[i] * b[i];       // Σ(bᵢ²)
  }

  return dotProduct / (sqrt(normA) * sqrt(normB));
}
```

### Recency Bias Formula
```
finalScore = cosineSimilarity + recencyBoost

Where recencyBoost:
  - Last 5 minutes:  +0.1
  - Last 1 hour:     +0.05
  - Older:           +0.0
```

## Performance Characteristics

### Time Complexity
- **O(n × m)** where:
  - n = number of messages with embeddings (~50)
  - m = embedding dimension (1536 for text-embedding-3-small)

### Typical Performance
```
Messages:     50
Embeddings:   1536 dimensions
Operations:   50 × 1536 = 76,800
Time:         <50ms (typical)
Target:       <100ms (goal)
```

### Space Complexity
- **O(n)** for storing scored messages during ranking
- No significant memory allocations

## Integration with Future Subtasks

### Subtask 132.4: Smart Reply Generator
```dart
// Will use semantic search for RAG context
class SmartReplyGenerator {
  Future<List<String>> generateReplies(Message incoming) async {
    // 1. Get relevant context via semantic search
    final context = await semanticSearch.searchRelevantContext(
      conversationId,
      incoming,
      limit: 10,
    );

    // 2. Build prompt with context
    final prompt = buildPromptWithContext(context, incoming);

    // 3. Call LLM
    return callLLM(prompt);
  }
}
```

### Subtask 132.5: User Style Analyzer Integration
```dart
// Can enhance relevance scoring with style similarity
finalScore = cosineSimilarity
           + recencyBoost
           + styleMatchBoost  // NEW
```

## Edge Case Handling Matrix

| Case                           | Detection                  | Behavior                      |
|--------------------------------|----------------------------|-------------------------------|
| No embedding on incoming msg   | `embedding == null`        | Return recent 10 messages     |
| No messages with embeddings    | `filtered.isEmpty`         | Return recent 10 messages     |
| Empty conversation             | `messages.isEmpty`         | Return empty list             |
| Fewer than limit messages      | `messages.length < limit`  | Return all available          |
| Repository error               | `Either.Left(failure)`     | Return empty list (logged)    |
| Vector length mismatch         | `a.length != b.length`     | Return 0.0 similarity         |
| Zero vector                    | `norm == 0`                | Return 0.0 similarity         |

## Offline-First Guarantee

The semantic search service is **100% offline-compatible**:

1. ✅ **No network calls**: All data from local Drift database
2. ✅ **Fast queries**: Drift queries are ~1-5ms
3. ✅ **Computation only**: Cosine similarity is pure computation
4. ✅ **Graceful degradation**: Falls back to recent messages if no embeddings

## Future Enhancements

### Planned (Not in Current Scope)
- [ ] Hybrid search (semantic + keyword)
- [ ] Configurable recency bias weights
- [ ] Sender-based filtering
- [ ] Time range filtering
- [ ] Result caching layer
- [ ] A/B testing for relevance scoring

### Research Ideas
- [ ] BM25 + semantic hybrid search
- [ ] User feedback-based reranking
- [ ] Dynamic recency bias based on conversation pace
- [ ] Multi-vector embeddings for different aspects

---

**Last Updated**: 2025-10-23
**Architecture Version**: 1.0
**Status**: Implemented
