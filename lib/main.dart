import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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

  // Run the app
  runApp(const App());
}
