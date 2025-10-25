/// Adjust message formality use case
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/formality_adjustment/data/services/formality_adjustment_service.dart';
import 'package:message_ai/features/formality_adjustment/domain/entities/formality_level.dart';

/// Use case for adjusting the formality level of a message
class AdjustMessageFormality {
  const AdjustMessageFormality(this._formalityAdjustmentService);

  final FormalityAdjustmentService _formalityAdjustmentService;

  /// Execute the formality adjustment
  Future<Either<Failure, String>> call({
    required String text,
    required FormalityLevel targetFormality,
    FormalityLevel? currentFormality,
    String? language,
  }) async => _formalityAdjustmentService.adjustFormality(
      text: text,
      targetFormality: targetFormality,
      currentFormality: currentFormality,
      language: language,
    );
}
