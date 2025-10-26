/// Riverpod providers for typing indicators
library;

import 'package:firebase_database/firebase_database.dart';
import 'package:message_ai/features/messaging/data/services/rtdb_typing_service.dart'
    show RtdbTypingService, TypingUser;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'typing_providers.g.dart';

// ========== Typing Indicator Providers ==========

/// Provides the [RtdbTypingService] instance for typing indicators.
///
/// Uses Firebase Realtime Database with automatic cleanup via onDisconnect()
/// callbacks when user disconnects or app is closed.
@riverpod
RtdbTypingService typingIndicatorService(Ref ref) {
  final service = RtdbTypingService(database: FirebaseDatabase.instance);

  // Dispose when provider is disposed
  ref.onDispose(service.dispose);

  return service;
}

/// Watches typing users for a specific conversation.
@riverpod
Stream<List<TypingUser>> conversationTypingUsers(
  Ref ref,
  String conversationId,
  String currentUserId,
) {
  final service = ref.watch(typingIndicatorServiceProvider);
  return service.watchTypingUsers(
    conversationId: conversationId,
    currentUserId: currentUserId,
  );
}
