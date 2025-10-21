/// Environment configuration for the app
///
/// This class defines environment-specific settings that differ between
/// development and production builds.
abstract class EnvConfig {
  /// Environment name (dev, prod)
  String get environment;

  /// Firebase project ID
  String get firebaseProjectId;

  /// App display name
  String get appName;

  /// Enable debug logging
  bool get enableDebugLogging;

  /// Enable Firebase Analytics
  bool get enableAnalytics;

  /// Enable Firebase Crashlytics
  bool get enableCrashlytics;
}

/// Development environment configuration
class DevConfig implements EnvConfig {
  @override
  String get environment => 'dev';

  @override
  String get firebaseProjectId => 'message-ai';

  @override
  String get appName => 'MessageAI (Dev)';

  @override
  bool get enableDebugLogging => true;

  @override
  bool get enableAnalytics => false; // Disable in dev to avoid polluting analytics

  @override
  bool get enableCrashlytics => false; // Disable in dev
}

/// Production environment configuration
class ProdConfig implements EnvConfig {
  @override
  String get environment => 'prod';

  @override
  String get firebaseProjectId => 'message-ai-prod';

  @override
  String get appName => 'MessageAI';

  @override
  bool get enableDebugLogging => false;

  @override
  bool get enableAnalytics => true;

  @override
  bool get enableCrashlytics => true;
}

/// Global environment configuration instance
/// This will be set by the appropriate main_*.dart file
late final EnvConfig envConfig;
