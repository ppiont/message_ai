/// Tests for ConversationListItem widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/messaging/presentation/widgets/conversation_list_item.dart';

void main() {
  // Test data
  final testParticipants = [
    {
      'uid': 'user-1',
      'name': 'Alice Smith',
      'imageUrl': null,
      'preferredLanguage': 'en',
    },
    {
      'uid': 'user-2',
      'name': 'Bob Johnson',
      'imageUrl': null, // Using null to avoid network request in tests
      'preferredLanguage': 'es',
    },
  ];

  Widget createTestWidget({
    required List<Map<String, dynamic>> participants,
    String? lastMessage,
    int unreadCount = 0,
    String currentUserId = 'user-1',
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ConversationListItem(
          conversationId: 'conv-1',
          participants: participants,
          lastMessage: lastMessage,
          lastUpdatedAt: DateTime(2024, 1, 1, 12, 0),
          unreadCount: unreadCount,
          currentUserId: currentUserId,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  group('ConversationListItem', () {
    group('participant display', () {
      testWidgets('should display other participant name', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            participants: testParticipants,
            currentUserId: 'user-1',
          ),
        );

        // Assert - Should show user-2's name since current user is user-1
        expect(find.text('Bob Johnson'), findsOneWidget);
        expect(find.text('Alice Smith'), findsNothing);
      });

      testWidgets('should display avatar with initials when no image', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            participants: [
              {
                'uid': 'user-1',
                'name': 'Current User',
                'imageUrl': null,
                'preferredLanguage': 'en',
              },
              {
                'uid': 'user-2',
                'name': 'John Doe',
                'imageUrl': null,
                'preferredLanguage': 'en',
              },
            ],
            currentUserId: 'user-1',
          ),
        );

        // Assert - Should show initials "JD" for John Doe
        expect(find.text('JD'), findsOneWidget);
        expect(find.byType(CircleAvatar), findsOneWidget);
      });

      testWidgets('should display single initial for single name', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            participants: [
              {
                'uid': 'user-1',
                'name': 'Current',
                'imageUrl': null,
                'preferredLanguage': 'en',
              },
              {
                'uid': 'user-2',
                'name': 'Madonna',
                'imageUrl': null,
                'preferredLanguage': 'en',
              },
            ],
            currentUserId: 'user-1',
          ),
        );

        // Assert
        expect(find.text('M'), findsOneWidget);
      });

      testWidgets('should handle empty participant list gracefully', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(participants: [], currentUserId: 'user-1'),
        );

        // Assert - Should show 'Unknown' and not crash
        expect(find.text('Unknown'), findsOneWidget);
      });

      testWidgets(
        'should fall back to first participant if current user not found',
        (tester) async {
          // Arrange & Act
          await tester.pumpWidget(
            createTestWidget(
              participants: testParticipants,
              currentUserId: 'user-999', // Not in participants
            ),
          );

          // Assert - Should show first participant
          expect(find.text('Alice Smith'), findsOneWidget);
        },
      );
    });

    group('message display', () {
      testWidgets('should display last message', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            participants: testParticipants,
            lastMessage: 'Hello, how are you?',
          ),
        );

        // Assert
        expect(find.text('Hello, how are you?'), findsOneWidget);
      });

      testWidgets('should display placeholder when no message', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(participants: testParticipants, lastMessage: null),
        );

        // Assert
        expect(find.text('No messages yet'), findsOneWidget);
      });

      testWidgets('should truncate long messages', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            participants: testParticipants,
            lastMessage:
                'This is a very long message that should be truncated '
                'because it exceeds the maximum length for display',
          ),
        );

        // Assert - Text widget should have ellipsis
        final textWidget = tester.widget<Text>(
          find.text(
            'This is a very long message that should be truncated '
            'because it exceeds the maximum length for display',
          ),
        );
        expect(textWidget.overflow, TextOverflow.ellipsis);
        expect(textWidget.maxLines, 1);
      });
    });

    group('unread badge', () {
      testWidgets('should display unread badge when unread > 0', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(participants: testParticipants, unreadCount: 5),
        );

        // Assert
        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('should not display badge when unread = 0', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(participants: testParticipants, unreadCount: 0),
        );

        // Assert - No badge container
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).borderRadius != null,
          ),
          findsNothing,
        );
      });

      testWidgets('should display 99+ for counts over 99', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(participants: testParticipants, unreadCount: 150),
        );

        // Assert
        expect(find.text('99+'), findsOneWidget);
      });

      testWidgets('should make text bold when unread > 0', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            participants: testParticipants,
            lastMessage: 'Test message',
            unreadCount: 3,
          ),
        );

        // Assert - Name should be bold
        final nameText = tester.widget<Text>(find.text('Bob Johnson'));
        expect(nameText.style?.fontWeight, FontWeight.bold);

        // Last message should be medium weight
        final messageText = tester.widget<Text>(find.text('Test message'));
        expect(messageText.style?.fontWeight, FontWeight.w500);
      });
    });

    group('timestamp formatting', () {
      testWidgets('should display formatted timestamp', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(participants: testParticipants),
        );

        // Assert - Should have some timestamp text (format depends on current date)
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                widget.style?.fontSize == 12 &&
                widget.data != null,
          ),
          findsWidgets,
        );
      });
    });

    group('interaction', () {
      testWidgets('should call onTap when tapped', (tester) async {
        // Arrange
        bool tapped = false;
        await tester.pumpWidget(
          createTestWidget(
            participants: testParticipants,
            onTap: () {
              tapped = true;
            },
          ),
        );

        // Act
        await tester.tap(find.byType(ListTile));
        await tester.pump();

        // Assert
        expect(tapped, isTrue);
      });
    });

    group('edge cases', () {
      testWidgets('should handle participant with empty name', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            participants: [
              {
                'uid': 'user-1',
                'name': 'Current',
                'imageUrl': null,
                'preferredLanguage': 'en',
              },
              {
                'uid': 'user-2',
                'name': '',
                'imageUrl': null,
                'preferredLanguage': 'en',
              },
            ],
            currentUserId: 'user-1',
          ),
        );

        // Assert - Empty string is technically valid, but fallback shows Unknown
        // The widget uses `?? 'Unknown'` so empty string passes through
        // This test verifies the widget doesn't crash with empty name
        expect(find.byType(ListTile), findsOneWidget);
      });

      testWidgets('should handle participant without name field', (
        tester,
      ) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            participants: [
              {
                'uid': 'user-1',
                'name': 'Current',
                'imageUrl': null,
                'preferredLanguage': 'en',
              },
              {
                'uid': 'user-2',
                // name field missing
                'imageUrl': null,
                'preferredLanguage': 'en',
              },
            ],
            currentUserId: 'user-1',
          ),
        );

        // Assert - Should show Unknown
        expect(find.text('Unknown'), findsOneWidget);
      });

      testWidgets('should handle very long names gracefully', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createTestWidget(
            participants: [
              {
                'uid': 'user-1',
                'name': 'Current User',
                'imageUrl': null,
                'preferredLanguage': 'en',
              },
              {
                'uid': 'user-2',
                'name': 'A' * 100, // 100 character name
                'imageUrl': null,
                'preferredLanguage': 'en',
              },
            ],
            currentUserId: 'user-1',
          ),
        );

        // Assert - Should display with ellipsis
        final nameText = tester.widget<Text>(find.text('A' * 100));
        expect(nameText.overflow, TextOverflow.ellipsis);
      });
    });
  });
}
