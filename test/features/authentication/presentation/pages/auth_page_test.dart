import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/features/authentication/presentation/pages/auth_page.dart';
import 'package:message_ai/features/authentication/presentation/pages/sign_in_page.dart';
import 'package:message_ai/features/authentication/presentation/pages/sign_up_page.dart';

void main() {
  group('AuthPage Widget Tests', () {
    Widget createWidgetUnderTest() {
      return const ProviderScope(child: MaterialApp(home: AuthPage()));
    }

    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('MessageAI'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display Sign In and Sign Up tabs', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Note: "Sign In" appears twice - once in tab, once in button
      expect(find.text('Sign In'), findsNWidgets(2));
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('should display SignInPage by default', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
    });

    testWidgets('should switch to SignUpPage when Sign Up tab is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.pumpAndSettle();

      // Tap the Sign Up tab
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Should display SignUpPage
      expect(find.byType(SignUpPage), findsOneWidget);
    });

    testWidgets('should switch back to SignInPage when Sign In tab is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.pumpAndSettle();

      // Switch to Sign Up
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Switch back to Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
    });

    testWidgets('should have TabBarView with 2 children', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final tabBarView = tester.widget<TabBarView>(find.byType(TabBarView));
      expect(tabBarView.children.length, 2);
    });
  });
}
