/// Message context details entity
library;

import 'package:equatable/equatable.dart';
import 'package:message_ai/features/messaging/domain/entities/idiom_explanation.dart';

/// Rich context analysis for a message
///
/// Contains detailed cultural analysis including formality, cultural notes,
/// and idiom explanations. This data is fetched on-demand when user requests
/// context analysis and cached in Firestore for eventual consistency.
///
/// Benefits:
/// - Offline-first: Cached in Drift for instant access
/// - Group chat optimized: Multiple users benefit from same analysis
/// - No duplicate processing: Stored once in Firestore
class MessageContextDetails extends Equatable {
  const MessageContextDetails({
    this.formality,
    this.culturalNote,
    this.idioms = const [],
  });

  /// Create from JSON
  factory MessageContextDetails.fromJson(Map<String, dynamic> json) {
    // Parse idioms list
    final idiomsJson = json['idioms'] as List<dynamic>? ?? <dynamic>[];
    final idiomsList = idiomsJson
        .map<IdiomExplanation?>((final Object? idiom) {
          if (idiom is Map<Object?, Object?>) {
            final idiomMap = Map<String, dynamic>.from(idiom);
            return IdiomExplanation.fromJson(idiomMap);
          }
          return null;
        })
        .whereType<IdiomExplanation>()
        .toList();

    return MessageContextDetails(
      formality: json['formality'] as String?,
      culturalNote: json['culturalNote'] as String?,
      idioms: idiomsList,
    );
  }

  /// Formality level of the message
  ///
  /// Possible values: "very formal", "formal", "neutral", "casual", "very casual"
  final String? formality;

  /// Detailed cultural explanation
  ///
  /// Explains cultural nuances, greetings, customs, or references that
  /// might not be obvious to non-native speakers.
  final String? culturalNote;

  /// List of idioms, slang, or colloquialisms found in the message
  ///
  /// Each idiom includes phrase, meaning, cultural note, and
  /// equivalent expressions in multiple languages.
  final List<IdiomExplanation> idioms;

  /// Whether this analysis contains any meaningful content
  bool get hasContent =>
      formality != null || culturalNote != null || idioms.isNotEmpty;

  /// Whether idioms were found
  bool get hasIdioms => idioms.isNotEmpty;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'formality': formality,
    'culturalNote': culturalNote,
    'idioms': idioms.map((idiom) => idiom.toJson()).toList(),
  };

  /// Create a copy with updated fields
  MessageContextDetails copyWith({
    String? formality,
    String? culturalNote,
    List<IdiomExplanation>? idioms,
  }) => MessageContextDetails(
    formality: formality ?? this.formality,
    culturalNote: culturalNote ?? this.culturalNote,
    idioms: idioms ?? this.idioms,
  );

  @override
  List<Object?> get props => [formality, culturalNote, idioms];
}
