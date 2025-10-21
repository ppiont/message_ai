import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_ai/app.dart';
import 'package:message_ai/config/env_config.dart';

void main() {
  group('App Widget Tests', () {
    setUpAll(() {
      // Initialize envConfig once for all tests
      envConfig = DevConfig();
    });

    test('App widget is created successfully', () {
      const app = App();
      expect(app, isA<App>());
      expect(app, isA<ConsumerWidget>());
    });

    // Note: Full widget rendering tests for App are covered by integration tests
    // Individual page tests (AuthPage, SignInPage, etc.) provide comprehensive coverage
  });
}
