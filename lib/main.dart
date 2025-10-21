import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/core/error/error_logger.dart';
import 'app.dart';

/// Application entry point
///
/// Initializes Firebase and the Flutter application.
/// Sets up error handling and runs the root App widget.
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize error logging
  await ErrorLogger.initialize();

  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
