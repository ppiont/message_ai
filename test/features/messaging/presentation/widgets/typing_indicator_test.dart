import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/messaging/presentation/widgets/typing_indicator.dart';

void main() {
  group('TypingIndicator Widget', () {
    testWidgets('should not display when typingUserNames is empty', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(typingUserNames: [])),
        ),
      );

      // Assert
      expect(find.byType(TypingIndicator), findsOneWidget);
      expect(find.text('is typing...'), findsNothing);
    });

    testWidgets('should display single user typing', (tester) async {
      // Arrange
      const typingUsers = ['Alice'];

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(typingUserNames: typingUsers)),
        ),
      );

      // Assert
      expect(find.text('Alice is typing...'), findsOneWidget);
    });

    testWidgets('should display two users typing', (tester) async {
      // Arrange
      const typingUsers = ['Alice', 'Bob'];

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(typingUserNames: typingUsers)),
        ),
      );

      // Assert
      expect(find.text('Alice and Bob are typing...'), findsOneWidget);
    });

    testWidgets('should display multiple users typing with count', (
      tester,
    ) async {
      // Arrange
      const typingUsers = ['Alice', 'Bob', 'Charlie'];

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(typingUserNames: typingUsers)),
        ),
      );

      // Assert
      expect(find.text('Alice and 2 others are typing...'), findsOneWidget);
    });

    testWidgets('should display animated dots', (tester) async {
      // Arrange
      const typingUsers = ['Alice'];

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(typingUserNames: typingUsers)),
        ),
      );

      // Assert - Check for dot containers
      final dotContainers = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );

      expect(dotContainers, findsNWidgets(3)); // 3 dots
    });

    testWidgets('should animate dots', (tester) async {
      // Arrange
      const typingUsers = ['Alice'];

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(typingUserNames: typingUsers)),
        ),
      );

      // Initial state
      await tester.pump();

      // Pump animation
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - Widget should still be visible and animating
      expect(find.text('Alice is typing...'), findsOneWidget);
    });

    testWidgets('should update when typingUserNames changes', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(typingUserNames: ['Alice'])),
        ),
      );

      expect(find.text('Alice is typing...'), findsOneWidget);

      // Act - Update with new users
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(typingUserNames: ['Bob', 'Charlie']),
          ),
        ),
      );

      // Assert
      expect(find.text('Alice is typing...'), findsNothing);
      expect(find.text('Bob and Charlie are typing...'), findsOneWidget);
    });

    testWidgets('should handle empty to non-empty transition', (tester) async {
      // Arrange - Start with empty
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(typingUserNames: const [])),
        ),
      );

      expect(find.text('is typing...'), findsNothing);

      // Act - Add user
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(typingUserNames: const ['Alice']),
          ),
        ),
      );

      // Assert
      expect(find.text('Alice is typing...'), findsOneWidget);
    });

    testWidgets('should handle non-empty to empty transition', (tester) async {
      // Arrange - Start with user
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TypingIndicator(typingUserNames: const ['Alice']),
          ),
        ),
      );

      expect(find.text('Alice is typing...'), findsOneWidget);

      // Act - Clear users
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TypingIndicator(typingUserNames: const [])),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.text('Alice is typing...'), findsNothing);
    });

    testWidgets('should apply correct styling', (tester) async {
      // Arrange
      const typingUsers = ['Alice'];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TypingIndicator(typingUserNames: typingUsers)),
        ),
      );

      // Assert
      final textWidget = tester.widget<Text>(find.text('Alice is typing...'));

      expect(textWidget.style?.fontStyle, FontStyle.italic);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should handle long names gracefully', (tester) async {
      // Arrange
      const typingUsers = [
        'Very Long User Name That Might Overflow',
        'Another Long Name',
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: TypingIndicator(typingUserNames: typingUsers),
            ),
          ),
        ),
      );

      // Assert - Should render without overflow
      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Very Long User Name That Might Overflow and Another Long Name are typing...',
        ),
        findsOneWidget,
      );
    });
  });
}
