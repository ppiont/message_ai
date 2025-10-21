import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'config/env_config.dart';

/// Development environment entry point
///
/// This file initializes the app with development-specific configuration.
///
/// Run with: flutter run --flavor dev -t lib/main_dev.dart
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set development environment configuration
  envConfig = DevConfig();

  // Initialize Firebase with dev project
  await Firebase.initializeApp();

  // Log environment info in dev
  debugPrint('🚀 Starting MessageAI in ${envConfig.environment} mode');
  debugPrint('📱 App name: ${envConfig.appName}');
  debugPrint('🔥 Firebase project: ${envConfig.firebaseProjectId}');
  debugPrint('📊 Analytics enabled: ${envConfig.enableAnalytics}');
  debugPrint('🐛 Debug logging: ${envConfig.enableDebugLogging}');

  // Run the app with Riverpod's ProviderScope
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
