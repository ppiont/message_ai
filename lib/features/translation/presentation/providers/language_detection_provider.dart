import 'package:message_ai/features/translation/data/services/language_detection_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'language_detection_provider.g.dart';

/// Provider for the language detection service.
///
/// Creates a single instance of [LanguageDetectionService] that is shared
/// across the app. Uses keepAlive to maintain singleton pattern and prevent
/// multiple instances from being created on every MessageBubble render.
/// The service is properly disposed when no longer needed.
@Riverpod(keepAlive: true)
LanguageDetectionService languageDetectionService(
  Ref ref,
) {
  final service = LanguageDetectionService();

  // Dispose the service when the provider is disposed
  ref.onDispose(service.dispose);

  return service;
}
