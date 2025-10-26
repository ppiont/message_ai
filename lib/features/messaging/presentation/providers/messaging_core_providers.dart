/// Core infrastructure providers for messaging feature
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messaging_core_providers.g.dart';

// ========== Core Infrastructure Providers ==========

/// Provides the FirebaseFirestore instance for messaging operations.
@riverpod
FirebaseFirestore messagingFirestore(Ref ref) => FirebaseFirestore.instance;
