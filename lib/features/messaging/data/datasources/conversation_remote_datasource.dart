/// Remote data source for conversations stored in Firestore
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:message_ai/core/error/exceptions.dart';
import 'package:message_ai/features/messaging/data/models/conversation_model.dart';

/// Abstract interface for remote conversation data operations.
abstract class ConversationRemoteDataSource {
  /// Creates a new conversation
  Future<ConversationModel> createConversation(ConversationModel conversation);

  /// Retrieves a conversation by ID
  Future<ConversationModel> getConversationById(String conversationId);

  /// Retrieves conversations for a specific user
  Future<List<ConversationModel>> getConversationsForUser(
    String userId, {
    int limit = 50,
    DateTime? before,
  });

  /// Updates an existing conversation
  Future<ConversationModel> updateConversation(ConversationModel conversation);

  /// Deletes a conversation
  Future<void> deleteConversation(String conversationId);

  /// Watches conversations for a user in real-time
  Stream<List<ConversationModel>> watchConversationsForUser(
    String userId, {
    int limit = 50,
  });

  /// Finds an existing 1-to-1 conversation between two users
  Future<ConversationModel?> findDirectConversation(
    String userId1,
    String userId2,
  );

  /// Updates the last message in a conversation
  Future<void> updateLastMessage(
    String conversationId,
    String messageText,
    String senderId,
    String senderName,
    DateTime timestamp,
  );

  /// Updates unread count for a user in a conversation
  Future<void> updateUnreadCount(
    String conversationId,
    String userId,
    int count,
  );
}

/// Implementation of [ConversationRemoteDataSource] using Firebase Firestore.
class ConversationRemoteDataSourceImpl implements ConversationRemoteDataSource {
  final FirebaseFirestore _firestore;

  ConversationRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  static const String _conversationsCollection = 'conversations';

  CollectionReference<Map<String, dynamic>> get _conversationsRef =>
      _firestore.collection(_conversationsCollection);

  @override
  Future<ConversationModel> createConversation(
    ConversationModel conversation,
  ) async {
    try {
      final docRef = _conversationsRef.doc(conversation.documentId);

      // Check if conversation already exists
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        throw RecordAlreadyExistsException(
          recordType: 'Conversation',
          recordId: conversation.documentId,
        );
      }

      // Create the conversation document
      await docRef.set(conversation.toJson());

      // Return the created conversation
      return conversation;
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to create conversation',
        originalError: e,
      );
    }
  }

  @override
  Future<ConversationModel> getConversationById(String conversationId) async {
    try {
      final docSnapshot = await _conversationsRef.doc(conversationId).get();

      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'Conversation',
          recordId: conversationId,
        );
      }

      return ConversationModel.fromJson(docSnapshot.data()!);
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to get conversation',
        originalError: e,
      );
    }
  }

  @override
  Future<List<ConversationModel>> getConversationsForUser(
    String userId, {
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _conversationsRef
          .where('participantIds', arrayContains: userId)
          .orderBy('lastUpdatedAt', descending: true)
          .limit(limit);

      // Add pagination if before timestamp is provided
      if (before != null) {
        query = query.where('lastUpdatedAt', isLessThan: before);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => ConversationModel.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to get conversations',
        originalError: e,
      );
    }
  }

  @override
  Future<ConversationModel> updateConversation(
    ConversationModel conversation,
  ) async {
    try {
      final docRef = _conversationsRef.doc(conversation.documentId);

      // Check if conversation exists
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw RecordNotFoundException(
          recordType: 'Conversation',
          recordId: conversation.documentId,
        );
      }

      // Update the conversation document
      await docRef.update(conversation.toJson());

      // Return the updated conversation
      return conversation;
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to update conversation',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      // For a chat app, we might prefer soft delete
      // For now, we'll do hard delete for simplicity in MVP
      await _conversationsRef.doc(conversationId).delete();
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to delete conversation',
        originalError: e,
      );
    }
  }

  @override
  Stream<List<ConversationModel>> watchConversationsForUser(
    String userId, {
    int limit = 50,
  }) {
    try {
      return _conversationsRef
          .where('participantIds', arrayContains: userId)
          .orderBy('lastUpdatedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ConversationModel.fromJson(doc.data()))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to watch conversations',
        originalError: e,
      );
    }
  }

  @override
  Future<ConversationModel?> findDirectConversation(
    String userId1,
    String userId2,
  ) async {
    try {
      // Query for direct conversations where both users are participants
      final querySnapshot = await _conversationsRef
          .where('type', isEqualTo: 'direct')
          .where('participantIds', arrayContains: userId1)
          .get();

      // Filter results to find conversation with exactly these two users
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final participantIds = List<String>.from(data['participantIds'] as List);

        if (participantIds.length == 2 &&
            participantIds.contains(userId1) &&
            participantIds.contains(userId2)) {
          return ConversationModel.fromJson(data);
        }
      }

      return null;
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to find direct conversation',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateLastMessage(
    String conversationId,
    String messageText,
    String senderId,
    String senderName,
    DateTime timestamp,
  ) async {
    try {
      await _conversationsRef.doc(conversationId).update({
        'lastMessage': {
          'text': messageText,
          'senderId': senderId,
          'senderName': senderName,
          'timestamp': Timestamp.fromDate(timestamp),
          'type': 'text', // Required field for LastMessageModel.fromJson()
        },
        'lastUpdatedAt': Timestamp.fromDate(timestamp),
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to update last message',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateUnreadCount(
    String conversationId,
    String userId,
    int count,
  ) async {
    try {
      await _conversationsRef.doc(conversationId).update({
        'unreadCount.$userId': count,
      });
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    } catch (e) {
      throw UnknownException(
        message: 'Failed to update unread count',
        originalError: e,
      );
    }
  }

  /// Map Firestore exceptions to app exceptions
  AppException _mapFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const UnauthorizedException(
          message: 'You do not have permission to access this resource',
        );
      case 'not-found':
        return const RecordNotFoundException(recordType: 'Document');
      case 'already-exists':
        return const RecordAlreadyExistsException(recordType: 'Document');
      case 'resource-exhausted':
        return const RateLimitExceededException();
      case 'failed-precondition':
        return const ConstraintViolationException(
          message: 'Operation failed due to constraint violation',
        );
      case 'aborted':
        return const ServerException(
          message: 'Operation was aborted. Please try again',
        );
      case 'out-of-range':
        return const ValidationException(
          message: 'Invalid range for operation',
          fieldErrors: {},
        );
      case 'unimplemented':
        return const NotImplementedException(
          message: 'This operation is not implemented',
        );
      case 'unavailable':
        return const NoInternetException();
      case 'deadline-exceeded':
        return const NetworkTimeoutException();
      default:
        return ServerException(message: 'Firestore error: ${e.message}');
    }
  }
}
