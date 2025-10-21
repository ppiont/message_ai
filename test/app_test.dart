import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/app.dart';
import 'package:message_ai/config/env_config.dart';

void main() {
  group('App Widget Tests', () {
    setUpAll(() {
      // Initialize envConfig once for all tests
      envConfig = DevConfig();
    });

    testWidgets('App renders without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const App());

      // Verify the app renders with dev environment
      expect(find.text('MessageAI (Dev)'), findsOneWidget);
      expect(find.text('Environment: dev'), findsOneWidget);
    });

    test('App widget is created successfully', () {
      const app = App();
      expect(app, isA<App>());
    });
  });
}
