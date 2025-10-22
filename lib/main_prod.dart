import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/messaging/data/services/fcm_service.dart';
import 'app.dart';
import 'config/env_config.dart';

/// Production environment entry point
///
/// This file initializes the app with production-specific configuration.
///
/// Run with: flutter run --flavor prod -t lib/main_prod.dart
/// Build with: flutter build apk --release --flavor prod -t lib/main_prod.dart
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set production environment configuration
  envConfig = ProdConfig();

  // Initialize Firebase with prod project (when available)
  await Firebase.initializeApp();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Run the app with Riverpod's ProviderScope
  runApp(const ProviderScope(child: App()));
}
