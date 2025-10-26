/// Splash page
library;

import 'package:flutter/material.dart';

/// Splash screen displayed during app initialization.
///
/// Shows immediately on app launch while services initialize in the background.
/// Provides visual feedback with loading indicator and app branding.
class SplashPage extends StatelessWidget {
  const SplashPage({
    this.message = 'Initializing...',
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[700]!,
                  Colors.blue[500]!,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon/logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // App name
                  const Text(
                    'MessageAI',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'Smart Messaging',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 64),

                  // Loading indicator
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 24),

                  // Status message
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
