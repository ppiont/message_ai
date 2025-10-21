import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/app.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('App renders without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const App());

      // Verify the app renders
      expect(
        find.text('MessageAI - Clean Architecture Setup Complete'),
        findsOneWidget,
      );
    });

    test('App widget is created successfully', () {
      const app = App();
      expect(app, isA<App>());
    });
  });
}
