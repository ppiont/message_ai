# Smart Replies Feature

This feature provides AI-powered smart reply suggestions that match the user's communication style.

## User Communication Style Learning (Subtask 132.2)

### Overview

The User Communication Style Learning Algorithm analyzes a user's message history to learn their unique communication patterns. This enables AI features (like smart replies) to generate responses that match the user's natural writing style.

### Components

#### 1. Domain Entity: `UserCommunicationStyle`

Location: `lib/features/smart_replies/domain/entities/user_communication_style.dart`

Represents a user's learned communication style with these metrics:

- **averageMessageLength**: Average character count per message
- **emojiUsageRate**: Percentage of messages containing emojis (0.0-1.0)
- **exclamationRate**: Percentage of messages with exclamation marks (0.0-1.0)
- **casualityScore**: How casual the language is (0.0=formal, 0.5=neutral, 1.0=casual)
- **styleDescription**: Human-readable style (e.g., "brief, casual, enthusiastic")
- **primaryLanguage**: ISO language code (e.g., 'en', 'es')
- **lastAnalyzedAt**: Timestamp for cache invalidation

**Key Methods:**
- `toJson()`: Converts to GPT-friendly format for prompt injection
- `defaultStyle()`: Factory for new users with <5 messages

#### 2. Domain Service: `UserStyleAnalyzer`

Location: `lib/features/smart_replies/domain/services/user_style_analyzer.dart`

Analyzes message history to determine communication patterns.

**Main Method:**
```dart
Future<UserCommunicationStyle> analyzeUserStyle(
  String userId,
  String conversationId,
)
```

**Performance:**
- Target: <500ms for 20 messages
- Single database query
- Single-pass analysis algorithm
- Returns default style if <5 messages

**Analysis Algorithm:**
1. Fetches last 20 user messages from conversation
2. Single-pass analysis calculates:
   - Average length (excludes messages <5 chars)
   - Emoji usage rate (Unicode emoji detection)
   - Exclamation rate
   - Casualty score (contractions + slang detection)
   - Primary language (most frequent)
3. Generates style description

**Casual Language Markers:**
- Contractions: don't, gonna, wanna, gotta, ain't, etc.
- Slang: lol, omg, tbh, idk, nah, yeah, etc.

#### 3. Riverpod Providers

Location: `lib/features/smart_replies/presentation/providers/style_analyzer_providers.dart`

**Service Provider:**
```dart
@riverpod
UserStyleAnalyzer userStyleAnalyzer(Ref ref)
```

**Cache Provider:**
```dart
@riverpod
class UserStyleCache extends _$UserStyleCache
```

Methods:
- `get(userId, conversationId)`: Retrieve cached style
- `put(userId, conversationId, style)`: Store in cache
- `invalidate(userId, conversationId)`: Force re-analysis
- `clear()`: Clear all cache

**Analysis Provider:**
```dart
@riverpod
Future<UserCommunicationStyle> analyzeUserStyle(
  Ref ref, {
  required String userId,
  required String conversationId,
})
```

### Usage Example

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/smart_replies/presentation/providers/style_analyzer_providers.dart';

class UserStyleWidget extends ConsumerWidget {
  final String userId;
  final String conversationId;

  const UserStyleWidget({
    required this.userId,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styleAsync = ref.watch(
      analyzeUserStyleProvider(
        userId: userId,
        conversationId: conversationId,
      ),
    );

    return styleAsync.when(
      data: (style) => Column(
        children: [
          Text('Style: ${style.styleDescription}'),
          Text('Language: ${style.primaryLanguage}'),
          Text('Avg Length: ${style.averageMessageLength.toStringAsFixed(0)} chars'),
          Text('Emoji Rate: ${(style.emojiUsageRate * 100).toStringAsFixed(0)}%'),
        ],
      ),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error analyzing style'),
    );
  }
}
```

### Using Style in GPT Prompts

```dart
final styleAsync = await ref.read(
  analyzeUserStyleProvider(
    userId: currentUserId,
    conversationId: conversationId,
  ).future,
);

final styleJson = styleAsync.toJson();

// Example GPT prompt
final prompt = '''
Generate a smart reply that matches this user's style:
${jsonEncode(styleJson)}

The reply should be ${styleJson['styleDescription']} in tone.
''';
```

### Caching Strategy

The system implements a two-level caching approach:

1. **In-Memory Cache (Riverpod State)**
   - Key: `userId-conversationId`
   - TTL: 1 hour
   - Automatic invalidation if stale

2. **Consumer-Managed Invalidation**
   - Recommended: Invalidate after every ~20 new messages
   - Manual invalidation for real-time updates

```dart
// Force re-analysis after 20 messages
final cache = ref.read(userStyleCacheProvider.notifier);
cache.invalidate(userId, conversationId);
```

### Performance Characteristics

- **Database Query**: 1 query for last 100 messages (filtered to 20 by user)
- **Analysis Time**: <500ms for 20 messages
- **Memory**: ~1KB per cached style
- **Algorithm**: O(n) single-pass where n = message count

### Edge Cases Handled

1. **New user (no messages)**: Returns default neutral style
2. **Few messages (<5)**: Returns default neutral style
3. **Mixed languages**: Uses most frequent language
4. **No emojis/exclamations**: Scores 0.0
5. **Very short messages**: Excluded from length average
6. **Repository failure**: Returns default style

### Integration Points

This feature integrates with:
- **Smart Reply Generation** (future): Injects style into GPT prompts
- **Message Repository**: Uses existing message data
- **Language Detection**: Leverages detected language from messages

### Future Enhancements

- [ ] Persistent storage (Drift table) for offline access
- [ ] Per-conversation style adaptation over time
- [ ] Sentiment analysis integration
- [ ] Vocabulary richness scoring
- [ ] Formality level detection (separate from casualty)
