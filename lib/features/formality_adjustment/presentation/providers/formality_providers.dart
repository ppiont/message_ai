/// Formality adjustment providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/formality_adjustment/data/services/formality_adjustment_service.dart';
import 'package:message_ai/features/formality_adjustment/domain/usecases/adjust_message_formality.dart';

export 'package:message_ai/features/formality_adjustment/presentation/controllers/formality_controller.dart';

/// Provider for FormalityAdjustmentService
final formalityAdjustmentServiceProvider = Provider<FormalityAdjustmentService>(
  (ref) => FormalityAdjustmentService(),
);

/// Provider for AdjustMessageFormality use case
final adjustMessageFormalityProvider = Provider<AdjustMessageFormality>(
  (ref) => AdjustMessageFormality(
    ref.watch(formalityAdjustmentServiceProvider),
  ),
);
