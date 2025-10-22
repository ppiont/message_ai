import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/language_detection_service.dart';

/// Provider for the language detection service.
///
/// Creates a single instance of [LanguageDetectionService] that is shared
/// across the app. The service is properly disposed when no longer needed.
final languageDetectionServiceProvider = Provider<LanguageDetectionService>(
  (ref) {
    final service = LanguageDetectionService();

    // Dispose the service when the provider is disposed
    ref.onDispose(() => service.dispose());

    return service;
  },
);
