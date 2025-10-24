/// Idiom explanation providers (legacy - for backward compatibility)
///
/// DEPRECATED: Use idiom_explanation_providers.dart for new implementations
/// This file is kept for backward compatibility with existing code
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/idiom_explanation/domain/usecases/explain_message_idioms.dart';
import 'package:message_ai/features/idiom_explanation/presentation/providers/idiom_explanation_providers.dart';

/// Provider for ExplainMessageIdioms use case
///
/// DEPRECATED: Use idiomExplanationService directly from idiom_explanation_providers.dart
/// for new implementations
final explainMessageIdiomsProvider = Provider<ExplainMessageIdioms>(
  (ref) => ExplainMessageIdioms(ref.watch(idiomExplanationServiceProvider)),
);
