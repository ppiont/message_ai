/// Tests for MessageBubble widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/messaging/presentation/widgets/message_bubble.dart';

void main() {
  Widget createTestWidget({
    required String message,
    required bool isMe,
    String senderName = 'Test User',
    DateTime? timestamp,
    bool showTimestamp = false,
    String status = 'sent',
  }) => MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: message,
          isMe: isMe,
          senderName: senderName,
          timestamp: timestamp ?? DateTime(2024, 1, 1, 12),
          showTimestamp: showTimestamp,
          status: status,
        ),
      ),
    );

  group('MessageBubble', () {
    group('message display', () {
      testWidgets('should display message text', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(message: 'Hello, how are you?', isMe: true),
        );

        // Assert
        expect(find.text('Hello, how are you?'), findsOneWidget);
      });

      testWidgets('should display long message', (tester) async {
        // Arrange & Act
        const longMessage =
            'This is a very long message that spans multiple '
            'lines and should be properly wrapped within the message bubble '
            'without causing any layout issues or overflow errors.';

        await tester.pumpWidget(
          createTestWidget(message: longMessage, isMe: false),
        );

        // Assert
        expect(find.text(longMessage), findsOneWidget);
      });
    });

    group('sender identification', () {
      testWidgets('should show sender name for received messages', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            message: 'Test message',
            isMe: false,
            senderName: 'Alice',
          ),
        );

        // Assert
        expect(find.text('Alice'), findsOneWidget);
      });

      testWidgets('should NOT show sender name for sent messages', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            message: 'Test message',
            isMe: true,
            senderName: 'Me',
          ),
        );

        // Assert
        expect(find.text('Me'), findsNothing);
      });
    });

    group('styling', () {
      testWidgets('should use primary color for sent messages', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(message: 'My message', isMe: true),
        );

        // Assert
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MessageBubble),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, isNotNull);
      });

      testWidgets('should use grey color for received messages', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(message: 'Their message', isMe: false),
        );

        // Assert
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MessageBubble),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, Colors.grey[200]);
      });

      testWidgets('should align sent messages to right', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(message: 'My message', isMe: true),
        );

        // Assert
        final column = tester.widget<Column>(find.byType(Column).first);
        expect(column.crossAxisAlignment, CrossAxisAlignment.end);
      });

      testWidgets('should align received messages to left', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(message: 'Their message', isMe: false),
        );

        // Assert
        final column = tester.widget<Column>(find.byType(Column).first);
        expect(column.crossAxisAlignment, CrossAxisAlignment.start);
      });
    });

    group('timestamp', () {
      testWidgets('should always display message time', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            message: 'Test',
            isMe: true,
            timestamp: DateTime(2024, 1, 1, 14, 30),
          ),
        );

        // Assert - Should show formatted time (exact format may vary by locale)
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                widget.style?.fontSize == 11 &&
                widget.data != null,
          ),
          findsWidgets,
        );
      });

      testWidgets('should show timestamp divider when showTimestamp is true', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(message: 'Test', isMe: true, showTimestamp: true),
        );

        // Assert - Should have divider with timestamp
        expect(
          find.byType(Divider),
          findsNWidgets(2),
        ); // Left and right divider
      });

      testWidgets(
        'should NOT show timestamp divider when showTimestamp is false',
        (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            createTestWidget(message: 'Test', isMe: true),
          );

          // Assert
          expect(find.byType(Divider), findsNothing);
        },
      );
    });

    group('delivery status', () {
      testWidgets('should show single check for sent status', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(message: 'Test', isMe: true),
        );

        // Assert
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Icon && widget.icon == Icons.check,
          ),
          findsOneWidget,
        );
      });

      testWidgets('should show double check for delivered status', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(message: 'Test', isMe: true, status: 'delivered'),
        );

        // Assert
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Icon && widget.icon == Icons.done_all,
          ),
          findsOneWidget,
        );
      });

      testWidgets('should show colored double check for read status', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(message: 'Test', isMe: true, status: 'read'),
        );

        // Assert
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Icon && widget.icon == Icons.done_all,
          ),
          findsOneWidget,
        );
      });

      testWidgets('should NOT show status icon for received messages', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(message: 'Test', isMe: false),
        );

        // Assert
        expect(find.byIcon(Icons.check), findsNothing);
        expect(find.byIcon(Icons.done_all), findsNothing);
      });

      testWidgets('should handle unknown status gracefully', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(message: 'Test', isMe: true, status: 'unknown'),
        );

        // Assert - Should render without crashing
        expect(find.text('Test'), findsOneWidget);
        // No status icon should be shown
        expect(find.byType(Icon), findsNothing);
      });
    });

    group('edge cases', () {
      testWidgets('should handle empty message', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(message: '', isMe: true));

        // Assert - Should render without crashing
        expect(find.byType(MessageBubble), findsOneWidget);
      });

      testWidgets('should handle very long sender name', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(message: 'Test', isMe: false, senderName: 'A' * 100),
        );

        // Assert - Should render without overflow
        expect(find.text('A' * 100), findsOneWidget);
      });

      testWidgets('should handle special characters in message', (
        tester,
      ) async {
        // Arrange & Act
        const specialMessage = '👋 Hello! How are you? 🎉\n\nNew line test';

        await tester.pumpWidget(
          createTestWidget(message: specialMessage, isMe: true),
        );

        // Assert
        expect(find.text(specialMessage), findsOneWidget);
      });
    });
  });
}
