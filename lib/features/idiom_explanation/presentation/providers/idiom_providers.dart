/// Idiom explanation providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/idiom_explanation/data/services/idiom_explanation_service.dart';
import 'package:message_ai/features/idiom_explanation/domain/usecases/explain_message_idioms.dart';

/// Provider for IdiomExplanationService
final idiomExplanationServiceProvider = Provider<IdiomExplanationService>(
  (ref) => IdiomExplanationService(),
);

/// Provider for ExplainMessageIdioms use case
final explainMessageIdiomsProvider = Provider<ExplainMessageIdioms>(
  (ref) => ExplainMessageIdioms(
    ref.watch(idiomExplanationServiceProvider),
  ),
);
