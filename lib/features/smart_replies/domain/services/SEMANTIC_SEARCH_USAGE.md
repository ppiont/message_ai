# Semantic Search Service Usage

## Overview

The `SemanticSearchService` enables RAG-based smart replies by finding the most semantically relevant messages in a conversation history using cosine similarity on vector embeddings.

## Performance

- **Target**: <100ms for searching 50-100 messages
- **Algorithm**: Single-pass cosine similarity with recency bias
- **Offline-first**: Works entirely with local Drift data

## Basic Usage

### Using Providers (Recommended)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/smart_replies/presentation/providers/embedding_providers.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationId = 'conversation_123';
    final incomingMessage = Message(...); // The message to find context for

    // Use the FutureProvider to search for relevant context
    final relevantMessagesAsync = ref.watch(
      searchRelevantContextProvider(
        conversationId,
        incomingMessage,
        limit: 10, // Optional: defaults to 10
      ),
    );

    return relevantMessagesAsync.when(
      data: (messages) {
        // Use the relevant messages for RAG context
        return Text('Found ${messages.length} relevant messages');
      },
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### Direct Service Usage

```dart
import 'package:message_ai/features/smart_replies/domain/services/semantic_search_service.dart';

// Get the service instance from a provider
final searchService = ref.read(semanticSearchServiceProvider);

// Search for relevant context
final relevantMessages = await searchService.searchRelevantContext(
  conversationId,
  incomingMessage,
  limit: 10, // Optional: defaults to 10
);

// Use the results
for (final msg in relevantMessages) {
  print('Relevant: ${msg.text}');
}
```

## How It Works

### 1. Embedding Generation
Messages must have embeddings generated first (handled by `EmbeddingGenerator`):
- Automatic for new messages when sent
- Background processing for historical messages

### 2. Cosine Similarity Calculation
The service calculates similarity between the incoming message embedding and each stored embedding:

```
similarity = dot_product(a, b) / (norm(a) * norm(b))
```

Result ranges from 0.0 (completely different) to 1.0 (identical).

### 3. Recency Bias
Recent messages get a boost to prefer recent context:
- Last 5 minutes: +0.1
- Last hour: +0.05
- Older: no boost

### 4. Final Ranking
Messages are ranked by: `finalScore = similarityScore + recencyBoost`

## Edge Cases

The service handles various edge cases gracefully:

### Incoming message has no embedding
→ Returns most recent 10 messages as fallback

### No messages with embeddings in conversation
→ Returns most recent 10 messages as fallback

### Empty conversation
→ Returns empty list

### Fewer than limit messages available
→ Returns all available messages

### Repository errors
→ Returns empty list (logged but doesn't throw)

## Integration with Smart Replies

Example RAG-based smart reply generation:

```dart
Future<List<String>> generateSmartReplies({
  required String conversationId,
  required Message incomingMessage,
}) async {
  // 1. Get relevant context using semantic search
  final relevantMessages = await ref.read(
    searchRelevantContextProvider(
      conversationId,
      incomingMessage,
      limit: 10,
    ).future,
  );

  // 2. Build context string from relevant messages
  final context = relevantMessages
      .map((msg) => '${msg.senderId}: ${msg.text}')
      .join('\n');

  // 3. Call LLM with context + incoming message
  final prompt = '''
Context (relevant conversation history):
$context

Incoming message: ${incomingMessage.text}

Generate 3 appropriate reply suggestions.
''';

  // 4. Return generated replies
  return callLLM(prompt);
}
```

## Performance Optimization

### Search Pool Size
The service searches the last 100 messages by default. This can be adjusted via the `_searchPoolSize` constant.

### Limiting Results
Always specify a reasonable limit (default: 10) to avoid processing too many results.

### Caching
Consider caching search results for identical incoming messages if needed.

## Debugging

Enable debug mode to see detailed logs:

```dart
// Logs include:
// - Number of messages searched
// - Number with embeddings
// - Top result scores
// - Edge cases encountered

// Example output:
// SemanticSearchService: Searching for relevant context in conversation abc123
// SemanticSearchService: Found 45 messages with embeddings (from 87 total)
// SemanticSearchService: Top result - similarity: 0.847, recency boost: 0.100, final: 0.947
```

## Future Enhancements

Potential improvements:
- Support for filtering by sender or time range
- Configurable recency bias weights
- Caching layer for repeated searches
- Support for hybrid search (semantic + keyword)
