/// Tests for MessageInput widget
library;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/usecases/send_message.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:message_ai/features/messaging/presentation/widgets/message_input.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockSendMessage extends Mock implements SendMessage {}

void main() {
  late MockSendMessage mockSendMessage;

  setUp(() {
    mockSendMessage = MockSendMessage();
    // Register fallback values for any() matchers
    registerFallbackValue(
      Message(
        id: 'test',
        senderId: 'user-1',
        senderName: 'Test User',
        text: 'test',
        timestamp: DateTime.now(),
        status: 'sent',
        type: 'text',
        metadata: MessageMetadata.defaultMetadata(),
      ),
    );
  });

  Widget createTestWidget({
    MockSendMessage? sendMessage,
    VoidCallback? onMessageSent,
  }) {
    return ProviderScope(
      overrides: [
        if (sendMessage != null)
          sendMessageUseCaseProvider.overrideWithValue(sendMessage),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MessageInput(
            conversationId: 'conv-1',
            currentUserId: 'user-1',
            currentUserName: 'Test User',
            onMessageSent: onMessageSent,
          ),
        ),
      ),
    );
  }

  group('MessageInput', () {
    group('UI elements', () {
      testWidgets('should display text field', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('should display send button', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byIcon(Icons.send), findsOneWidget);
      });

      testWidgets('should display hint text', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.text('Type a message...'), findsOneWidget);
      });
    });

    group('message sending', () {
      testWidgets('should send message when send button pressed', (
        tester,
      ) async {
        // Arrange
        final testMessage = Message(
          id: 'msg-1',
          senderId: 'user-1',
          senderName: 'Test User',
          text: 'Hello',
          timestamp: DateTime.now(),
          status: 'sent',
          type: 'text',
          metadata: MessageMetadata.defaultMetadata(),
        );

        when(
          () => mockSendMessage(any(), any()),
        ).thenAnswer((_) async => Right(testMessage));

        await tester.pumpWidget(createTestWidget(sendMessage: mockSendMessage));

        // Act - Enter text and press send
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Assert
        verify(() => mockSendMessage('conv-1', any())).called(1);
      });

      testWidgets('should NOT send empty message', (tester) async {
        // Arrange
        when(() => mockSendMessage(any(), any())).thenAnswer(
          (_) async => Right(
            Message(
              id: 'msg-1',
              senderId: 'user-1',
              senderName: 'Test User',
              text: '',
              timestamp: DateTime.now(),
              status: 'sent',
              type: 'text',
              metadata: MessageMetadata.defaultMetadata(),
            ),
          ),
        );

        await tester.pumpWidget(createTestWidget(sendMessage: mockSendMessage));

        // Act - Press send without entering text
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        // Assert
        verifyNever(() => mockSendMessage(any(), any()));
      });

      testWidgets('should NOT send whitespace-only message', (tester) async {
        // Arrange
        when(() => mockSendMessage(any(), any())).thenAnswer(
          (_) async => Right(
            Message(
              id: 'msg-1',
              senderId: 'user-1',
              senderName: 'Test User',
              text: '   ',
              timestamp: DateTime.now(),
              status: 'sent',
              type: 'text',
              metadata: MessageMetadata.defaultMetadata(),
            ),
          ),
        );

        await tester.pumpWidget(createTestWidget(sendMessage: mockSendMessage));

        // Act - Enter whitespace and press send
        await tester.enterText(find.byType(TextField), '   ');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        // Assert
        verifyNever(() => mockSendMessage(any(), any()));
      });

      testWidgets('should clear input after successful send', (tester) async {
        // Arrange
        final testMessage = Message(
          id: 'msg-1',
          senderId: 'user-1',
          senderName: 'Test User',
          text: 'Hello',
          timestamp: DateTime.now(),
          status: 'sent',
          type: 'text',
          metadata: MessageMetadata.defaultMetadata(),
        );

        when(
          () => mockSendMessage(any(), any()),
        ).thenAnswer((_) async => Right(testMessage));

        await tester.pumpWidget(createTestWidget(sendMessage: mockSendMessage));

        // Act
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Assert - Input should be cleared
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, isEmpty);
      });

      testWidgets('should call onMessageSent callback after successful send', (
        tester,
      ) async {
        // Arrange
        bool callbackCalled = false;
        final testMessage = Message(
          id: 'msg-1',
          senderId: 'user-1',
          senderName: 'Test User',
          text: 'Hello',
          timestamp: DateTime.now(),
          status: 'sent',
          type: 'text',
          metadata: MessageMetadata.defaultMetadata(),
        );

        when(
          () => mockSendMessage(any(), any()),
        ).thenAnswer((_) async => Right(testMessage));

        await tester.pumpWidget(
          createTestWidget(
            sendMessage: mockSendMessage,
            onMessageSent: () {
              callbackCalled = true;
            },
          ),
        );

        // Act
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Assert
        expect(callbackCalled, isTrue);
      });

      testWidgets('should send message on keyboard submit', (tester) async {
        // Arrange
        final testMessage = Message(
          id: 'msg-1',
          senderId: 'user-1',
          senderName: 'Test User',
          text: 'Hello',
          timestamp: DateTime.now(),
          status: 'sent',
          type: 'text',
          metadata: MessageMetadata.defaultMetadata(),
        );

        when(
          () => mockSendMessage(any(), any()),
        ).thenAnswer((_) async => Right(testMessage));

        await tester.pumpWidget(createTestWidget(sendMessage: mockSendMessage));

        // Act - Enter text and submit via keyboard
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Assert
        verify(() => mockSendMessage('conv-1', any())).called(1);
      });
    });

    group('loading state', () {
      testWidgets('should show loading indicator when sending', (tester) async {
        // Arrange
        final testMessage = Message(
          id: 'msg-1',
          senderId: 'user-1',
          senderName: 'Test User',
          text: 'Hello',
          timestamp: DateTime.now(),
          status: 'sent',
          type: 'text',
          metadata: MessageMetadata.defaultMetadata(),
        );

        when(() => mockSendMessage(any(), any())).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 500));
          return Right(testMessage);
        });

        await tester.pumpWidget(createTestWidget(sendMessage: mockSendMessage));

        // Act
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump(); // Start sending

        // Assert - Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.send), findsNothing);

        // Cleanup - wait for send to complete
        await tester.pumpAndSettle();
      });

      testWidgets('should disable input during sending', (tester) async {
        // Arrange
        final testMessage = Message(
          id: 'msg-1',
          senderId: 'user-1',
          senderName: 'Test User',
          text: 'Hello',
          timestamp: DateTime.now(),
          status: 'sent',
          type: 'text',
          metadata: MessageMetadata.defaultMetadata(),
        );

        when(() => mockSendMessage(any(), any())).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 500));
          return Right(testMessage);
        });

        await tester.pumpWidget(createTestWidget(sendMessage: mockSendMessage));

        // Act
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump(); // Start sending

        // Assert - TextField should be disabled
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.enabled, isFalse);

        // Cleanup
        await tester.pumpAndSettle();
      });
    });

    group('error handling', () {
      testWidgets('should show error message on send failure', (tester) async {
        // Arrange
        when(() => mockSendMessage(any(), any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Connection failed')),
        );

        await tester.pumpWidget(createTestWidget(sendMessage: mockSendMessage));

        // Act
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Assert - Should show error snackbar
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text('Failed to send message: Connection failed'),
          findsOneWidget,
        );
      });

      testWidgets('should NOT clear input on send failure', (tester) async {
        // Arrange
        when(() => mockSendMessage(any(), any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Connection failed')),
        );

        await tester.pumpWidget(createTestWidget(sendMessage: mockSendMessage));

        // Act
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Assert - Input should still contain the message
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'Hello');
      });

      testWidgets('should re-enable input after error', (tester) async {
        // Arrange
        when(() => mockSendMessage(any(), any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Connection failed')),
        );

        await tester.pumpWidget(createTestWidget(sendMessage: mockSendMessage));

        // Act
        await tester.enterText(find.byType(TextField), 'Hello');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Assert - Input should be enabled again
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.enabled, isTrue);
      });
    });

    group('edge cases', () {
      testWidgets('should handle very long messages', (tester) async {
        // Arrange
        final longMessage = 'A' * 1000;
        final testMessage = Message(
          id: 'msg-1',
          senderId: 'user-1',
          senderName: 'Test User',
          text: longMessage,
          timestamp: DateTime.now(),
          status: 'sent',
          type: 'text',
          metadata: MessageMetadata.defaultMetadata(),
        );

        when(
          () => mockSendMessage(any(), any()),
        ).thenAnswer((_) async => Right(testMessage));

        await tester.pumpWidget(createTestWidget(sendMessage: mockSendMessage));

        // Act
        await tester.enterText(find.byType(TextField), longMessage);
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Assert
        verify(() => mockSendMessage('conv-1', any())).called(1);
      });

      testWidgets('should handle special characters', (tester) async {
        // Arrange
        const specialMessage = '👋 Hello! @user #hashtag 🎉\n\nNew line';
        final testMessage = Message(
          id: 'msg-1',
          senderId: 'user-1',
          senderName: 'Test User',
          text: specialMessage,
          timestamp: DateTime.now(),
          status: 'sent',
          type: 'text',
          metadata: MessageMetadata.defaultMetadata(),
        );

        when(
          () => mockSendMessage(any(), any()),
        ).thenAnswer((_) async => Right(testMessage));

        await tester.pumpWidget(createTestWidget(sendMessage: mockSendMessage));

        // Act
        await tester.enterText(find.byType(TextField), specialMessage);
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Assert
        verify(() => mockSendMessage('conv-1', any())).called(1);
      });
    });
  });
}
