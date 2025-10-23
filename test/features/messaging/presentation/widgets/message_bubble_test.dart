import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/messaging/presentation/widgets/message_bubble.dart';

void main() {
  group('MessageBubble Translation UI', () {
    testWidgets('should show translate button for received messages with translations',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                messageId: 'msg-123',
                message: 'Hello',
                isMe: false,
                timestamp: DateTime.now(),
                detectedLanguage: 'en',
                translations: const {'es': 'Hola', 'fr': 'Bonjour'},
                userPreferredLanguage: 'es',
              ),
            ),
          ),
        ),
      );

      // Should show translate button
      expect(find.text('Translate'), findsOneWidget);
      expect(find.byIcon(Icons.translate), findsOneWidget);
    });

    testWidgets('should NOT show translate button for sent messages',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                messageId: 'msg-123',
                message: 'Hello',
                isMe: true, // Sent by current user
                timestamp: DateTime.now(),
                detectedLanguage: 'en',
                translations: const {'es': 'Hola'},
                userPreferredLanguage: 'es',
              ),
            ),
          ),
        ),
      );

      // Should NOT show translate button
      expect(find.text('Translate'), findsNothing);
    });

    testWidgets('should toggle translation when button tapped',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                messageId: 'msg-123',
                message: 'Hello',
                isMe: false,
                timestamp: DateTime.now(),
                detectedLanguage: 'en',
                translations: const {'es': 'Hola', 'fr': 'Bonjour'},
                userPreferredLanguage: 'es',
              ),
            ),
          ),
        ),
      );

      // Initially shows original
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Translate'), findsOneWidget);

      // Tap translate button
      await tester.tap(find.text('Translate'));
      await tester.pumpAndSettle();

      // Should show translated text
      expect(find.text('Hola'), findsOneWidget);
      expect(find.text('Show original'), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);

      // Tap again to show original
      await tester.tap(find.text('Show original'));
      await tester.pumpAndSettle();

      // Should show original again
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Translate'), findsOneWidget);
    });

    testWidgets('should NOT show button when message is already in user language',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                messageId: 'msg-123',
                message: 'Hola',
                isMe: false,
                timestamp: DateTime.now(),
                detectedLanguage: 'es', // Already in Spanish
                translations: const {'en': 'Hello'},
                userPreferredLanguage: 'es', // User prefers Spanish
              ),
            ),
          ),
        ),
      );

      // Should NOT show translate button (message already in user's language)
      expect(find.text('Translate'), findsNothing);
    });

    testWidgets('should NOT show button when no translation available',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                messageId: 'msg-123',
                message: 'Hello',
                isMe: false,
                timestamp: DateTime.now(),
                detectedLanguage: 'en',
                userPreferredLanguage: 'es',
              ),
            ),
          ),
        ),
      );

      // Should NOT show translate button
      expect(find.text('Translate'), findsNothing);
    });

    testWidgets('should show smooth fade animation when toggling',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MessageBubble(
                messageId: 'msg-123',
                message: 'Hello',
                isMe: false,
                timestamp: DateTime.now(),
                detectedLanguage: 'en',
                translations: const {'es': 'Hola'},
                userPreferredLanguage: 'es',
              ),
            ),
          ),
        ),
      );

      // Verify AnimatedSwitcher exists
      expect(find.byType(AnimatedSwitcher), findsOneWidget);

      // Tap translate button
      await tester.tap(find.text('Translate'));

      // Pump a few frames to check animation
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      // Should be animating
      expect(find.byType(FadeTransition), findsWidgets);

      // Complete animation
      await tester.pumpAndSettle();

      // Should show translated text
      expect(find.text('Hola'), findsOneWidget);
    });
  });
}
